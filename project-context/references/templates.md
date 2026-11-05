# Plantillas de los documentos

Leer este archivo al entrar en la Fase 3. Cada plantilla es la estructura mínima; eliminar
secciones que quedarían vacías en lugar de rellenarlas.

---

## CLAUDE.md — máximo 150 líneas

```markdown
# <Nombre del proyecto>

<Qué hace, para quién, cuál es su core. 3 líneas.>

## Stack

<Lenguaje + versión, framework + versión, base de datos, infraestructura. Lista corta.>

## Comandos

| Acción | Comando |
|---|---|
| Levantar | `<verificado contra scripts reales>` |
| Tests | `` |
| Migrar | `` |
| Lint / format | `` |

## Mapa

| Quiero... | Voy a... |
|---|---|
| Agregar un endpoint | `<ruta real>` |
| Cambiar una regla de negocio | `<ruta real>` |
| Tocar el esquema | `<ruta real>` |

## Reglas

<5–8 reglas que si se rompen rompen el build o el patrón. Una línea cada una.>

## No tocar

<Código generado, legacy, vendor. Con ruta y motivo.>

## Detalle

- Arquitectura → `docs/ARCHITECTURE.md`
- Convenciones → `docs/CONVENTIONS.md`
- Dominio → `docs/DOMAIN.md`
- Tests → `docs/TESTING.md`
- Estado actual → `CONTEXT_MEMORY.md`
```

---

## docs/ARCHITECTURE.md

- **Flujo de una petición** — de la entrada a la respuesta, nombrando archivos reales en cada
  salto. Es la sección más valiosa; escribirla primero.
- **Capas y responsabilidades** — qué hace cada una y qué tiene prohibido hacer.
- **Límites entre módulos** — qué puede importar qué. Si hay violaciones en el código, anotarlas
  como deuda, no normalizarlas.
- **Dependencias externas** — cada una con el motivo por el que está y dónde se usa.
- **Decisiones estructurales** — solo las visibles en el código. Si no hay evidencia del porqué,
  decir "motivo no documentado" en lugar de inventarlo.

---

## docs/CONVENTIONS.md

Cada regla con ejemplo real del repositorio:

```markdown
### <Regla>

✅ `<ruta:línea>`
​```<lenguaje>
<código real del repo>
​```

❌ Antipatrón
​```<lenguaje>
<contraejemplo>
​```
```

Cubrir: nomenclatura por tipo de archivo · estructura interna de clases y módulos · manejo de
errores y excepciones · validación · logging · configuración y secretos · convención de commits
y ramas.

Si el repositorio es inconsistente en algo, decirlo: *"conviven dos patrones, X en módulos nuevos
e Y en legacy; seguir X"*. Esa información vale más que una regla limpia e inventada.

---

## docs/DOMAIN.md

- **Glosario** — términos del negocio tal como aparecen en el código, incluyendo los que están en
  inglés en el código pero en español en la conversación.
- **Entidades y relaciones** — nombre, tabla, archivo, relaciones clave.
- **Reglas de negocio** — cada una con el archivo donde vive. Si la misma regla está duplicada en
  dos lugares, anotarlo.
- **Estados y transiciones** — máquinas de estado explícitas o implícitas.

---

## docs/TESTING.md

Cómo correr · cómo se nombran · qué se mockea y qué no · fixtures y datos de prueba · qué se
espera de un PR. Si la cobertura real es baja, decirlo con el número, no lo maquilles.

---

## CONTEXT_MEMORY.md

```markdown
# Contexto vivo

> Actualizar al cerrar cualquier tarea significativa.

## Estado actual
<Qué funciona, qué está a medias, qué está roto. Con fecha.>

## En curso
<En qué se está trabajando ahora mismo.>

## Decisiones
| Fecha | Decisión | Motivo |
|---|---|---|

## Gotchas
<Cosas que sorprendieron. Cada una ahorra una hora la próxima vez.>

## Deuda conocida
<Lo que se sabe que está mal y por qué no se ha arreglado.>

## ⚠️ Suposiciones sin confirmar
<Lo que quedó pendiente de la sesión de documentación.>
```

Inicializarlo con lo aprendido en la sesión, fechado.

---

## AGENTS.md

Solo si el repositorio ya lo usa o el usuario trabaja con otras herramientas de agente. Máximo 20
líneas, apuntando a `CLAUDE.md`. Nunca duplicar contenido: dos fuentes divergen en semanas.
