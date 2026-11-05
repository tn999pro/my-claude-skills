# Aeropuertos de Colombia y plantillas de enlaces

Referencia para convertir ciudades a código IATA y para armar enlaces directos
pre-rellenados a fuentes confiables. El skill principal apunta aquí.

## 1. Códigos IATA de aeropuertos colombianos

| Ciudad | Código | Aeropuerto |
|---|---|---|
| Bogotá | **BOG** | El Dorado |
| Medellín | **MDE** | José María Córdova (Rionegro) — principal |
| Medellín (centro) | EOH | Olaya Herrera — solo regionales/turbohélice |
| Cali | **CLO** | Alfonso Bonilla Aragón |
| Cartagena | **CTG** | Rafael Núñez |
| Barranquilla | **BAQ** | Ernesto Cortissoz |
| Santa Marta | **SMR** | Simón Bolívar |
| Bucaramanga | **BGA** | Palonegro |
| Pereira | **PEI** | Matecaña |
| San Andrés | **ADZ** | Gustavo Rojas Pinilla |
| Cúcuta | **CUC** | Camilo Daza |
| Armenia | **AXM** | El Edén |
| Manizales | **MZL** | La Nubia |
| Montería | **MTR** | Los Garzones |
| Valledupar | **VUP** | Alfonso López Pumarejo |
| Riohacha | **RCH** | Almirante Padilla |
| Leticia | **LET** | Alfredo Vásquez Cobo |
| Pasto | **PSO** | Antonio Nariño |
| Neiva | **NVA** | Benito Salas |
| Ibagué | **IBE** | Perales |
| Villavicencio | **VVC** | La Vanguardia |
| Yopal | **EYP** | El Alcaraván |
| Popayán | **PPN** | Guillermo León Valencia |
| Quibdó | **UIB** | El Caraño |
| Tumaco | **TCO** | La Florida |
| Apartadó | **APO** | Antonio Roldán Betancourt |
| Sincelejo/Corozal | **CZU** | Las Brujas |
| Florencia | **FLA** | Gustavo Artunduaga |

Si la ciudad no está en la tabla, búscala con WebSearch (`código IATA aeropuerto
[ciudad] Colombia`) antes de armar los enlaces.

## 2. Plantillas de enlaces directos

Reemplaza los marcadores:
- `ORI` / `DES` = código IATA en mayúsculas (BOG, MDE…) o minúsculas según indique cada plantilla
- `YYYY-MM-DD` = fecha ISO; `YYMMDD` = fecha corta (p. ej. 15 jul 2026 → `260715`)
- `PAX` = número de pasajeros adultos

### Agregadores (comparan todas las aerolíneas)

**Google Flights** (acepta lenguaje natural en `q`):
```
https://www.google.com/travel/flights?q=Flights%20from%20ORI%20to%20DES%20on%20YYYY-MM-DD&curr=COP&hl=es
```
Ida y vuelta:
```
https://www.google.com/travel/flights?q=Flights%20from%20ORI%20to%20DES%20on%20YYYY-MM-DD%20returning%20YYYY-MM-DD&curr=COP&hl=es
```

**Skyscanner Colombia** (códigos en minúscula):
```
https://www.skyscanner.com.co/transporte/vuelos/ori/des/YYMMDD/?adults=PAX&currency=COP
```
Ida y vuelta (dos fechas):
```
https://www.skyscanner.com.co/transporte/vuelos/ori/des/YYMMDD/YYMMDD/?adults=PAX&currency=COP
```

**Kayak Colombia** (códigos en mayúscula):
```
https://www.kayak.com.co/flights/ORI-DES/YYYY-MM-DD?sort=price_a&currency=COP
```
Ida y vuelta:
```
https://www.kayak.com.co/flights/ORI-DES/YYYY-MM-DD/YYYY-MM-DD?sort=price_a&currency=COP
```

### Aerolíneas que operan en Colombia

Las páginas de las aerolíneas no aceptan deep-links de fecha/ruta confiables, así
que entrega el enlace de su buscador. Las **low-cost** (Wingo, JetSMART) suelen
tener las tarifas base más bajas.

| Aerolínea | Tipo | Enlace | Notas |
|---|---|---|---|
| Avianca | Tradicional | https://www.avianca.com/co/es/ | Mayor red doméstica |
| LATAM Colombia | Tradicional | https://www.latamairlines.com/co/es | Amplia red |
| Wingo | Low-cost | https://www.wingo.com/es | Tarifas base muy bajas; cobra extras |
| JetSMART | Low-cost | https://jetsmart.com/co/es/ | Ultra low-cost; cobra casi todo aparte |
| Satena | Regional/estatal | https://www.satena.com/ | Rutas regionales y apartadas |
| Clic | Regional | https://www.clic.com.co/ | Antes EasyFly; rutas regionales |
| EasyFly | Regional | https://www.easyfly.com.co/ | Turbohélice, ciudades intermedias |

### Agencias online

| Agencia | Enlace | Notas |
|---|---|---|
| Despegar Colombia | https://www.despegar.com.co/vuelos/ | A veces tarifas/paquetes distintos |
| Tiquetes Baratos | https://www.tiquetesbaratos.com/ | Comparador local |

## 3. Qué aerolíneas sugerir por tipo de ruta

- **Rutas troncales** (BOG, MDE, CLO, CTG, BAQ entre sí): Avianca, LATAM, Wingo,
  JetSMART. Para el precio más bajo, prioriza Wingo y JetSMART en la comparación.
- **Rutas regionales / ciudades intermedias** (PPN, IBE, NVA, EYP, UIB, etc.):
  Satena, Clic, EasyFly, además de Avianca/LATAM si operan.
- **San Andrés (ADZ) y Leticia (LET):** Avianca, LATAM, Wingo y/o Satena según
  temporada.

Si no estás seguro de qué aerolíneas cubren una ruta, verifícalo con WebSearch
(`qué aerolíneas vuelan ORI DES Colombia`) antes de listar.
