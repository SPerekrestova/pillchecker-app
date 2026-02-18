import { createWorker, type Worker } from "tesseract.js";

let worker: Worker | null = null;

async function getWorker(): Promise<Worker> {
  if (!worker) {
    worker = await createWorker("eng");
  }
  return worker;
}

export async function recognizeText(imageFile: File): Promise<string | null> {
  const w = await getWorker();
  const url = URL.createObjectURL(imageFile);

  try {
    const { data } = await w.recognize(url);
    const text = data.text.trim();
    return text || null;
  } finally {
    URL.revokeObjectURL(url);
  }
}

export async function terminateWorker(): Promise<void> {
  if (worker) {
    await worker.terminate();
    worker = null;
  }
}
