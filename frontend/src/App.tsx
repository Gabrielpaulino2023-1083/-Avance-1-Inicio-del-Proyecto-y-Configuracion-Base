import { Routes, Route } from "react-router-dom";
import AppLayout from "./components/Layout/AppLayout";
import LoginScreen from "./screens/Login/LoginScreen";
import DashboardScreen from "./screens/Dashboard/DashboardScreen";
import ContentScreen from "./screens/Content/ContentScreen";
import ResultsScreen from "./screens/Results/ResultsScreen";
import ProgressScreen from "./screens/Progress/ProgressScreen";

export default function App() {
  return (
    <Routes>
      {/* El login queda fuera del layout con navegación: antes de
          autenticarse, el estudiante no debe ver el menú interno. */}
      <Route path="/login" element={<LoginScreen />} />

      <Route element={<AppLayout />}>
        <Route path="/" element={<DashboardScreen />} />
        <Route path="/contenido" element={<ContentScreen />} />
        <Route path="/resultados" element={<ResultsScreen />} />
        <Route path="/progreso" element={<ProgressScreen />} />
      </Route>
    </Routes>
  );
}