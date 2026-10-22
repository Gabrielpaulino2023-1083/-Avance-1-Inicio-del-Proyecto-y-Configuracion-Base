import type { ReactNode } from "react";
import { CapIcon, ShieldIcon } from "./icons";
import "./auth.css";

interface Props {
  title: string;
  subtitle: string;
  children: ReactNode;
}

export default function AuthShell({ title, subtitle, children }: Props) {
  return (
    <main className="auth">
      <svg
        className="auth__net"
        viewBox="0 0 800 400"
        preserveAspectRatio="xMidYMid slice"
        aria-hidden="true"
      >
        <g stroke="#ffffff" strokeWidth="1" fill="none">
          <path d="M60 320 L220 220 L380 290 L540 150 L720 230" />
          <path d="M220 220 L300 90 L540 150" />
          <path d="M380 290 L470 370 L720 230" />
        </g>
        <g fill="#ffffff">
          <circle cx="60" cy="320" r="4" />
          <circle cx="220" cy="220" r="5" />
          <circle cx="300" cy="90" r="4" />
          <circle cx="380" cy="290" r="5" />
          <circle cx="470" cy="370" r="3" />
          <circle cx="540" cy="150" r="5" />
          <circle cx="720" cy="230" r="4" />
        </g>
      </svg>

      <div className="auth__brand">
        <span className="auth__brand-mark">
          <CapIcon />
        </span>
        Aprendizaje Adaptativo
      </div>

      <section className="auth-card">
        <span className="auth-card__mark">
          <CapIcon />
        </span>
        <h1>{title}</h1>
        <p className="auth-card__sub">{subtitle}</p>
        {children}
      </section>

      <p className="auth__secure">
        <ShieldIcon />
        Tus datos se almacenan de forma segura
      </p>
    </main>
  );
}