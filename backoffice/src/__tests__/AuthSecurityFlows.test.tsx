import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { ThemeProvider } from '../context/ThemeContext';
import { ForgotPasswordPage } from '../features/auth/ForgotPasswordPage';
import { LoginPage } from '../features/auth/LoginPage';
import { authApi } from '../lib/api';
import { useAuthStore } from '../stores/authStore';

describe('Auth security & 2FA flows', () => {
  beforeEach(() => {
    localStorage.clear();
    localStorage.setItem('toc_theme', 'light');
    if (typeof window.matchMedia !== 'function') {
      Object.defineProperty(window, 'matchMedia', {
        writable: true,
        value: vi.fn().mockImplementation((query: string) => ({
          matches: false,
          media: query,
          onchange: null,
          addListener: vi.fn(),
          removeListener: vi.fn(),
          addEventListener: vi.fn(),
          removeEventListener: vi.fn(),
          dispatchEvent: vi.fn(),
        })),
      });
    }
    useAuthStore.setState({ user: null, token: null, isAuthenticated: false, isPinLocked: false });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('prompts for 2FA TOTP challenge on superadmin login and completes auth on code validation', async () => {
    vi.spyOn(authApi, 'login').mockResolvedValue({
      access_token: '',
      refresh_token: '',
      token_type: 'bearer',
      requires_2fa: true,
      challenge_token: 'challenge-jwt',
      user: {
        id: 'sa-1',
        username: 'superroot',
        role: 'superadmin',
        permissions: ['*'],
        has_pin: false,
        totp_enabled: true,
      },
    });

    const verifySpy = vi.spyOn(authApi, 'verify2faChallenge').mockResolvedValue({
      access_token: 'real-access-jwt',
      refresh_token: 'real-refresh-jwt',
      token_type: 'bearer',
      requires_2fa: false,
      user: {
        id: 'sa-1',
        username: 'superroot',
        role: 'superadmin',
        permissions: ['*'],
        has_pin: false,
        totp_enabled: true,
      },
    });

    render(
      <ThemeProvider>
        <MemoryRouter>
          <LoginPage />
        </MemoryRouter>
      </ThemeProvider>
    );

    fireEvent.change(screen.getByPlaceholderText('Ex: admin ou caissier1'), { target: { value: 'superroot' } });
    fireEvent.change(screen.getByPlaceholderText('********'), { target: { value: 'Secret123!' } });
    fireEvent.click(screen.getByRole('button', { name: /Se connecter/i }));

    expect(await screen.findByText(/Validation 2FA Super-Administrateur/i)).toBeInTheDocument();

    fireEvent.change(screen.getByPlaceholderText('000000'), { target: { value: '123456' } });
    fireEvent.click(screen.getByRole('button', { name: /Valider le code 2FA/i }));

    await waitFor(() => {
      expect(verifySpy).toHaveBeenCalledWith('challenge-jwt', '123456');
    });
    expect(localStorage.getItem('toc_access_token')).toBe('real-access-jwt');
  });

  it('submits forgot password email request and shows confirmation banner', async () => {
    const forgotSpy = vi.spyOn(authApi, 'forgotPassword').mockResolvedValue({
      status: 'ok',
      message: 'Lien envoye si le compte existe.',
    });

    render(
      <MemoryRouter>
        <ForgotPasswordPage />
      </MemoryRouter>
    );

    fireEvent.change(screen.getByPlaceholderText('vous@boutique.com'), {
      target: { value: 'merchant@tocmanager.com' },
    });
    fireEvent.click(screen.getByRole('button', { name: /Envoyer le lien/i }));

    await waitFor(() => {
      expect(forgotSpy).toHaveBeenCalledWith('merchant@tocmanager.com');
    });
    expect(await screen.findByText('Lien envoye si le compte existe.')).toBeInTheDocument();
  });
});
