export interface ClaseActivo {
  id: number;
  codigo: string;
  descripcion: string;
  porcentaje_depreciacion_anual: string;
  vida_util_anios: number;
}

export interface ActivoFijo {
  id: number;
  empresa_id: number;
  codigo_patrimonial: string;
  descripcion: string;
  clase_activo_id: number;
  clase_nombre?: string;
  fecha_adquisicion: string; // AAAA-MM-DD
  costo_adquisicion: string; // "6000.00"
  valor_residual: string; // "0.00"
  metodo_depreciacion: string; // "1"
  tipo_activo_fijo: string; // "1"
  estado_activo_fijo: string; // "9"
  situacion: string; // "P" (pendiente), "A" (aprobado)
  estado_conservacion?: string;
  marca?: string;
  modelo?: string;
  numero_serie?: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  page: number;
  limit: number;
  total: number;
}

export interface ApiError {
  codigo: string;
  mensaje: string;
  detalle?: string;
}

export interface HealthResponse {
  status: string;
  database?: string;
  timestamp?: string;
}
