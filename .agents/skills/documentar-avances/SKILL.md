---
name: documentar-avances
description: Al finalizar una tarea relevante, proponer el párrafo para "Cambios recientes" en AGENTS.md y/o README. El usuario aprueba antes de que se escriba en el repo.
trigger: Después de implementar correcciones o mejoras relevantes (features, convenciones, reglas de negocio, integraciones).
scope: AGENTS.md, README.md, .cursorrules
author: Zonix Team
version: 1.0
---

# Documentar avances — Cambios recientes

## Objetivo

Mantener la sección **"Cambios recientes"** de AGENTS.md (y si aplica README) al día, para que la IA y el equipo tengan contexto de lo último hecho. La skill **no escribe** en el repo sin aprobación: **propone** el texto y el usuario decide si lo aplica.

## Cuándo aplicar

- Al terminar una tarea que merezca quedar registrada (nueva funcionalidad, cambio de convención, fix importante, integración nueva).
- No hace falta en cada fix typo o cambio menor; sí en cambios que afecten cómo se trabaja o qué hace el sistema.

## Formato propuesto

Una línea por cambio, con fecha y descripción breve, por ejemplo:

```markdown
- **DD MMM AAAA:** Descripción breve. Detalle opcional (archivos o módulos tocados).
```

## Flujo

1. Al finalizar la tarea, el agente **propone** el párrafo(s) para "Cambios recientes" (y si aplica para README).
2. Indica dónde pegarlo (ej. "En AGENTS.md, sección 'Cambios recientes', después de la última entrada").
3. **No** escribe en AGENTS.md ni README hasta que el usuario apruebe (ej. "sí, aplica" o "pegá eso").
4. Si el usuario aprueba, entonces se realiza la edición y se actualiza la fecha "Última actualización" en .cursorrules, AGENTS.md y README.md según las reglas del proyecto.

## Regla

Nunca modificar "Cambios recientes" o "Última actualización" sin que el usuario confirme. Siempre ofrecer el texto para copiar/pegar como alternativa.
