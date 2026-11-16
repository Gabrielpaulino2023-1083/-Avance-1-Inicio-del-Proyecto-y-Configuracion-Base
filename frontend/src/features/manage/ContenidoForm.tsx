import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { ESTADOS, type ContenidoInput } from "../../types/curriculum";

interface Props {
  title: string;
  submitLabel: string;
  initial: ContenidoInput;
  onSubmit: (values: ContenidoInput) => Promise<void>;
  onClose: () => void;
}

export default function ContenidoForm({
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
  } = useForm<ContenidoInput>({ defaultValues: initial });
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
          <label htmlFor="mg-nombre">Nombre</label>
          <input
            id="mg-nombre"
            type="text"
            autoFocus
            {...register("nombre", {
              validate: (v) => v.trim() !== "" || "El nombre es obligatorio.",
            })}
          />
          {errors.nombre && <small>{errors.nombre.message}</small>}
        </div>

        <div className="mg-field">
          <label htmlFor="mg-descripcion">Descripción</label>
          <textarea
            id="mg-descripcion"
            {...register("descripcion", {
              validate: (v) =>
                v.trim() !== "" || "La descripción es obligatoria.",
            })}
          />
          {errors.descripcion && <small>{errors.descripcion.message}</small>}
        </div>

        <div className="mg-two">
          <div className="mg-field">
            <label htmlFor="mg-orden">Orden</label>
            <input
              id="mg-orden"
              type="number"
              min={1}
              {...register("orden", {
                valueAsNumber: true,
                validate: (v) =>
                  (Number.isInteger(v) && v > 0) ||
                  "Debe ser un entero mayor que 0.",
              })}
            />
            {errors.orden && <small>{errors.orden.message}</small>}
          </div>

          <div className="mg-field">
            <label htmlFor="mg-estado">Estado</label>
            <select id="mg-estado" {...register("estado")}>
              {ESTADOS.map((estado) => (
                <option key={estado} value={estado}>
                  {estado.charAt(0) + estado.slice(1).toLowerCase()}
                </option>
              ))}
            </select>
          </div>
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