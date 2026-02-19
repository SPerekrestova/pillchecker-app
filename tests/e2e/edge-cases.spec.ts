import { test, expect } from "./fixtures/tunnel";
import { clearHistory } from "./helpers/seed-history";

test.describe("Edge Cases & Error States", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
    await clearHistory(page);
    await page.evaluate(() => sessionStorage.clear());
  });

  /** Helper: fill both slots with given names via free-text entry */
  async function fillBothSlots(
    page: import("@playwright/test").Page,
    drugA: string,
    drugB: string
  ) {
    await page.goto("/new");
    await page.locator("button", { hasText: "Type" }).first().click();
    await page.getByPlaceholder("Type drug name...").fill(drugA);
    await page.getByPlaceholder("Type drug name...").press("Enter");
    await page.locator("button", { hasText: "Type" }).first().click();
    await page.getByPlaceholder("Type drug name...").fill(drugB);
    await page.getByPlaceholder("Type drug name...").press("Enter");
  }

  test("E1: backend unreachable shows error toast", async ({ page }) => {
    await fillBothSlots(page, "ibuprofen", "warfarin");

    // Intercept API calls — abort them
    await page.route("**/interactions", (route) => route.abort("connectionrefused"));

    await page.getByRole("button", { name: /Check Interactions/i }).click();
    await expect(page.getByText(/Can't reach server/i)).toBeVisible({ timeout: 10_000 });

    // Button should re-enable
    await expect(page.getByRole("button", { name: /Check Interactions/i })).toBeEnabled();
  });

  test("E2: backend timeout shows timeout toast", async ({ page }) => {
    test.setTimeout(60_000);
    await fillBothSlots(page, "ibuprofen", "warfarin");

    // Intercept and delay beyond the 30s timeout
    await page.route("**/interactions", async (route) => {
      await new Promise((r) => setTimeout(r, 35_000));
      await route.fulfill({ status: 200, body: "{}" });
    });

    await page.getByRole("button", { name: /Check Interactions/i }).click();
    await expect(page.getByText(/timed out/i)).toBeVisible({ timeout: 45_000 });
  });

  test("E3: backend 500 shows server error toast", async ({ page }) => {
    await fillBothSlots(page, "ibuprofen", "warfarin");

    await page.route("**/interactions", (route) =>
      route.fulfill({ status: 500, body: "Internal Server Error" })
    );

    await page.getByRole("button", { name: /Check Interactions/i }).click();
    await expect(page.getByText(/Server error.*500/i)).toBeVisible({ timeout: 10_000 });
  });

  test("E4: backend 422 shows invalid request toast", async ({ page }) => {
    await fillBothSlots(page, "ibuprofen", "warfarin");

    await page.route("**/interactions", (route) =>
      route.fulfill({
        status: 422,
        contentType: "application/json",
        body: JSON.stringify({ detail: [{ msg: "validation error" }] }),
      })
    );

    await page.getByRole("button", { name: /Check Interactions/i }).click();
    await expect(page.getByText(/Invalid request/i)).toBeVisible({ timeout: 10_000 });
  });

  test("E5: RxNorm API down shows no suggestions gracefully", async ({ page }) => {
    await page.goto("/new");

    // Block RxNorm API before navigating to search
    await page.route("**/rxnav.nlm.nih.gov/**", (route) => route.abort("connectionrefused"));

    await page.locator("button", { hasText: "Type" }).first().click();
    await page.getByPlaceholder("Type drug name...").fill("ibuprofen");
    await page.waitForTimeout(1000); // debounce + attempt

    await expect(page.getByText("No suggestions found")).toBeVisible();
    // No crash — Enter still works
    await page.getByPlaceholder("Type drug name...").press("Enter");
    await expect(page.getByText("ibuprofen")).toBeVisible();
  });

  test("E6: very long drug name", async ({ page }) => {
    const longName = "A".repeat(500);
    await fillBothSlots(page, longName, "warfarin");

    // Should not crash — slot shows something
    await expect(page.getByRole("button", { name: /Check Interactions/i })).toBeEnabled();
  });

  test("E7: XSS attempt in drug name", async ({ page }) => {
    const xss = "<script>alert(1)</script>";

    // Listen for dialogs before filling slots
    let alertFired = false;
    page.on("dialog", () => {
      alertFired = true;
    });

    await fillBothSlots(page, xss, "warfarin");

    // Should render as text, not execute
    await expect(page.getByText(xss)).toBeVisible();
    expect(alertFired).toBe(false);
  });

  test("E8: unicode drug name", async ({ page }) => {
    await fillBothSlots(page, "\u0418\u0431\u0443\u043F\u0440\u043E\u0444\u0435\u043D", "warfarin");
    await expect(page.getByText("\u0418\u0431\u0443\u043F\u0440\u043E\u0444\u0435\u043D")).toBeVisible();
    await expect(page.getByRole("button", { name: /Check Interactions/i })).toBeEnabled();
  });

  test("E9: rapid double-click sends single request", async ({ page }) => {
    await fillBothSlots(page, "ibuprofen", "warfarin");

    let requestCount = 0;
    await page.route("**/interactions", async (route) => {
      requestCount++;
      await route.continue();
    });

    const btn = page.getByRole("button", { name: /Check Interactions/i });
    // Double-click rapidly
    await btn.click();
    await btn.click({ force: true }).catch(() => {}); // may be disabled already

    await page.getByText("Results").waitFor({ timeout: 30_000 });
    expect(requestCount).toBe(1);
  });

  test("E10: IndexedDB unavailable — history handles gracefully", async ({ page }) => {
    // Delete all databases before loading
    await page.evaluate(() => indexedDB.deleteDatabase("pillchecker"));

    // Block IndexedDB opens
    await page.evaluate(() => {
      const original = indexedDB.open.bind(indexedDB);
      indexedDB.open = (...args: Parameters<typeof original>) => {
        const req = original(...args);
        setTimeout(() => {
          Object.defineProperty(req, "error", {
            value: new DOMException("blocked"),
          });
          req.dispatchEvent(new Event("error"));
        }, 0);
        return req;
      };
    });

    await page.goto("/");
    // Should not crash — either shows empty state or error, but page renders
    await expect(page.getByText("My Checks")).toBeVisible();
  });

  test("E11: concurrent slot filling", async ({ page }) => {
    await page.goto("/new");

    // Fill slot 0
    await page.locator("button", { hasText: "Type" }).first().click();
    await page.getByPlaceholder("Type drug name...").fill("drugA");
    await page.getByPlaceholder("Type drug name...").press("Enter");

    // Immediately fill slot 1
    await page.locator("button", { hasText: "Type" }).first().click();
    await page.getByPlaceholder("Type drug name...").fill("drugB");
    await page.getByPlaceholder("Type drug name...").press("Enter");

    // Both should be correctly filled
    await expect(page.getByText("drugA")).toBeVisible();
    await expect(page.getByText("drugB")).toBeVisible();
  });

  test("E12: invalid slot index in URL", async ({ page }) => {
    // Numeric out of bounds
    await page.goto("/scan/99");
    // Should not crash — page renders
    await expect(page.locator("header")).toBeVisible();

    // Non-numeric
    await page.goto("/scan/abc");
    await expect(page.locator("header")).toBeVisible();
  });
});
