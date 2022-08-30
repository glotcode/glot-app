/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["../glot_core/**/*.rs"],
  theme: {
    extend: {},
  },
  plugins: [require("@tailwindcss/forms")],
};
