"use client";

import { useState, useEffect } from "react";
import { X, PlusCircle, AlertTriangle, Building, Calendar, DollarSign, Tag, Hash, Loader2 } from "lucide-react";
import { ClaseActivo, ActivoFijo, CreateActivoDto } from "@/lib/types";
import { getClasesActivos, createActivo } from "@/lib/api";

interface ActivoCreateModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: (nuevoActivo: ActivoFijo, isMock: boolean, message: string) => void;
}

export function ActivoCreateModal({ isOpen, onClose, onSuccess }: ActivoCreateModalProps) {
  const [clases, setClases] = useState<ClaseActivo[]>([]);
  const [loadingClases, setLoadingClases] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  // Form fields
  const [descripcion, setDescripcion] = useState("");
  const [claseId, setClaseId] = useState<number>(7); // Default a equipos de computo
  const [fechaAdquisicion, setFechaAdquisicion] = useState(
    () => new Date().toISOString().split("T")[0]
  );
  const [costoAdquisicion, setCostoAdquisicion] = useState("");
  const [valorResidual, setValorResidual] = useState("0.00");
  const [marca, setMarca] = useState("");
  const [modelo, setModelo] = useState("");
  const [numeroSerie, setNumeroSerie] = useState("");

  // Cargar clases SUNAT
  useEffect(() => {
    if (!isOpen) return;
    setLoadingClases(true);
    getClasesActivos().then((res) => {
      setClases(res.data);
      if (res.data.length > 0 && !claseId) {
        setClaseId(res.data[0].id);
      }
      setLoadingClases(false);
    });
  }, [isOpen]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape" && !submitting) onClose();
    };
    if (isOpen) {
      window.addEventListener("keydown", handleKeyDown);
      document.body.style.overflow = "hidden";
    }
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
      document.body.style.overflow = "unset";
    };
  }, [isOpen, onClose, submitting]);

  if (!isOpen) return null;

  const selectedClaseObj = clases.find((c) => c.id === Number(claseId));

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);

    // Validaciones
    if (!descripcion.trim()) {
      setFormError("La descripción del activo es obligatoria.");
      return;
    }
    if (!claseId) {
      setFormError("Debe seleccionar una clase de activo válida.");
      return;
    }
    if (!fechaAdquisicion) {
      setFormError("La fecha de adquisición es obligatoria.");
      return;
    }
    const parsedCosto = parseFloat(costoAdquisicion);
    if (isNaN(parsedCosto) || parsedCosto <= 0) {
      setFormError("Ingrese un costo de adquisición válido mayor a 0.");
      return;
    }

    setSubmitting(true);

    try {
      const dto: CreateActivoDto = {
        empresa_id: 1, // Empresa default del MVP
        descripcion: descripcion.trim(),
        clase_activo_id: Number(claseId),
        fecha_adquisicion: fechaAdquisicion,
        costo_adquisicion: parsedCosto.toFixed(2),
        valor_residual: (parseFloat(valorResidual) || 0).toFixed(2),
        metodo_depreciacion: "1", // Línea Recta (SUNAT)
        tipo_activo_fijo: "1",
        estado_activo_fijo: "9", // Operativo
        situacion: "P", // Pendiente de aprobación
        marca: marca.trim() || undefined,
        modelo: modelo.trim() || undefined,
        numero_serie: numeroSerie.trim() || undefined,
      };

      const result = await createActivo(dto);
      onSuccess(result.data, result.isMock, result.message || "Activo registrado correctamente.");

      // Reset form
      setDescripcion("");
      setCostoAdquisicion("");
      setValorResidual("0.00");
      setMarca("");
      setModelo("");
      setNumeroSerie("");
      onClose();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Error al registrar el activo.";
      setFormError(msg);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs animate-in fade-in duration-150">
      <div
        className="w-full max-w-2xl rounded-2xl border border-[var(--border)] bg-[var(--surface)] shadow-2xl overflow-hidden flex flex-col max-h-[90vh]"
        role="dialog"
        aria-modal="true"
      >
        {/* Header */}
        <div className="px-6 py-4 border-b border-[var(--border)] flex items-center justify-between bg-[var(--surface-subtle)]">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-[var(--accent)] text-white flex items-center justify-center">
              <PlusCircle className="w-4 h-4" />
            </div>
            <div>
              <h3 className="text-base font-bold text-[var(--foreground)]">
                Registrar Nuevo Activo Fijo
              </h3>
              <p className="text-xs text-[var(--muted)]">
                Alta mínima para control patrimonial y contable
              </p>
            </div>
          </div>

          <button
            onClick={onClose}
            disabled={submitting}
            className="p-1 rounded-lg text-[var(--muted)] hover:text-[var(--foreground)] hover:bg-[var(--border)] transition-colors disabled:opacity-50"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="flex flex-col flex-1 overflow-hidden">
          <div className="p-6 overflow-y-auto space-y-5 custom-scrollbar text-sm text-[var(--foreground)]">
            {formError && (
              <div className="p-3 rounded-lg bg-red-50 border border-red-200 text-red-700 dark:bg-red-950/40 dark:border-red-800 dark:text-red-300 flex items-center gap-2 text-xs">
                <AlertTriangle className="w-4 h-4 shrink-0" />
                <span>{formError}</span>
              </div>
            )}

            {/* Descripción */}
            <div>
              <label className="block text-xs font-semibold uppercase tracking-wider text-[var(--muted)] mb-1.5">
                Descripción del Activo <span className="text-red-500">*</span>
              </label>
              <textarea
                rows={2}
                placeholder="Ejemplo: Servidor Rack Dell PowerEdge R750 32GB RAM"
                value={descripcion}
                onChange={(e) => setDescripcion(e.target.value)}
                required
                className="w-full px-3 py-2 text-sm rounded-lg border border-[var(--border)] bg-[var(--surface-subtle)] text-[var(--foreground)] placeholder:text-[var(--muted)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
              />
            </div>

            {/* Clasificación SUNAT */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-semibold uppercase tracking-wider text-[var(--muted)] mb-1.5 flex items-center gap-1">
                  <Building className="w-3.5 h-3.5 text-[var(--accent)]" />
                  Clase de Activo (SUNAT) <span className="text-red-500">*</span>
                </label>
                <select
                  value={claseId}
                  onChange={(e) => setClaseId(Number(e.target.value))}
                  disabled={loadingClases}
                  className="w-full px-3 py-2 text-sm rounded-lg border border-[var(--border)] bg-[var(--surface-subtle)] text-[var(--foreground)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
                >
                  {clases.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.codigo} - {c.descripcion}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold uppercase tracking-wider text-[var(--muted)] mb-1.5 flex items-center gap-1">
                  <Calendar className="w-3.5 h-3.5 text-[var(--muted)]" />
                  Fecha de Adquisición <span className="text-red-500">*</span>
                </label>
                <input
                  type="date"
                  value={fechaAdquisicion}
                  onChange={(e) => setFechaAdquisicion(e.target.value)}
                  required
                  className="w-full px-3 py-2 text-sm rounded-lg border border-[var(--border)] bg-[var(--surface-subtle)] text-[var(--foreground)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
                />
              </div>
            </div>

            {/* Info tributaria automática */}
            {selectedClaseObj && (
              <div className="p-3 rounded-lg border border-[var(--border)] bg-[var(--surface-subtle)]/60 text-xs text-[var(--muted)] flex items-center justify-between">
                <span>
                  Vida Útil Legal: <strong className="text-[var(--foreground)]">{selectedClaseObj.vida_util_anios} años</strong>
                </span>
                <span>
                  Tasa Depreciación Anual: <strong className="text-[var(--foreground)]">{selectedClaseObj.porcentaje_depreciacion_anual}%</strong>
                </span>
                <span className="hidden sm:inline">Método: Línea Recta</span>
              </div>
            )}

            {/* Costos */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-semibold uppercase tracking-wider text-[var(--muted)] mb-1.5 flex items-center gap-1">
                  <DollarSign className="w-3.5 h-3.5 text-emerald-600" />
                  Costo de Adquisición (S/) <span className="text-red-500">*</span>
                </label>
                <div className="relative">
                  <span className="absolute left-3 top-1/2 -translate-y-1/2 text-xs font-semibold text-[var(--muted)]">
                    S/
                  </span>
                  <input
                    type="number"
                    step="0.01"
                    min="0.01"
                    placeholder="6000.00"
                    value={costoAdquisicion}
                    onChange={(e) => setCostoAdquisicion(e.target.value)}
                    required
                    className="w-full pl-8 pr-3 py-2 text-sm rounded-lg border border-[var(--border)] bg-[var(--surface-subtle)] text-[var(--foreground)] tabular-nums focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold uppercase tracking-wider text-[var(--muted)] mb-1.5 flex items-center gap-1">
                  <DollarSign className="w-3.5 h-3.5 text-slate-500" />
                  Valor Residual Estimado (S/)
                </label>
                <div className="relative">
                  <span className="absolute left-3 top-1/2 -translate-y-1/2 text-xs font-semibold text-[var(--muted)]">
                    S/
                  </span>
                  <input
                    type="number"
                    step="0.01"
                    min="0"
                    placeholder="0.00"
                    value={valorResidual}
                    onChange={(e) => setValorResidual(e.target.value)}
                    className="w-full pl-8 pr-3 py-2 text-sm rounded-lg border border-[var(--border)] bg-[var(--surface-subtle)] text-[var(--foreground)] tabular-nums focus:outline-none focus:ring-1 focus:ring-[var(--accent)]"
                  />
                </div>
              </div>
            </div>

            {/* Datos complementarios */}
            <div className="space-y-2 pt-2 border-t border-[var(--border)]">
              <span className="text-xs font-semibold uppercase tracking-wider text-[var(--muted)] flex items-center gap-1">
                <Tag className="w-3.5 h-3.5 text-blue-600" />
                Datos de Identificación (Opcionales)
              </span>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <input
                  type="text"
                  placeholder="Marca (ej. Lenovo)"
                  value={marca}
                  onChange={(e) => setMarca(e.target.value)}
                  className="px-3 py-2 text-xs rounded-lg border border-[var(--border)] bg-[var(--surface-subtle)] text-[var(--foreground)]"
                />
                <input
                  type="text"
                  placeholder="Modelo (ej. T14 Gen 4)"
                  value={modelo}
                  onChange={(e) => setModelo(e.target.value)}
                  className="px-3 py-2 text-xs rounded-lg border border-[var(--border)] bg-[var(--surface-subtle)] text-[var(--foreground)]"
                />
                <div className="relative">
                  <Hash className="w-3 h-3 absolute left-2.5 top-1/2 -translate-y-1/2 text-[var(--muted)]" />
                  <input
                    type="text"
                    placeholder="N° de Serie"
                    value={numeroSerie}
                    onChange={(e) => setNumeroSerie(e.target.value)}
                    className="w-full pl-7 pr-3 py-2 text-xs rounded-lg border border-[var(--border)] bg-[var(--surface-subtle)] text-[var(--foreground)]"
                  />
                </div>
              </div>
            </div>
          </div>

          {/* Footer actions */}
          <div className="px-6 py-4 border-t border-[var(--border)] bg-[var(--surface-subtle)] flex items-center justify-end gap-3">
            <button
              type="button"
              onClick={onClose}
              disabled={submitting}
              className="px-4 py-2 rounded-lg border border-[var(--border)] bg-[var(--surface)] text-[var(--foreground)] text-xs font-medium hover:bg-[var(--border)] transition-colors disabled:opacity-50"
            >
              Cancelar
            </button>

            <button
              type="submit"
              disabled={submitting}
              className="inline-flex items-center gap-2 px-5 py-2 rounded-lg bg-[var(--accent)] text-white text-xs font-semibold hover:opacity-90 transition-opacity disabled:opacity-50 cursor-pointer shadow-xs"
            >
              {submitting ? (
                <>
                  <Loader2 className="w-3.5 h-3.5 animate-spin" />
                  <span>Guardando...</span>
                </>
              ) : (
                <>
                  <PlusCircle className="w-3.5 h-3.5" />
                  <span>Guardar Activo</span>
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
