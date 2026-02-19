import { useLocation, useNavigate, Navigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { InteractionCard } from "@/components/InteractionCard";
import { SafeResult } from "@/components/SafeResult";
import { saveCheck } from "@/lib/storage";
import type { InteractionsResponse, CheckRecord } from "@/lib/types";

interface ResultsState {
  result: InteractionsResponse;
  drugNames: string[];
  source: "scan" | "manual";
}

const Results = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const state = location.state as ResultsState | null;

  if (!state?.result) {
    return <Navigate to="/" replace />;
  }

  const { result, drugNames, source } = state;

  const handleSaveAndStartOver = async () => {
    const record: CheckRecord = {
      id: crypto.randomUUID(),
      drugA: drugNames[0],
      drugB: drugNames[1],
      safe: result.safe,
      interactions: result.interactions,
      checkedAt: new Date().toISOString(),
      source,
    };
    await saveCheck(record);
    sessionStorage.removeItem("drugSlots");
    navigate("/", { replace: true });
  };

  return (
    <div className="min-h-screen bg-muted/30">
      {/* Header */}
      <header className="bg-foreground px-5 pt-12 pb-6">
        <h1 className="text-xl font-bold text-background">Results</h1>
      </header>

      <main className="px-5 py-6">
        {result.safe ? (
          <SafeResult />
        ) : (
          <div className="flex flex-col gap-4">
            {result.interactions.map((interaction, i) => (
              <InteractionCard key={i} interaction={interaction} />
            ))}
          </div>
        )}

        <Button className="w-full mt-8 h-12" onClick={handleSaveAndStartOver}>
          Save & Start Over
        </Button>
      </main>
    </div>
  );
};

export default Results;
