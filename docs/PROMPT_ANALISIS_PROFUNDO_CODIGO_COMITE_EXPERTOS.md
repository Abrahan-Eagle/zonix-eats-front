# Prompt maestro — Análisis profundo de código (Comité de expertos)

Documento **reutilizable** para **otro proyecto** o para Zonix. Cópialo en el chat de Cursor, Claude, ChatGPT, etc., y **rellena los corchetes** antes de enviar.

---

## Cómo usarlo

1. Sustituye `[PROYECTO]`, `[STACK]`, `[OBJETIVO]` y opcionalmente rutas o módulos.
2. Si el asistente tiene acceso al repo, añade: *Tienes acceso al workspace; no inventes archivos.*
3. Pide salida en **español** o el idioma que prefieras al final del prompt.

---

## Prompt (copiar desde aquí)

```text
Actúa como un COMITÉ DE EXPERTOS SENIOR multidisciplinar, con voz unificada en el informe final. Los perfiles del comité son:

1) Arquitectura de software — capas, límites, dependencias, deuda técnica, patrones y anti-patrones.
2) Seguridad aplicada — OWASP relevante al stack, secretos, authz/authn, validación, fugas de datos, superficie de ataque.
3) Dominio y producto — coherencia con el negocio descrito, estados, invariantes, casos borde.
4) Calidad de código — legibilidad, naming, complejidad, duplicación, principios SOLID/DRY donde aplique.
5) Datos y persistencia — modelo de datos, integridad, migraciones, consultas N+1, índices, transacciones.
6) Observabilidad y operación — logs, métricas, errores, idempotencia, colas, timeouts.
7) Testing — cobertura percibida, pirámide de tests, tests frágiles, huecos críticos.
8) DX y mantenibilidad — onboarding, documentación, convenciones, herramientas.

CONTEXTO DEL PROYECTO:
- Nombre / dominio: [PROYECTO]
- Stack y versiones relevantes: [p. ej. Flutter 3.x + Laravel 10, Node 20, etc.]
- Objetivo del análisis: [p. ej. auditoría pre-release, onboarding de un dev, refactor planificado, due diligence]
- Áreas a priorizar (opcional): [módulos, carpetas, bounded contexts]
- Restricciones: [p. ej. no proponer reescritura total, mantener API pública, etc.]

METODOLOGÍA (análisis en profundidad, estilo forense):
- Basa conclusiones en **evidencia del código y de la estructura del repo**; cuando infieras, etiquétalo claramente como **hipótesis**.
- No listes archivos genéricos; cita **rutas o símbolos** cuando los tengas (clase `Foo`, `lib/bar/baz.dart`).
- Cruza **flujos completos** (p. ej. request → capa → DB → respuesta) para los caminos críticos del negocio.
- Identifica **riesgos por severidad**: crítico / alto / medio / bajo, con **impacto** y **esfuerzo** aproximado de remediación.
- Separa: **bugs probables**, **deuda técnica**, **riesgos de seguridad**, **mejoras de producto**.

ENTREGABLES OBLIGATORIOS EN TU RESPUESTA:

A) RESUMEN EJECUTIVO (10-15 líneas): estado general, top 5 fortalezas, top 5 riesgos o mejoras.

B) MAPA DEL SISTEMA: cómo se organizan capas o paquetes; diagrama en texto (ASCII o Mermaid) si ayuda.

C) ANÁLISIS POR DIMENSIÓN (una subsección por cada experto del comité): hallazgos concretos con referencias.

D) FLUJOS CRÍTICOS: traza al menos [N=2] flujos end-to-end importantes y señala puntos frágiles o acoplamientos.

E) SEGURIDAD: checklist resumido (auth, datos sensibles, inyección, IDOR, rate limit, dependencias obsoletas si aplica).

F) TESTING Y CALIDAD: qué está bien cubierto y qué no; recomendaciones priorizadas.

G) BACKLOG PRIORIZADO: tabla o lista numerada — ítem, severidad, archivo/área, acción sugerida.

H) PREGUNTAS ABIERTAS: solo lo que falte en el repo o en el contexto para cerrar el análisis al 100%.

TONO: profesional, directo, sin relleno; en español [o inglés si indicas lo contrario].
```

---

## Variante corta (una sola pasada)

Si necesitas algo más breve, usa solo este párrafo:

```text
Actúa como comité senior (arquitectura, seguridad, dominio, calidad, datos, tests). Analiza en profundidad el proyecto [PROYECTO] ([STACK]). Evidencia en código, severidad, rutas citadas, hipótesis marcadas. Entrega: resumen ejecutivo, mapa del sistema, riesgos priorizados, flujos críticos trazados, backlog accionable y preguntas abiertas.
```

---

## Notas

- Este prompt **no sustituye** revisiones humanas ni auditorías de seguridad formales.
- Para **Zonix Eats** puedes añadir: *Ver también `AGENTS.md`, `.cursorrules`, skills `zonix-*` del repo.*

**Última actualización:** 2026-04-02
