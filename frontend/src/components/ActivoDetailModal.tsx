"use client";

import { useEffect } from "react";
import { X, Building, Calendar, DollarSign, Tag, CheckCircle2, Clock, ShieldCheck, Hash } from "lucide-react";
import { ActivoFijo } from "@/lib/types";
import { MOCK_CLASES_ACTIVO } from "@/lib/mock-data";

interface ActivoDetailModalProps {
  activo: ActivoFijo | null;
  isOpen: boolean;
  onClose: () => void;
}

export function ActivoDetailModal({ activo, isOpen, onClose }: ActivoDetailModalProps) {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    if (isOpen) {
      window.addEventListener("keydown", handleKeyDown);
      document.body.style.overflow = "hidden";
    }
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
      document.body.style.overflow = "unset";
    };
  }, [isOpen, onClose]);

  if (!isOpen || !activo) return null;

  const clase = MOCK_CLASES_ACTIVO.find((c) => c.id === activo.clase_activo_id);
  const costo = parseFloat(activo.costo_adquisicion || "0");
  const residual = parseFloat(activo.valor_residual || "0");

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs animate-in fade-in duration-150">
      <div
        className="w-full max-w-2xl rounded-2xl border border-[var(--border)] bg-[var(--surface)] shadow-2xl overflow-hidden flex flex-col max-h-[90vh]"
        role="dialog"
        aria-modal="true"
      >
        {/* Header */}
        <div className="px-6 py-4 border-b border-[var(--border)] flex items-center justify-between bg-[var(--surface-subtle)]">
          <div className="flex items-center gap-3">
            <span className="font-mono text-xs font-bold px-2.5 py-1 rounded bg-[var(--accent)] text-white">
              {activo.codigo_patrimonial}
            </span>
            <span
              className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium border ${
                activo.situacion === "A"
                  ? "bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-950/40 dark:text-emerald-300 dark:border-emerald-800"
                  : "bg-amber-50 text-amber-700 border-amber-200 dark:bg-amber-950/40 dark:text-amber-300 dark:border-amber-800"
              }`}
            >
              {activo.situacion === "A" ? (
                <>
                  <CheckCircle2 className="w-3 h-3" /> Aprobado
                </>
              ) : (
                <>
                  <Clock className="w-3 h-3" /> Pendiente de Aprobación
                </>
              )}
            </span>
          </div>

          <button
            onClick={onClose}
            className="p-1 rounded-lg text-[var(--muted)] hover:text-[var(--foreground)] hover:bg-[var(--border)] transition-colors"
            title="Cerrar (Esc)"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content body */}
        <div className="p-6 overflow-y-auto space-y-6 custom-scrollbar text-sm text-[var(--foreground)]">
          {/* Main Title */}
          <div>
            <h3 className="text-lg font-bold text-[var(--foreground)] leading-snug">
              {activo.descripcion}
            </h3>
            <p className="text-xs text-[var(--muted)] mt-1">
              Catálogo Patrimonial · Empresa ID: {activo.empresa_id}
            </p>
          </div>

          {/* Section 1: Financial information */}
          <div className="space-y-3">
            <h4 className="text-xs font-semibold uppercase tracking-wider text-[var(--muted)] flex items-center gap-1.5">
              <DollarSign className="w-3.5 h-3.5 text-emerald-600 dark:text-emerald-400" />
              Información Financiera y Contable
            </h4>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 p-3.5 rounded-xl border border-[var(--border)] bg-[var(--surface-subtle)]/50">
              <div>
                <span className="text-xs text-[var(--muted)] block">Costo Adquisición</span>
                <span className="text-base font-bold tabular-nums text-[var(--foreground)]">
                  S/ {costo.toLocaleString("es-PE", { minimumFractionDigits: 2 })}
                </span>
              </div>
              <div>
                <span className="text-xs text-[var(--muted)] block">Valor Residual</span>
                <span className="text-base font-bold tabular-nums text-[var(--foreground)]">
                  S/ {residual.toLocaleString("es-PE", { minimumFractionDigits: 2 })}
                </span>
              </div>
              <div>
                <span className="text-xs text-[var(--muted)] block">Fecha Adquisición</span>
                <span className="text-sm font-semibold tabular-nums text-[var(--foreground)] flex items-center gap-1 mt-0.5">
                  <Calendar className="w-3.5 h-3.5 text-[var(--muted)]" />
                  {activo.fecha_adquisicion}
                </span>
              </div>
            </div>
          </div>

          {/* Section 2: SUNAT Classification & Depreciation */}
          <div className="space-y-3">
            <h4 className="text-xs font-semibold uppercase tracking-wider text-[var(--muted)] flex items-center gap-1.5">
              <Building className="w-3.5 h-3.5 text-[var(--accent)]" />
              Clasificación SUNAT (PLE) y Depreciación
            </h4>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 p-3.5 rounded-xl border border-[var(--border)] bg-[var(--surface-subtle)]/50">
              <div>
                <span className="text-xs text-[var(--muted)] block">Clase de Activo</span>
                <span className="text-xs font-semibold text-[var(--foreground)]">
                  {clase ? `${clase.codigo} - ${clase.descripcion}` : `Clase ${activo.clase_activo_id}`}
                </span>
              </div>
              <div>
                <span className="text-xs text-[var(--muted)] block">Vida Útil Legal</span>
                <span className="text-sm font-bold tabular-nums text-[var(--foreground)]">
                  {clase ? `${clase.vida_util_anios} años` : "Según norma"}
                </span>
              </div>
              <div>
                <span className="text-xs text-[var(--muted)] block">Tasa Anual Legal</span>
                <span className="text-sm font-bold tabular-nums text-[var(--foreground)]">
                  {clase ? `${clase.porcentaje_depreciacion_anual}%` : "10%"}
                </span>
              </div>
            </div>
          </div>

          {/* Section 3: Technical specifications */}
          <div className="space-y-3">
            <h4 className="text-xs font-semibold uppercase tracking-wider text-[var(--muted)] flex items-center gap-1.5">
              <Tag className="w-3.5 h-3.5 text-blue-600 dark:text-blue-400" />
              Especificaciones del Bien
            </h4>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 p-3.5 rounded-xl border border-[var(--border)] bg-[var(--surface-subtle)]/50">
              <div>
                <span className="text-xs text-[var(--muted)] block">Marca</span>
                <span className="text-sm font-medium text-[var(--foreground)]">
                  {activo.marca || "No especificada"}
                </span>
              </div>
              <div>
                <span className="text-xs text-[var(--muted)] block">Modelo</span>
                <span className="text-sm font-medium text-[var(--foreground)]">
                  {activo.modelo || "No especificado"}
                </span>
              </div>
              <div>
                <span className="text-xs text-[var(--muted)] block">N° de Serie</span>
                <span className="text-xs font-mono font-medium text-[var(--foreground)] flex items-center gap-1 mt-0.5">
                  <Hash className="w-3 h-3 text-[var(--muted)]" />
                  {activo.numero_serie || "S/N"}
                </span>
              </div>
            </div>
          </div>

          {/* System metadata */}
          <div className="p-3 rounded-lg border border-[var(--border)] bg-[var(--surface)] text-xs text-[var(--muted)] flex items-center justify-between">
            <span className="flex items-center gap-1.5">
              <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
              Método: Línea Recta (Tabla 19 SUNAT)
            </span>
            <span>Estado: {activo.estado_conservacion || "Operativo (Código 9)"}</span>
          </div>
        </div>

        {/* Footer actions */}
        <div className="px-6 py-3 border-t border-[var(--border)] bg-[var(--surface-subtle)] flex items-center justify-end">
          <button
            onClick={onClose}
            className="px-4 py-2 rounded-lg bg-[var(--accent)] text-white text-xs font-medium hover:opacity-90 transition-opacity cursor-pointer"
          >
            Cerrar Ficha
          </button>
        </div>
      </div>
    </div>
  );
}
