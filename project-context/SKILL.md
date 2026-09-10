---
name: project-context
description: |
  Documenta un repositorio que Claude no conoce, generando CLAUDE.md, docs/ARCHITECTURE.md,
  docs/CONVENTIONS.md, docs/DOMAIN.md, docs/TESTING.md y CONTEXT_MEMORY.md a partir de
  evidencia real del código, nunca de suposiciones. Úsala siempre que el usuario pida
  "documentar el proyecto", "generar el CLAUDE.md", "que entiendas este repo", "crear el
  contexto del proyecto", "escribir las convenciones", o cuando esté por empezar a trabajar
  en un repositorio que no tiene CLAUDE.md ni documentación de contexto para agentes —
  aunque no lo pida con esas palabras exactas. No es para instalar dependencias ni levantar
  el entorno: para eso existe project-onboarding.
---

# Project Context

Generar la documentación de contexto que Claude leerá en todas las sesiones futuras de este
repositorio.

## Alcance

**Esto SÍ:** leer el código y escribir documentos que describan lo que el proyecto es hoy.

**Esto NO:** instalar dependencias, levantar servicios, corregir configuración, escribir
código de producto, proponer refactors. Si el usuario necesita dejar el proyecto corriendo,
usar `project-onboarding` en su lugar. Si no existe `CLAUDE.md` después de correr
`project-onboarding`, sugerir esta skill al final.

## Regla dura

Toda afirmación en los documentos debe salir de un archivo que leíste. Si no la puedes
verificar, va en **"Suposiciones a confirmar"** marcada con ⚠️.

Queda prohibido escribir prácticas de la industria que este repositorio no sigue realmente.
Un `CONVENTIONS.md` que describe convenciones inventadas es peor que no tener archivo:
envenena todas las sesiones siguientes y el usuario no tiene forma de saber cuáles reglas
son reales.

---

## Fase 1 — Reconocimiento (solo lectura)

No escribas ningún archivo en esta fase.

Para identificar el stack, usar `references/stack-detection.md` de la skill `project-onboarding`
si está instalada — no duplicar esa tabla aquí. Para saber qué buscar dentro del código una vez
identificado, consultar `references/conventions.md`.

El barrido base:

1. **Estructura** — árbol hasta 3 niveles, excluyendo `node_modules`, `.venv`, `build`,
   `dist`, `target`, `.dart_tool`, `vendor`.
2. **Manifiestos** — versiones exactas de lenguaje y framework.
3. **Configuración** — `.env.example`, `application*.yml|properties`, `docker-compose*`,
   `Dockerfile`, `config/`.
4. **Punto de entrada** — dónde arranca, y seguir el flujo 2–3 saltos hacia adentro.
5. **Dominio** — modelos, entidades, tablas, migraciones, `schema.sql`.
6. **Convenciones reales** — leer 3–5 archivos representativos por capa. Detectar patrón de
   nombres, manejo de errores, DTOs vs entidades, inyección de dependencias, estilo de logs.
7. **Tests** — framework, ubicación, qué se prueba de verdad.
8. **Calidad y CI** — linters, formatters, hooks, `.github/workflows`, pipelines.
9. **Historia** — `git log --oneline -30`, `git log --pretty=format:"%s" -100`,
   `git branch -a`. Deducir convención de commits y ramas activas.
10. **Docs existentes** — README, `docs/`, ADRs. No duplicar: referenciar y anotar lo
    desactualizado.

Al leer código, priorizar archivos con muchos commits recientes (`git log --format= --name-only -50 | sort | uniq -c | sort -rn`).
Es donde vive el patrón vigente, no el legacy.

---

## Fase 2 — Checkpoint (obligatorio)

Presentar en el chat, sin escribir archivos:

- Resumen de 10 líneas: qué hace el sistema, para quién, cuál es su core.
- Stack con versiones exactas.
- 5 convenciones detectadas, cada una con `archivo:línea` de ejemplo.
- Lo que no se pudo deducir: máximo 7 preguntas concretas, priorizadas.
- Índice de archivos a crear.

**Esperar aprobación explícita.** Si el usuario responde con correcciones, incorporarlas
antes de escribir. Este checkpoint es lo que separa documentación útil de documentación
plausible pero falsa: sin él, el modelo llena huecos con lo que "debería" ser.

---

## Fase 3 — Escritura

Plantillas completas en `references/templates.md`. Resumen de destinos:

| Archivo | Propósito | Límite |
|---|---|---|
| `CLAUDE.md` | Índice de navegación. Se carga en cada sesión. | 150 líneas |
| `docs/ARCHITECTURE.md` | Flujo end-to-end, capas, límites, dependencias. | — |
| `docs/CONVENTIONS.md` | Reglas con ejemplo real correcto/incorrecto. | — |
| `docs/DOMAIN.md` | Glosario, entidades, reglas de negocio y dónde viven. | — |
| `docs/TESTING.md` | Cómo correr, nombrar, mockear. Qué espera un PR. | — |
| `CONTEXT_MEMORY.md` | Documento vivo: estado, decisiones fechadas, gotchas, deuda. | — |
| `AGENTS.md` | Puntero corto a `CLAUDE.md`. Solo si el repo lo usa. | 20 líneas |

`CLAUDE.md` corto no es estética: entra en contexto en cada sesión. Si crece a 600 líneas,
el usuario paga tokens en cada tarea por información que el 90% de ellas no necesita.

**Antes de escribir**, verificar si los archivos ya existen. Si existen, no sobrescribir:
mostrar qué cambiaría y preguntar.

---

## Formato de los documentos

- Español, directo, sin relleno.
- Nada de "es importante notar", "en resumen", ni consejos genéricos de la industria.
- Toda ruta de archivo real y verificada.
- Si una sección quedaría vacía o inventada: eliminarla y decir por qué.

## Cierre

Entregar la lista de archivos creados con su conteo de líneas y las suposiciones ⚠️
pendientes de confirmar.

Recordar al usuario que `CONTEXT_MEMORY.md` es un documento vivo: si nadie lo actualiza,
en dos meses miente.
