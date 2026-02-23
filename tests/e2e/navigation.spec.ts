import { test, expect } from "./fixtures/tunnel";
import { clearHistory, seedHistory, makeCheck } from "./helpers/seed-history";

test.describe("Navigation & Routing", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
    await clearHistory(page);
    await page.evaluate(() => sessionStorage.clear());
  });

  test("N1: 404 page", async ({ page }) => {
    await page.goto("/some/random/path");
    await expect(page.getByText("404")).toBeVisible();
    await expect(page.getByText("Page not found")).toBeVisible();
    await page.getByRole("button", { name: /Go Home/i }).click();
    await expect(page.getByText("My Checks")).toBeVisible();
  });

  test("N2: back from DrugInput", async ({ page }) => {
    await page.goto("/new");
    await page.locator(".lucide-arrow-left").first().click();
    await expect(page.getByText("My Checks")).toBeVisible();
  });

  test("N3: back from ScanMedicine", async ({ page }) => {
    // Navigate via UI to build proper history stack
    await page.goto("/new");
    await page.locator("button", { hasText: "Scan" }).first().click();
    await page.getByText("Scan Medicine").waitFor();
    await page.locator(".lucide-arrow-left").first().click();
    // Should go back to DrugInput
    await expect(page.getByText("New Check")).toBeVisible();
  });

  test("N4: back from DrugSearch", async ({ page }) => {
    // Navigate via UI to build proper history stack
    await page.goto("/new");
    await page.locator("button", { hasText: "Type" }).first().click();
    await page.getByText("Search Drug").waitFor();
    await page.locator(".lucide-arrow-left").first().click();
    // Should go back to DrugInput
    await expect(page.getByText("New Check")).toBeVisible();
  });

  test("N5: direct URL /new", async ({ page }) => {
    await page.goto("/new");
    await expect(page.getByText("New Check")).toBeVisible();
    // Both slots should be empty (scan/type buttons visible)
    await expect(page.locator("button", { hasText: "Scan" }).first()).toBeVisible();
  });

  test("N6: direct /results without state redirects home", async ({ page }) => {
    await page.goto("/results");
    await page.waitForURL("/");
    await expect(page.getByText("My Checks")).toBeVisible();
  });

  test("N7: deep link to valid history record", async ({ page }) => {
    const check = makeCheck({ id: "deep-link-test-id", drugA: "deepDrugA", drugB: "deepDrugB" });
    await page.goto("/");
    await seedHistory(page, [check]);

    await page.goto("/history/deep-link-test-id");
    await expect(page.getByText("deepDrugA + deepDrugB")).toBeVisible();
  });

  test("N8: slot state persists in session", async ({ page }) => {
    await page.goto("/new");
    // Fill slot 0 via search
    await page.locator("button", { hasText: "Type" }).first().click();
    await page.getByPlaceholder("Type drug name...").fill("ibuprofen");
    await page.getByPlaceholder("Type drug name...").press("Enter");

    // Slot 0 should show ibuprofen
    await expect(page.getByText("ibuprofen")).toBeVisible();

    // Navigate away and back
    await page.goto("/");
    await page.goto("/new");

    // Slot 0 should still be filled
    await expect(page.getByText("ibuprofen")).toBeVisible();
  });

  test("N9: session cleared after Save & Start Over", async ({ page }) => {
    await page.goto("/new");

    // Fill both slots
    await page.locator("button", { hasText: "Type" }).first().click();
    await page.getByPlaceholder("Type drug name...").fill("ibuprofen");
    await page.getByPlaceholder("Type drug name...").press("Enter");
    await page.locator("button", { hasText: "Type" }).first().click();
    await page.getByPlaceholder("Type drug name...").fill("warfarin");
    await page.getByPlaceholder("Type drug name...").press("Enter");

    await page.getByRole("button", { name: /Check Interactions/i }).click();
    await page.getByText("Results").waitFor();
    await page.getByRole("button", { name: /Save & Start Over/i }).click();

    // Now start new check — slots should be empty
    await page.locator("button:has(.lucide-plus)").click();
    await page.getByRole("button", { name: /Scan Medicine/i }).click();
    await expect(page.locator("button", { hasText: "Scan" }).first()).toBeVisible();
    await expect(page.locator("button", { hasText: "Type" }).first()).toBeVisible();
  });
});
