// --- API response types (snake_case matches backend JSON) ---

export interface DrugResult {
  rxcui: string | null;
  name: string;
  dosage: string | null;
  form: string | null;
  source: "ner" | "rxnorm_fallback";
  confidence: number;
}

export interface AnalyzeResponse {
  drugs: DrugResult[];
  raw_text: string;
}

export interface InteractionResult {
  drug_a: string;
  drug_b: string;
  severity: string;
  description: string;
  management: string;
}

export interface InteractionsResponse {
  interactions: InteractionResult[];
  safe: boolean;
}

// --- Client-side types (camelCase) ---

export interface DrugSlot {
  drug: DrugResult | null;
  manualName: string | null;
}

export function getDisplayName(slot: DrugSlot): string | null {
  const name = slot.drug?.name ?? slot.manualName;
  return name?.trim() || null;
}

export function isFilled(slot: DrugSlot): boolean {
  return getDisplayName(slot) !== null;
}

// Stored in IndexedDB
export interface CheckRecord {
  id: string;
  drugA: string;
  drugB: string;
  safe: boolean;
  interactions: InteractionResult[];
  checkedAt: string; // ISO date
  source: "scan" | "manual";
}
