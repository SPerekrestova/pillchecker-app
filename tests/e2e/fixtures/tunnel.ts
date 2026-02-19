import { test as base, expect } from "@playwright/test";

export const test = base.extend<{ ensureTunnel: void }>({
  ensureTunnel: [
    async ({}, use) => {
      const API = "http://localhost:8000";
      try {
        const health = await fetch(`${API}/health`);
        expect(health.ok).toBe(true);
        const dataHealth = await fetch(`${API}/health/data`);
        expect(dataHealth.ok).toBe(true);
      } catch {
        throw new Error(
          "Backend unreachable at localhost:8000.\n" +
            "Is the SSH tunnel running? Start it with:\n" +
            "  ssh -L 8000:localhost:8000 pillchecker"
        );
      }
      await use();
    },
    { auto: true, scope: "worker" },
  ],
});

export { expect };
