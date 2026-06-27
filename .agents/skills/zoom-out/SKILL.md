---
name: zoom-out
description: >
  Explicar código o un cambio en el contexto del sistema completo del proyecto activo
  (módulos, capas, flujos). Uso bajo demanda.
  Trigger: Pedir contexto arquitectónico, explicar módulo desconocido, donde encaja un archivo.
license: UNLICENSED
metadata:
  version: "2.0.0"
  adapted_from: mattpocock/skills (zoom-out)
  related-skills: [jarvis-core, clean-architecture, software-architecture]
---

# Zoom out (global)

Perspectiva de **alto nivel** antes de tocar código en cualquier proyecto.

## Cuándo invocar

- Archivo o módulo desconocido en la sesión
- Pregunta "¿dónde encaja X?" o "¿qué flujo usa esto?"
- Antes de un refactor que cruza módulos
- Tras leer solo un fragmento (pantalla, servicio, controlador)

## Procedimiento

1. Leer `AGENTS.md` y `README.md` del repo para mapa de módulos.
2. Leer `docs/active_context.md` si existe.
3. Identificar capa del archivo (UI, API, dominio, infra).
4. Dibujar flujo en 3–5 bullets: entrada → procesamiento → salida.
5. Señalar dependencias y skills de dominio `{producto}-*` si aplican.

## Salida esperada

- Mapa mental breve del área afectada
- Archivos y servicios relacionados (rutas del repo activo)
- Riesgos de cambio transversal
- Siguiente skill de dominio a invocar si hace falta detalle
