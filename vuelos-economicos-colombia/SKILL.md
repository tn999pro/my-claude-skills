---
name: vuelos-economicos-colombia
description: >-
  Busca y compara vuelos económicos en Colombia (rutas domésticas) y entrega los
  resultados ordenados del más barato al más caro, con precio en COP, aerolínea,
  horarios, escalas, equipaje incluido y enlace directo para comprar. Actívala
  SIEMPRE que el usuario mencione: "buscar vuelos", "tiquetes baratos", "vuelo
  económico", "cuánto cuesta volar", "pasajes a/desde [ciudad colombiana]",
  "vuelos Bogotá-Medellín" (o cualquier par de ciudades de Colombia), "vuelo más
  barato", "comparar tiquetes", o pida ayuda para encontrar el precio más bajo de
  un vuelo dentro de Colombia. Úsala incluso si el usuario solo da origen, destino
  y fecha sin decir explícitamente "skill" o "buscar".
---

# Vuelos económicos en Colombia

Encuentra el vuelo doméstico más barato dentro de Colombia. El objetivo es claro:
**entre más económico, mejor**. Siempre se entregan precios aproximados en vivo
**y** enlaces directos a fuentes confiables para que el usuario confirme y compre.

> **Alcance actual:** solo rutas dentro de Colombia (origen y destino colombianos).
> Si el usuario pide un vuelo internacional, avísale que por ahora el skill cubre
> únicamente vuelos nacionales y ofrécele igualmente los enlaces de búsqueda.

## 1. Reunir los datos de la búsqueda

Antes de buscar, confirma estos datos. Si el usuario ya los dio, no los vuelvas a
preguntar; solo pide lo que falte.

| Dato | Necesario | Default si no lo dan |
|---|---|---|
| Ciudad de **origen** | Sí | — (preguntar) |
| Ciudad de **destino** | Sí | — (preguntar) |
| **Fecha de ida** | Sí | — (preguntar) |
| Solo ida o ida y vuelta | Sí | Solo ida |
| Fecha de regreso | Si es ida y vuelta | — (preguntar) |
| N° de pasajeros | No | 1 adulto |
| Fechas flexibles (±días) | No | Asumir fecha fija, pero ofrecer revisar días cercanos |

Convierte los nombres de ciudad a **código IATA** usando
[references/aeropuertos-colombia.md](references/aeropuertos-colombia.md). Si una
ciudad tiene varios aeropuertos (p. ej. Medellín → MDE / EOH), usa el principal
(MDE) salvo que el usuario indique otro.

## 2. Traer precios aproximados en vivo

Usa **WebSearch** para obtener una idea real del precio actual. Haz búsquedas
concretas combinando ruta, fecha y fuentes confiables, por ejemplo:

- `vuelos baratos Bogotá Medellín 15 julio 2026 precio`
- `Avianca Wingo LATAM tiquetes BOG MDE julio 2026`
- `Google Flights BOG to MDE 2026-07-15 cheapest`

Cuando una búsqueda devuelva un resultado prometedor pero sin el precio claro, usa
**WebFetch** sobre la página del agregador (Google Flights / Skyscanner / Kayak) o
de la aerolínea para extraer el monto.

**Tratamiento honesto de los precios:** los precios de vuelos cambian por minuto y
varían según disponibilidad. Nunca presentes un precio en vivo como definitivo.
Etiquétalos siempre como **"aprox."** y deja claro que el precio real se confirma
en el enlace. Si no logras un precio confiable para una opción, no lo inventes:
marca esa opción como **"ver precio en el enlace"**.

## 3. Construir los enlaces directos

Para cada búsqueda, arma enlaces directos pre-rellenados (origen, destino, fecha,
moneda COP) a varias fuentes confiables. Las plantillas exactas están en
[references/aeropuertos-colombia.md](references/aeropuertos-colombia.md). Incluye
siempre, como mínimo:

1. **Un agregador** (Google Flights, Skyscanner o Kayak) — compara todas las
   aerolíneas de una.
2. **Las aerolíneas relevantes de la ruta** (las low-cost suelen ganar en precio:
   Wingo, JetSMART; ver qué aerolíneas cubren la ruta).

Estos enlaces son la fuente de verdad para que el usuario confirme y compre.

## 4. Presentar resultados — del más barato al más caro

Ordena **siempre de menor a mayor precio**. La primera opción debe ser la más
económica encontrada. Usa esta estructura:

```
## ✈️ Vuelos [ORIGEN] → [DESTINO] · [fecha] · [N pax]

### 🥇 Más económico — $[precio] COP aprox.
- **Aerolínea:** [nombre]
- **Horario:** [salida] → [llegada]  ([duración], [directo / N escalas])
- **Equipaje:** [solo de mano / incluye bodega XKg / no especificado]
- **Comprar:** [enlace directo]

### 2 — $[precio] COP aprox.
...

### 3 — $[precio] COP aprox.
...
```

Después de la lista, añade una sección breve:

```
### 🔎 Confirma y compara tú mismo
- Google Flights: [enlace]
- Skyscanner: [enlace]
- [Aerolínea low-cost de la ruta]: [enlace]

### 💡 Para pagar menos
- [1-3 tips relevantes según el caso]
```

## 5. Consejos para bajar el precio (incluir los que apliquen)

- **Fechas flexibles:** volar martes/miércoles suele ser más barato que viernes o
  domingo. Si el usuario tiene flexibilidad, revisa ±2-3 días y muéstrale si hay
  una fecha cercana más económica.
- **Equipaje:** una tarifa "básica" sin bodega puede salir más cara al final si el
  usuario necesita maleta. Compara el precio **con el equipaje que realmente
  necesita**, no solo el precio gancho.
- **Anticipación:** los vuelos domésticos suelen estar más baratos comprando con
  varias semanas de anticipación.
- **Low-cost:** Wingo y JetSMART suelen tener las tarifas base más bajas, pero
  cobran aparte casi todo; tenlo en cuenta al comparar.
- **Aeropuertos alternos:** si aplica (p. ej. Medellín MDE vs EOH), menciónalo.

## Reglas clave

- **Honestidad sobre los precios:** todo precio en vivo es **aproximado**; el
  enlace manda. Nunca afirmes un precio como garantizado.
- **Siempre enlaces:** aunque traigas precios en vivo, entrega siempre los enlaces
  directos. Es lo más confiable y lo que el usuario realmente usa para comprar.
- **No inventes vuelos ni precios.** Si no encuentras datos confiables, dilo y
  entrega los enlaces de búsqueda para que el usuario lo revise en vivo.
- **Solo Colombia (por ahora).** Origen y destino deben ser colombianos.
