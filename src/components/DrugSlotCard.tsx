import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Camera, Keyboard, X } from "lucide-react";

interface DrugSlotCardProps {
  index: number;
  drugName: string | null;
  onScan: () => void;
  onType: () => void;
  onClear: () => void;
}

export function DrugSlotCard({ index, drugName, onScan, onType, onClear }: DrugSlotCardProps) {
  return (
    <Card>
      <CardContent className="p-4">
        {drugName ? (
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs text-muted-foreground">Drug {index + 1}</p>
              <p className="font-semibold text-foreground">{drugName}</p>
            </div>
            <Button variant="ghost" size="icon" onClick={onClear} aria-label="Clear drug">
              <X className="h-4 w-4" />
            </Button>
          </div>
        ) : (
          <div>
            <p className="text-sm text-muted-foreground mb-3">Drug {index + 1}</p>
            <div className="flex gap-2">
              <Button variant="outline" className="flex-1 gap-2" onClick={onScan}>
                <Camera className="h-4 w-4" />
                Scan
              </Button>
              <Button variant="outline" className="flex-1 gap-2" onClick={onType}>
                <Keyboard className="h-4 w-4" />
                Type
              </Button>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
