import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react-swc";
import path from "path";

export default defineConfig({
  server: {
    host: "::",
    port: 8080,
  },
  plugins: [react() as any],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  test: {
    environment: "jsdom",
    setupFiles: [],
    exclude: ["tests/e2e/**", "node_modules/**"],
    alias: {
      "@/": new URL("./src/", import.meta.url).pathname,
    },
  },
});
