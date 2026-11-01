/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#f0f5ff',
          100: '#e5edff',
          200: '#cddbfe',
          300: '#b4c6fc',
          400: '#8da2fb',
          500: '#6366f1', // Primary indigo/blue
          600: '#4f46e5',
          700: '#4338ca',
          800: '#3730a3',
          900: '#1e1b4b',
        },
        toc: {
          dark: '#0f172a',
          card: '#ffffff',
          border: '#e2e8f0',
          muted: '#64748b',
          bg: '#f8fafc',
        }
      },
    },
  },
  plugins: [],
}
