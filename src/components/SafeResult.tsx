import { CheckCircle } from "lucide-react";

export function SafeResult() {
  return (
    <div className="flex flex-col items-center justify-center py-12 text-center">
      <CheckCircle className="h-20 w-20 text-green-600 mb-4" />
      <p className="text-xl font-semibold text-foreground">No known interactions found</p>
      <p className="text-muted-foreground mt-2">
        These medications appear safe to take together.
      </p>
    </div>
  );
}
