# Backlog y SCRUM ligero (equipos de 1-2)

## Jerarquía

```
Épica          ← objetivo de negocio (semanas)
  Historia     ← valor entregable y verificable (horas a 2-3 días)
    Tarea      ← paso técnico (opcional; a menudo sobra en equipo de 1)
```

## Historia de usuario — formato

```markdown
### HU-012 — Filtrar pedidos por estado
**Como** administrador de la tienda
**Quiero** filtrar la lista de pedidos por estado
**Para** atender primero los pendientes sin buscar manualmente

**Criterios de aceptación:**
- [ ] El listado tiene un filtro con todos los estados de `EstadoPedido`
- [ ] Al filtrar, la paginación se reinicia a la página 1
- [ ] El filtro activo persiste al navegar al detalle y volver
- [ ] Sin resultados → mensaje "No hay pedidos <estado>" (no tabla vacía)

**Fuera de alcance:** filtros combinados (estado + fecha) → HU-015
**Estimación:** M
```

Reglas:
- El "Para" es obligatorio — si no se puede escribir, la historia no tiene
  valor claro y probablemente sobra.
- Criterios = comprobables por un dev o un test. Nada de "debe ser intuitivo".
- "Fuera de alcance" explícito mata el scope creep en la raíz.
- Historias técnicas (refactors, deuda) existen y son legítimas — mismo
  formato, el beneficiario es "el equipo": *Como dev, quiero migrar X, para
  reducir el tiempo de build de 8 a 2 min*.

## Definition of Done (global, no por historia)

```markdown
## DoD
- [ ] Criterios de aceptación verificados
- [ ] Tests de la lógica nueva pasan (y los existentes no se rompieron)
- [ ] Build/lint en verde (0 errores, 0 warnings)
- [ ] PR revisado (equipo de 2) o auto-revisión del diff (solo)
- [ ] Migraciones/seeds aplicables desde cero
- [ ] Documentación tocada si cambió el contrato (README, CLAUDE.md, API)
```

## Sprint ligero para 1-2 personas

- **Duración**: 1-2 semanas fijas.
- **Objetivo del sprint**: UNA frase. "Un cliente puede completar un pedido
  de punta a punta". Las historias del sprint sirven a ese objetivo.
- **Planning** (30 min): elegir historias que quepan — capacidad real
  descontando soporte, reuniones y la vida. Para 1 dev medio tiempo: 2-3
  historias M por semana, no 10.
- **Review honesta** al cierre: qué se terminó (según DoD), qué no y POR QUÉ
  — la causa alimenta el siguiente planning (¿estimación? ¿interrupciones?
  ¿alcance creció?).
- Daily de 2 personas = un mensaje en el chat: ayer/hoy/bloqueos. No reunión.

## Priorización del backlog

1. Ordenado de arriba (próximo) hacia abajo (algún día) — sin empates.
2. Solo el top ~10 se mantiene detallado; el resto puede ser una línea.
3. Re-priorizar al inicio de cada sprint, no a mitad (salvo incendio real).
4. Bug en producción que bloquea usuarios > todo lo demás. Bug cosmético =
   historia más, compite por prioridad.

## Dónde vivir

| Contexto | Herramienta |
|---|---|
| Proyecto solo | `docs/backlog.md` en el repo — cero fricción |
| Equipo de 2 con PRs | GitHub Issues + labels (`epic`, `bug`, prioridad) y milestones como sprints |
| Cliente que quiere visibilidad | GitHub Projects (board público del repo) |
