---
name: context-updater
description: Actualizar el contexto de sesión para que la IA "recuerde" entre sesiones. Resumir cambios relevantes en docs/active_context.md al cerrar o finalizar una sesión de trabajo significativa.
trigger: Al finalizar una sesión de trabajo con cambios arquitectónicos, de negocio o de convenciones; o cuando el usuario indique que va a cerrar o pausar.
scope: docs/active_context.md
author: Zonix Team
version: 1.0
---

# Context Updater — Memoria entre sesiones

## Objetivo

Mantener **docs/active_context.md** actualizado con un resumen breve de lo hecho en la sesión, para que la próxima vez que se abra el proyecto (en Cursor, Angravity o Copilot) la IA tenga contexto sin que el usuario tenga que pedir "lee .cursorrules / README".

## Cuándo aplicar

- Al finalizar una tarea o conjunto de tareas relevante (no en cada mensaje).
- Cuando el usuario diga que va a cerrar, pausar o cambiar de tema.
- Después de cambios que afecten arquitectura, reglas de negocio, convenciones o estado del proyecto.

## Qué incluir en el resumen

1. **Fecha** de la última actualización (ej. 6 Mar 2026).
2. **Resumen** en 2–4 líneas: qué se hizo y por qué importa.
3. **Áreas tocadas:** archivos, módulos o docs modificados (rutas relativas).
4. **Próximos pasos sugeridos:** tareas a medio hacer, mejoras obvias, o "—" si no aplica.

## Cómo actualizar

- Editar **docs/active_context.md** y reemplazar la sección "Última actualización de contexto" (no añadir entradas infinitas; una sola entrada actual).
- No modificar el resto del proyecto sin aprobación del usuario; solo este archivo.
- Si el usuario prefiere no escribir en disco, se puede **proponer** el contenido del resumen para que él lo pegue manualmente.

## Regla

Al proponer el resumen, preguntar: "¿Querés que actualice docs/active_context.md con este resumen o lo pegás vos?"
