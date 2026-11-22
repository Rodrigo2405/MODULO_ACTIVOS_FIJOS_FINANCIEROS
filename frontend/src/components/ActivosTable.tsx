"use client";

import { useState, useEffect, useMemo, useCallback } from "react";
import {
  Search,
  Filter,
  Box,
  DollarSign,
  Clock,
  CheckCircle,
  PlusCircle,
  ChevronLeft,
  ChevronRight,
  Eye,
  CheckCircle2,
  AlertCircle,
  X,
  Loader2,
} from "lucide-react";
import { ActivoFijo, ClaseActivo } from "@/lib/types";
import { getActivos, getClasesActivos } from "@/lib/api";
import { ActivoDetailModal } from "./ActivoDetailModal";
import { ActivoCreateModal } from "./ActivoCreateModal";

export function ActivosTable() {
  const [activos, setActivos] = useState<ActivoFijo[]>([]);
  const [clases, setClases] = useState<ClaseActivo[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const limit = 10;
  const [search, setSearch] = useState("");
  const [selectedClase, setSelectedClase] = useState<string>("all");
  const [loading, setLoading] = useState(true);

  // Modals state
  const [detailActivo, setDetailActivo] = useState<ActivoFijo | null>(null);
  const [isDetailOpen, setIsDetailOpen] = useState(false);
  const [isCreateOpen, setIsCreateOpen] = useState(false);

  // Notification Toast state
  const [toast, setToast] = useState<{ message: string; isMock: boolean } | null>(null);

  // Cargar clases
  useEffect(() => {
    getClasesActivos().then((res) => setClases(res.data));
  }, []);

  // Cargar activos según filtros y página
  const loadActivos = useCallback(async () => {
    setLoading(true);
    const claseIdNum = selectedClase === "all" ? undefined : Number(selectedClase);
    const result = await getActivos(page, limit, search, claseIdNum);
    setActivos(result.data.data);
    setTotal(result.data.total);
    setLoading(false);
  }, [page, limit, search, selectedClase]);

  useEffect(() => {
    loadActivos();
  }, [loadActivos]);

  // Manejo de éxito al crear
  const handleCreateSuccess = (nuevo: ActivoFijo, isMock: boolean, msg: string) => {
    setToast({ message: msg, isMock });
    loadActivos();
  };

  // KPIs
  const totalValor = useMemo(() => {
    return activos.reduce((acc, curr) => acc + parseFloat(curr.costo_adquisicion || "0"), 0);
  }, [activos]);

  const pendientesAprobacion = useMemo(() => {
    return activos.filter((a) => a.situacion === "P").length;
  }, [activos]);

  const totalPages = Math.max(1, Math.ceil(total / limit));

  return (
    <div className="space-y-6">
      {/* Toast Notification */}
      {toast && (
        <div
          className={`p-3.5 rounded-xl border flex items-center justify-between text-xs animate-in fade-in duration-200 ${
            toast.isMock
              ? "bg-amber-50 text-amber-800 border-amber-200 dark:bg-amber-950/40 dark:text-amber-200 dark:border-amber-800"
              : "bg-emerald-50 text-emerald-800 border-emerald-200 dark:bg-emerald-950/40 dark:text-emerald-200 dark:border-emerald-800"
          }`}
        >
          <div className="flex items-center gap-2">
            {toast.isMock ? (
              <AlertCircle className="w-4 h-4 text-amber-600 dark:text-amber-400 shrink-0" />
            ) : (
              <CheckCircle2 className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
            )}
            <span>{toast.message}</span>
          </div>
          <button
            onClick={() => setToast(null)}
            className="p-1 rounded text-slate-500 hover:text-slate-800 dark:hover:text-slate-200"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        </div>
      )}

      {/* Action Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold tracking-tight text-[var(--foreground)]">
            Catálogo Patrimonial de Activos Fijos
          </h2>
          <p className="text-xs text-[var(--muted)]">
            Gestión y control de bienes patrimoniales según normativa SUNAT (PLE)
          </p>
        </div>

        <div>
          <button
            type="button"
            onClick={() => setIsCreateOpen(true)}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-[var(--accent)] text-white text-xs font-semibold hover:opacity-90 transition-opacity shadow-xs cursor-pointer"
          >
            <PlusCircle className="w-4 h-4" />
            <span>Registrar Activo</span>
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="p-4 rounded-xl border border-[var(--border)] bg-[var(--surface)] shadow-xs">
          <div className="flex items-center justify-between text-[var(--muted)] mb-2">
            <span className="text-xs font-medium uppercase tracking-wider">Total de Activos</span>
            <Box className="w-4 h-4 text-[var(--accent)]" />
          </div>
          <div className="text-2xl font-bold tracking-tight tabular-nums text-[var(--foreground)]">
            {total}
          </div>
          <p className="text-xs text-[var(--muted)] mt-1">Activos registrados en el módulo</p>
        </div>

        <div className="p-4 rounded-xl border border-[var(--border)] bg-[var(--surface)] shadow-xs">
          <div className="flex items-center justify-between text-[var(--muted)] mb-2">
            <span className="text-xs font-medium uppercase tracking-wider">Costo en Libros (Vista)</span>
            <DollarSign className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />
          </div>
          <div className="text-2xl font-bold tracking-tight tabular-nums text-[var(--foreground)]">
            S/ {totalValor.toLocaleString("es-PE", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
          </div>
          <p className="text-xs text-[var(--muted)] mt-1">Suma de costos en la página actual</p>
        </div>

        <div className="p-4 rounded-xl border border-[var(--border)] bg-[var(--surface)] shadow-xs">
          <div className="flex items-center justify-between text-[var(--muted)] mb-2">
            <span className="text-xs font-medium uppercase tracking-wider">Pendientes de Aprobación</span>
            <Clock className="w-4 h-4 text-amber-600 dark:text-amber-400" />
          </div>
          <div className="text-2xl font-bold tracking-tight tabular-nums text-[var(--foreground)]">
            {pendientesAprobacion}
          </div>
          <p className="text-xs text-[var(--muted)] mt-1">Situación &apos;P&apos; (alta pendiente de V°B°)</p>
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
            onChange={(e) => {
              setSearch(e.target.value);
              setPage(1);
            }}
            className="w-full pl-9 pr-3 py-2 text-xs rounded-lg border border-[var(--border)] bg-[var(--surface-subtle)] text-[var(--foreground)] placeholder:text-[var(--muted)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
          />
        </div>

        <div className="flex items-center gap-2 w-full sm:w-auto">
          <Filter className="w-4 h-4 text-[var(--muted)]" />
          <select
            value={selectedClase}
            onChange={(e) => {
              setSelectedClase(e.target.value);
              setPage(1);
            }}
            className="w-full sm:w-auto px-3 py-2 text-xs rounded-lg border border-[var(--border)] bg-[var(--surface-subtle)] text-[var(--foreground)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
          >
            <option value="all">Todas las clases SUNAT</option>
            {clases.map((clase) => (
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
                <th scope="col" className="px-4 py-3 text-center">Acciones</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[var(--border)] text-[var(--foreground)]">
              {loading ? (
                <tr>
                  <td colSpan={7} className="px-4 py-12 text-center text-[var(--muted)]">
                    <Loader2 className="w-6 h-6 animate-spin mx-auto mb-2 text-[var(--accent)]" />
                    <span>Cargando catálogo de activos...</span>
                  </td>
                </tr>
              ) : activos.length > 0 ? (
                activos.map((item) => (
                  <tr
                    key={item.id}
                    onClick={() => {
                      setDetailActivo(item);
                      setIsDetailOpen(true);
                    }}
                    className="hover:bg-[var(--surface-subtle)]/70 transition-colors cursor-pointer group"
                  >
                    <td className="px-4 py-3 font-mono text-xs font-semibold text-[var(--accent)] group-hover:underline">
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
                    <td className="px-4 py-3 text-center">
                      <button
                        type="button"
                        onClick={(e) => {
                          e.stopPropagation();
                          setDetailActivo(item);
                          setIsDetailOpen(true);
                        }}
                        className="p-1.5 rounded text-[var(--muted)] hover:text-[var(--accent)] hover:bg-[var(--border)] transition-colors cursor-pointer"
                        title="Ver ficha técnica"
                      >
                        <Eye className="w-4 h-4" />
                      </button>
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

        {/* Pagination bar */}
        <div className="p-4 border-t border-[var(--border)] bg-[var(--surface-subtle)]/40 flex flex-col sm:flex-row items-center justify-between gap-3 text-xs text-[var(--muted)]">
          <div>
            Mostrando <strong className="text-[var(--foreground)]">{activos.length}</strong> de{" "}
            <strong className="text-[var(--foreground)]">{total}</strong> activos registrados
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page <= 1}
              className="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg border border-[var(--border)] bg-[var(--surface)] text-[var(--foreground)] hover:bg-[var(--border)] disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
            >
              <ChevronLeft className="w-3.5 h-3.5" />
              <span>Anterior</span>
            </button>

            <span className="px-2 font-medium text-[var(--foreground)]">
              Página {page} de {totalPages}
            </span>

            <button
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={page >= totalPages}
              className="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg border border-[var(--border)] bg-[var(--surface)] text-[var(--foreground)] hover:bg-[var(--border)] disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
            >
              <span>Siguiente</span>
              <ChevronRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      </div>

      {/* Modals */}
      <ActivoDetailModal
        activo={detailActivo}
        isOpen={isDetailOpen}
        onClose={() => setIsDetailOpen(false)}
      />

      <ActivoCreateModal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        onSuccess={handleCreateSuccess}
      />
    </div>
  );
}
