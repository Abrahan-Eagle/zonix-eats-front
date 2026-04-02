# Prompt maestro — UI, colores y tema (claro / oscuro)

**Proyecto:** Zonix Eats — Flutter (`zonix-eats-front`)  
**Última actualización:** 2 Abr 2026  
**Índice general:** Para elegir entre auditoría full-stack y solo UI, ver [`docs/PROMPT_MAESTRO_ZONIX_EATS.md`](PROMPT_MAESTRO_ZONIX_EATS.md).

**Uso:** Pegar este documento (o la sección de fase activa) al inicio de un chat con la IA, o compartirlo con el equipo. No sustituye a `AGENTS.md`; lo complementa para **trabajo visual acotado**.

---

## 1. Objetivo

- Unificar la **apariencia** entre roles: el rol **`users` (buyer)** es la **referencia de oro** (jerarquía, cards, estados vacío/error, contraste).
- Eliminar **colores hardcodeados** (`Colors.*`, `Color(0x...)` sueltos) donde sea posible, en favor de **`AppColors`** + **`Theme.of(context).colorScheme`**.
- Garantizar comportamiento correcto en **modo claro y modo oscuro**.
- **Solo cambios visuales** — ver sección 8.

---

## 2. Contexto técnico (archivos clave)

| Recurso | Ruta |
|--------|------|
| Paleta y tokens | `lib/features/utils/app_colors.dart` |
| Tema global | `lib/main.dart` (o donde esté `ThemeData` / `darkTheme`) |
| Reglas de proyecto | `AGENTS.md`, skill `zonix-ui-design` |

**Referencia visual:** pantallas del **buyer** (restaurantes, carrito, órdenes, checkout).

---

## 3. Alcance por fases

| Fase | Roles / carpetas | Notas |
|------|-------------------|--------|
| **Fase 1** | **commerce** + **delivery** (agente / motorizado) | Incluir widgets compartidos **solo** si son necesarios para cerrar el diff de esas features o si son el único sitio donde corregir un color usido ahí. |
| **Fase 2** | **delivery_company** + **admin** | Mismo criterio; otro PR o chat recomendado. |

**Fuera de alcance en todas las fases:** cambios de API, validaciones, navegación distinta, estado de Provider, lógica de negocio.

---

## 4. Fuente de verdad de color

1. **`AppColors`** — ampliar **solo** con **tokens semánticos** si falta algo (ej. borde sutil, texto apagado que deba variar con el tema). Cada token nuevo: **comentario breve** de uso.
2. **`colorScheme`** — superficies, `onSurface`, `outline`, `primary`, errores (`error` / `onError`).
3. **Evitar** en archivos editados: `Colors.red`, `Colors.white`, `Colors.black`, `Color(0xFF...)` salvo **una excepción documentada** en el mensaje de commit si no hay mapeo razonable.

---

## 5. Modo oscuro (reglas concretas)

- Fondos: `colorScheme.surface`, `surfaceContainerHighest`, `scaffoldBackgroundColor` — no “blancos” en dark.
- Texto: `onSurface` / `onSurfaceVariant`; no grises fijos salvo token en `AppColors` con variante coherente.
- Bordes: `outline` / `outlineVariant` (con opacidad si hace falta).
- Tras cambios: validar **legibilidad** de botones y chips en **dark** (contraste).

---

## 6. Metodología (orden sugerido)

1. **Inventario** (desde la raíz del proyecto Flutter):
   ```bash
   rg "Colors\." lib/features --glob "*.dart"
   rg "Color\(0x" lib/features --glob "*.dart"
   ```
   Filtrar por rutas de la **fase activa**.
2. Por pantalla: **Scaffold** → **AppBar** → **body** → **cards** → **botones** → **loading / error / vacío**.
3. Sustituir hardcodes → `AppColors` / `colorScheme`; no extraer abstracciones grandes salvo patrón ya usado en buyer.
4. Probar en dispositivo o emulador: **light** y **dark**.
5. **`flutter analyze`** sin issues en archivos tocados.

