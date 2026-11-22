"use client";

import { useState, useMemo } from "react";
import { Search, Filter, Box, DollarSign, Clock, CheckCircle } from "lucide-react";
import { ActivoFijo } from "@/lib/types";
import { MOCK_ACTIVOS, MOCK_CLASES_ACTIVO } from "@/lib/mock-data";

export function ActivosTable() {
  const [search, setSearch] = useState("");
  const [selectedClase, setSelectedClase] = useState<string>("all");
  const [activos] = useState<ActivoFijo[]>(MOCK_ACTIVOS);

  const filteredActivos = useMemo(() => {
    return activos.filter((item) => {
      const matchSearch =
        item.codigo_patrimonial.toLowerCase().includes(search.toLowerCase()) ||
        item.descripcion.toLowerCase().includes(search.toLowerCase());

      const matchClase =
        selectedClase === "all" || item.clase_activo_id === Number(selectedClase);

      return matchSearch && matchClase;
    });
  }, [activos, search, selectedClase]);

  // KPIs
  const totalActivos = activos.length;
  const totalValor = activos.reduce((acc, curr) => acc + parseFloat(curr.costo_adquisicion || "0"), 0);
  const pendientesAprobacion = activos.filter((a) => a.situacion === "P").length;

  return (
    <div className="space-y-6">
      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="p-4 rounded-xl border border-[var(--border)] bg-[var(--surface)] shadow-xs">
          <div className="flex items-center justify-between text-[var(--muted)] mb-2">
            <span className="text-xs font-medium uppercase tracking-wider">Total de Activos</span>
            <Box className="w-4 h-4 text-[var(--accent)]" />
          </div>
          <div className="text-2xl font-bold tracking-tight tabular-nums text-[var(--foreground)]">
            {totalActivos}
          </div>
          <p className="text-xs text-[var(--muted)] mt-1">Activos registrados en el módulo</p>
        </div>

        <div className="p-4 rounded-xl border border-[var(--border)] bg-[var(--surface)] shadow-xs">
          <div className="flex items-center justify-between text-[var(--muted)] mb-2">
            <span className="text-xs font-medium uppercase tracking-wider">Costo Total en Libros</span>
            <DollarSign className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />
          </div>
          <div className="text-2xl font-bold tracking-tight tabular-nums text-[var(--foreground)]">
            S/ {totalValor.toLocaleString("es-PE", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
          </div>
          <p className="text-xs text-[var(--muted)] mt-1">Suma del costo de adquisición</p>
        </div>

        <div className="p-4 rounded-xl border border-[var(--border)] bg-[var(--surface)] shadow-xs">
          <div className="flex items-center justify-between text-[var(--muted)] mb-2">
            <span className="text-xs font-medium uppercase tracking-wider">Pendientes de Aprobación</span>
            <Clock className="w-4 h-4 text-amber-600 dark:text-amber-400" />
          </div>
          <div className="text-2xl font-bold tracking-tight tabular-nums text-[var(--foreground)]">
            {pendientesAprobacion}
          </div>
          <p className="text-xs text-[var(--muted)] mt-1">Situación &apos;P&apos; (registro inicial)</p>
        </div>
      </div>

      {/* Filters Bar */}
      <div className="p-4 rounded-xl border border-[var(--border)] bg-[var(--surface)] flex flex-col sm:flex-row items-center justify-between gap-4">
        <div className="relative w-full sm:w-80">
          <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-[var(--muted)]" />
          <input
            type="text"
            placeholder="Buscar por código o descripción..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-3 py-2 text-sm rounded-lg border border-[var(--border)] bg-[var(--surface-subtle)] text-[var(--foreground)] placeholder:text-[var(--muted)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
          />
        </div>

        <div className="flex items-center gap-2 w-full sm:w-auto">
          <Filter className="w-4 h-4 text-[var(--muted)]" />
          <select
            value={selectedClase}
            onChange={(e) => setSelectedClase(e.target.value)}
            className="w-full sm:w-auto px-3 py-2 text-sm rounded-lg border border-[var(--border)] bg-[var(--surface-subtle)] text-[var(--foreground)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
          >
            <option value="all">Todas las clases de activo</option>
            {MOCK_CLASES_ACTIVO.map((clase) => (
              <option key={clase.id} value={clase.id}>
                {clase.codigo} - {clase.descripcion}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Assets Table */}
      <div className="rounded-xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden shadow-xs">
        <div className="overflow-x-auto custom-scrollbar">
          <table className="w-full text-left text-sm">
            <thead className="bg-[var(--surface-subtle)] border-b border-[var(--border)] text-xs uppercase font-medium text-[var(--muted)]">
              <tr>
                <th scope="col" className="px-4 py-3">Código</th>
                <th scope="col" className="px-4 py-3">Descripción</th>
                <th scope="col" className="px-4 py-3">Clase SUNAT</th>
                <th scope="col" className="px-4 py-3">Fecha Adq.</th>
                <th scope="col" className="px-4 py-3 text-right">Costo (S/)</th>
                <th scope="col" className="px-4 py-3 text-center">Situación</th>
                <th scope="col" className="px-4 py-3 text-center">Estado</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[var(--border)] text-[var(--foreground)]">
              {filteredActivos.length > 0 ? (
                filteredActivos.map((item) => (
                  <tr key={item.id} className="hover:bg-[var(--surface-subtle)]/60 transition-colors">
                    <td className="px-4 py-3 font-mono text-xs font-semibold text-[var(--accent)]">
                      {item.codigo_patrimonial}
                    </td>
                    <td className="px-4 py-3">
                      <div className="font-medium text-[var(--foreground)]">{item.descripcion}</div>
                      {(item.marca || item.modelo) && (
                        <div className="text-xs text-[var(--muted)]">
                          {[item.marca, item.modelo].filter(Boolean).join(" · ")}
                        </div>
                      )}
                    </td>
                    <td className="px-4 py-3 text-xs text-[var(--muted)]">
                      {item.clase_nombre || `Clase ${item.clase_activo_id}`}
                    </td>
                    <td className="px-4 py-3 text-xs tabular-nums text-[var(--muted)]">
                      {item.fecha_adquisicion}
                    </td>
                    <td className="px-4 py-3 text-right font-medium tabular-nums text-[var(--foreground)]">
                      S/ {parseFloat(item.costo_adquisicion).toLocaleString("es-PE", { minimumFractionDigits: 2 })}
                    </td>
                    <td className="px-4 py-3 text-center">
                      <span
                        className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium border ${
                          item.situacion === "A"
                            ? "bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-950/40 dark:text-emerald-300 dark:border-emerald-800"
                            : "bg-amber-50 text-amber-700 border-amber-200 dark:bg-amber-950/40 dark:text-amber-300 dark:border-amber-800"
                        }`}
                      >
                        {item.situacion === "A" ? (
                          <>
                            <CheckCircle className="w-3 h-3" /> Aprobado
                          </>
                        ) : (
                          <>
                            <Clock className="w-3 h-3" /> Pendiente
                          </>
                        )}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-center text-xs text-[var(--muted)]">
                      {item.estado_conservacion || "Operativo"}
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={7} className="px-4 py-8 text-center text-[var(--muted)]">
                    No se encontraron activos que coincidan con la búsqueda.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
