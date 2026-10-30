/** @type {import('tailwindcss').Config} */
const withMT = require("@material-tailwind/react/utils/withMT");
export default withMT({
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        varela: ["Varela Round", "sans-serif"],
        concert: ["Concert One", "serif"],
        dyna: ["DynaPuff", "serif"],
        pangolin: ["Pangolin", "serif"],
        playpen: ["Playpen Sans", "serif"],
        playwrite: ["Playwrite GB S", "serif"],
        shortstack: ["Short Stack", "serif"],
        sofia: ["Sofia Sans", "serif"],
        holtwood: ["Holtwood One SC", "serif"],
        dm: ["DM Serif Text", "serif"],
        parkinsans: ["Parkinsans", "serif"],
      },
      colors: {
        primary: {
          DEFAULT: "#004080",  // Base color
          light: "#336699",   // Lighter shade
          dark: "#00264D",    // Darker shade
        },
        secondary: {
          DEFAULT: "#E53777",  // Base color
          light: "#F06395",    // Lighter shade
          dark: "#A82655",     // Darker shade
        },
        accent: {
          yellow: "#FFC107",   // Accent color: Yellow
          green: "#4CAF50",    // Accent color: Green
          orange: "#FF5722",   // Accent color: Orange
        },
        neutral: {
          light: "#F9F9F9",    // Very light neutral
          DEFAULT: "#E5E5E5",  // Base neutral
          dark: "#7A7A7A",     // Dark neutral
        },
        danger: {
          DEFAULT: "#FF0000",  // Danger color (red)
          light: "#FF6666",    // Lighter red
          dark: "#B20000",     // Darker red
        },
        success: {
          DEFAULT: "#4CAF50",  // Success color (green)
          light: "#81C784",    // Lighter green
          dark: "#388E3C",     // Darker green
        },
        info: {
          DEFAULT: "#2196F3",  // Info color (blue)
          light: "#64B5F6",    // Lighter blue
          dark: "#1976D2",     // Darker blue
        },
        warning: {
          DEFAULT: "#FFC107",  // Warning color (yellow)
          light: "#FFD54F",    // Lighter yellow
          dark: "#FFA000",     // Darker yellow
        },
        lightbg: "#F5F5DC",
      },
    },
  },
  plugins: [
    require('@tailwindcss/line-clamp'),
    require('@tailwindcss/forms'),
  ],
});

