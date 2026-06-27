# Contexto activo — Zonix Glasses Frontend

> Espejo — canon de negocio en [../zonix-glasses-back/docs/](../zonix-glasses-back/docs/).

## Estado (2026-06-27)

### Fase del proyecto

- **Diseño de negocio** en hub back — modelo multi-fabricante, pedidos parciales, multi-courier.
- **No implementar** pantallas nuevas hasta HITL founder + realineación backend + seguridad 001.

### Producto

- Óptica B2B2C (no smart glasses — pivot Jun 2026).
- Tipos pedido: solo lentes / solo montura / ambos.
- `frame_only` mixto: stock top sellers + resto contra pedido (§12 back).
- Try-on + checkout montura sin fórmula.

### Código

- Feature 001 backend **congelado** (experimental pre-pivot) — ver [active_context.md](../zonix-glasses-back/docs/active_context.md).
- Front `lib/features/optical/` — **en pausa** hasta post-HITL.
- [SCAFFOLD_INVENTORY.md](SCAFFOLD_INVENTORY.md) actualizado (sin UI smart-glasses).

### Skills JARVIS

- `zonix-glasses-ui-patterns` — fórmulas, catálogo, try-on, checkout (no emparejamiento dispositivo).

### Auditoría forense v2 (Jun 2026)

- Informe índice: [AUDIT_FORENSE_2026-06-27.md](../zonix-glasses-back/docs/AUDIT_FORENSE_2026-06-27.md)
- Riesgos 001: [AUDIT_RIESGOS_SEGURIDAD.md](../zonix-glasses-back/docs/AUDIT_RIESGOS_SEGURIDAD.md)
- Mejoras negocio: [MEJORAS_MODELO_NEGOCIO.md](../zonix-glasses-back/docs/MEJORAS_MODELO_NEGOCIO.md)
- Skill `ui-router` — enrutamiento Glasses (`zonix-glasses-ui-patterns`), no Pharma

## Próximos pasos

1. Founder: [CHECKLIST_FOUNDER_S11.md](../zonix-glasses-back/docs/MODELO_NEGOCIO/CHECKLIST_FOUNDER_S11.md) en hub back
2. Revisión seguridad 001 en hub back
3. Tras HITL → [REALIGNMENT_POST_HITL.md](../zonix-glasses-back/specs/001-prescription-intake/REALIGNMENT_POST_HITL.md)
4. Flutter partner/paciente fórmulas

**Última actualización:** 2026-06-27 (cierre forense v2 — docs only)
