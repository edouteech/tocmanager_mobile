/** @type {import('tailwindcss').Config} */
export default {
  darkMode: 'class',
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#F0F9FE',
          100: '#E8F5FD',
          200: '#BAE3F9',
          300: '#7DC8F3',
          400: '#38ACEC',
          500: '#29ABE2', // Primary Brand Mobile
          600: '#1A8FBF', // Hover / Dark Primary
          700: '#147198',
          800: '#125B7B',
          900: '#134B64',
          950: '#0C3042',
        },
        toc: {
          primary: '#29ABE2',
          primaryDark: '#1A8FBF',
          primaryLight: '#E8F5FD',
          primarySurface: '#F0F9FE',
          success: '#27AE60',
          successLight: '#E8F8F0',
          warning: '#F39C12',
          warningLight: '#FEF5E7',
          danger: '#E74C3C',
          dangerLight: '#FDEBE9',
          purple: '#8E44AD',
          purpleLight: '#F5EEF8',
          surface: '#F0F9FE',
          bg: '#F5FAFD',
          cardBg: '#FFFFFF',
          divider: '#E8EFF5',
          dark: '#1C2B3A',
          medium: '#5A7184',
          light: '#9FB3C8',
        },
        dark: {
          900: '#0B131B', // Dark main page bg
          800: '#121E2A', // Dark container / sidebar bg
          700: '#1C2B3A', // Dark card / header bg
          600: '#26384C', // Dark border / divider
          500: '#3D546D',
        }
      },
      fontFamily: {
        sans: ['"Plus Jakarta Sans"', 'Inter', 'system-ui', 'sans-serif'],
      },
      boxShadow: {
        'soft': '0 2px 10px rgba(28, 43, 58, 0.04)',
        'soft-md': '0 4px 16px rgba(28, 43, 58, 0.08)',
        'soft-lg': '0 10px 30px rgba(28, 43, 58, 0.12)',
        'glow-cyan': '0 0 20px rgba(41, 171, 226, 0.25)',
      },
      borderRadius: {
        'xl': '12px',
        '2xl': '16px',
        '3xl': '20px',
      },
      animation: {
        'fade-in': 'fadeIn 0.2s ease-out forwards',
        'slide-in-right': 'slideInRight 0.25s cubic-bezier(0.16, 1, 0.3, 1) forwards',
        'pulse-subtle': 'pulseSubtle 2.5s infinite',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0', transform: 'scale(0.98)' },
          '100%': { opacity: '1', transform: 'scale(1)' },
        },
        slideInRight: {
          '0%': { transform: 'translateX(100%)' },
          '100%': { transform: 'translateX(0)' },
        },
        pulseSubtle: {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.6' },
        }
      }
    },
  },
  plugins: [],
}