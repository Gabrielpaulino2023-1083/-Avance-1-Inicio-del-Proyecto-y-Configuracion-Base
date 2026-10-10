import { Navigate } from "react-router-dom";
import { useAuth } from "../../context/authContext";
import LoginForm from "../../features/auth/LoginForm";

export default function LoginScreen() {
  const { isAuthenticated } = useAuth();

  if (isAuthenticated) {
    return <Navigate to="/" replace />;
  }

  return (
    <main className="login-page">
      <aside className="login-aside">
        <span className="login-aside__brand">Aprendizaje Adaptativo</span>
        <div>
          <p className="login-aside__title">
            Estudia a tu ritmo, la plataforma se adapta a ti.
          </p>
          <p className="login-aside__text">
            Analizamos cómo estudias para ajustar los contenidos, las
            evaluaciones y la dificultad a tu progreso.
          </p>
        </div>
      </aside>

      <section className="login-main">
        <div className="login-panel">
          <h1>Iniciar sesión</h1>
          <p>Ingresa con tu correo para continuar.</p>
          <LoginForm />
        </div>
      </section>
    </main>
  );
}