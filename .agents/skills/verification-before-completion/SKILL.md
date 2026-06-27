---
name: verification-before-completion
description: >
  OBLIGATORIO antes de declarar cualquier tarea completada en cualquier proyecto.
  Ejecuta verificación fresca del stack y solo entonces afirma éxito.
  Trigger: Antes de cerrar módulo, commit, o decir "listo/tests OK".
license: UNLICENSED
metadata:
  author: JARVIS Global
  version: "2.0.0"
  scope: [global]
  auto_invoke:
    - "Terminar módulo"
    - "Crear commit"
  related-skills: [systematic-debugging, jarvis-core, test-driven-development]
---

# Verificación antes de completar (global)

## Ley de hierro

```
NINGÚN CLAIM DE COMPLETADO SIN EVIDENCIA FRESCA DE VERIFICACIÓN EN ESTE TURNO
```

## Puerta de verificación

1. **IDENTIFICAR** qué comando prueba el claim.
2. **EJECUTAR** el comando completo.
3. **LEER** exit code y errores.
4. **VERIFICAR** que el output confirma el claim.
5. **SOLO ENTONCES** declarar completado.

## Tabla por stack (detectar desde AGENTS.md / repo)

| Stack | Claim típico | Comando |
|-------|-------------|---------|
| Flutter | Tests / analyze | `flutter test`, `flutter analyze` |
| Laravel | Tests / rutas | `php artisan test`, `php artisan route:list` |
| Node/TS | Tests / lint | `npm test`, `npm run lint` |
| Docs solo | Coherencia | Revisión manual + links válidos |
| Genérico | Build | Comando documentado en README |

## NO es suficiente

- "Debería pasar"
- Tests ejecutados en un turno anterior
- Solo leer código sin ejecutar
- Asumir CI verde sin correr local

## Si falla

Invocar `systematic-debugging` antes de proponer fix.
