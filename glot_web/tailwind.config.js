/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["../glot_core/**/*_page.rs"],
  theme: {
    extend: {},
  },
  plugins: [require("@tailwindcss/forms")],
};
