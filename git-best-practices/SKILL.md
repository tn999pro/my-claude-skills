---
name: git-best-practices
description: |
  Buenas prácticas de Git y GitHub para todos los proyectos.
  Actívala SIEMPRE en estos contextos:
  - Crear o nombrar ramas (feature, fix, hotfix, release, refactor, chore)
  - Escribir o revisar mensajes de commit (Conventional Commits)
  - Abrir, revisar o mergear pull requests (squash, merge, rebase, gh CLI)
  - Resolver conflictos de merge o rebase
  - Sincronizar ramas con main/develop, limpiar ramas tras el merge
  - Proyectos con Gitflow (develop/main, ramas release y hotfix)
  - Cualquier comando git: checkout, commit, merge, rebase, push, branch
  Si el CLAUDE.md del proyecto define convenciones propias de ramas o
  commits, esas tienen PRIORIDAD sobre este skill.
---

# Git Best Practices

Buenas prácticas de Git para el flujo completo de desarrollo. Aplica a todos
los proyectos; las convenciones del CLAUDE.md de cada proyecto tienen prioridad.

---

## Nomenclatura de ramas

### Formato
```
<tipo>/<descripcion-corta>
```

| Tipo | Cuándo usarlo |
|------|---------------|
| `feature/` | Nueva funcionalidad |
| `fix/` | Corrección de bug |
| `hotfix/` | Corrección urgente en producción |
| `release/` | Preparación de release (solo Gitflow) |
| `refactor/` | Reestructuración sin cambio de comportamiento |
| `chore/` | Mantenimiento, dependencias, configuración |
| `docs/` | Solo documentación |
| `test/` | Agregar o corregir tests |

### Reglas
- **kebab-case** (minúsculas, guiones), sin caracteres especiales salvo `-` y `/`
- Descriptiva pero concisa (3-5 palabras máximo)

```
feature/user-authentication
fix/null-pointer-login
hotfix/payment-gateway-timeout
release/1.4.0
```

---

## Mensajes de commit (Conventional Commits)

### Formato
```
<tipo>(<scope>): <descripción corta>

[cuerpo opcional]

[footer opcional]
```

| Tipo | Cuándo |
|------|--------|
| `feat` | Nueva funcionalidad |
| `fix` | Corrección de bug |
| `refactor` | Refactorización |
| `chore` | Mantenimiento, deps |
| `docs` | Documentación |
| `test` | Tests |
| `style` | Formato, sin cambio de lógica |
| `perf` | Mejora de rendimiento |
| `ci` | Cambios de CI/CD |
| `revert` | Revierte un commit previo |

### Reglas
- Asunto en **inglés**, máximo **72 caracteres**, **modo imperativo** ("add", no "added"), sin punto final
- Scope opcional pero recomendado
- El cuerpo explica **qué y por qué**, no cómo
- Un cambio lógico por commit

```
✅ feat(auth): add JWT refresh token endpoint
✅ fix(catalog): resolve null price on out-of-stock items
✅ chore(deps): upgrade Spring Boot to 3.4.2

❌ fix bug   ❌ changes   ❌ WIP   ❌ updated stuff
```

---

## Elegir el flujo: trunk-based vs Gitflow

| Señal | Flujo |
|---|---|
| Proyecto personal, deploy continuo, una sola rama estable | **Trunk-based**: `feature/* → main` |
| Equipo, releases versionados, rama `develop` existe en el remoto | **Gitflow**: `feature/* → develop`, `release/* → main`, `hotfix/* → main + develop` |

Verifica primero: `git branch -r` — si existe `origin/develop`, el proyecto usa Gitflow.

---

## Flujo trunk-based (estándar)

```bash
# Partir siempre del main actualizado
git checkout main && git pull origin main
git checkout -b feature/mi-nueva-funcionalidad

# Durante el desarrollo: commits pequeños y lógicos
git status
git add src/archivo/especifico.java   # evitar git add .
git commit -m "feat(module): add specific behavior"

# Mantener la rama al día
git fetch origin && git rebase origin/main

# Al terminar: push y PR
git push -u origin feature/mi-nueva-funcionalidad
```

---

## Flujo Gitflow

```bash
# FEATURE — sale de develop y vuelve a develop
git checkout develop && git pull origin develop
git checkout -b feature/mi-funcionalidad
# ... desarrollo, commits, push ...
# PR: feature/mi-funcionalidad → develop

# RELEASE — congela develop para estabilizar
git checkout develop && git pull origin develop
git checkout -b release/1.4.0
# solo fixes y ajustes de versión; PR: release/1.4.0 → main
# tras el merge a main: taggear y mergear main de vuelta a develop
git tag v1.4.0 && git push origin v1.4.0

# HOTFIX — sale de main (no de develop)
git checkout main && git pull origin main
git checkout -b hotfix/descripcion-del-bug
git commit -m "fix(module): fix critical issue"
# PR: hotfix → main; tras el merge, llevar el fix también a develop:
git checkout develop && git pull origin develop
git merge main && git push origin develop
```

**Regla de oro Gitflow:** todo lo que llega a `main` debe terminar también en
`develop` (vía merge de vuelta), o el próximo release revierte el hotfix.

---

## Pull Requests

- Título con formato Conventional Commits: `feat(auth): add JWT refresh token endpoint`
- Descripción: **qué** cambió y **por qué**, cómo probarlo, screenshots si hay UI, referencia al ticket/issue
- Nunca mergear a `main` o `develop` sin revisión

### Con gh CLI
```bash
gh pr create --base develop --title "feat(auth): add refresh token" --body "..."
gh pr view 42 --comments      # ver un PR
gh pr diff 42                 # ver el diff
gh pr merge 42 --squash --delete-branch
```

### Estrategia de merge
- **Squash and merge** para features (historial de main limpio) — preferido
- **Merge commit** solo cuando importa preservar el historial completo (ramas release largas)
- **Rebase and merge** solo con commits ya limpios y atómicos

### Después del merge
```bash
git branch -d feature/mi-funcionalidad
git push origin --delete feature/mi-funcionalidad   # si gh no la borró
git checkout main && git pull origin main
```

---

## Resolución de conflictos

```bash
git status                        # ver archivos en conflicto
# resolver manualmente cada archivo
git add src/archivo/resuelto.java
git rebase --continue             # o: git merge --continue
# si algo sale mal: abortar y empezar de nuevo
git rebase --abort                # o: git merge --abort
```

**Reglas:**
- Nunca aceptar "ours"/"theirs" a ciegas — entender ambos cambios
- Correr los tests después de resolver, antes de commitear
- Ante dudas, preguntar al autor del código en conflicto

---

## Comandos interactivos — limitaciones

`git rebase -i` y `git add -i` abren un editor interactivo y **no funcionan
en agentes ni CI**. Alternativas no interactivas:

```bash
git rebase origin/main                  # sincronizar sin reordenar commits
git commit --amend -m "nuevo mensaje"   # corregir el último commit (solo local)
# para aplastar commits: usar "Squash and merge" en el PR
```

---

## Reglas generales

- **Nunca** force push a `main` o `develop`
- **Nunca** commitear secretos, API keys, contraseñas ni archivos `.env`
- Mantener `.gitignore` actualizado antes del primer commit
- Ramas de vida corta (días, no semanas); si se alarga, rebase frecuente con la base
- Un cambio lógico por commit; revisar el propio diff antes del PR (`git diff origin/main`)
