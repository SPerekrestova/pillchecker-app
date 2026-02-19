import { describe, it, expect, vi, beforeEach } from "vitest";
import { analyze, checkInteractions, ApiError } from "@/lib/api-client";

// Mock VITE_API_URL
vi.stubEnv("VITE_API_URL", "http://localhost:8000");

describe("analyze", () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it("returns AnalyzeResponse on success", async () => {
    const mockResponse = {
      drugs: [{ rxcui: "5640", name: "Ibuprofen", dosage: "400mg", form: "tablet", source: "ner", confidence: 0.95 }],
      raw_text: "Ibuprofen 400mg",
    };

    global.fetch = vi.fn().mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve(mockResponse),
    });

    const result = await analyze("Ibuprofen 400mg");

    expect(result.drugs).toHaveLength(1);
    expect(result.drugs[0].name).toBe("Ibuprofen");
    expect(result.raw_text).toBe("Ibuprofen 400mg");

    expect(fetch).toHaveBeenCalledWith(
      "http://localhost:8000/analyze",
      expect.objectContaining({
        method: "POST",
        body: JSON.stringify({ text: "Ibuprofen 400mg" }),
      })
    );
  });

  it("throws ApiError with message for 422", async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: false,
      status: 422,
    });

    await expect(analyze("x")).rejects.toThrow(ApiError);
    await expect(analyze("x")).rejects.toThrow("Invalid request");
  });

  it("throws ApiError with message for 500", async () => {
    global.fetch = vi.fn().mockResolvedValueOnce({
      ok: false,
      status: 500,
    });

    await expect(analyze("x")).rejects.toThrow("Server error (500)");
  });

  it("throws ApiError for network error", async () => {
    global.fetch = vi.fn().mockRejectedValueOnce(new TypeError("Failed to fetch"));

    await expect(analyze("x")).rejects.toThrow("Can't reach server");
  });
});

describe("checkInteractions", () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it("returns InteractionsResponse on success", async () => {
    const mockResponse = {
      interactions: [
        { drug_a: "Ibuprofen", drug_b: "Warfarin", severity: "Major", description: "Risk", management: "Avoid" },
      ],
      safe: false,
    };

    global.fetch = vi.fn().mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve(mockResponse),
    });

    const result = await checkInteractions(["Ibuprofen", "Warfarin"]);

    expect(result.safe).toBe(false);
    expect(result.interactions).toHaveLength(1);
    expect(result.interactions[0].severity).toBe("Major");

    expect(fetch).toHaveBeenCalledWith(
      "http://localhost:8000/interactions",
      expect.objectContaining({
        method: "POST",
        body: JSON.stringify({ drugs: ["Ibuprofen", "Warfarin"] }),
      })
    );
  });
});