---

## 7. Criterios de aceptación (checklist)

- [ ] Sin nuevos `Colors.` en archivos editados de la fase (salvo excepción documentada).
- [ ] Pantallas de la fase: coherencia con buyer en **ambos** temas.
- [ ] Estados loading / error / vacío usan tema o tokens, no grises sueltos.
- [ ] Diff acotado a **presentación** (ver sección 8).
- [ ] Lista de archivos tocados + tabla breve si se añadieron tokens en `AppColors` (nombre → uso).

---

## 8. Solo UI — no tocar la lógica (crítico)

**Permitido**

- `Color`, `TextStyle` (color / peso / tamaño si es solo presentación), `decoration`, `BoxDecoration`, `Theme`, `colorScheme`, `AppColors`.
- Ajustes de `padding` / `margin` / `alignment` que **no** cambien condiciones ni flujos.
- Envolver en `Theme` / `Builder` **solo** para obtener `context` del tema.

**Prohibido**

- Cambiar condiciones (`if`), bucles de negocio, llamadas a **API**, **servicios**, **Provider** (salvo que sea imposible sin tocar lógica — en ese caso **parar y preguntar**).
- Cambiar rutas de **navegación**, validaciones, parsers, firmas de métodos.
- Refactors “de limpieza” del árbol de widgets **no** necesarios para color/tema.

**Regla práctica:** si una línea no es **estilo o tema**, no se modifica. Antes de commit: *“¿esto podría cambiar qué se ejecuta (API, estado, navegación)?”* → Si sí, revertir.

---

## 9. Colaboración, honestidad y claridad

Comportamiento esperado de la IA:

1. **Honestidad epistémica:** Si algo es ambiguo (marca vs. estado semántico), **decirlo** y ofrecer **2 opciones** cortas con pros/contras. No afirmar certeza sin verificar en tema claro/oscuro o en `AppColors`.
2. **Preguntar antes de decisiones grandes:** Antes de añadir **más de ~3 tokens** nuevos en `AppColors`, o de tocar **`ThemeData` global**, o de modificar **widgets compartidos** usados por buyer + otros roles — **parar** y preguntar al dueño del producto con recomendación breve.
3. **Inconsistencias de diseño:** Si buyer hace X y commerce hace Y, **nombrarlo** y preguntar si se alinea a buyer o se deja para después.
4. **Cierre:** Párrafo **“Riesgos / dudas”**: qué quedó ambiguo, qué validar en dispositivo real.
5. **Lenguaje:** Evitar jerga innecesaria; si se usa un término técnico (`surfaceContainerHighest`), **una línea** en lenguaje de producto.

---

## 10. Frase opcional al abrir el chat

> Trabaja en modo **colaborativo**: si hay ambigüedad, trade-offs o riesgo de romper coherencia con buyer, **pregunta** antes. Sé **honesto** sobre lo que no está claro en el repo o no puedes validar sin ejecutar la app. **Solo UI** — colores, tema y estilos; **cero** cambios de lógica, estado o API.

---

## 11. Skills recomendadas (Cursor / Jarvis)

- `zonix-ui-design`
- `flutter-expert`

---

## 12. Plantilla de “solo Fase 1” o “solo Fase 2”

Sustituye el párrafo de alcance en el chat:

**Fase 1 — activa**

> Aplica las reglas de `docs/PROMPT_MAESTRO_UI_COLORES_Y_TEMA.md` **solo a Fase 1** (commerce + delivery). No modificar delivery_company ni admin en este PR.

**Fase 2 — activa**

> Aplica el mismo documento **solo a Fase 2** (delivery_company + admin).

---

## Historial

| Fecha | Cambio |
|-------|--------|
| 2026-04-02 | Creación: prompt maestro unificado (fases, metodología, solo UI, colaboración). |
