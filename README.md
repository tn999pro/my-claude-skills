# Mis Claude Skills

Fuente de verdad de mis skills personales de Claude Code. Los directorios en
`C:\Users\stivn\.claude\skills\` son enlaces (symlink/junction) a este repo.

## Skills

| Skill | Propósito |
|---|---|
| code-quality | Revisión de código, refactorización, seguridad, reporte por prioridad |
| spring-boot-expert | Desarrollo Java 21 / Spring Boot (Flyway, MapStruct, Security, JPA) |
| fastapi-expert | Desarrollo Python / FastAPI (Supabase, auth, IA, n8n) |
| nextjs-expert | Next.js App Router (Server Components, Supabase SSR, SEO, UI premium) |
| flutter-expert | Desarrollo Flutter (estado, HTTP, Supabase, performance) |
| supabase-expert | Plataforma Supabase (RLS, Edge Functions, Realtime, Storage, Auth) |
| n8n-expert | Workflows n8n (webhooks, HTTP, WhatsApp Business, patrones robustos) |
| git-best-practices | Ramas, Conventional Commits, PRs, Gitflow |
| project-onboarding | Entender y configurar cualquier proyecto desde cero |
| app-security | Revisión de seguridad defensiva por stack: detectar y corregir |
| product-owner | Roadmaps, backlog SCRUM, specs técnicas, ADRs |
| tech-proposals | Propuestas comerciales B2B, pricing COP/USD, Word/PDF |
| content-automation | Contenido con IA + distribución n8n (embudo WhatsApp de Vantedge) |

## Nota: ui-ux-pro-max

El skill de UI/UX **se consume como plugin de Claude Code (`ui-ux-pro-max`
v2.5.0)**, no como skill propio de este repo. El plugin es una versión más
completa (7 sub-skills, 531 líneas el principal) que la copia Gemini que vive
en `vantedge/.gemini/skills/` — no duplicar aquí para evitar drift y conflicto
de triggers.

## Convenciones

- Cada skill: `SKILL.md` con frontmatter YAML (`name`, `description` con
  triggers) + `references/` para material extenso.
- Idioma: español; identificadores y comandos en su forma original.
- Commits: Conventional Commits en inglés, sin firma de Claude.
