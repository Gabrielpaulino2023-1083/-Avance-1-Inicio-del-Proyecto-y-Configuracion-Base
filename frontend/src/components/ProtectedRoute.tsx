import { Navigate, Outlet } from "react-router-dom";
import { useAuth } from "../context/authContext";

// Envuelve las pantallas internas: sin sesión, se redirige al login.
export default function ProtectedRoute() {
  const { isAuthenticated } = useAuth();

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  return <Outlet />;
}