import { useState, useCallback, useMemo } from "react";
import type { DrugSlot, DrugResult } from "@/lib/types";
import { getDisplayName, isFilled } from "@/lib/types";

const STORAGE_KEY = "drugSlots";

function emptySlot(): DrugSlot {
  return { drug: null, manualName: null };
}

function loadSlots(): [DrugSlot, DrugSlot] {
  try {
    const raw = sessionStorage.getItem(STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed) && parsed.length === 2) {
        return parsed as [DrugSlot, DrugSlot];
      }
    }
  } catch {
    // ignore corrupt data
  }
  return [emptySlot(), emptySlot()];
}

function persistSlots(slots: [DrugSlot, DrugSlot]) {
  sessionStorage.setItem(STORAGE_KEY, JSON.stringify(slots));
}

export function useDrugSlots() {
  const [slots, setSlots] = useState<[DrugSlot, DrugSlot]>(loadSlots);

  const update = useCallback((updater: (prev: [DrugSlot, DrugSlot]) => [DrugSlot, DrugSlot]) => {
    setSlots((prev) => {
      const next = updater(prev);
      persistSlots(next);
      return next;
    });
  }, []);

  const setDrug = useCallback((index: number, drug: DrugResult) => {
    update((prev) => {
      const next: [DrugSlot, DrugSlot] = [...prev] as [DrugSlot, DrugSlot];
      next[index] = { drug, manualName: null };
      return next;
    });
  }, [update]);

  const setManualName = useCallback((index: number, name: string) => {
    update((prev) => {
      const next: [DrugSlot, DrugSlot] = [...prev] as [DrugSlot, DrugSlot];
      next[index] = { drug: null, manualName: name };
      return next;
    });
  }, [update]);

  const clearSlot = useCallback((index: number) => {
    update((prev) => {
      const next: [DrugSlot, DrugSlot] = [...prev] as [DrugSlot, DrugSlot];
      next[index] = emptySlot();
      return next;
    });
  }, [update]);

  const reset = useCallback(() => {
    const empty: [DrugSlot, DrugSlot] = [emptySlot(), emptySlot()];
    setSlots(empty);
    sessionStorage.removeItem(STORAGE_KEY);
  }, []);

  const bothFilled = useMemo(() => isFilled(slots[0]) && isFilled(slots[1]), [slots]);

  const drugNames = useMemo(
    () => slots.map(getDisplayName).filter((n): n is string => n !== null),
    [slots]
  );

  return { slots, setDrug, setManualName, clearSlot, reset, bothFilled, drugNames };
}
