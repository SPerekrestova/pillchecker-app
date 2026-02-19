import { Toaster as Sonner } from "@/components/ui/sonner";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import History from "./pages/History";
import DrugInput from "./pages/DrugInput";
import ScanMedicine from "./pages/ScanMedicine";
import DrugSearch from "./pages/DrugSearch";
import Results from "./pages/Results";
import CheckDetail from "./pages/CheckDetail";
import NotFound from "./pages/NotFound";

const App = () => (
  <>
    <Sonner />
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<History />} />
        <Route path="/new" element={<DrugInput />} />
        <Route path="/scan/:slot" element={<ScanMedicine />} />
        <Route path="/search/:slot" element={<DrugSearch />} />
        <Route path="/results" element={<Results />} />
        <Route path="/history/:id" element={<CheckDetail />} />
        <Route path="*" element={<NotFound />} />
      </Routes>
    </BrowserRouter>
  </>
);

export default App;
