import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { RegisterPage } from '../features/landing/RegisterPage';
import { saasApi } from '../lib/api';

describe('RegisterPage', () => {
  beforeEach(() => {
    localStorage.clear();
    vi.spyOn(saasApi, 'getPlans').mockResolvedValue([]);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  const renderPage = () =>
    render(
      <MemoryRouter initialEntries={['/register?plan=pro']}>
        <RegisterPage />
      </MemoryRouter>
    );

  it('blocks step 1 when password has fewer than 6 characters', async () => {
    renderPage();
    fireEvent.change(screen.getByPlaceholderText('Ex: Amadou Diallo'), {
      target: { value: 'Amadou Diallo' },
    });
    fireEvent.change(screen.getByPlaceholderText('amadou@boutique.com'), {
      target: { value: 'amadou@toc.com' },
    });
    fireEvent.change(screen.getByPlaceholderText('Minimum 6 caractères'), {
      target: { value: '12345' },
    });
    fireEvent.click(screen.getByRole('button', { name: /Continuer vers mon Entreprise/i }));

    expect(
      await screen.findByText(/Le mot de passe doit comporter au moins 6 caractères\./i)
    ).toBeInTheDocument();
  });

  it('requires terms acceptance before submitting credentials', async () => {
    renderPage();
    fireEvent.change(screen.getByPlaceholderText('Ex: Amadou Diallo'), {
      target: { value: 'Amadou Diallo' },
    });
    fireEvent.change(screen.getByPlaceholderText('amadou@boutique.com'), {
      target: { value: 'amadou@toc.com' },
    });
    fireEvent.change(screen.getByPlaceholderText('Minimum 6 caractères'), {
      target: { value: 'Secret123' },
    });
    fireEvent.click(screen.getByRole('button', { name: /Continuer vers mon Entreprise/i }));

    expect(
      await screen.findByText(/Veuillez accepter les Conditions Générales d'Utilisation\./i)
    ).toBeInTheDocument();
  });

  it('registers normalized credentials and transitions to step 2', async () => {
    const regSpy = vi.spyOn(saasApi, 'registerCredentials').mockResolvedValue({
      access_token: 'step1-jwt',
      token_type: 'bearer',
      user_id: 'u-1',
    });

    renderPage();
    fireEvent.change(screen.getByPlaceholderText('Ex: Amadou Diallo'), {
      target: { value: '  Amadou Diallo  ' },
    });
    fireEvent.change(screen.getByPlaceholderText('amadou@boutique.com'), {
      target: { value: 'AMADOU@Toc.Com' },
    });
    fireEvent.change(screen.getByPlaceholderText('Minimum 6 caractères'), {
      target: { value: 'Secret123' },
    });
    fireEvent.click(screen.getByRole('checkbox'));
    fireEvent.click(screen.getByRole('button', { name: /Continuer vers mon Entreprise/i }));

    await waitFor(() => {
      expect(regSpy).toHaveBeenCalledWith({
        full_name: 'Amadou Diallo',
        username_or_email: 'amadou@toc.com',
        password: 'Secret123',
        phone: undefined,
      });
    });
    expect(localStorage.getItem('toc_access_token')).toBe('step1-jwt');
    expect(await screen.findByText(/Configurez votre Entreprise/i)).toBeInTheDocument();
  });
});
