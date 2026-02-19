import { test, expect } from "./fixtures/tunnel";

const API = "http://localhost:8000";

test.describe("API Smoke Tests", () => {
  test("S1: health check returns 200", async () => {
    const res = await fetch(`${API}/health`);
    expect(res.status).toBe(200);
  });

  test("S2: data health check returns 200", async () => {
    const res = await fetch(`${API}/health/data`);
    expect(res.status).toBe(200);
  });

  test("S3: analyze valid text returns drugs", async () => {
    const res = await fetch(`${API}/analyze`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ text: "BRUFEN Ibuprofen 400 mg Film-Coated Tablets" }),
    });
    expect(res.status).toBe(200);
    const data = await res.json();
    expect(data.drugs.length).toBeGreaterThanOrEqual(1);
    expect(data.drugs[0]).toHaveProperty("name");
    expect(data.drugs[0]).toHaveProperty("rxcui");
  });

  test("S4: analyze empty text returns 422", async () => {
    const res = await fetch(`${API}/analyze`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ text: "" }),
    });
    expect(res.status).toBe(422);
  });

  test("S5: analyze gibberish returns empty drugs", async () => {
    const res = await fetch(`${API}/analyze`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ text: "xkcd 12345 !!! random gibberish" }),
    });
    expect(res.status).toBe(200);
    const data = await res.json();
    expect(data.drugs).toHaveLength(0);
  });

  test("S6: interactions — known dangerous pair", async () => {
    const res = await fetch(`${API}/interactions`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ drugs: ["ibuprofen", "warfarin"] }),
    });
    expect(res.status).toBe(200);
    const data = await res.json();
    expect(data.safe).toBe(false);
    expect(data.interactions.length).toBeGreaterThanOrEqual(1);
  });

  test("S7: interactions — safe pair", async () => {
    const res = await fetch(`${API}/interactions`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ drugs: ["paracetamol", "omeprazole"] }),
    });
    expect(res.status).toBe(200);
    const data = await res.json();
    // Note: if this fails, the backend DB may have an interaction for this pair.
    // See testing-issues.md #4 — verify safe pairs against actual backend data.
    expect(data.safe).toBe(true);
  });

  test("S8: interactions — single drug returns 422", async () => {
    const res = await fetch(`${API}/interactions`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ drugs: ["ibuprofen"] }),
    });
    expect(res.status).toBe(422);
  });

  test("S9: interactions — unknown drug does not crash", async () => {
    const res = await fetch(`${API}/interactions`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ drugs: ["ibuprofen", "notarealdrug12345"] }),
    });
    expect(res.status).toBe(200);
    const data = await res.json();
    expect(data).toHaveProperty("safe");
    expect(data).toHaveProperty("interactions");
  });

  test("S10: analyze — large text does not timeout", async () => {
    const largeText = "Ibuprofen 400mg tablets ".repeat(250); // ~6000 chars
    const res = await fetch(`${API}/analyze`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ text: largeText }),
    });
    expect([200, 422]).toContain(res.status);
  });
});
