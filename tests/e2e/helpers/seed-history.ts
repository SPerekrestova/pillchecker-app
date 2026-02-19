import type { Page } from "@playwright/test";

export interface CheckRecord {
  id: string;
  drugA: string;
  drugB: string;
  safe: boolean;
  interactions: {
    drug_a: string;
    drug_b: string;
    severity: string;
    description: string;
    management: string;
  }[];
  checkedAt: string;
  source: "scan" | "manual";
}

export async function seedHistory(page: Page, records: CheckRecord[]): Promise<void> {
  await page.evaluate(async (data) => {
    const request = indexedDB.open("pillchecker", 1);
    const db: IDBDatabase = await new Promise((resolve, reject) => {
      request.onupgradeneeded = () => {
        const db = request.result;
        if (!db.objectStoreNames.contains("checks")) {
          const store = db.createObjectStore("checks", { keyPath: "id" });
          store.createIndex("checkedAt", "checkedAt");
          store.createIndex("drugA", "drugA");
          store.createIndex("drugB", "drugB");
        }
      };
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });

    const tx = db.transaction("checks", "readwrite");
    const store = tx.objectStore("checks");
    for (const record of data) {
      store.put(record);
    }
    await new Promise<void>((resolve, reject) => {
      tx.oncomplete = () => resolve();
      tx.onerror = () => reject(tx.error);
    });
    db.close();
  }, records);
}

export async function clearHistory(page: Page): Promise<void> {
  await page.evaluate(async () => {
    const dbs = await indexedDB.databases();
    for (const db of dbs) {
      if (db.name) indexedDB.deleteDatabase(db.name);
    }
  });
}

export function makeCheck(overrides: Partial<CheckRecord> = {}): CheckRecord {
  return {
    id: crypto.randomUUID(),
    drugA: "ibuprofen",
    drugB: "warfarin",
    safe: false,
    interactions: [
      {
        drug_a: "ibuprofen",
        drug_b: "warfarin",
        severity: "Major",
        description: "Increased risk of bleeding",
        management: "Monitor INR closely",
      },
    ],
    checkedAt: new Date().toISOString(),
    source: "manual",
    ...overrides,
  };
}
