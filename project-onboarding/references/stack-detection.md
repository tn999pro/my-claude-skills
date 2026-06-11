# Detección de Stack por Archivos

## Señales primarias (archivo → stack)

| Archivo encontrado | Stack detectado |
|---|---|
| `package.json` + `next.config.*` | Next.js |
| `package.json` + `vite.config.*` + React imports | React + Vite |
| `package.json` + `vite.config.*` + Vue imports | Vue 3 + Vite |
| `package.json` + `nuxt.config.*` | Nuxt.js |
| `package.json` + `svelte.config.*` | SvelteKit |
| `package.json` + `angular.json` | Angular |
| `package.json` + `remix.config.*` | Remix |
| `package.json` + `astro.config.*` | Astro |
| `package.json` (solo, sin framework) | Node.js puro |
| `requirements.txt` / `pyproject.toml` + `manage.py` | Django |
| `requirements.txt` + `app.py` / `main.py` + flask | Flask |
| `requirements.txt` + `main.py` + fastapi | FastAPI |
| `pubspec.yaml` | Flutter |
| `pubspec.yaml` + `.fvm/fvm_config.json` | Flutter con FVM (usar `fvm flutter`, nunca `flutter` directo) |
| `go.mod` | Go |
| `pom.xml` + dep `spring-boot-starter` | Spring Boot (Maven) |
| `pom.xml` | Java / Maven |
| `build.gradle` | Java / Gradle / Kotlin |
| `Cargo.toml` | Rust |
| `*.ipynb` / `notebooks/` | Jupyter / Data Science |
| `pyproject.toml` + poetry | Python + Poetry |
| `Pipfile` | Python + Pipenv |

## Señales de monorepo

| Archivo | Tipo de monorepo |
|---|---|
| `pnpm-workspace.yaml` | pnpm workspaces |
| `lerna.json` | Lerna |
| `nx.json` | Nx |
| `turbo.json` | Turborepo |
| `packages/` + `apps/` dirs | Monorepo genérico |

## Señales de BaaS y automatización

| Archivo / dependencia | Servicio |
|---|---|
| `supabase/config.toml` o carpeta `supabase/` | Supabase (CLI local, migraciones, edge functions) |
| `@supabase/supabase-js` o `@supabase/ssr` en deps | Supabase en JS/Next.js |
| `supabase_flutter` en pubspec.yaml | Supabase en Flutter |
| `supabase` en requirements.txt | Supabase en Python |
| `docker-compose.yml` con imagen `n8nio/n8n` | n8n (automatización) |
| Carpeta de workflows `.json` exportados de n8n | n8n (workflows versionados) |

## Señales de base de datos

| Archivo / dependencia | BD |
|---|---|
| `prisma/schema.prisma` | Prisma ORM |
| `drizzle.config.*` | Drizzle ORM |
| `typeorm` en deps | TypeORM |
| `mongoose` en deps | MongoDB |
| `sequelize` en deps | Sequelize (SQL) |
| `alembic/` dir | SQLAlchemy + Alembic |
| `migrations/` dir | BD con migraciones |
| `docker-compose.yml` con postgres/mysql/mongo | BD en Docker |

## Señales de testing

| Archivo / dependencia | Framework de test |
|---|---|
| `jest.config.*` | Jest |
| `vitest.config.*` | Vitest |
| `cypress/` | Cypress (E2E) |
| `playwright.config.*` | Playwright (E2E) |
| `pytest` en deps | Pytest |

## Señales de deployment / CI

| Archivo | Plataforma |
|---|---|
| `vercel.json` / `.vercel/` | Vercel |
| `netlify.toml` | Netlify |
| `railway.json` | Railway |
| `fly.toml` | Fly.io |
| `Dockerfile` | Docker |
| `docker-compose.yml` | Docker Compose |
| `.github/workflows/` | GitHub Actions |
| `cloudbuild.yaml` | Google Cloud Build |

## Detección de package manager (JS)

```
package-lock.json   → npm
yarn.lock           → Yarn
pnpm-lock.yaml      → pnpm
bun.lockb           → Bun
```

Si hay varios lock files → advertir conflicto, preguntar cuál usar.
