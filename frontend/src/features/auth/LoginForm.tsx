import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../../context/authContext";
import { loginSchema, type LoginFormValues } from "./loginSchema";
import { ArrowIcon, EyeIcon, EyeOffIcon, LockIcon, MailIcon } from "./icons";

const SHOW_TEST_HINT = import.meta.env.VITE_USE_MOCK !== "false";

export default function LoginForm() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [serverError, setServerError] = useState<string | null>(null);
  const [showPassword, setShowPassword] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginFormValues>({ resolver: zodResolver(loginSchema) });

  async function onSubmit(values: LoginFormValues) {
    setServerError(null);
    try {
      await login(values);
      navigate("/", { replace: true });
    } catch (error) {
      setServerError(
        error instanceof Error ? error.message : "No se pudo iniciar sesión."
      );
    }
  }

  return (
    <form className="login-form" onSubmit={handleSubmit(onSubmit)} noValidate>
      <div className="field">
        <label htmlFor="email">Correo electrónico</label>
        <div className="input">
          <MailIcon />
          <input
            id="email"
            type="email"
            placeholder="tu@correo.com"
            autoComplete="username"
            aria-invalid={errors.email ? "true" : "false"}
            {...register("email")}
          />
        </div>
        {errors.email && (
          <p className="field-error" role="alert">
            {errors.email.message}
          </p>
        )}
      </div>

      <div className="field">
        <label htmlFor="password">Contraseña</label>
        <div className="input input--password">
          <LockIcon />
          <input
            id="password"
            type={showPassword ? "text" : "password"}
            placeholder="Tu contraseña"
            autoComplete="current-password"
            aria-invalid={errors.password ? "true" : "false"}
            {...register("password")}
          />
          <button
            type="button"
            className="input__toggle"
            onClick={() => setShowPassword((v) => !v)}
            aria-label={showPassword ? "Ocultar contraseña" : "Mostrar contraseña"}
            aria-pressed={showPassword}
          >
            {showPassword ? <EyeOffIcon /> : <EyeIcon />}
          </button>
        </div>
        {errors.password && (
          <p className="field-error" role="alert">
            {errors.password.message}
          </p>
        )}
      </div>

      {serverError && (
        <p className="form-error" role="alert">
          {serverError}
        </p>
      )}

      <button type="submit" className="auth-submit" disabled={isSubmitting}>
        {isSubmitting ? "Ingresando..." : "Iniciar sesión"}
        <ArrowIcon />
      </button>

      {SHOW_TEST_HINT && (
        <p className="login-hint">
          Modo de prueba: estudiante@example.com / estudiante123
        </p>
      )}
    </form>
  );
}