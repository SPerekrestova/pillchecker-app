import { useEffect, useState } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import { DrugSlotCard } from "@/components/DrugSlotCard";
import { useDrugSlots } from "@/hooks/use-drug-slots";
import { checkInteractions, ApiError } from "@/lib/api-client";
import { getDisplayName } from "@/lib/types";
import type { DrugResult } from "@/lib/types";
import { toast } from "sonner";

const DrugInput = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { slots, setDrug, setManualName, clearSlot, bothFilled, drugNames, hasScanned } = useDrugSlots();
  const [loading, setLoading] = useState(false);

  // Merge incoming state from ScanMedicine or DrugSearch
  useEffect(() => {
    const state = location.state as { slot?: number; drugName?: string; drug?: DrugResult } | null;
    if (state?.slot !== undefined && state?.drugName) {
      if (state.drug) {
        setDrug(state.slot, state.drug);
      } else {
        setManualName(state.slot, state.drugName);
      }
      // Clear the state so it doesn't re-apply on re-render
      window.history.replaceState({}, "");
    }
  }, [location.state, setDrug, setManualName]);

  const handleCheck = async () => {
    if (!bothFilled) return;
    setLoading(true);

    try {
      const result = await checkInteractions(drugNames);
      navigate("/results", {
        state: { result, drugNames, source: hasScanned ? "scan" : "manual" },
        replace: true,
      });
    } catch (error) {
      const message = error instanceof ApiError ? error.message : "Something went wrong.";
      toast.error(message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-muted/30">
      {/* Header */}
      <header className="bg-foreground px-5 pt-12 pb-6">
        <div className="flex items-center gap-3">
          <button onClick={() => navigate("/")} className="text-background">
            <ArrowLeft className="h-6 w-6" />
          </button>
          <h1 className="text-xl font-bold text-background">New Check</h1>
        </div>
      </header>

      {/* Content */}
      <main className="px-5 py-6">
        <p className="text-muted-foreground">
          Scan or type two medications to check interactions
        </p>

        <div className="flex flex-col gap-4 mt-6">
          {slots.map((slot, i) => (
            <DrugSlotCard
              key={i}
              index={i}
              drugName={getDisplayName(slot)}
              onScan={() => navigate(`/scan/${i}`)}
              onType={() => navigate(`/search/${i}`)}
              onClear={() => clearSlot(i)}
            />
          ))}
        </div>

        <Button
          className="w-full mt-6 h-12"
          disabled={!bothFilled || loading}
          onClick={handleCheck}
        >
          {loading ? "Checking..." : "Check Interactions"}
        </Button>
      </main>
    </div>
  );
};

export default DrugInput;
