import sharp from "sharp";
import { readdir } from "node:fs/promises";
import { join, extname } from "node:path";

const IMAGES_DIR = join(import.meta.dirname, "../fixtures/images");
const OUTPUT_DIR = join(import.meta.dirname, "../fixtures/generated-images");

const IMAGE_EXTENSIONS = new Set([".jpg", ".jpeg", ".png"]);

async function findFirstImage(): Promise<string> {
  const files = await readdir(IMAGES_DIR);
  const image = files.find((f) => IMAGE_EXTENSIONS.has(extname(f).toLowerCase()));
  if (!image) throw new Error(`No image found in ${IMAGES_DIR}`);
  return join(IMAGES_DIR, image);
}

async function main() {
  const source = await findFirstImage();
  console.log(`Source image: ${source}`);

  // Blurry variant — heavy Gaussian blur
  await sharp(source).blur(15).toFile(join(OUTPUT_DIR, "blurry.jpg"));
  console.log("Created: blurry.jpg");

  // Rotated variant — 90 degrees
  await sharp(source).rotate(90).toFile(join(OUTPUT_DIR, "rotated.jpg"));
  console.log("Created: rotated.jpg");

  // Tiny variant — 50x50
  await sharp(source).resize(50, 50).toFile(join(OUTPUT_DIR, "tiny.jpg"));
  console.log("Created: tiny.jpg");

  // Solid color (no text at all)
  await sharp({
    create: { width: 400, height: 300, channels: 3, background: { r: 200, g: 200, b: 200 } },
  })
    .jpeg()
    .toFile(join(OUTPUT_DIR, "no-text.jpg"));
  console.log("Created: no-text.jpg");

  // Over-exposed (nearly white)
  await sharp(source)
    .modulate({ brightness: 3 })
    .toFile(join(OUTPUT_DIR, "overexposed.jpg"));
  console.log("Created: overexposed.jpg");

  console.log("Done. All degraded images written to fixtures/generated-images/");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
