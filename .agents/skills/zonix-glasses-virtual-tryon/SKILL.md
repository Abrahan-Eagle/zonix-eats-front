---
name: zonix-glasses-virtual-tryon
description: >
  Try-on virtual IA: captura rostro, overlay monturas, modo recomendación.
  Trigger: try-on, face capture, virtual mirror, montura en rostro.
license: UNLICENSED
metadata:
  author: Zonix Glasses
  version: "1.0"
  scope: [domain]
  category: mobile
  related-skills: [zonix-glasses-ui-patterns, mobile-developer, security]
allowed-tools: [Read, Edit, Write, Glob, Grep, Bash]
---

# Zonix Glasses — Virtual Try-On

## Modos (ver FLUJOS_OPERATIVOS)

**A — Exploración:** usuario elige montura del catálogo → preview IA en su foto.

**B — Recomendación:** IA sugiere monturas según análisis facial → previews ranked.

## UX captura

- Guía: luz frontal, rostro centrado, sin lentes puestos.
- Mínimo 1 foto frontal; perfil opcional para recomendación.
- Consentimiento explícito (`PRIVACIDAD_OPTICA.md`).

## Implementación

- `lib/features/optical/services/tryon_service.dart`
- Upload multipart a `/api/patient/face-captures`
- Preview: URL temporal firmada o base64 según API `[PENDIENTE]`

## Privacidad

- No persistir raw en cliente más allá de sesión salvo consentimiento.
- Borrar caché al logout.

## Performance

- Comprimir imágenes antes de upload; indicador progreso try-on.
