import { openDB, type IDBPDatabase } from "idb";
import type { CheckRecord } from "./types";

const DB_NAME = "pillchecker";
const DB_VERSION = 1;
const STORE_NAME = "checks";

let dbPromise: Promise<IDBPDatabase> | null = null;

function getDB(): Promise<IDBPDatabase> {
  if (!dbPromise) {
    dbPromise = openDB(DB_NAME, DB_VERSION, {
      upgrade(db) {
        const store = db.createObjectStore(STORE_NAME, { keyPath: "id" });
        store.createIndex("checkedAt", "checkedAt");
        store.createIndex("drugA", "drugA");
        store.createIndex("drugB", "drugB");
      },
    });
  }
  return dbPromise;
}

export async function closeDB(): Promise<void> {
  if (dbPromise) {
    const db = await dbPromise;
    db.close();
    dbPromise = null;
  }
}

export async function getAllChecks(): Promise<CheckRecord[]> {
  const db = await getDB();
  const all = await db.getAll(STORE_NAME);
  return all.sort(
    (a, b) => new Date(b.checkedAt).getTime() - new Date(a.checkedAt).getTime()
  );
}

export async function getCheck(id: string): Promise<CheckRecord | undefined> {
  const db = await getDB();
  return db.get(STORE_NAME, id);
}

export async function saveCheck(record: CheckRecord): Promise<void> {
  const db = await getDB();
  await db.put(STORE_NAME, record);
}

export async function deleteCheck(id: string): Promise<void> {
  const db = await getDB();
  await db.delete(STORE_NAME, id);
}

export async function searchChecks(query: string): Promise<CheckRecord[]> {
  const q = query.toLowerCase();
  const all = await getAllChecks();
  return all.filter(
    (r) => r.drugA.toLowerCase().includes(q) || r.drugB.toLowerCase().includes(q)
  );
}
