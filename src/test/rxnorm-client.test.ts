import { describe, it, expect, vi, beforeEach } from "vitest";
import { suggest } from "@/lib/rxnorm-client";

describe("suggest", () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it("returns empty array for short query", async () => {
    expect(await suggest("")).toEqual([]);
    expect(await suggest(" ")).toEqual([]);
    expect(await suggest("a")).toEqual([]);
  });

  it("returns drug names from RxNorm API", async () => {
    // Mock approximateTerm response
    const approxResponse = {
      approximateGroup: {
        candidate: [
          { rxcui: "5640" },
          { rxcui: "5641" },
        ],
      },
    };

    // Mock properties responses
    const propsResponse5640 = { properties: { name: "ibuprofen" } };
    const propsResponse5641 = { properties: { name: "ibuprofen lysine" } };

    global.fetch = vi.fn()
      .mockResolvedValueOnce({ ok: true, json: () => Promise.resolve(approxResponse) })
      .mockResolvedValueOnce({ ok: true, json: () => Promise.resolve(propsResponse5640) })
      .mockResolvedValueOnce({ ok: true, json: () => Promise.resolve(propsResponse5641) });

    const result = await suggest("ibuprofen");

    expect(result).toEqual(["ibuprofen", "ibuprofen lysine"]);
    expect(fetch).toHaveBeenCalledTimes(3);
  });

  it("returns empty array when no candidates", async () => {
    global.fetch = vi.fn().mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({ approximateGroup: { candidate: [] } }),
    });

    expect(await suggest("zzzzzzz")).toEqual([]);
  });

  it("returns empty array on network error", async () => {
    global.fetch = vi.fn().mockRejectedValueOnce(new Error("Network error"));

    expect(await suggest("aspirin")).toEqual([]);
  });

  it("deduplicates rxcui values", async () => {
    const approxResponse = {
      approximateGroup: {
        candidate: [
          { rxcui: "5640" },
          { rxcui: "5640" }, // duplicate
        ],
      },
    };
    const propsResponse = { properties: { name: "ibuprofen" } };

    global.fetch = vi.fn()
      .mockResolvedValueOnce({ ok: true, json: () => Promise.resolve(approxResponse) })
      .mockResolvedValueOnce({ ok: true, json: () => Promise.resolve(propsResponse) });

    const result = await suggest("ibu");

    // Only 1 properties call (deduplicated), 1 result
    expect(result).toEqual(["ibuprofen"]);
    expect(fetch).toHaveBeenCalledTimes(2);
  });
});
