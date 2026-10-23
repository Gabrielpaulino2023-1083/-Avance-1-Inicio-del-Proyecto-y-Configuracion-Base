import { useEffect, useState } from "react";
import { useCountUp } from "./useCountUp";

const RADIUS = 54;
const CIRCUMFERENCE = 2 * Math.PI * RADIUS;

export default function ProgressRing({ percent }: { percent: number }) {
  const [ready, setReady] = useState(false);
  const shown = useCountUp(percent);

  useEffect(() => {
    const id = requestAnimationFrame(() => setReady(true));
    return () => cancelAnimationFrame(id);
  }, []);

  const offset = CIRCUMFERENCE * (1 - (ready ? percent : 0) / 100);

  return (
    <div className="ring" role="img" aria-label={`Progreso global: ${percent}%`}>
      <svg viewBox="0 0 128 128" width="100%" height="100%" aria-hidden="true">
        <circle className="ring__track" cx="64" cy="64" r={RADIUS} />
        <circle
          className="ring__value"
          cx="64"
          cy="64"
          r={RADIUS}
          strokeDasharray={CIRCUMFERENCE}
          strokeDashoffset={offset}
          transform="rotate(-90 64 64)"
        />
      </svg>
      <div className="ring__label">
        <strong>{Math.round(shown)}%</strong>
        <span>completado</span>
      </div>
    </div>
  );
}