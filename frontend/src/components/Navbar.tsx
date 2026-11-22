import { BackendStatusBadge } from "./BackendStatusBadge";
import { Building2 } from "lucide-react";

export function Navbar() {
  return (
    <header className="sticky top-0 z-30 border-b border-[var(--border)] bg-[var(--surface)]/90 backdrop-blur-md">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-lg bg-[var(--accent)] flex items-center justify-center text-white shadow-sm">
            <Building2 className="w-5 h-5" />
          </div>
          <div>
            <h1 className="text-base font-semibold text-[var(--foreground)] tracking-tight">
              Módulo de Activos Fijos
            </h1>
            <p className="text-xs text-[var(--muted)]">
              Control Patrimonial ERP · FSI
            </p>
          </div>
        </div>

        <div className="flex items-center gap-4">
          <BackendStatusBadge />
        </div>
      </div>
    </header>
  );
}
