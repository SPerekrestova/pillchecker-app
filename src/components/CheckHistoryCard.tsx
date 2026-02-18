import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { format } from "date-fns";
import type { CheckRecord } from "@/lib/types";

interface CheckHistoryCardProps {
  record: CheckRecord;
  onClick: () => void;
}

export function CheckHistoryCard({ record, onClick }: CheckHistoryCardProps) {
  const maxSeverity = record.safe
    ? null
    : record.interactions.reduce((max, i) => {
        const s = i.severity.toLowerCase();
        if (s === "major") return "major";
        if (s === "moderate" && max !== "major") return "moderate";
        return max;
      }, "minor" as string);

  return (
    <button onClick={onClick} className="w-full text-left">
      <Card className="hover:bg-muted/50 transition-colors">
        <CardContent className="p-4">
          <p className="font-semibold text-foreground text-sm">
            {record.drugA} + {record.drugB}
          </p>
          <div className="flex items-center justify-between mt-2">
            {record.safe ? (
              <Badge variant="secondary" className="text-green-600 bg-green-50">
                SAFE
              </Badge>
            ) : (
              <Badge
                variant="secondary"
                className={
                  maxSeverity === "major"
                    ? "text-red-600 bg-red-50"
                    : maxSeverity === "moderate"
                    ? "text-orange-500 bg-orange-50"
                    : "text-yellow-600 bg-yellow-50"
                }
              >
                {maxSeverity?.toUpperCase()}
              </Badge>
            )}
            <span className="text-xs text-muted-foreground">
              {format(new Date(record.checkedAt), "MMM d")}
            </span>
          </div>
        </CardContent>
      </Card>
    </button>
  );
}
