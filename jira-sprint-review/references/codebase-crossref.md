# Codebase cross-reference heuristics

How to go from a Jira issue to its real footprint in the repo, and how to judge
what that footprint means. Read this during Phase 2 of the workflow.

## From a ticket's nouns to the right files

Issue descriptions name things. Those names are your search seeds:

- **Domain entities / classes** — e.g. a ticket about "ProductImageReferenceProvider"
  → grep for that identifier and its interface/base type. Found it? The component
  exists; the question becomes how complete it is. Not found? It's net-new.
- **Fields / columns** — a ticket about an identifier like `cloudinaryPublicId`
  → search for the field across entities, DTOs, migrations, and the persistence
  layer. Where it already exists vs. where the ticket says it *should* exist is
  the gap to implement.
- **Endpoints / routes** — search controllers/routers for the path or operation.
- **UI contexts / config keys** — string-literal keys (e.g. context names like
  `landing_main_media`) are very greppable and tell you which components consume
  them.

Start broad (the most distinctive identifier), then narrow. Prefer one precise
search over many vague ones.

## What counts as "already implemented"

Be strict. A match is not the same as satisfied criteria.

- **Satisfied** — the acceptance criteria can be traced to code that does what
  they require. Note the file/path as evidence.
- **Partial** — the scaffolding exists (a class, a field, a stub) but the
  behavior the criteria describe isn't there. Most "surprises" live here; call
  out exactly which criteria remain.
- **Absent** — no meaningful footprint. Net-new work.

When in doubt, treat it as partial and flag for the user rather than declaring it
done. Over-claiming "done" is worse than over-claiming "todo".

## Precursor vs. duplicate

Two issues touching the same area aren't automatically duplicates.

- **Duplicate** — same component, same goal, same acceptance criteria in
  substance. Recommend closing one as a dup or merging.
- **Precursor** — one defines/contracts something (a catalog, an interface, a
  data model) and the other consumes it. Keep both; the precursor is a
  foundation and must precede the consumer.
- **Sibling** — same component, different goals (e.g. one adds a field, another
  adds logging around it). Keep both; they may even be parallelizable.

Decide which case applies by comparing acceptance criteria against each other and
against the code, not by title similarity alone.

## Reading dependencies from the code, not the prose

The strongest dependency signal is shared code surface:

- If issue B's work can't compile/run until issue A's type/field/contract
  exists, A blocks B — regardless of what the descriptions claim.
- If two issues both modify the same method for unrelated reasons, they're a
  merge-conflict risk, not a dependency; note it so they're not scheduled blind
  against each other.
- A "transversal" issue (logging, observability, error handling over an
  architecture) usually depends on that architecture existing first, but doesn't
  block the feature issues — schedule it after the architecture lands.

## Output per issue (keep it short)

For each issue, record something like:

```
SCRUM-XX — <one-line summary>
  Footprint: <files/modules>, e.g. src/.../FooProvider.java (new), Bar.java (edit)
  State:     absent | partial (criteria N,M remain) | satisfied
  Relations: foundation for SCRUM-YY | depends on SCRUM-ZZ | overlaps SCRUM-WW (dup/precursor)
```

These blocks feed directly into the Phase 3 dependency graph.
