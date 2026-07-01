---
name: zonix-glasses-ui-patterns
description: >
  UI Flutter óptica B2B2C: fórmulas, catálogo monturas, carrito, panel aliado.
  Trigger: Pantallas óptica, catálogo, checkout, partner panel.
license: UNLICENSED
metadata:
  author: Zonix Glasses
  version: "1.0"
  scope: [domain]
  category: mobile
  auto_invoke:
    - "UI Zonix Glasses"
    - "Pantalla óptica"
  triggers: zonix-glasses, ui, optical, catalog, cart
  related-skills: [flutter-expert, ui-router, ui-ux-pro-max, zonix-glasses-virtual-tryon]
allowed-tools: [Read, Edit, Write, Glob, Grep, Bash]
---

# Zonix Glasses — UI Patterns

## Convenciones

- Features bajo `lib/features/` (`optical/`, `catalog/`, `cart/`, `partner/`)
- Provider + servicios HTTP; `AppConfig.apiUrl`; `AuthHelper.getAuthHeaders()`
- Brand: `../zonix-glasses-back/docs/BRAND_ZONIX_GLASSES.md`

## Flujos MVP

| Pantalla | Notas |
|----------|-------|
| Onboarding + código óptica | Asignar tenant partner |
| Mis fórmulas / upload | Manual + OCR status |
| Catálogo monturas | Grid, filtros, precio |
| Try-on | Ver skill `zonix-glasses-virtual-tryon` |
| Carrito | Líneas `OrderLineItem` (montura, lentes/lab, courier, delivery) |
| Checkout | Desglose dinámico v3.1: **total checkout**; IVA incluido (línea `iva_info`); envío gratis por zona; modalidad **4.1** (100%) o **4.2** (30%+70%); comprobante VE |
| Partner: pacientes | Lista + alta + cargar fórmula |

## Anti-patrones

- Copy smart-glasses / BLE
- `Colors.*` hardcoded fuera de tema
- URLs fuera de `AppConfig`

## API

Alinear con `../zonix-glasses-back/.agents/skills/zonix-glasses-api-patterns/SKILL.md`
