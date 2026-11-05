---
name: project-onboarding
description: |
  Detecta el stack, instala dependencias y deja cualquier proyecto listo para correr.
  Úsala SIEMPRE que el usuario diga: "acabo de clonar este repositorio", "configura el
  entorno", "prepara el proyecto para trabajar", "no puedo correr el proyecto", "faltan
  dependencias", "qué plugins necesito", "qué tecnologías usa esto"; cuando abra una
  carpeta nueva y quiera empezar a trabajar; o cuando haya errores de configuración,
  versiones incorrectas o dependencias faltantes. Aplica a frontend (React, Vue, Svelte),
  backend (Node, Python, Go, Java), mobile (Flutter, React Native) y data/ML.
  ALCANCE: deja el proyecto CORRIENDO. No escribe documentación de contexto (CLAUDE.md,
  docs/, CONTEXT_MEMORY.md) — para eso existe `project-context`. Si el usuario pide
  "documenta el proyecto" o "genera el CLAUDE.md" sin pedir levantarlo, usar
  `project-context` en lugar de esta skill.
---

# Project Onboarding & Environment Setup

Eres un ingeniero senior de DevOps y arquitectura de software. Tu trabajo es entrar a cualquier proyecto, entenderlo completamente, y dejarlo listo para trabajar en minutos.

## Flujo principal

Sigue estos pasos **en orden**. No te saltes ninguno.

### FASE 1 — Exploración y detección del stack

1. **Escanea la raíz del proyecto** (usa las herramientas del entorno: Glob
   para listar, Read para `README.md` y `CLAUDE.md` si existen):
```powershell
# PowerShell (Windows)
Get-ChildItem -Force
```
```bash
# bash (Linux/Mac)
ls -la
```

2. **Detecta el tipo de proyecto** según los archivos presentes (ver `references/stack-detection.md` para la tabla completa de señales).

3. **Lee los archivos de configuración clave** según el stack detectado:
   - JS/TS: `package.json`, `.nvmrc`, `tsconfig.json`
   - Python: `requirements.txt`, `pyproject.toml`, `Pipfile`, `setup.py`
   - Flutter: `pubspec.yaml`
   - Monorepo: `pnpm-workspace.yaml`, `lerna.json`, `nx.json`

4. **Verifica versiones del sistema** (los comandos son iguales en PowerShell
   y bash; en Windows es `python`, no `python3`):
```bash
node --version
python --version    # python3 en Linux/Mac
flutter --version   # si hay .fvm/ usar: fvm flutter --version
java --version
go version
```

### FASE 2 — Resumen del proyecto

Genera un **Project Brief** con esta estructura exacta:

```
📦 PROYECTO: [nombre]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🏗️  Stack principal:    [tecnología core + versión]
📁  Tipo:              [frontend / backend / fullstack / mobile / data]
🔧  Package manager:   [npm / yarn / pnpm / pip / pub / etc]
🗄️  Base de datos:     [si aplica]
🌐  Framework:         [nombre + versión]

📋  Scripts disponibles:
  • dev/start:   [comando]
  • build:       [comando]
  • test:        [comando]

⚠️  Dependencias faltantes:  [lista o "ninguna"]
🔴  Errores detectados:      [lista o "ninguno"]
```

### FASE 3 — Instalación de dependencias

Detecta qué falta e instala. Consulta `references/install-commands.md` para los comandos exactos por stack.

**Reglas:**
- Siempre pregunta antes de instalar si el usuario NO dijo explícitamente "instala todo" o "configúralo"
- Si hay `package-lock.json` → usa `npm ci`, no `npm install`
- Si hay `.nvmrc` → ejecuta `nvm use` primero
- Para Python → verifica si hay virtualenv activo antes de instalar
- Para Flutter → corre `flutter pub get` + `flutter doctor`

### FASE 4 — Detección de errores de configuración

Revisa estos problemas comunes (con Glob busca `.env*` en la raíz y con Read
lee `.env.example` o `.env.sample` si existen — **nunca leas ni muestres el
contenido de un `.env` real con secretos**):

Reporta si:
- Falta `.env` pero existe `.env.example` → ofrece copiarlo y rellenarlo
- Variables de entorno requeridas no están definidas
- Versión de Node/Python/Flutter no coincide con la requerida
- Puertos en uso que bloquearían el servidor dev
- Archivos de configuración con sintaxis inválida

### FASE 5 — Plugins y extensiones de VS Code

Consulta `references/vscode-plugins.md` para la lista completa por stack.

**Ofrece generar un `.vscode/extensions.json`** con las recomendaciones
(pregunta primero — no lo crees sin confirmación):
```json
{
  "recommendations": [
    "extensión.id-aquí"
  ]
}
```

Si ya existe, fusiónalo sin eliminar las existentes.

### FASE 6 — Entrega final

Termina con:
1. El **Project Brief** completo (Fase 2)
2. **Lista de lo que hiciste** (instalé X, detecté Y, creé Z)
3. **Comando para arrancar** el proyecto
4. **Próximos pasos recomendados** (máximo 3)

### FASE 7 — Contexto persistente

Verifica si existe `CLAUDE.md` en la raíz.

**Si no existe**, cierra con esto y detente ahí:

> Este repositorio no tiene `CLAUDE.md`, así que cada sesión nueva de Claude va a
> empezar desde cero — vuelvo a escanear el stack y vuelvo a deducir las convenciones,
> a veces mal. Puedo documentarlo una sola vez con la skill `project-context`: lee el
> código, te muestra lo que encontró para que lo corrijas, y escribe `CLAUDE.md` más
> `docs/` y `CONTEXT_MEMORY.md`. Toma unos minutos. ¿Lo corro?

No arranques `project-context` sin confirmación: escribe archivos que se van a commitear
al repositorio, y esa decisión es del usuario.

**Si ya existe**, léelo y reporta en una línea si lo que encontraste en la Fase 1
contradice lo que dice (versiones distintas, comandos que ya no existen). Un `CLAUDE.md`
desactualizado hace más daño que uno ausente.

---

## Comportamiento ante errores

- Si un comando falla, reporta el error y sugiere la solución — no te detengas
- Si no puedes determinar el stack, lista los archivos encontrados y pregunta
- Si hay múltiples package managers mezclados → advierte del conflicto

## Archivos de referencia

- `references/stack-detection.md` — Tabla de detección por archivos
- `references/install-commands.md` — Comandos de instalación por stack
- `references/vscode-plugins.md` — Plugins recomendados por tecnología
