# Specs técnicas y ADRs

## Spec técnica — antes de implementar algo no trivial

Cuándo escribirla: la feature toca varias capas, tiene decisiones de diseño
abiertas, o la implementará otra persona (incluido tu yo de dentro de un mes).
Si es un CRUD obvio, no — el costo debe ser menor que el de equivocarse.

```markdown
# Spec — <feature>
_Estado: borrador | aprobada | implementada_
_Fecha: 2026-06-10_

## Problema
<Qué duele hoy y a quién. Sin mencionar la solución.>

## Objetivo
<Qué será posible cuando esto exista. Medible si se puede.>

## No-objetivos
<Qué NO resuelve esta spec, aunque parezca relacionado.>

## Diseño propuesto
<La solución: flujo, modelos/tablas nuevas, endpoints, componentes.
Diagramas en texto si ayudan. Lo suficiente para implementar sin
re-decidir, no una novela.>

### Cambios por capa
- BD: <migraciones>
- Backend: <endpoints/servicios>
- Frontend/App: <pantallas/componentes>

## Alternativas consideradas
<1-2 alternativas reales y por qué no. Si no hubo alternativas, decirlo.>

## Riesgos y preguntas abiertas
- <riesgo> → mitigación
- ❓ <pregunta que necesita respuesta antes/durante>

## Plan de verificación
<Cómo sabremos que funciona: tests clave, escenario de prueba manual,
métrica post-deploy.>
```

Vive en `docs/specs/<feature>.md`, se versiona, y el PR que la implementa
la enlaza.

---

## ADR — Architecture Decision Record

Cuándo: la decisión es costosa de revertir (>1 día), generó debate, o alguien
la va a cuestionar en 6 meses. Ejemplos reales: "Supabase vs backend propio
para retail-inventory", "JWT propio vs Supabase Auth", "monorepo vs repos
separados", "n8n vs código para la distribución de contenido".

```markdown
# ADR-0003 — Supabase como backend de retail-inventory
_Estado: aceptada_       ← propuesta | aceptada | reemplazada por ADR-NNNN
_Fecha: 2026-06-10_

## Contexto
<La situación que obliga a decidir: restricciones, fuerzas en tensión.
Proyecto solo-dev, sin presupuesto de infra, time-to-market corto.>

## Decisión
<En una frase activa: "Usaremos Supabase (Postgres + Auth + Storage)
como backend, sin servidor propio en la v1.">

## Consecuencias
**Positivas:**
- <qué se gana>

**Negativas (aceptadas conscientemente):**
- <qué se sacrifica — esta sección es la valiosa>

**Neutras:**
- <qué cambia en el flujo de trabajo>
```

Reglas:
- Numerados y append-only: `docs/adr/0001-titulo.md`. Una decisión revertida
  no se edita — se escribe un ADR nuevo que la reemplaza y se actualiza el
  estado del viejo.
- 15-30 líneas. Un ADR de 3 páginas no lo lee nadie.
- Las "consecuencias negativas aceptadas" son la parte más importante:
  documentan que el trade-off fue consciente, no un descuido.

## Índice de decisiones

Con 5+ ADRs, mantener `docs/adr/README.md`:

```markdown
| # | Decisión | Estado | Fecha |
|---|---|---|---|
| 0001 | Gitflow para buigo_server | aceptada | 2025-11-02 |
| 0002 | Cloudinary para imágenes | aceptada | 2025-12-10 |
| 0003 | Supabase para retail-inventory | aceptada | 2026-06-10 |
```
