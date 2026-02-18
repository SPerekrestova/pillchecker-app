import { describe, it, expect, beforeEach } from "vitest";
import { renderHook, act } from "@testing-library/react";
import { useDrugSlots } from "@/hooks/use-drug-slots";

describe("useDrugSlots", () => {
  beforeEach(() => {
    sessionStorage.clear();
  });

  it("initializes with two empty slots", () => {
    const { result } = renderHook(() => useDrugSlots());

    expect(result.current.slots).toHaveLength(2);
    expect(result.current.slots[0].drug).toBeNull();
    expect(result.current.slots[1].drug).toBeNull();
    expect(result.current.bothFilled).toBe(false);
  });

  it("setManualName fills a slot", () => {
    const { result } = renderHook(() => useDrugSlots());

    act(() => result.current.setManualName(0, "Aspirin"));

    expect(result.current.slots[0].manualName).toBe("Aspirin");
  });

  it("clearSlot empties a slot", () => {
    const { result } = renderHook(() => useDrugSlots());

    act(() => result.current.setManualName(0, "Aspirin"));
    act(() => result.current.clearSlot(0));

    expect(result.current.slots[0].manualName).toBeNull();
  });

  it("bothFilled returns true when both slots have names", () => {
    const { result } = renderHook(() => useDrugSlots());

    act(() => result.current.setManualName(0, "Aspirin"));
    act(() => result.current.setManualName(1, "Ibuprofen"));

    expect(result.current.bothFilled).toBe(true);
  });

  it("drugNames returns filled slot names", () => {
    const { result } = renderHook(() => useDrugSlots());

    act(() => result.current.setManualName(0, "Aspirin"));
    act(() => result.current.setManualName(1, "Ibuprofen"));

    expect(result.current.drugNames).toEqual(["Aspirin", "Ibuprofen"]);
  });

  it("reset clears all slots and sessionStorage", () => {
    const { result } = renderHook(() => useDrugSlots());

    act(() => result.current.setManualName(0, "Aspirin"));
    act(() => result.current.reset());

    expect(result.current.slots[0].manualName).toBeNull();
    expect(sessionStorage.getItem("drugSlots")).toBeNull();
  });

  it("persists slots to sessionStorage", () => {
    const { result } = renderHook(() => useDrugSlots());

    act(() => result.current.setManualName(0, "Aspirin"));

    const stored = JSON.parse(sessionStorage.getItem("drugSlots")!);
    expect(stored[0].manualName).toBe("Aspirin");
  });
});
