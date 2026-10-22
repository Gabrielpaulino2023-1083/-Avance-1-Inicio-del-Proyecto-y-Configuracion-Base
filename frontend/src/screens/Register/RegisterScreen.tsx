import { Link, Navigate } from "react-router-dom";
import { useAuth } from "../../context/authContext";
import AuthShell from "../../features/auth/AuthShell";
import RegisterForm from "../../features/auth/RegisterForm";

export default function RegisterScreen() {
  const { isAuthenticated } = useAuth();

  if (isAuthenticated) {
    return <Navigate to="/" replace />;
  }

  return (
    <AuthShell
      title="Crea tu cuenta"
      subtitle="Regístrate como estudiante y empieza a aprender a tu manera."
    >
      <RegisterForm />
      <p className="login-switch">
        ¿Ya tienes cuenta? <Link to="/login">Iniciar sesión</Link>
      </p>
    </AuthShell>
  );
}