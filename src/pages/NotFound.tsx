import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";

const NotFound = () => {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-muted/30 flex flex-col items-center justify-center px-5 text-center">
      <p className="text-6xl font-bold text-foreground">404</p>
      <p className="text-muted-foreground mt-2">Page not found</p>
      <Button className="mt-6" onClick={() => navigate("/", { replace: true })}>
        Go Home
      </Button>
    </div>
  );
};

export default NotFound;
