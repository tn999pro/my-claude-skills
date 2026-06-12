# CLAUDE.md — Global (Brando)

> Archivo global y **portable**. Vive en `~/.claude/CLAUDE.md` y se versiona en el repo `my-claude-skills`.
> **No incluir rutas absolutas de máquina** (usar `~/` o `%USERPROFILE%`) para que sincronice igual en cualquier equipo.

## Quién soy
Brando — desarrollador full-stack en Cali, Colombia.

## Idioma
Responde **siempre en español**.

## Stack
- **Backend:** Java 21 / Spring Boot 3.4 · Java 8 (sistemas legacy) · Python / FastAPI · PHP
- **Frontend:** Angular · React · Next.js · Flutter
- **Datos:** PostgreSQL · Supabase · MongoDB
- **Infra:** Docker · n8n

## Reglas universales de trabajo
- **Git:** nunca ejecutar `git add` / `commit` / `push` sin que yo lo pida explícitamente.
- **Antes de escribir archivos**, muéstrame el cambio o el contenido primero — salvo que diga "hazlo directo".
- **Acciones destructivas** (borrar, sobrescribir, mover): confirmar antes de ejecutar.
- No inventar. Si falta contexto, decir "por confirmar" en vez de asumir.
- **Git multi-cuenta:** trabajo con múltiples cuentas según el contexto de cada máquina.
- Verificar siempre la cuenta activa antes de commitear. Los proyectos y cuentas
- específicos viven en el `CONTEXT_MEMORY.md` de cada máquina.

## Estilo de código (preferencias transversales)
- **Naming:** `verbo + sustantivo` sin preposiciones intermedias (en, de, para, por, a, con).
  Ej.: `actualizarClienteListo`, no `actualizarEnListoCliente`.
- **Código nuevo al final:** métodos nuevos al final de la clase; variables/campos nuevos al final de su grupo o bloque, nunca intercalados en medio.
- Las convenciones detalladas por lenguaje/proyecto viven en el `CLAUDE.md` de **cada proyecto**, no aquí.

## Skills
- Los skills globales viven en `~/.claude/skills/` (symlinks al repo `my-claude-skills`).
- Úsalos cuando apliquen, sin pedir permiso.

## Estado del ecosistema
- Al iniciar una sesión, **lee `~/.claude/CONTEXT_MEMORY.md`** para el estado actual de mis proyectos y cómo se comunican entre sí.
  (Si tu versión de Claude Code soporta imports, equivale a `@CONTEXT_MEMORY.md`.)
