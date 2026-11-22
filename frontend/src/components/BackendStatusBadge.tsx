"use client";

import { useEffect, useState } from "react";
import { CheckCircle2, AlertCircle, RefreshCw } from "lucide-react";

export function BackendStatusBadge() {
  const [status, setStatus] = useState<"checking" | "online" | "mock">("checking");
  const [apiUrl, setApiUrl] = useState<string>("");

  const checkHealth = async () => {
    setStatus("checking");
    const base = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3001/api/v1";
    setApiUrl(base);

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 2500);

      const res = await fetch(`${base}/health`, {
        signal: controller.signal,
        cache: "no-store",
      });

      clearTimeout(timeoutId);

      if (res.ok) {
        setStatus("online");
      } else {
        setStatus("mock");
      }
    } catch {
      setStatus("mock");
    }
  };

  useEffect(() => {
    checkHealth();
  }, []);

  return (
    <div className="flex items-center gap-2">
      <div
        className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium border transition-colors ${
          status === "online"
            ? "bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-950/40 dark:text-emerald-300 dark:border-emerald-800"
            : status === "mock"
            ? "bg-amber-50 text-amber-700 border-amber-200 dark:bg-amber-950/40 dark:text-amber-300 dark:border-amber-800"
            : "bg-slate-50 text-slate-600 border-slate-200 dark:bg-slate-900 dark:text-slate-400 dark:border-slate-800"
        }`}
        title={`URL API: ${apiUrl}`}
      >
        {status === "checking" && <RefreshCw className="w-3.5 h-3.5 animate-spin text-slate-500" />}
        {status === "online" && <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600 dark:text-emerald-400" />}
        {status === "mock" && <AlertCircle className="w-3.5 h-3.5 text-amber-600 dark:text-amber-400" />}

        <span>
          {status === "checking" && "Comprobando API..."}
          {status === "online" && "API Backend Conectada"}
          {status === "mock" && "Modo Datos Mock (API Offline)"}
        </span>
      </div>

      <button
        onClick={checkHealth}
        className="p-1 rounded text-slate-400 hover:text-slate-600 dark:hover:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
        title="Reintentar verificación de conexión"
      >
        <RefreshCw className="w-3 h-3" />
      </button>
    </div>
  );
}
