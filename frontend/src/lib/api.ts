import {
  ActivoFijo,
  ClaseActivo,
  PaginatedResponse,
  CreateActivoDto,
  ApiResult,
} from "./types";
import {
  MOCK_CLASES_ACTIVO,
  getMockActivosPaginados,
  getMockActivoById,
  addMockActivo,
} from "./mock-data";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3001/api/v1";

/**
 * Función auxiliar para realizar peticiones HTTP con timeout y control de errores.
 */
async function fetchWithTimeout(url: string, options: RequestInit = {}, timeoutMs = 3000): Promise<Response> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const res = await fetch(url, {
      ...options,
      signal: controller.signal,
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        ...(options.headers || {}),
      },
    });
    return res;
  } finally {
    clearTimeout(timeoutId);
  }
}

/**
 * 1. Health Check
 */
export async function checkBackendHealth(): Promise<{ online: boolean; message: string }> {
  try {
    const res = await fetchWithTimeout(`${API_BASE_URL}/health`, { method: "GET", cache: "no-store" }, 2000);
    if (res.ok) {
      return { online: true, message: "API Backend Conectada" };
    }
    return { online: false, message: `API respondió con estado HTTP ${res.status}` };
  } catch {
    return { online: false, message: "API Backend no disponible (Offline)" };
  }
}

/**
 * 2. Obtener Clases de Activo SUNAT
 * Endpoint: GET /activos-fijos/clases
 */
export async function getClasesActivos(): Promise<ApiResult<ClaseActivo[]>> {
  try {
    const res = await fetchWithTimeout(`${API_BASE_URL}/activos-fijos/clases`, { method: "GET" });
    if (res.ok) {
      const data = await res.json();
      // Tolerancia: si viene { data: [...] } o [...] directamente
      const list = Array.isArray(data) ? data : Array.isArray(data.data) ? data.data : MOCK_CLASES_ACTIVO;
      return { data: list, isMock: false };
    }
  } catch {
    // Fallback silencioso a mock
  }
  return { data: MOCK_CLASES_ACTIVO, isMock: true, message: "Cargado desde catálogo local SUNAT" };
}

/**
 * 3. Obtener Lista Paginada de Activos
 * Endpoint: GET /activos-fijos?page=1&limit=50
 */
export async function getActivos(
  page = 1,
  limit = 50,
  search = "",
  claseId?: number
): Promise<ApiResult<PaginatedResponse<ActivoFijo>>> {
  try {
    const params = new URLSearchParams({
      page: String(page),
      limit: String(limit),
    });
    if (search.trim()) params.append("search", search.trim());
    if (claseId) params.append("clase_activo_id", String(claseId));

    const res = await fetchWithTimeout(`${API_BASE_URL}/activos-fijos?${params.toString()}`, {
      method: "GET",
      cache: "no-store",
    });

    if (res.ok) {
      const json = await res.json();
      // Tolerancia: si el backend envía { data, total, page, limit }
      if (json && Array.isArray(json.data)) {
        return {
          data: {
            data: json.data,
            page: json.page || page,
            limit: json.limit || limit,
            total: json.total ?? json.data.length,
          },
          isMock: false,
        };
      }
      // Tolerancia si devuelve el arreglo directo [...]
      if (Array.isArray(json)) {
        return {
          data: {
            data: json,
            page: page,
            limit: limit,
            total: json.length,
          },
          isMock: false,
        };
      }
    }
  } catch {
    // Error de conexión o backend apagado
  }

  // Fallback a mock local
  const mockResult = getMockActivosPaginados(page, limit, search, claseId);
  return {
    data: mockResult,
    isMock: true,
    message: "Modo simulación local (Backend offline)",
  };
}

/**
 * 4. Obtener Detalle de un Activo
 * Endpoint: GET /activos-fijos/:id
 */
export async function getActivoById(id: number): Promise<ApiResult<ActivoFijo | null>> {
  try {
    const res = await fetchWithTimeout(`${API_BASE_URL}/activos-fijos/${id}`, { method: "GET" });
    if (res.ok) {
      const json = await res.json();
      const item = json.data || json;
      if (item && item.id) {
        return { data: item, isMock: false };
      }
    }
  } catch {
    // Fallback a mock
  }

  const mockItem = getMockActivoById(id);
  return {
    data: mockItem || null,
    isMock: true,
    message: "Detalle obtenido de catálogo local",
  };
}

/**
 * 5. Registrar un Nuevo Activo (Alta mínima)
 * Endpoint: POST /activos-fijos
 */
export async function createActivo(dto: CreateActivoDto): Promise<ApiResult<ActivoFijo>> {
  const payload = {
    empresa_id: dto.empresa_id || 1,
    descripcion: dto.descripcion.trim(),
    clase_activo_id: Number(dto.clase_activo_id),
    fecha_adquisicion: dto.fecha_adquisicion,
    costo_adquisicion: parseFloat(dto.costo_adquisicion).toFixed(2),
    valor_residual: dto.valor_residual ? parseFloat(dto.valor_residual).toFixed(2) : "0.00",
    metodo_depreciacion: dto.metodo_depreciacion || "1",
    tipo_activo_fijo: dto.tipo_activo_fijo || "1",
    estado_activo_fijo: dto.estado_activo_fijo || "9",
    situacion: dto.situacion || "P",
    marca: dto.marca?.trim() || undefined,
    modelo: dto.modelo?.trim() || undefined,
    numero_serie: dto.numero_serie?.trim() || undefined,
  };

  try {
    const res = await fetchWithTimeout(`${API_BASE_URL}/activos-fijos`, {
      method: "POST",
      body: JSON.stringify(payload),
    });

    if (res.ok) {
      const json = await res.json();
      const created = json.data || json;
      return {
        data: created,
        isMock: false,
        message: "Activo registrado exitosamente en la base de datos.",
      };
    } else {
      const errJson = await res.json().catch(() => null);
      const errorMsg = errJson?.mensaje || `Error del servidor (${res.status})`;
      throw new Error(errorMsg);
    }
  } catch {
    // Si la API falla o está apagada, registramos en memoria local para no bloquear la prueba
    const localCreated = addMockActivo(payload);
    return {
      data: localCreated,
      isMock: true,
      message: "Activo registrado en modo simulación (Backend no disponible).",
    };
  }
}
