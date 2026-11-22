import { ActivosTable } from "@/components/ActivosTable";
import { PlusCircle } from "lucide-react";

export default function HomePage() {
  return (
    <div className="space-y-6">
      {/* Top action header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold tracking-tight text-[var(--foreground)]">
            Catálogo Patrimonial de Activos Fijos
          </h2>
          <p className="text-sm text-[var(--muted)]">
            Gestión y control de bienes patrimoniales según normativa SUNAT (PLE)
          </p>
        </div>

        <div>
          <button
            type="button"
            className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-[var(--accent)] text-white text-sm font-medium hover:opacity-90 transition-opacity shadow-xs cursor-pointer"
            title="Próximamente disponible en v0.2"
          >
            <PlusCircle className="w-4 h-4" />
            <span>Registrar Activo</span>
          </button>
        </div>
      </div>

      {/* Assets table & metrics */}
      <ActivosTable />
    </div>
  );
}
