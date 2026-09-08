import { defineConfig } from "vite";

export default defineConfig(({ command }) => ({
  base: command === "build" ? "/static/" : "/",
  build: {
    outDir: "../glot_backend/priv/static",
    emptyOutDir: true,
    manifest: "manifest.json",
    rollupOptions: {
      input: {
        frontend: new URL("./js/public.ts", import.meta.url).pathname,
        admin: new URL("./js/admin.ts", import.meta.url).pathname,
        styles: new URL("./js/styles.ts", import.meta.url).pathname,
      },
      output: {
        entryFileNames: "assets/[name]-[hash].js",
        assetFileNames: "assets/[name]-[hash][extname]",
        chunkFileNames: "assets/[name]-[hash].js",
      },
    },
  },
  server: {
    proxy: {
      "/api": {
        target: "http://127.0.0.1:3000",
      },
      "/ads": {
        target: "http://127.0.0.1:3000",
      },
    },
  },
}));
