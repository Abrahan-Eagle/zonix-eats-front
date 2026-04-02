# Verificación: solo estética — sin daño a lógica ni negocio

**Proyecto:** Zonix Eats (`zonix-eats-front` y, si aplica, `zonix-eats-back`)  
**Última actualización:** 2 Abr 2026  
**Cuándo usar:** Después de un PR o rama que **debió** limitarse a UI (colores, tema, tipografía, espaciado visual). Objetivo: **asegurar** que no se alteró lógica de código, lógica de negocio ni flujo de negocio.

**Índice general:** [`PROMPT_MAESTRO_ZONIX_EATS.md`](PROMPT_MAESTRO_ZONIX_EATS.md) (incluye el **Bloque D** equivalente).

---

## Prompt listo para pegar (chat con IA)

Copia todo el bloque entre las líneas:

```text
Tu rol: revisor de regresión para cambios declarados SOLO ESTÉTICOS (UI/visual). No implementes nuevas features.

CONTEXTO: Acabo de integrar o voy a integrar cambios que deben limitarse a apariencia (Theme, AppColors, TextStyle, BoxDecoration, padding visual). Necesito CERTEZA de que no hubo daño a:
- lógica de programación (condiciones, bucles, flujo de control),
- lógica de negocio (reglas de orden, pagos, delivery, roles),
- flujo de negocio (pasos de usuario, navegación, llamadas API).

ENTRADA: [Describe: rama/PR/commit o lista de archivos tocados, o pega el diff resumido]

TAREAS (ejecuta en orden y reporta):
1) DIFF SEMÁNTICO: Lista archivos cambiados. Clasifica cada uno como: (a) solo presentación, (b) sospechoso / revisar, (c) no debería tocarse en cambio solo-UI. Si hay archivos en (b) o (c), cita líneas o patrones concretos.
2) PATRONES PROHIBIDOS en cambios solo-UI (si aparecen en el diff, es ALERTA):
   - Flutter: cambios en llamadas http/post/get, URLs, headers, AuthHelper, parseo JSON, condiciones de negocio (if sobre status de orden, rol, payment), Provider/ChangeNotifier fuera de Theme, Navigator.push con rutas distintas, lógica en onPressed que cambie comportamiento.
   - Backend (si el diff lo incluye): cambios en Controllers de negocio, Services, Requests, rutas api.php, migraciones — no deberían existir en un PR solo UI.
3) PRUEBAS AUTOMATIZADAS (indica comandos; si puedes ejecutarlos en el entorno, hazlo y pega resultado):
   - Frontend: `flutter analyze` y `flutter test` (al menos suite completa o tests relevantes).
   - Backend: solo si hubo cambios de back: `php artisan test`.
4) CONCLUSIÓN: “SEGURO SOLO ESTÉTICA” / “RIESGO: revisar antes de merge” con lista de bullets. Sé honesto: si no tienes el diff completo, indica qué falta para cerrar.

SALIDA: Markdown en español, tabla archivos + veredicto, y sección “Riesgos residuales”.
```

---

## Checklist humano (rápido, sin IA)

- [ ] `git diff` no muestra cambios en `*_service.dart` de red (salvo imports de `material`/`theme` sin tocar métodos).
- [ ] No cambian strings de URLs ni paths de API.
- [ ] No hay `if (order.status` …) nuevos ni modificados salvo presentación (ej. color por estado puede ser OK si la condición ya existía).
- [ ] `flutter analyze` en verde.
- [ ] Smoke manual: login → una pantalla clave por rol.

---

## Historial

| Fecha | Cambio |
|-------|--------|
| 2026-04-02 | Creación: prompt de verificación post-UI solo estética. |
