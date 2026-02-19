import { useState, useRef } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { ArrowLeft, Camera } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { recognizeText } from "@/lib/ocr-service";
import { analyze, ApiError } from "@/lib/api-client";
import type { DrugResult } from "@/lib/types";
import { toast } from "sonner";

type Stage = "idle" | "processing" | "result";

const ScanMedicine = () => {
  const navigate = useNavigate();
  const { slot } = useParams<{ slot: string }>();
  const slotIndex = Number(slot);
  const fileRef = useRef<HTMLInputElement>(null);

  const [stage, setStage] = useState<Stage>("idle");
  const [preview, setPreview] = useState<string | null>(null);
  const [drug, setDrug] = useState<DrugResult | null>(null);
  const [editedName, setEditedName] = useState("");
  const [rawText, setRawText] = useState("");

  const handleFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setPreview(URL.createObjectURL(file));
    setStage("processing");

    try {
      // Step 1: OCR
      const text = await recognizeText(file);
      if (!text) {
        toast.error("Could not read text from image. Try again or type manually.");
        setStage("idle");
        return;
      }

      setRawText(text);

      // Step 2: NLP analysis
      const response = await analyze(text);
      if (response.drugs.length > 0) {
        const d = response.drugs[0];
        setDrug(d);
        setEditedName(d.name);
      } else {
        toast.error("No drug found in image. Try again or type manually.");
        setStage("idle");
        return;
      }

      setStage("result");
    } catch (error) {
      const message =
        error instanceof ApiError ? error.message : "Recognition failed. Please try again.";
      toast.error(message);
      setStage("idle");
    }
  };

  const handleUse = () => {
    navigate("/new", {
      state: {
        slot: slotIndex,
        drugName: editedName,
        drug: drug && drug.name === editedName ? drug : null,
      },
      replace: true,
    });
  };

  const handleRetake = () => {
    if (preview) URL.revokeObjectURL(preview);
    setStage("idle");
    setPreview(null);
    setDrug(null);
    setEditedName("");
    setRawText("");
  };

  return (
    <div className="min-h-screen bg-muted/30">
      {/* Header */}
      <header className="bg-foreground px-5 pt-12 pb-6">
        <div className="flex items-center gap-3">
          <button onClick={() => navigate(-1)} className="text-background">
            <ArrowLeft className="h-6 w-6" />
          </button>
          <h1 className="text-xl font-bold text-background">Scan Medicine</h1>
        </div>
      </header>

      <main className="px-5 py-6">
        {stage === "idle" && (
          <div className="flex flex-col items-center justify-center py-12 text-center">
            <div className="h-20 w-20 rounded-full bg-muted flex items-center justify-center mb-6">
              <Camera className="h-10 w-10 text-muted-foreground" />
            </div>
            <p className="text-lg font-semibold text-foreground">Take a photo of a medicine pack</p>
            <p className="text-muted-foreground mt-1">to identify the drug</p>
            <Button className="mt-6 h-12 px-8" onClick={() => fileRef.current?.click()}>
              Open Camera
            </Button>
            <input
              ref={fileRef}
              type="file"
              accept="image/*"
              capture="environment"
              className="hidden"
              onChange={handleFile}
            />
          </div>
        )}

        {stage === "processing" && (
          <div className="flex flex-col items-center py-12 text-center">
            {preview && (
              <img
                src={preview}
                alt="Captured"
                className="max-h-48 rounded-lg mb-6 object-contain"
              />
            )}
            <div className="animate-spin h-8 w-8 border-4 border-primary border-t-transparent rounded-full mb-4" />
            <p className="text-foreground font-medium">Recognizing medication...</p>
          </div>
        )}

        {stage === "result" && (
          <div>
            {preview && (
              <img
                src={preview}
                alt="Captured"
                className="max-h-48 rounded-lg mb-6 object-contain mx-auto"
              />
            )}

            <div className="space-y-4">
              <div>
                <Label>Drug Name</Label>
                <Input value={editedName} onChange={(e) => setEditedName(e.target.value)} />
              </div>

              {drug?.dosage && (
                <div>
                  <Label>Dosage</Label>
                  <Input value={drug.dosage} disabled />
                </div>
              )}

              {rawText && (
                <div className="mt-4">
                  <p className="text-xs text-muted-foreground font-mono break-all">
                    Raw OCR: &quot;{rawText}&quot;
                  </p>
                </div>
              )}
            </div>

            <div className="flex gap-3 mt-6">
              <Button variant="outline" className="flex-1 h-12" onClick={handleRetake}>
                Retake
              </Button>
              <Button
                className="flex-1 h-12"
                disabled={!editedName.trim()}
                onClick={handleUse}
              >
                Use This Drug
              </Button>
            </div>
          </div>
        )}
      </main>
    </div>
  );
};

export default ScanMedicine;
