import { test, expect } from "./fixtures/tunnel";
import { clearHistory } from "./helpers/seed-history";
import { readdir } from "node:fs/promises";
import { join, extname } from "node:path";

const IMAGES_DIR = join(import.meta.dirname, "fixtures/images");
const GENERATED_DIR = join(import.meta.dirname, "fixtures/generated-images");

const IMAGE_EXTENSIONS = new Set([".jpg", ".jpeg", ".png"]);

async function findGoodImage(): Promise<string> {
  const files = await readdir(IMAGES_DIR);
  const img = files.find((f) =>
    IMAGE_EXTENSIONS.has(extname(f).toLowerCase()) && f !== "README.md"
  );
  if (!img) throw new Error(`No image in ${IMAGES_DIR}. Upload medicine images first.`);
  return join(IMAGES_DIR, img);
}

async function findAllGoodImages(): Promise<string[]> {
  const files = await readdir(IMAGES_DIR);
  return files
    .filter((f) => IMAGE_EXTENSIONS.has(extname(f).toLowerCase()))
    .map((f) => join(IMAGES_DIR, f));
}

/** Navigate to DrugInput and click Scan for the given slot (0-indexed) */
async function goToScanSlot(page: import("@playwright/test").Page, slot: number) {
  await page.goto("/new");
  await page.evaluate(() => sessionStorage.clear());
  await page.reload();
  await page.getByText(`Drug ${slot + 1}`).waitFor();
  const scanButtons = page.locator("button", { hasText: "Scan" });
  await scanButtons.nth(slot).click();
}

test.describe("Scan Flow", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
    await clearHistory(page);
    await page.evaluate(() => sessionStorage.clear());
  });

  test("SC1: happy path — clear image recognized", async ({ page }) => {
    const imagePath = await findGoodImage();
    await goToScanSlot(page, 0);

    // Upload image via hidden file input
    const fileInput = page.locator('input[type="file"]');
    await fileInput.setInputFiles(imagePath);

    // Should see processing spinner then result
    await page.getByText("Recognizing medication...").waitFor();

    // Wait for result stage — "Use This Drug" button appears
    await page.getByRole("button", { name: /Use This Drug/i }).waitFor({ timeout: 60_000 });

    // Result stage: drug name input should have a value
    const nameInput = page.locator("input").first();
    await expect(nameInput).not.toHaveValue("");
    await expect(page.getByRole("button", { name: /Use This Drug/i })).toBeEnabled();

    // Use it
    await page.getByRole("button", { name: /Use This Drug/i }).click();

    // Back on DrugInput with slot 0 filled
    await page.getByText("New Check").waitFor();
  });

  test("SC2: edit scanned name before using", async ({ page }) => {
    const imagePath = await findGoodImage();
    await goToScanSlot(page, 0);
    await page.locator('input[type="file"]').setInputFiles(imagePath);

    // Wait for result stage
    await page.getByRole("button", { name: /Use This Drug/i }).waitFor({ timeout: 60_000 });

    // Edit name
    const nameInput = page.locator("input").first();
    await nameInput.clear();
    await nameInput.fill("aspirin");
    await page.getByRole("button", { name: /Use This Drug/i }).click();

    // Back on DrugInput, slot shows "aspirin"
    await expect(page.getByText("aspirin")).toBeVisible();
  });

  test("SC3: retake clears result", async ({ page }) => {
    const imagePath = await findGoodImage();
    await goToScanSlot(page, 0);
    await page.locator('input[type="file"]').setInputFiles(imagePath);
    await page.getByRole("button", { name: /Retake/i }).waitFor({ timeout: 60_000 });

    await page.getByRole("button", { name: /Retake/i }).click();

    // Back to idle stage — "Open Camera" visible
    await expect(page.getByRole("button", { name: /Open Camera/i })).toBeVisible();
  });

  test("SC4: blurry/unreadable image shows error", async ({ page }) => {
    const blurryPath = join(GENERATED_DIR, "blurry.jpg");
    await goToScanSlot(page, 0);
    await page.locator('input[type="file"]').setInputFiles(blurryPath);

    // Should get an error toast and return to idle
    // Either "Could not read text" or "No drug found" depending on OCR result
    await expect(
      page.getByText(/Could not read text|No drug found/i)
    ).toBeVisible({ timeout: 60_000 });
    await expect(page.getByRole("button", { name: /Open Camera/i })).toBeVisible();
  });

  test("SC5: non-medicine text shows no drug found", async ({ page }) => {
    const noTextPath = join(GENERATED_DIR, "no-text.jpg");
    await goToScanSlot(page, 0);
    await page.locator('input[type="file"]').setInputFiles(noTextPath);

    await expect(
      page.getByText(/Could not read text|No drug found/i)
    ).toBeVisible({ timeout: 60_000 });
  });

  test("SC6: full E2E both slots scanned", async ({ page }) => {
    const images = await findAllGoodImages();
    if (images.length < 2) {
      test.skip(true, "Need at least 2 good images for this test");
      return;
    }

    // Scan slot 0
    await page.goto("/new");
    await page.locator("button", { hasText: "Scan" }).first().click();
    await page.locator('input[type="file"]').setInputFiles(images[0]);
    await page.getByRole("button", { name: /Use This Drug/i }).waitFor({ timeout: 60_000 });
    await page.getByRole("button", { name: /Use This Drug/i }).click();

    // Scan slot 1
    await page.locator("button", { hasText: "Scan" }).first().click();
    await page.locator('input[type="file"]').setInputFiles(images[1]);
    await page.getByRole("button", { name: /Use This Drug/i }).waitFor({ timeout: 60_000 });
    await page.getByRole("button", { name: /Use This Drug/i }).click();

    // Check interactions
    await page.getByRole("button", { name: /Check Interactions/i }).click();
    await page.getByText("Results").waitFor({ timeout: 30_000 });

    // Save
    await page.getByRole("button", { name: /Save & Start Over/i }).click();
    await page.getByText("My Checks").waitFor();
  });

  test("SC7: mixed flow — scan + manual", async ({ page }) => {
    const imagePath = await findGoodImage();
    await page.goto("/new");

    // Scan slot 0
    await page.locator("button", { hasText: "Scan" }).first().click();
    await page.locator('input[type="file"]').setInputFiles(imagePath);
    await page.getByRole("button", { name: /Use This Drug/i }).waitFor({ timeout: 60_000 });
    await page.getByRole("button", { name: /Use This Drug/i }).click();

    // Manual slot 1
    await page.locator("button", { hasText: "Type" }).first().click();
    await page.getByPlaceholder("Type drug name...").fill("warfarin");
    await page.getByPlaceholder("Type drug name...").press("Enter");

    await page.getByRole("button", { name: /Check Interactions/i }).click();
    await page.getByText("Results").waitFor({ timeout: 30_000 });
  });

  test("SC8: empty name disables Use button", async ({ page }) => {
    const imagePath = await findGoodImage();
    await goToScanSlot(page, 0);
    await page.locator('input[type="file"]').setInputFiles(imagePath);
    await page.getByRole("button", { name: /Use This Drug/i }).waitFor({ timeout: 60_000 });

    // Clear the name
    const nameInput = page.locator("input").first();
    await nameInput.clear();

    await expect(page.getByRole("button", { name: /Use This Drug/i })).toBeDisabled();
  });
});
