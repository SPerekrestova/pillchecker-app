import { Card, CardContent } from "@/components/ui/card";
import { AlertTriangle, AlertCircle, Info } from "lucide-react";
import type { InteractionResult } from "@/lib/types";

interface InteractionCardProps {
  interaction: InteractionResult;
}

function severityConfig(severity: string) {
  const s = severity.toLowerCase();
  if (s === "major") return { color: "text-red-600 border-red-600", icon: AlertTriangle, label: "MAJOR" };
  if (s === "moderate") return { color: "text-orange-500 border-orange-500", icon: AlertCircle, label: "MODERATE" };
  return { color: "text-yellow-600 border-yellow-600", icon: Info, label: "MINOR" };
}

export function InteractionCard({ interaction }: InteractionCardProps) {
  const config = severityConfig(interaction.severity);
  const Icon = config.icon;

  return (
    <Card className={`border-l-4 ${config.color}`}>
      <CardContent className="p-4">
        <div className="flex items-start gap-3">
          <Icon className={`h-5 w-5 mt-0.5 ${config.color.split(" ")[0]}`} />
          <div className="flex-1">
            <p className={`font-semibold text-sm ${config.color.split(" ")[0]}`}>{config.label}</p>
            <p className="font-medium text-foreground text-sm mt-1">
              {interaction.drug_a} + {interaction.drug_b}
            </p>
            <p className="text-muted-foreground text-sm mt-2">{interaction.description}</p>
            {interaction.management && (
              <p className="text-muted-foreground text-xs mt-2">
                <span className="font-medium text-foreground">Management:</span> {interaction.management}
              </p>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
