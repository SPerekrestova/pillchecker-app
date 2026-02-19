import { useState, useEffect, useRef } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { ArrowLeft, Loader2 } from "lucide-react";
import { Input } from "@/components/ui/input";
import { suggest } from "@/lib/rxnorm-client";

const DrugSearch = () => {
  const navigate = useNavigate();
  const { slot } = useParams<{ slot: string }>();
  const slotIndex = Number(slot);

  const [query, setQuery] = useState("");
  const [suggestions, setSuggestions] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const inputRef = useRef<HTMLInputElement>(null);

  // Autofocus on mount
  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  // Debounced search
  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current);

    if (query.trim().length < 2) {
      setSuggestions([]);
      return;
    }

    setLoading(true);
    debounceRef.current = setTimeout(async () => {
      const results = await suggest(query);
      setSuggestions(results);
      setLoading(false);
    }, 300);

    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
  }, [query]);

  const selectDrug = (name: string) => {
    navigate("/new", {
      state: { slot: slotIndex, drugName: name },
      replace: true,
    });
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter" && query.trim()) {
      selectDrug(query.trim());
    }
  };

  return (
    <div className="min-h-screen bg-muted/30">
      {/* Header */}
      <header className="bg-foreground px-5 pt-12 pb-6">
        <div className="flex items-center gap-3">
          <button onClick={() => navigate(-1)} className="text-background">
            <ArrowLeft className="h-6 w-6" />
          </button>
          <h1 className="text-xl font-bold text-background">Search Drug</h1>
        </div>
      </header>

      <main className="px-5 py-6">
        <Input
          ref={inputRef}
          placeholder="Type drug name..."
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onKeyDown={handleKeyDown}
          className="bg-background"
        />

        {loading && (
          <div className="flex items-center gap-2 mt-4 text-muted-foreground">
            <Loader2 className="h-4 w-4 animate-spin" />
            <span className="text-sm">Searching...</span>
          </div>
        )}

        {suggestions.length > 0 && (
          <div className="mt-4 rounded-lg border bg-background overflow-hidden">
            {suggestions.map((name) => (
              <button
                key={name}
                onClick={() => selectDrug(name)}
                className="w-full text-left px-4 py-3 text-sm text-foreground hover:bg-muted/50 transition-colors border-b last:border-b-0"
              >
                {name}
              </button>
            ))}
          </div>
        )}

        {!loading && query.trim().length >= 2 && suggestions.length === 0 && (
          <p className="text-sm text-muted-foreground mt-4">
            No suggestions found. Press Enter to use &quot;{query}&quot; as-is.
          </p>
        )}
      </main>
    </div>
  );
};

export default DrugSearch;
