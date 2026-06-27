---
name: ui-router
description: >
  Orquesta precedencia UI/UX: skill dominio del producto, ui-ux-pro-max, responsive-design.
  Trigger: diseño UI, landing, dashboard, a11y, paleta, layout, revisión visual.
license: UNLICENSED
metadata:
  author: JARVIS Global
  version: "1.0"
  scope: [global]
  category: core
  auto_invoke:
    - "Diseñar UI o UX"
    - "Revisar accesibilidad o layout"
    - "Landing page o dashboard"
    - "Paleta de colores o tipografía"
  triggers: ui, ux, design, landing, dashboard, a11y, layout, paleta
  related-skills:
    - jarvis-core
    - open-design-router
    - stitch-router
    - ai-media-landing-ops
    - ui-ux-pro-max
    - responsive-design
    - sdd-router
allowed-tools: [Read, Edit, Write, Glob, Grep, Bash]
---

# UI Router — precedencia JARVIS

Router de **proceso UI**, no de dominio. Skills `{producto}-ui-design` y overlays viven en el repo del producto.

Ver también [docs/UI_UX_PRO_MAX_INTEGRATION.md](../../docs/UI_UX_PRO_MAX_INTEGRATION.md).

## Detección (repo activo)

```bash
# Zonix Glasses (Flutter — este repo)
grep -q 'name: zonix_glasses' pubspec.yaml 2>/dev/null && echo GLASSES_FLUTTER

# Zonix Glasses (Backend hub espejo)
test -f ../zonix-glasses-back/docs/MODELO_NEGOCIO/DECISIONES_FOUNDER.md && echo GLASSES

# Zonix Pharma — DEPRECATED en repo Glasses; usar solo en ZonixPharma-Front/Back
# test -f docs/BRAND_ZONIX_PHARMA.md && echo ZONIX

# CorralX (Flutter)
test -f lib/config/corral_x_theme.dart && echo CORRALX

# Overlay local (cualquier producto)
test -f .cursor/skills/ui-ux-pro-max/CORRALX.md && echo HAS_CORRALX_OVERLAY
test -f .agents/skills/ui-ux-pro-max/OVERLAY.md && echo HAS_AGENTS_OVERLAY
```

| Producto detectado | Skill dominio | Doc marca | Overlay típico |
|--------------------|---------------|-----------|----------------|
| **GLASSES / GLASSES_FLUTTER** | `zonix-glasses-ui-patterns` | `../zonix-glasses-back/docs/MODELO_NEGOCIO/DECISIONES_FOUNDER.md` | `ui-ux-pro-max/OVERLAY.md` |
| CORRALX | `corralx-ui-design` | tema en `lib/config/` | `CORRALX.md` |
| Genérico | `frontend-design` (si no hay dominio) | — | `OVERLAY.md` opcional |

> **Nota repo Glasses:** no enrutar a `zonix-ui-design` / `BRAND_ZONIX_PHARMA.md` (vertical Pharma — copia legacy del manifest global).

## Precedencia (siempre)

1. Brand canon del producto (doc + tokens en código)
2. Skill dominio (`{producto}-ui-design` / `zonix-web-design`)
3. Overlay opcional (`ZONIX.md`, `CORRALX.md`, `OVERLAY.md`)
4. **ui-ux-pro-max** — patrones, BM25, checklist (no override tokens)
5. **responsive-design** — breakpoints, fluid layout (opcional según tarea)

**Regla:** Paletas del CSV son ideas; implementar con tokens del producto (`AppColors`, tema M3, `zonix.css`).

## Cadena por escenario

| Escenario | Cadena |
|-----------|--------|
| Flutter pantalla/componente | overlay → `{producto}-ui-design` → `ui-ux-pro-max` (`--stack flutter`) → `responsive-design` (opc.) |
| Blade/CSS landing (Zonix) | overlay → `zonix-web-design` + BRAND → `ui-ux-pro-max` (`--stack html-tailwind` o `nextjs`) |
| Revisión pre-entrega | `ui-ux-pro-max` (checklist prioridad 1–10) + skill dominio |
| Solo responsive/breakpoints | `responsive-design` primero; `ui-ux-pro-max` si hay dudas de layout global |
| Feature con Spec Kit + UI | `sdd-router` → specs → implement; al tocar UI, aplicar esta cadena |
| Artefacto standalone (carrusel, deck, email, prototipo HTML) | `open-design-router` → `open-design` (no código en repo) |
| Prototipo web en Google Stitch (MCP) | `stitch-router` → skills upstream ([STITCH_UPSTREAM.md](../../docs/STITCH_UPSTREAM.md)) |
| Landing con video hero generado por IA (cadena multi-tool: Nano Banana + Veo/Kling + Claude Design/Code) | `ai-media-landing-ops` (assets + draft HTML); implementación en repo → `ui-router` |

## Comandos antes de implementar UI nueva

```bash
export UI_UX_SKILL_ROOT="${UI_UX_SKILL_ROOT:-$HOME/.cursor/skills/ui-ux-pro-max}"

# Design system (markdown para pegar en plan o PR)
python3 "$UI_UX_SKILL_ROOT/scripts/search.py" "<query producto/rubro>" \
  --design-system -p "<NombreApp>" -f markdown

# Stack específico
python3 "$UI_UX_SKILL_ROOT/scripts/search.py" "<query stack>" --stack flutter
# Alternativas: nextjs, shadcn, html-tailwind, react-native, vue, swiftui, jetpack-compose

# Dominio puntual
python3 "$UI_UX_SKILL_ROOT/scripts/search.py" "<query>" --domain ux
python3 "$UI_UX_SKILL_ROOT/scripts/search.py" "sans serif professional" --domain google-fonts
```

Persistencia opcional en repo activo:

```bash
python3 "$UI_UX_SKILL_ROOT/scripts/search.py" "<query>" \
  --design-system --persist -p "Project" --page "dashboard"
```

## Gates (obligatorios)

- Leer overlay si existe en `.cursor/skills/ui-ux-pro-max/` o `.agents/skills/ui-ux-pro-max/`
- No sustituir tokens de marca con salida del design system generator
- Con Spec Kit: UI en `speckit-implement` sigue esta precedencia
- `verification-before-completion` antes de declarar UI "lista"

## Overlay sin duplicar la skill

Template: `skills/ui/ui-ux-pro-max/overlays/OVERLAY.template.md` en jarvis-skills-library.

En el repo producto: copiar solo el overlay (ej. `ZONIX.md`) bajo `.cursor/skills/ui-ux-pro-max/`; la skill global viene de `install.sh --all`.

## Cuándo NO invocar ui-ux-pro-max

- Solo backend/API sin cambio visual
- Performance no relacionada con UI
- Infra/DevOps sin interfaz

Si la tarea cambia **cómo se ve, se siente, se mueve o se interactúa** en el **código del producto**, usar esta cadena.

Para **entregables visuales standalone** (carrusel RRSS, deck, email HTML sin tocar `lib/`), usar `open-design-router` ([OPEN_DESIGN_INTEGRATION.md](../../docs/OPEN_DESIGN_INTEGRATION.md)).

Para **prototipos en plataforma Stitch** (MCP + `stitch::generate-design`, `stitch-loop`, etc.), usar `stitch-router` ([STITCH_UPSTREAM.md](../../docs/STITCH_UPSTREAM.md)) — no confundir con Flutter en repo.

Para **landings con video hero generado por IA** (cadena Claude → Nano Banana → Veo/Kling → Claude Design/Code), usar `ai-media-landing-ops` — assets + draft HTML; implementación en repo → `ui-router`.
