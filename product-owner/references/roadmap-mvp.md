# Roadmap y MVP

## Roadmap por horizontes (no por fechas)

Para equipos de 1-2, las fechas a 6 meses son ficción. Horizontes:

```markdown
# Roadmap — <proyecto>
_Actualizado: 2026-06-10_

## 🎯 Objetivo del producto
<una frase: para quién y qué problema resuelve>

## Ahora (este sprint / estas 2 semanas)
- [ ] <item con outcome claro>

## Siguiente (1-2 meses)
- <item> — depende de: <X>

## Luego (algún día — sin compromiso)
- <todo lo demás>

## Decidido NO hacer
- <item> — por qué: <razón>   ← esta sección evita re-discutir lo mismo
```

Reglas:
- "Ahora" tiene máximo 3-5 items. Si todo es prioridad, nada lo es.
- Cada item de "Ahora" tiene criterio de éxito medible.
- Mover items de horizonte es normal; hacerlo en silencio no — anotar por qué.

## Definir el MVP — el corte más agresivo que aún sirve

1. **Enunciar el flujo crítico**: la ÚNICA secuencia que el usuario debe poder
   completar para que el producto tenga sentido.
   - Ej. retail-inventory: "fotografío un producto → queda en el inventario
     con stock → lo encuentro buscándolo".
2. **Todo lo que no está en ese flujo, fuera de la v1**: login social, reportes,
   configuraciones, edge cases de importación — fuera.
3. **Test del MVP**: ¿una persona real puede usarlo mañana para el flujo
   crítico aunque le falte todo lo demás? Si no, sigue siendo demasiado grande.

```markdown
## MVP — <producto>
**Flujo crítico:** <secuencia>
**Incluye:** <3-6 capacidades mínimas>
**Explícitamente fuera de la v1:** <lista — tan importante como la anterior>
**Criterio de éxito:** <métrica observable: "X pedidos reales procesados">
```

## Priorización — matriz impacto/esfuerzo

| | Esfuerzo bajo | Esfuerzo alto |
|---|---|---|
| **Impacto alto** | HACER YA | Planear (partir en fases) |
| **Impacto bajo** | Rellenos (huecos entre tareas) | NO HACER |

- Impacto = acerca el flujo crítico o resuelve dolor reportado por usuarios
  reales. No "estaría cool".
- Esfuerzo en camisetas (S/M/L), no en horas — la precisión falsa cuesta más
  que la imprecisión honesta.

## MoSCoW para negociar alcance con un cliente

| Categoría | Significado | Uso en la conversación |
|---|---|---|
| **Must** | Sin esto no hay entrega | El contrato mínimo |
| **Should** | Importante, no bloqueante | Entra si el tiempo alcanza |
| **Could** | Deseable | Moneda de cambio ante recortes |
| **Won't** | Fuera de esta versión, por escrito | Evita el "yo pensé que incluía..." |

Regla práctica: si más del 60% queda en Must, la clasificación falló —
volver a preguntar "¿qué pasa si la v1 sale sin esto?".

## Métricas de éxito por tipo de proyecto

| Tipo | Métrica honesta (no vanidad) |
|---|---|
| E-commerce / catálogo | Pedidos completados, tasa carrito→pedido |
| Dashboard interno | Uso semanal por los usuarios objetivo, tareas que reemplazó |
| Automatización (n8n) | Horas manuales eliminadas/semana, tasa de error vs proceso manual |
| Landing / agencia | Conversión visita→contacto calificado |
