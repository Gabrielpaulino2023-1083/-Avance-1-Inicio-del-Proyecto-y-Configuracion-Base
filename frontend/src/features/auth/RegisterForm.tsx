import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { useNavigate } from "react-router-dom";
import { register as registerRequest } from "../../services/authService";
import { registerSchema, type RegisterFormValues } from "./registerSchema";
import { ArrowIcon, EyeIcon, EyeOffIcon, LockIcon, MailIcon, UserIcon } from "./icons";

export default function RegisterForm() {
  const navigate = useNavigate();
  const [serverError, setServerError] = useState<string | null>(null);
  const [showPassword, setShowPassword] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<RegisterFormValues>({ resolver: zodResolver(registerSchema) });

  async function onSubmit(values: RegisterFormValues) {
    setServerError(null);
    try {
      await registerRequest({
        nombre: values.nombre,
        apellido: values.apellido,
        email: values.email,
        password: values.password,
      });
      navigate("/login", { replace: true, state: { registered: true } });
    } catch (error) {
      setServerError(
        error instanceof Error ? error.message : "No se pudo crear la cuenta."
      );
    }
  }

  const toggleLabel = showPassword ? "Ocultar contraseña" : "Mostrar contraseña";

  return (
    <form className="login-form" onSubmit={handleSubmit(onSubmit)} noValidate>
      <div className="field-row">
        <div className="field">
          <label htmlFor="nombre">Nombre</label>
          <div className="input">
            <UserIcon />
            <input
              id="nombre"
              type="text"
              placeholder="Nombre"
              autoComplete="given-name"
              aria-invalid={errors.nombre ? "true" : "false"}
              {...register("nombre")}
            />
          </div>
          {errors.nombre && (
            <p className="field-error" role="alert">
              {errors.nombre.message}
            </p>
          )}
        </div>

        <div className="field">
          <label htmlFor="apellido">Apellido</label>
          <div className="input">
            <UserIcon />
            <input
              id="apellido"
              type="text"
              placeholder="Apellido"
              autoComplete="family-name"
              aria-invalid={errors.apellido ? "true" : "false"}
              {...register("apellido")}
            />
          </div>
          {errors.apellido && (
            <p className="field-error" role="alert">
              {errors.apellido.message}
            </p>
          )}
        </div>
      </div>

      <div className="field">
        <label htmlFor="email">Correo electrónico</label>
        <div className="input">
          <MailIcon />
          <input
            id="email"
            type="email"
            placeholder="tu@correo.com"
            autoComplete="email"
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
            placeholder="Mínimo 8 caracteres"
            autoComplete="new-password"
            aria-invalid={errors.password ? "true" : "false"}
            {...register("password")}
          />
          <button
            type="button"
            className="input__toggle"
            onClick={() => setShowPassword((v) => !v)}
            aria-label={toggleLabel}
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

      <div className="field">
        <label htmlFor="confirmPassword">Confirmar contraseña</label>
        <div className="input">
          <LockIcon />
          <input
            id="confirmPassword"
            type={showPassword ? "text" : "password"}
            placeholder="Repite tu contraseña"
            autoComplete="new-password"
            aria-invalid={errors.confirmPassword ? "true" : "false"}
            {...register("confirmPassword")}
          />
        </div>
        {errors.confirmPassword && (
          <p className="field-error" role="alert">
            {errors.confirmPassword.message}
          </p>
        )}
      </div>

      {serverError && (
        <p className="form-error" role="alert">
          {serverError}
        </p>
      )}

      <button type="submit" className="auth-submit" disabled={isSubmitting}>
        {isSubmitting ? "Creando cuenta..." : "Crear cuenta"}
        <ArrowIcon />
      </button>
    </form>
  );
}