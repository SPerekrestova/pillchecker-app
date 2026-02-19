import { useState, useEffect } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { ArrowLeft, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { InteractionCard } from "@/components/InteractionCard";
import { SafeResult } from "@/components/SafeResult";
import { Skeleton } from "@/components/ui/skeleton";
import { getCheck, deleteCheck } from "@/lib/storage";
import type { CheckRecord } from "@/lib/types";
import { format } from "date-fns";

const CheckDetail = () => {
  const navigate = useNavigate();
  const { id } = useParams<{ id: string }>();
  const [record, setRecord] = useState<CheckRecord | null | undefined>(undefined);

  useEffect(() => {
    if (id) {
      getCheck(id).then((r) => setRecord(r ?? null));
    }
  }, [id]);

  const handleDelete = async () => {
    if (id) {
      await deleteCheck(id);
      navigate("/", { replace: true });
    }
  };

  // Loading
  if (record === undefined) {
    return (
      <div className="min-h-screen bg-muted/30">
        <header className="bg-foreground px-5 pt-12 pb-6">
          <Skeleton className="h-6 w-32" />
        </header>
        <main className="px-5 py-6">
          <Skeleton className="h-8 w-48 mb-2" />
          <Skeleton className="h-4 w-32" />
        </main>
      </div>
    );
  }

  // Not found
  if (record === null) {
    return (
      <div className="min-h-screen bg-muted/30">
        <header className="bg-foreground px-5 pt-12 pb-6">
          <div className="flex items-center gap-3">
            <button onClick={() => navigate("/")} className="text-background">
              <ArrowLeft className="h-6 w-6" />
            </button>
            <h1 className="text-xl font-bold text-background">Not Found</h1>
          </div>
        </header>
        <main className="px-5 py-6">
          <p className="text-muted-foreground">Check not found.</p>
        </main>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-muted/30">
      {/* Header */}
      <header className="bg-foreground px-5 pt-12 pb-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <button onClick={() => navigate("/")} className="text-background">
              <ArrowLeft className="h-6 w-6" />
            </button>
          </div>
          <button onClick={handleDelete} className="text-destructive">
            <Trash2 className="h-5 w-5" />
          </button>
        </div>
      </header>

      <main className="px-5 py-6">
        <h2 className="text-2xl font-bold text-foreground">
          {record.drugA} + {record.drugB}
        </h2>
        <div className="flex items-center gap-3 mt-2">
          <Badge variant={record.safe ? "secondary" : "destructive"}>
            {record.safe ? "Safe" : "Unsafe"}
          </Badge>
          <span className="text-sm text-muted-foreground">
            Checked on {format(new Date(record.checkedAt), "MMM d, yyyy")}
          </span>
        </div>

        {/* Stat boxes */}
        <div className="grid grid-cols-2 gap-3 mt-6">
          <div className="rounded-lg bg-background p-4 text-center">
            <p className="text-xs text-muted-foreground">Status</p>
            <p className={`font-semibold ${record.safe ? "text-green-600" : "text-red-600"}`}>
              {record.safe ? "Safe" : "Unsafe"}
            </p>
          </div>
          <div className="rounded-lg bg-background p-4 text-center">
            <p className="text-xs text-muted-foreground">Source</p>
            <p className="font-semibold text-foreground">
              {record.source === "scan" ? "AI Scan" : "Manual"}
            </p>
          </div>
        </div>

        {/* Interactions */}
        <div className="mt-6">
          {record.safe ? (
            <SafeResult />
          ) : (
            <div className="flex flex-col gap-4">
              {record.interactions.map((interaction, i) => (
                <InteractionCard key={i} interaction={interaction} />
              ))}
            </div>
          )}
        </div>

        <Button
          variant="outline"
          className="w-full mt-8 h-12 text-destructive border-destructive hover:bg-destructive/10"
          onClick={handleDelete}
        >
          Delete from History
        </Button>
      </main>
    </div>
  );
};

export default CheckDetail;
