import { test, expect } from "./fixtures/tunnel";
import { clearHistory } from "./helpers/seed-history";

test.describe("Manual Entry Flow", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
    await clearHistory(page);
    await page.evaluate(() => sessionStorage.clear());
    await page.reload();
  });

  test("M1: happy path — interaction found", async ({ page }) => {
    // Open new check
    await page.locator("button:has(.lucide-plus)").click();
    await page.getByRole("button", { name: /Scan Medicine/i }).click();

    // Type slot 0
    await page.getByText("Drug 1").waitFor();
    await page.locator("button", { hasText: "Type" }).first().click();
    await page.getByPlaceholder("Type drug name...").fill("ibuprofen");
    await page.waitForTimeout(500); // debounce
    // Wait for suggestions or press Enter
    const suggestion = page.locator("button", { hasText: /ibuprofen/i }).first();
    if (await suggestion.isVisible({ timeout: 5000 }).catch(() => false)) {
      await suggestion.click();
    } else {
      await page.getByPlaceholder("Type drug name...").press("Enter");
    }

    // Should be back on DrugInput with slot 0 filled
    await page.getByText("Drug 1").waitFor();

    // Type slot 1
    await page.locator("button", { hasText: "Type" }).first().click();
    await page.getByPlaceholder("Type drug name...").fill("warfarin");
    await page.waitForTimeout(500);
    const suggestion2 = page.locator("button", { hasText: /warfarin/i }).first();
    if (await suggestion2.isVisible({ timeout: 5000 }).catch(() => false)) {
      await suggestion2.click();
    } else {
      await page.getByPlaceholder("Type drug name...").press("Enter");
    }

    // Check interactions
    await page.getByRole("button", { name: /Check Interactions/i }).click();

    // Should see results with interactions
    await page.getByText("Results").waitFor();
    await expect(
      page.locator("text=MAJOR").or(page.locator("text=MODERATE")).or(page.locator("text=MINOR"))
    ).toBeVisible();
  });

  test("M2: happy path — safe pair", async ({ page }) => {
    await page.locator("button:has(.lucide-plus)").click();
    await page.getByRole("button", { name: /Scan Medicine/i }).click();

    // Slot 0
    await page.locator("button", { hasText: "Type" }).first().click();
    await page.getByPlaceholder("Type drug name...").fill("paracetamol");
    await page.getByPlaceholder("Type drug name...").press("Enter");

    // Slot 1
    await page.locator("button", { hasText: "Type" }).first().click();
    await page.getByPlaceholder("Type drug name...").fill("omeprazole");
    await page.getByPlaceholder("Type drug name...").press("Enter");

    await page.getByRole("button", { name: /Check Interactions/i }).click();
    await page.getByText("No known interactions found").waitFor();
  });

  test("M3: RxNorm autocomplete appears", async ({ page }) => {
    // Mock RxNorm API for reliable results (external API can be slow/empty)
    await page.route("**/rxnav.nlm.nih.gov/**", (route) =>
      route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          approximateGroup: {
            candidate: [
              { rxcui: "5640", rxaui: "1", score: "100" },
            ],
          },
        }),
      })
    );
    // Also mock the rxcui properties lookup
    await page.route("**/rxcui/5640/properties.json", (route) =>
      route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          properties: { rxcui: "5640", name: "ibuprofen" },
        }),
      })
    );

    await page.locator("button:has(.lucide-plus)").click();
    await page.getByRole("button", { name: /Scan Medicine/i }).click();
    await page.locator("button", { hasText: "Type" }).first().click();

    await page.getByPlaceholder("Type drug name...").fill("ibup");
    // Wait for debounce + mocked API call
    await expect(
      page.locator("button", { hasText: /ibuprofen/i }).first()
    ).toBeVisible({ timeout: 10_000 });
  });

  test("M4: free-text Enter uses typed value", async ({ page }) => {
    await page.locator("button:has(.lucide-plus)").click();
    await page.getByRole("button", { name: /Scan Medicine/i }).click();
    await page.locator("button", { hasText: "Type" }).first().click();

    await page.getByPlaceholder("Type drug name...").fill("CustomDrug123");
    await page.getByPlaceholder("Type drug name...").press("Enter");

    // Back on DrugInput, slot shows the custom name
    await expect(page.getByText("CustomDrug123")).toBeVisible();
  });

  test("M5: clear filled slot", async ({ page }) => {
    await page.locator("button:has(.lucide-plus)").click();
    await page.getByRole("button", { name: /Scan Medicine/i }).click();

    // Fill slot 0
    await page.locator("button", { hasText: "Type" }).first().click();
    await page.getByPlaceholder("Type drug name...").fill("ibuprofen");
    await page.getByPlaceholder("Type drug name...").press("Enter");
    await expect(page.getByText("ibuprofen")).toBeVisible();

    // Clear it
    await page.getByLabel("Clear drug").first().click();

    // Scan/Type buttons should reappear for Drug 1
    await expect(page.locator("button", { hasText: "Scan" }).first()).toBeVisible();
  });

  test("M6: check button disabled until both filled", async ({ page }) => {
    await page.locator("button:has(.lucide-plus)").click();
    await page.getByRole("button", { name: /Scan Medicine/i }).click();

    // Button should be disabled initially
    await expect(page.getByRole("button", { name: /Check Interactions/i })).toBeDisabled();

    // Fill only slot 0
    await page.locator("button", { hasText: "Type" }).first().click();
    await page.getByPlaceholder("Type drug name...").fill("ibuprofen");
    await page.getByPlaceholder("Type drug name...").press("Enter");

    // Still disabled — only one slot filled
    await expect(page.getByRole("button", { name: /Check Interactions/i })).toBeDisabled();
  });

  test("M7: save & start over adds to history", async ({ page }) => {
    // Complete a full check
    await page.locator("button:has(.lucide-plus)").click();
    await page.getByRole("button", { name: /Scan Medicine/i }).click();

    await page.locator("button", { hasText: "Type" }).first().click();
    await page.getByPlaceholder("Type drug name...").fill("ibuprofen");
    await page.getByPlaceholder("Type drug name...").press("Enter");

    await page.locator("button", { hasText: "Type" }).first().click();
    await page.getByPlaceholder("Type drug name...").fill("warfarin");
    await page.getByPlaceholder("Type drug name...").press("Enter");

    await page.getByRole("button", { name: /Check Interactions/i }).click();
    await page.getByText("Results").waitFor();
    await page.getByRole("button", { name: /Save & Start Over/i }).click();

    // Should be on History with 1 record
    await page.getByText("My Checks").waitFor();
    await expect(page.getByText("1 check")).toBeVisible();
    await expect(page.getByText(/ibuprofen \+ warfarin/i)).toBeVisible();
  });

  test("M8: same drug in both slots does not crash", async ({ page }) => {
    await page.locator("button:has(.lucide-plus)").click();
    await page.getByRole("button", { name: /Scan Medicine/i }).click();

    await page.locator("button", { hasText: "Type" }).first().click();
    await page.getByPlaceholder("Type drug name...").fill("ibuprofen");
    await page.getByPlaceholder("Type drug name...").press("Enter");

    await page.locator("button", { hasText: "Type" }).first().click();
    await page.getByPlaceholder("Type drug name...").fill("ibuprofen");
    await page.getByPlaceholder("Type drug name...").press("Enter");

    await page.getByRole("button", { name: /Check Interactions/i }).click();
    // Should not crash — either results or safe screen
    await page.getByText("Results").waitFor();
  });
});
