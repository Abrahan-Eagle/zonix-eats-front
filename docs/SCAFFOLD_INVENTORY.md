# Inventario — Zonix Glasses Frontend

App Flutter óptica B2B2C. Paquete: `zonix_glasses`. ID nativo: `com.zonix.glasses`.

## Pantallas (scaffold base)

| Área | Pantallas |
|------|-----------|
| Auth | SignIn, onboarding 1–3 |
| Navegación | MainRouter — Inicio, Notificaciones, Perfil, Más |
| Perfil | CRUD perfil, teléfonos, direcciones, documentos |
| Privacidad | export, delete account, settings |

## Por implementar (dominio Glasses — post-HITL)

- Flujo fórmula paciente/partner (spec 001 UI)
- Catálogo monturas + try-on (`frame_only` / `lens_and_frame`)
- Carrito y checkout (`order_type`, prepago VE)
- Tracking multi-tramo (ShipmentLeg)
- Panel óptica aliada (pacientes, pedidos tenant)

Ver skill `zonix-glasses-ui-patterns`.

> **Pivot 2026:** ya no aplica UI de smart glasses / emparejamiento de dispositivo.

## Backend hermano

`../zonix-glasses-back`
