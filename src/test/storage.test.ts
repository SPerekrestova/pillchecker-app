import { describe, it, expect, beforeEach } from "vitest";
import "fake-indexeddb/auto";
import { getAllChecks, getCheck, saveCheck, deleteCheck, searchChecks, closeDB } from "@/lib/storage";
import type { CheckRecord } from "@/lib/types";

const makeRecord = (overrides: Partial<CheckRecord> = {}): CheckRecord => ({
  id: crypto.randomUUID(),
  drugA: "Ibuprofen",
  drugB: "Warfarin",
  safe: false,
  interactions: [],
  checkedAt: new Date().toISOString(),
  source: "manual",
  ...overrides,
});

describe("storage", () => {
  beforeEach(async () => {
    // Close the connection first, then delete the database
    await closeDB();
    const { deleteDB } = await import("idb");
    await deleteDB("pillchecker");
  });

  it("saves and retrieves a check", async () => {
    const record = makeRecord();
    await saveCheck(record);

    const retrieved = await getCheck(record.id);
    expect(retrieved).toEqual(record);
  });

  it("getAllChecks returns records sorted by checkedAt desc", async () => {
    const older = makeRecord({ checkedAt: "2026-01-01T00:00:00Z" });
    const newer = makeRecord({ checkedAt: "2026-02-01T00:00:00Z" });

    await saveCheck(older);
    await saveCheck(newer);

    const all = await getAllChecks();
    expect(all).toHaveLength(2);
    expect(all[0].id).toBe(newer.id);
    expect(all[1].id).toBe(older.id);
  });

  it("deletes a check", async () => {
    const record = makeRecord();
    await saveCheck(record);
    await deleteCheck(record.id);

    const retrieved = await getCheck(record.id);
    expect(retrieved).toBeUndefined();
  });

  it("searchChecks matches by drug name", async () => {
    const r1 = makeRecord({ drugA: "Ibuprofen", drugB: "Warfarin" });
    const r2 = makeRecord({ drugA: "Aspirin", drugB: "Lisinopril" });

    await saveCheck(r1);
    await saveCheck(r2);

    const results = await searchChecks("aspirin");
    expect(results).toHaveLength(1);
    expect(results[0].drugA).toBe("Aspirin");
  });
});
