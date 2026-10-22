import { Link, Navigate, useLocation } from "react-router-dom";
import { useAuth } from "../../context/authContext";
import AuthShell from "../../features/auth/AuthShell";
import LoginForm from "../../features/auth/LoginForm";

export default function LoginScreen() {
  const { isAuthenticated } = useAuth();
  const location = useLocation();
  const justRegistered =
    (location.state as { registered?: boolean } | null)?.registered === true;

  if (isAuthenticated) {
    return <Navigate to="/" replace />;
  }

  return (
    <AuthShell
      title="Bienvenido de vuelta"
      subtitle="Ingresa con tu correo para continuar tu aprendizaje."
    >
      {justRegistered && (
        <p className="login-notice" role="status">
          Cuenta creada. Ya puedes iniciar sesión.
        </p>
      )}
      <LoginForm />
      <p className="login-switch">
        ¿Primera vez? <Link to="/registro">Crear cuenta</Link>
      </p>
    </AuthShell>
  );
}