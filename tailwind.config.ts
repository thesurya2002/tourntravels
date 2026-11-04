import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: ["class"],
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        background: "#FBF4E6",
        foreground: "#2B2B2B",
        primary: "#0F5C63",
        "primary-dark": "#0A3F44",
        accent: "#F28C38",
        muted: "#6B6B6B",
        border: "#E3D9C4",
        ring: "#0F5C63",
        card: "#F7F0E6"
      },
      borderRadius: {
        card: "1rem",
        control: "0.75rem"
      },
      boxShadow: {
        paper: "0 10px 30px rgba(15, 92, 99, 0.08)"
      }
    }
  },
  plugins: []
};

export default config;
