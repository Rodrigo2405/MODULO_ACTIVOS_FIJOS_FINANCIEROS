import { ActivoFijo, ClaseActivo, PaginatedResponse } from "./types";

export const MOCK_CLASES_ACTIVO: ClaseActivo[] = [
  { id: 1, codigo: "1", descripcion: "Edificios y construcciones", porcentaje_depreciacion_anual: "5.00", vida_util_anios: 20 },
  { id: 2, codigo: "2", descripcion: "Maquinaria y equipo", porcentaje_depreciacion_anual: "10.00", vida_util_anios: 10 },
  { id: 3, codigo: "3", descripcion: "Unidades de transporte", porcentaje_depreciacion_anual: "20.00", vida_util_anios: 5 },
  { id: 4, codigo: "4", descripcion: "Muebles y enseres", porcentaje_depreciacion_anual: "10.00", vida_util_anios: 10 },
  { id: 5, codigo: "5", descripcion: "Equipos diversos", porcentaje_depreciacion_anual: "10.00", vida_util_anios: 10 },
  { id: 6, codigo: "6", descripcion: "Herramientas y unidades de reemplazo", porcentaje_depreciacion_anual: "25.00", vida_util_anios: 4 },
  { id: 7, codigo: "7", descripcion: "Equipos de procesamiento de datos", porcentaje_depreciacion_anual: "25.00", vida_util_anios: 4 },
];

export const MOCK_ACTIVOS: ActivoFijo[] = [
  {
    id: 1,
    empresa_id: 1,
    codigo_patrimonial: "AF-2026-0001",
    descripcion: "Servidor Rack Dell PowerEdge R750 32GB RAM",
    clase_activo_id: 7,
    clase_nombre: "Equipos de procesamiento de datos",
    fecha_adquisicion: "2026-01-15",
    costo_adquisicion: "12500.00",
    valor_residual: "0.00",
    metodo_depreciacion: "1",
    tipo_activo_fijo: "1",
    estado_activo_fijo: "9",
    situacion: "A",
    estado_conservacion: "Bueno",
    marca: "Dell",
    modelo: "PowerEdge R750",
    numero_serie: "SN-DELL-88219",
  },
  {
    id: 2,
    empresa_id: 1,
    codigo_patrimonial: "AF-2026-0002",
    descripcion: "Camioneta Hilux 4x4 Doble Cabina",
    clase_activo_id: 3,
    clase_nombre: "Unidades de transporte",
    fecha_adquisicion: "2026-02-10",
    costo_adquisicion: "115000.00",
    valor_residual: "15000.00",
    metodo_depreciacion: "1",
    tipo_activo_fijo: "1",
    estado_activo_fijo: "9",
    situacion: "A",
    estado_conservacion: "Operativo",
    marca: "Toyota",
    modelo: "Hilux 4x4",
    numero_serie: "TOY-HLX-49102",
  },
  {
    id: 3,
    empresa_id: 1,
    codigo_patrimonial: "AF-2026-0003",
    descripcion: "Laptop Lenovo ThinkPad T14 Gen 4 Core i7 16GB",
    clase_activo_id: 7,
    clase_nombre: "Equipos de procesamiento de datos",
    fecha_adquisicion: "2026-03-01",
    costo_adquisicion: "5400.00",
    valor_residual: "0.00",
    metodo_depreciacion: "1",
    tipo_activo_fijo: "1",
    estado_activo_fijo: "9",
    situacion: "P",
    estado_conservacion: "Nuevo",
    marca: "Lenovo",
    modelo: "ThinkPad T14 Gen 4",
    numero_serie: "LNV-TP-9921",
  },
  {
    id: 4,
    empresa_id: 1,
    codigo_patrimonial: "AF-2026-0004",
    descripcion: "Mesa de Reuniones Ejecutiva en Madera Caoba 10 personas",
    clase_activo_id: 4,
    clase_nombre: "Muebles y enseres",
    fecha_adquisicion: "2026-03-12",
    costo_adquisicion: "3800.00",
    valor_residual: "0.00",
    metodo_depreciacion: "1",
    tipo_activo_fijo: "1",
    estado_activo_fijo: "9",
    situacion: "A",
    estado_conservacion: "Bueno",
    marca: "Mueblería San José",
    modelo: "Ejecutivo 10P",
  },
  {
    id: 5,
    empresa_id: 1,
    codigo_patrimonial: "AF-2026-0005",
    descripcion: "Torno Industrial CNC de Precisión",
    clase_activo_id: 2,
    clase_nombre: "Maquinaria y equipo",
    fecha_adquisicion: "2026-03-20",
    costo_adquisicion: "82000.00",
    valor_residual: "5000.00",
    metodo_depreciacion: "1",
    tipo_activo_fijo: "1",
    estado_activo_fijo: "9",
    situacion: "P",
    estado_conservacion: "En calibración",
    marca: "Haas",
    modelo: "ST-20",
    numero_serie: "HAAS-ST20-773",
  },
];

export function getMockActivosPaginados(page = 1, limit = 50, search = "", claseId?: number): PaginatedResponse<ActivoFijo> {
  let filtered = [...MOCK_ACTIVOS];

  if (search.trim()) {
    const s = search.toLowerCase();
    filtered = filtered.filter(
      (a) => a.codigo_patrimonial.toLowerCase().includes(s) || a.descripcion.toLowerCase().includes(s)
    );
  }

  if (claseId) {
    filtered = filtered.filter((a) => a.clase_activo_id === claseId);
  }

  const total = filtered.length;
  const start = (page - 1) * limit;
  const paginated = filtered.slice(start, start + limit);

  return {
    data: paginated,
    page,
    limit,
    total,
  };
}
