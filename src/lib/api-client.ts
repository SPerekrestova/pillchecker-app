import type { AnalyzeResponse, InteractionsResponse } from "./types";

const API_BASE = import.meta.env.VITE_API_URL;

export class ApiError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ApiError";
  }
}

async function request<T>(path: string, body: unknown): Promise<T> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 30_000);

  try {
    const response = await fetch(`${API_BASE}${path}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
      signal: controller.signal,
    });

    if (!response.ok) {
      if (response.status === 422) {
        throw new ApiError("Invalid request. Please try again.");
      }
      throw new ApiError(`Server error (${response.status}). Please try again.`);
    }

    return (await response.json()) as T;
  } catch (error) {
    if (error instanceof ApiError) throw error;
    if (error instanceof DOMException && error.name === "AbortError") {
      throw new ApiError("Connection timed out. Check your network.");
    }
    if (error instanceof TypeError) {
      throw new ApiError("Can't reach server. Check your connection.");
    }
    throw new ApiError("Something went wrong. Please try again.");
  } finally {
    clearTimeout(timeout);
  }
}

export async function analyze(text: string): Promise<AnalyzeResponse> {
  return request<AnalyzeResponse>("/analyze", { text });
}

export async function checkInteractions(drugs: string[]): Promise<InteractionsResponse> {
  return request<InteractionsResponse>("/interactions", { drugs });
}
