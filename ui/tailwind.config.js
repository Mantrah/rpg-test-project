/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'das-blue': '#003B7A',
        'das-light-blue': '#0066CC',
        'das-gray': '#F5F5F5',
        'das-dark-gray': '#333333',
      }
    },
  },
  plugins: [],
}
