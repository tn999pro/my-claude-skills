# Qué buscar por stack

**Esta referencia no detecta stacks.** Para saber *qué es* el proyecto (manifiestos, monorepo,
package manager, BaaS, CI) usar `references/stack-detection.md` de la skill `project-onboarding`,
que ya tiene esa tabla. Si esa skill no está instalada, deducirlo de los manifiestos de la raíz.

Lo que sigue es lo otro: una vez sabes qué es el proyecto, **cómo está escrito**. Son las
preguntas que hay que responder leyendo código, no listando archivos. Leer solo la sección del
stack detectado; en monorepos, varias.

---

## Java / Spring Boot

- Versión de Java y de Spring Boot desde `pom.xml` / `build.gradle`.
- Perfiles en `application-*.yml`: qué cambia entre ellos, sin copiar valores sensibles.
- **Organización de paquetes**: por capa (`controller/`, `service/`) o por feature (`orders/`).
  Revela la intención arquitectónica mejor que cualquier README.
- **A detectar**: DTOs vs entidades expuestas en los controllers · dónde se pone `@Transactional` ·
  manejo de errores (`@ControllerAdvice`, excepciones propias) · validación (`@Valid`) ·
  inyección por constructor vs `@Autowired` en campo · MapStruct u otro mapper.
- Migraciones: `db/migration` (Flyway) o `db/changelog` (Liquibase).
- Tests: `@SpringBootTest` vs `@WebMvcTest`, Mockito, Testcontainers.

## Python / FastAPI

- **A detectar**: Pydantic v1 vs v2 · separación schemas / models · cómo se inyecta la sesión de BD
  vía `Depends` · async y sync mezclados en endpoints (gotcha caro: un `def` bloqueante en un
  endpoint async congela el event loop) · `HTTPException` vs handlers propios.
- ORM: SQLAlchemy declarativo vs core, SQLModel, Tortoise.
- Tests: fixtures en `conftest.py`, `TestClient` vs `httpx.AsyncClient`.

## Flutter / Dart

- **Estado**: Provider, Riverpod, Bloc, GetX, `setState`. Anotar cuál y **si hay mezcla** — es lo
  primero que rompe a quien llega nuevo.
- **Arquitectura**: por feature o por capa. `presentation/` `domain/` `data/` sugiere clean.
- **A detectar**: navegación (`Navigator` 1.0, `go_router`, `auto_route`) · capa de red (Dio vs
  http, interceptores) · manejo de errores y `Result`/`Either` · generación de código
  (`build_runner`, freezed, json_serializable) y si hay archivos `.g.dart` commiteados.
- Tests: widget tests, golden tests, `integration_test/`.

## React / Angular / Node

- Los `scripts` de `package.json` son la fuente de los comandos reales. No inventar comandos
  que no estén ahí.
- **A detectar**: TypeScript estricto o no (`tsconfig.json` → `strict`) · estructura por feature
  vs por tipo · gestión de estado · capa de datos (fetch, axios, react-query) · estilos
  (CSS modules, Tailwind, styled-components).
- Angular: standalone components vs módulos, uso de RxJS, servicios.

## PHP

- Framework (Laravel, Symfony) y versión desde `composer.json`, o PHP plano.
- Laravel: Eloquent vs query builder · form requests para validación · dónde vive la lógica
  (controller, service, modelo).
- PHP plano: si no hay estructura, decirlo. Es información útil, no un defecto que disimular.

## PostgreSQL / Supabase

- **Lógica en la base de datos**: RLS policies, funciones, triggers. En Supabase es el gotcha más
  caro — hay reglas de negocio que no están en el código de aplicación y quien lee solo el repo
  nunca las ve. Documentarlas en `DOMAIN.md`, no solo en `ARCHITECTURE.md`.
- Migraciones en `supabase/migrations`. Edge functions en `supabase/functions`.

## Procesos fuera de la aplicación

n8n, cron, colas, workers, GitHub Actions programadas. Se olvidan al documentar porque no
aparecen al leer el código de la app, y son los que más rompen en producción. Buscarlos
explícitamente.

---

## Señal antes que estructura

Si la estructura de carpetas y el código real se contradicen, gana el código. Una carpeta
`domain/` llena de código que en realidad es de infraestructura se reporta como tal, no como
evidencia de arquitectura limpia.

Priorizar los archivos con más commits recientes:

```bash
git log --format= --name-only -50 | sort | uniq -c | sort -rn | head -20
```

Ahí vive el patrón vigente. Leer 5 archivos al azar en un repo con legacy documenta el patrón
muerto como si fuera el actual.
