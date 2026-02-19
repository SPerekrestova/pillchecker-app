import { test, expect } from "./fixtures/tunnel";
import { seedHistory, clearHistory, makeCheck } from "./helpers/seed-history";

test.describe("History & CheckDetail", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
    await clearHistory(page);
    await page.evaluate(() => sessionStorage.clear());
    await page.reload();
  });

  test("H1: empty state", async ({ page }) => {
    await expect(page.getByText("No checks yet")).toBeVisible();
    await expect(page.getByText("0 checks")).toBeVisible();
  });

  test("H2: record appears after seeding", async ({ page }) => {
    await seedHistory(page, [makeCheck({ drugA: "aspirin", drugB: "lisinopril" })]);
    await page.reload();

    await expect(page.getByText("1 check")).toBeVisible();
    await expect(page.getByText(/aspirin \+ lisinopril/i)).toBeVisible();
  });

  test("H3: multiple records newest first", async ({ page }) => {
    const now = Date.now();
    await seedHistory(page, [
      makeCheck({ drugA: "oldest", drugB: "drug", checkedAt: new Date(now - 20_000).toISOString() }),
      makeCheck({ drugA: "middle", drugB: "drug", checkedAt: new Date(now - 10_000).toISOString() }),
      makeCheck({ drugA: "newest", drugB: "drug", checkedAt: new Date(now).toISOString() }),
    ]);
    await page.reload();

    const cards = page.locator("button.w-full.text-left");
    await expect(cards).toHaveCount(3);
    await expect(cards.first()).toContainText("newest");
    await expect(cards.last()).toContainText("oldest");
  });

  test("H4: sort by Drug A", async ({ page }) => {
    const now = Date.now();
    await seedHistory(page, [
      makeCheck({ drugA: "Zolpidem", drugB: "x", checkedAt: new Date(now).toISOString() }),
      makeCheck({ drugA: "Aspirin", drugB: "x", checkedAt: new Date(now - 1000).toISOString() }),
      makeCheck({ drugA: "Metformin", drugB: "x", checkedAt: new Date(now - 2000).toISOString() }),
    ]);
    await page.reload();

    // Open sort dropdown
    await page.getByRole("button", { name: /Newest First/i }).click();
    await page.getByRole("menuitem", { name: /Drug A/i }).click();

    const cards = page.locator("button.w-full.text-left");
    await expect(cards.first()).toContainText("Aspirin");
    await expect(cards.last()).toContainText("Zolpidem");
  });

  test("H5: sort by Drug B", async ({ page }) => {
    const now = Date.now();
    await seedHistory(page, [
      makeCheck({ drugA: "x", drugB: "Warfarin", checkedAt: new Date(now).toISOString() }),
      makeCheck({ drugA: "x", drugB: "Amlodipine", checkedAt: new Date(now - 1000).toISOString() }),
    ]);
    await page.reload();

    await page.getByRole("button", { name: /Newest First/i }).click();
    await page.getByRole("menuitem", { name: /Drug B/i }).click();

    const cards = page.locator("button.w-full.text-left");
    await expect(cards.first()).toContainText("Amlodipine");
  });

  test("H6: search filters results", async ({ page }) => {
    await seedHistory(page, [
      makeCheck({ drugA: "ibuprofen", drugB: "warfarin" }),
      makeCheck({ drugA: "aspirin", drugB: "lisinopril" }),
    ]);
    await page.reload();
    await expect(page.getByText("2 checks")).toBeVisible();

    await page.getByPlaceholder("Search by drug name...").fill("aspirin");
    const cards = page.locator("button.w-full.text-left");
    await expect(cards).toHaveCount(1);
    await expect(cards.first()).toContainText("aspirin");
  });

  test("H7: search no match", async ({ page }) => {
    await seedHistory(page, [makeCheck()]);
    await page.reload();
    await page.getByPlaceholder("Search by drug name...").fill("zzzznonexistent");
    await expect(page.getByText("No checks yet")).toBeVisible();
  });

  test("H8: view check detail", async ({ page }) => {
    const check = makeCheck({
      drugA: "ibuprofen",
      drugB: "warfarin",
      safe: false,
      source: "manual",
    });
    await seedHistory(page, [check]);
    await page.reload();

    await page.getByText(/ibuprofen \+ warfarin/i).click();

    // CheckDetail page
    await expect(page.getByText("ibuprofen + warfarin")).toBeVisible();
    await expect(page.getByText("Unsafe")).toBeVisible();
    await expect(page.getByText("Manual")).toBeVisible();
    await expect(page.getByText("MAJOR")).toBeVisible();
  });

  test("H9: delete from detail", async ({ page }) => {
    await seedHistory(page, [makeCheck({ drugA: "toDelete", drugB: "drug" })]);
    await page.reload();
    await page.getByText(/toDelete/i).click();

    await page.getByRole("button", { name: /Delete from History/i }).click();
    await page.getByRole("button", { name: /^Delete$/i }).click();

    // Back on History, record gone
    await page.getByText("My Checks").waitFor();
    await expect(page.getByText("0 checks")).toBeVisible();
  });

  test("H10: cancel delete", async ({ page }) => {
    await seedHistory(page, [makeCheck({ drugA: "keepMe", drugB: "drug" })]);
    await page.reload();
    await page.getByText(/keepMe/i).click();

    await page.getByRole("button", { name: /Delete from History/i }).click();
    await page.getByRole("button", { name: /Cancel/i }).click();

    // Record still visible
    await expect(page.getByText("keepMe + drug")).toBeVisible();
  });

  test("H11: detail not found", async ({ page }) => {
    await page.goto("/history/nonexistent-uuid-12345");
    await expect(page.getByText("Not Found")).toBeVisible();
    await expect(page.getByText("Check not found")).toBeVisible();
  });
});
