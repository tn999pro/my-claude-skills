---
name: listo-ecosystem
description: |
  Arquitectura y contratos de comunicación del ecosistema listo (integrador_recaudo,
  ListoMovil, trunk, app Flutter, web PHP, autoventa).
  Actívala SIEMPRE en estos contextos:
  - Trabajar en cualquier repo del ecosistema: listo_web_backend (trunk), listo_movil_back
    (ListoMovil), listo_movil_front (Flutter), listo_web_frontend (PHP), integrador_recaudo,
    integrador_autoventa
  - Tocar tramas de socket, Parser.next*, ServiciosEnum, SEPAREGISTROS, SEPACAMPOS
  - Consumir o exponer endpoints entre integrador ↔ ListoMovil ↔ trunk
  - Header Port-Mobile, routing GestionOrca, multiempresa/multitenant
  - Interpretar respuestas de trunk: payload.code, code 0, code 170
  - "¿por qué la lista viene vacía?", "¿por qué corrompió los datos sin error?"
  - Errores LIS00, NPE en socket, fsockopen, SocketListo
---

# Ecosistema listo — arquitectura y contratos

Cuatro piezas encadenadas. La regla de oro: **el orden de los campos en la trama ES
el protocolo** — romperlo corrompe datos sin lanzar excepción.

## 1. Mapa

```
integrador_autoventa (Angular)                        app móvil (Flutter, cobradores)
    │ HTTP REST                                           │ HTTP REST (urlPuente)
    ▼                                                     │
integrador_recaudo (:9092 /api/integradorrecaudo) HUB     │
    │ crea BD por empresa en listo                        │
    ↕ HTTP REST WebClient + header Port-Mobile            ▼
ListoMovil (:9598 /api/listomovil) — puente HTTP↔socket
    ↕ socket TCP (tramas)
trunk (Java 21 + Maven, motor multiempresa) — 1 proceso por empresa, 1 puerto TCP c/u
    ↕ JDBC
BD PostgreSQL del cliente (una por empresa)
```

La web PHP (`listo_web_frontend`, vía `SocketListo.php`) y la app Flutter son solo
presentación: **todo el SQL y la lógica de negocio viven en trunk**.

## 2. Repos vigentes

| Repo | Pieza | Nota |
|---|---|---|
| `listo_web_backend` | trunk | sources en `src\` plano; `build.xml`/`nbproject` = remanente Ant, no usar |
| `listo_movil_back` | ListoMovil | Spring Boot; proyecto en subcarpeta `ListoMovil` |
| `listo_movil_front` | app Flutter | proyecto en subcarpeta `listo`; Riverpod + sqflite |
| `listo_web_frontend` | web PHP | multitenant por prefijo `/clienteX` |

El monorepo viejo `listo` es referencia histórica — **no trabajar ahí**. Dentro de él,
`Servidor\Core\listo\`, `Servidor\Core\ListoWS\` y `Cliente\Movil\Android\trunk\`
son código muerto.

## 3. Contratos de comunicación

### integrador → ListoMovil (HTTP)
- `WebClient` **bloqueante**, respuesta siempre `JsonNode` (respuestas dinámicas).
- Header **`Port-Mobile` obligatorio en TODA llamada que involucre un cliente**
  (incluido login: consume el socket). Si falta → NPE genérico `LIS00`.
- Routing por empresa vía **`GestionOrca`** (tabla del integrador):
  `findByNombreByUrl(nombreBaseDatos)` → `urlBaseApi` + `puertoMovil`/`puertoWeb`.
- Auth: token Redis → si null → login → token → `Authorization: Bearer`.

### ListoMovil → trunk (socket TCP)
- Trama: `ServiciosEnum.CODIGO.getCode()` + `ConstantesEnum.SEPAREGISTROS` (`"&"`)
  / `SEPACAMPOS` (`"|"`) → `socketProvider.consumirSocket(trama)` →
  `mensajeError.esExitosa()` → parseo con `Parser` (registros, luego campos).
- trunk parsea con `Parser.nextString()/nextInt()` — los enums solo existen en
  ListoMovil, en trunk no.

### Respuestas de trunk
- **HTTP siempre 200**; el resultado va en `payload.code`.
- `0` = éxito · **`170` = sin resultados → lista vacía, NUNCA excepción**.
- Otros códigos vistos: `1343` (saldo inválido), `1530` (crédito simultáneo),
  `1533` (orden no numérico). NPE en trunk si campos opcionales van vacíos →
  enviar `"N"` (fallback `Constante.VACIO`, nunca el literal `"null"`).

## 4. Regla de protocolo — campos nuevos SIEMPRE al final

El orden de las llamadas `Parser.next*()` en trunk es el orden de la trama que arma
ListoMovil. **Insertar un campo en medio desplaza la lectura de todos los siguientes:
los datos se corrompen sin lanzar ninguna excepción.**

- Campo nuevo → al final de la secuencia `next*()` en trunk Y al final de la trama
  en ListoMovil. Ambos lados en el mismo cambio.
- Nunca reordenar campos existentes.
- Web PHP y app Flutter pegan al mismo trunk: un cambio de protocolo impacta a los dos.

## 5. Errores comunes

| Síntoma | Causa real |
|---|---|
| Lista vacía "inexplicable" | `code 170` es respuesta válida, no error |
| NPE genérico LIS00 | Falta header `Port-Mobile` |
| Datos corridos/corruptos sin excepción | Campo insertado en medio de la trama |
| `"null"` literal guardado en BD | Campo vacío sin fallback `Constante.VACIO` / `"N"` |
| Web PHP: 500 con cuerpo vacío | `SocketListo.php` pone `display_errors=off` |
| Crédito creado pero invisible en la vista | Sucursal ajena — usar la `codigo_sucursal` que devuelve `registrar-cliente` |
| PG17: `trailing junk after parameter` | SQL concatenado sin espacio (`?AND`) — todo fragmento debe terminar en espacio |

## 6. Convenciones que NO se mezclan

`integrador_recaudo` y `ListoMovil` tienen convenciones Lombok/DTO **diferentes**.
Leer el `CLAUDE.md` de cada proyecto antes de escribir código; sus convenciones
tienen prioridad sobre este skill. Puertos, credenciales y entornos de prueba son
locales por máquina — viven en las memorias de cada equipo, no aquí.
