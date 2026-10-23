import { Routes, Route } from "react-router-dom";
import AppLayout from "./components/Layout/AppLayout";
import ProtectedRoute from "./components/ProtectedRoute";
import LoginScreen from "./screens/Login/LoginScreen";
import RegisterScreen from "./screens/Register/RegisterScreen";
import DashboardScreen from "./screens/Dashboard/DashboardScreen";
import ContentScreen from "./screens/Content/ContentScreen";
import ResultsScreen from "./screens/Results/ResultsScreen";
import ProgressScreen from "./screens/Progress/ProgressScreen";

export default function App() {
  return (
    <Routes>
      {/* Login y registro quedan fuera del layout con navegación: antes de
          autenticarse, el estudiante no debe ver el menú interno. */}
      <Route path="/login" element={<LoginScreen />} />
      <Route path="/registro" element={<RegisterScreen />} />

      {/* Todo lo que está aquí dentro exige sesión iniciada. */}
      <Route element={<ProtectedRoute />}>
        <Route element={<AppLayout />}>
          <Route path="/" element={<DashboardScreen />} />
          <Route path="/contenido" element={<ContentScreen />} />
          <Route path="/resultados" element={<ResultsScreen />} />
          <Route path="/progreso" element={<ProgressScreen />} />
        </Route>
      </Route>
    </Routes>
  );
}