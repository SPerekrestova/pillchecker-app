const RXNORM_BASE = "https://rxnav.nlm.nih.gov/REST";

export async function suggest(query: string): Promise<string[]> {
  if (query.trim().length < 2) return [];

  try {
    const url = `${RXNORM_BASE}/approximateTerm.json?term=${encodeURIComponent(query)}&maxEntries=5`;
    const response = await fetch(url);
    const data = await response.json();

    const candidates = data?.approximateGroup?.candidate;
    if (!Array.isArray(candidates) || candidates.length === 0) return [];

    // Extract unique rxcui values
    const rxcuis = new Set<string>();
    for (const c of candidates) {
      if (c.rxcui) rxcuis.add(c.rxcui);
    }

    // Resolve each rxcui to a drug name in parallel
    const names = await Promise.all(
      Array.from(rxcuis).map((rxcui) => resolveName(rxcui))
    );

    return names.filter((n): n is string => n !== null);
  } catch {
    return [];
  }
}

async function resolveName(rxcui: string): Promise<string | null> {
  try {
    const response = await fetch(`${RXNORM_BASE}/rxcui/${rxcui}/properties.json`);
    const data = await response.json();
    return data?.properties?.name ?? null;
  } catch {
    return null;
  }
}
