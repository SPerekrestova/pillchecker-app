import { describe, it, expect } from "vitest";
import { getDisplayName, isFilled, type DrugSlot } from "@/lib/types";

describe("getDisplayName", () => {
  it("returns drug name when drug is set", () => {
    const slot: DrugSlot = {
      drug: { rxcui: "123", name: "Ibuprofen", dosage: null, form: null, source: "ner", confidence: 0.9 },
      manualName: null,
    };
    expect(getDisplayName(slot)).toBe("Ibuprofen");
  });

  it("returns manualName when no drug", () => {
    const slot: DrugSlot = { drug: null, manualName: "Aspirin" };
    expect(getDisplayName(slot)).toBe("Aspirin");
  });

  it("returns null for empty slot", () => {
    const slot: DrugSlot = { drug: null, manualName: null };
    expect(getDisplayName(slot)).toBeNull();
  });

  it("returns null for whitespace-only manualName", () => {
    const slot: DrugSlot = { drug: null, manualName: "   " };
    expect(getDisplayName(slot)).toBeNull();
  });

  it("prefers drug.name over manualName", () => {
    const slot: DrugSlot = {
      drug: { rxcui: "1", name: "DrugA", dosage: null, form: null, source: "ner", confidence: 1 },
      manualName: "DrugB",
    };
    expect(getDisplayName(slot)).toBe("DrugA");
  });
});

describe("isFilled", () => {
  it("returns true when drug is set", () => {
    const slot: DrugSlot = {
      drug: { rxcui: "1", name: "X", dosage: null, form: null, source: "ner", confidence: 1 },
      manualName: null,
    };
    expect(isFilled(slot)).toBe(true);
  });

  it("returns false for empty slot", () => {
    expect(isFilled({ drug: null, manualName: null })).toBe(false);
  });
});
