import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import type { CursoInput } from "../../types/course";

interface Props {
  title: string;
  submitLabel: string;
  initial: CursoInput;
  onSubmit: (values: CursoInput) => Promise<void>;
  onClose: () => void;
}

export default function CursoForm({
  title,
  submitLabel,
  initial,
  onSubmit,
  onClose,
}: Props) {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<CursoInput>({ defaultValues: initial });
  const [serverError, setServerError] = useState<string | null>(null);

  // Escape cierra la ventana.
  useEffect(() => {
    function onKey(event: KeyboardEvent) {
      if (event.key === "Escape") onClose();
    }
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  const submit = handleSubmit(async (values) => {
    setServerError(null);
    try {
      await onSubmit(values);
    } catch (error) {
      setServerError(
        error instanceof Error ? error.message : "No se pudo guardar."
      );
    }
  });

  return (
    <div
      className="mg-overlay"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget) onClose();
      }}
    >
      <form
        className="mg-dialog"
        role="dialog"
        aria-modal="true"
        aria-label={title}
        onSubmit={submit}
        noValidate
      >
        <h2>{title}</h2>

        <div className="mg-field">
          <label htmlFor="cu-codigo">Código</label>
          <input
            id="cu-codigo"
            type="text"
            autoFocus
            placeholder="Ej.: SQL-101"
            {...register("codigo", {
              validate: (v) =>
                (v.trim() !== "" && v.trim().length <= 50) ||
                "El código es obligatorio (máximo 50 caracteres).",
            })}
          />
          {errors.codigo && <small>{errors.codigo.message}</small>}
        </div>

        <div className="mg-field">
          <label htmlFor="cu-nombre">Nombre</label>
          <input
            id="cu-nombre"
            type="text"
            {...register("nombre", {
              validate: (v) =>
                (v.trim() !== "" && v.trim().length <= 150) ||
                "El nombre es obligatorio (máximo 150 caracteres).",
            })}
          />
          {errors.nombre && <small>{errors.nombre.message}</small>}
        </div>

        <div className="mg-field">
          <label htmlFor="cu-descripcion">Descripción</label>
          <textarea
            id="cu-descripcion"
            {...register("descripcion", {
              validate: (v) =>
                (v.trim() !== "" && v.trim().length <= 1000) ||
                "La descripción es obligatoria (máximo 1000 caracteres).",
            })}
          />
          {errors.descripcion && <small>{errors.descripcion.message}</small>}
        </div>

        {serverError && (
          <p className="mg-notice mg-notice--error" role="alert">
            {serverError}
          </p>
        )}

        <div className="mg-dialog__actions">
          <button type="button" className="mg-btn" onClick={onClose}>
            Cancelar
          </button>
          <button
            type="submit"
            className="mg-btn mg-btn--primary"
            disabled={isSubmitting}
          >
            {isSubmitting ? "Guardando..." : submitLabel}
          </button>
        </div>
      </form>
    </div>
  );
}