import { useState, useMemo, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Plus, Search, Camera, PenLine, Pill, SlidersHorizontal } from "lucide-react";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { CheckHistoryCard } from "@/components/CheckHistoryCard";
import { getAllChecks } from "@/lib/storage";
import type { CheckRecord } from "@/lib/types";

type SortMode = "newest" | "drugA" | "drugB";

const History = () => {
  const navigate = useNavigate();
  const [checks, setChecks] = useState<CheckRecord[]>([]);
  const [search, setSearch] = useState("");
  const [sort, setSort] = useState<SortMode>("newest");
  const [showAdd, setShowAdd] = useState(false);

  useEffect(() => {
    getAllChecks().then(setChecks);
  }, []);

  // Refresh when returning to this page
  useEffect(() => {
    const handler = () => { getAllChecks().then(setChecks); };
    window.addEventListener("focus", handler);
    return () => window.removeEventListener("focus", handler);
  }, []);

  const filtered = useMemo(() => {
    let list = checks;
    if (search.trim()) {
      const q = search.toLowerCase();
      list = list.filter(
        (c) => c.drugA.toLowerCase().includes(q) || c.drugB.toLowerCase().includes(q)
      );
    }
    switch (sort) {
      case "drugA":
        return [...list].sort((a, b) => a.drugA.localeCompare(b.drugA));
      case "drugB":
        return [...list].sort((a, b) => a.drugB.localeCompare(b.drugB));
      default:
        return list; // already sorted newest first from storage
    }
  }, [checks, search, sort]);

  const sortLabel =
    sort === "newest" ? "Newest First" : sort === "drugA" ? "Drug A (A-Z)" : "Drug B (A-Z)";

  return (
    <div className="min-h-screen bg-muted/30">
      {/* Header */}
      <header className="bg-foreground px-5 pt-12 pb-6">
        <div className="flex items-center gap-2">
          <Pill className="h-6 w-6 text-destructive" />
          <h1 className="text-xl font-bold text-background">PillChecker</h1>
        </div>
      </header>

      {/* Content */}
      <main className="px-5 py-6">
        <h2 className="text-3xl font-extrabold text-foreground">My Checks</h2>
        <p className="text-muted-foreground mt-1">
          {checks.length} check{checks.length !== 1 ? "s" : ""} in your history
        </p>

        {/* Search */}
        <div className="relative mt-5">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Search by drug name..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-10 bg-background"
          />
        </div>

        {/* Sort */}
        <div className="mt-3">
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="outline" className="w-full justify-between">
                {sortLabel}
                <SlidersHorizontal className="h-4 w-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent className="w-56">
              <DropdownMenuItem onClick={() => setSort("newest")}>Newest First</DropdownMenuItem>
              <DropdownMenuItem onClick={() => setSort("drugA")}>Drug A (A-Z)</DropdownMenuItem>
              <DropdownMenuItem onClick={() => setSort("drugB")}>Drug B (A-Z)</DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>

        {/* List */}
        {filtered.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            <Pill className="h-16 w-16 text-muted-foreground/40 mb-4" />
            <p className="text-lg font-semibold text-foreground">No checks yet</p>
            <p className="text-muted-foreground mt-1">
              Tap the + button to check your first drug interaction!
            </p>
          </div>
        ) : (
          <div className="flex flex-col gap-3 mt-5">
            {filtered.map((check) => (
              <CheckHistoryCard
                key={check.id}
                record={check}
                onClick={() => navigate(`/history/${check.id}`)}
              />
            ))}
          </div>
        )}
      </main>

      {/* FAB */}
      <button
        onClick={() => setShowAdd(true)}
        className="fixed bottom-6 right-6 h-14 w-14 rounded-full bg-primary text-primary-foreground shadow-lg flex items-center justify-center hover:bg-primary/90 transition-colors z-50"
      >
        <Plus className="h-7 w-7" />
      </button>

      {/* Add Dialog */}
      <Dialog open={showAdd} onOpenChange={setShowAdd}>
        <DialogContent className="max-w-xs mx-auto">
          <DialogHeader>
            <DialogTitle>New Check</DialogTitle>
          </DialogHeader>
          <div className="flex flex-col gap-3 pt-2">
            <Button
              className="justify-start gap-3 h-14"
              onClick={() => {
                setShowAdd(false);
                navigate("/new");
              }}
            >
              <Camera className="h-5 w-5" />
              Scan Medicine
            </Button>
            <Button
              variant="outline"
              className="justify-start gap-3 h-14"
              onClick={() => {
                setShowAdd(false);
                navigate("/new");
              }}
            >
              <PenLine className="h-5 w-5" />
              Enter Manually
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default History;
