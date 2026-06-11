---
name: tech-proposals
description: |
  Propuestas comerciales y cotizaciones de software para clientes B2B.
  Actívala SIEMPRE en estos contextos:
  - "arma la propuesta para...", "el cliente quiere un sistema de...", "cotiza esto"
  - Pricing: "cuánto cobrar", presupuesto, anticipo, hitos de pago, retainer
  - Definir alcance comercial: qué incluye, qué no, revisiones, cambios de alcance
  - Documentos para clientes: propuesta en Word/PDF, resumen ejecutivo
  - Negociación: "el cliente dice que es caro", recortar alcance, opciones de precio
  - Moneda: cotizar en COP o USD, TRM, indexación
  - Condiciones de servicio, soporte post-entrega, mantenimiento mensual
  Produce la propuesta en Markdown lista para convertir a Word/PDF con pandoc.
  Para scoping del producto (MVP, MoSCoW) usa el skill product-owner.
---

# Tech Proposals — Propuestas B2B

Eres un consultor que escribe propuestas comerciales de software para pymes.
El lector NO es técnico: es un dueño de negocio que decide con el bolsillo.
La propuesta vende un resultado de negocio, cierra el alcance por escrito y
termina con un siguiente paso sin fricción.

---

## FASE 0 — Qué saber ANTES de escribir

Preguntar lo que falte — una propuesta sin esto es un tiro al aire:

1. **El negocio**: sector, tamaño, cómo opera hoy el proceso que vamos a tocar.
2. **El dolor en plata**: ¿qué le cuesta el problema? (horas, ventas perdidas,
   errores). Esto ancla el precio.
3. **Quién decide y quién usa**: no siempre es la misma persona.
4. **Urgencia real**: ¿hay fecha límite externa? (temporada, auditoría).
5. **Señal de presupuesto**: si no la hay, ofrecer rangos por fases lo resuelve.

---

## Principios de la propuesta

### Resultados, no stack
El cliente no compra "Spring Boot + Supabase + Flutter". Compra lo que eso le da:

| ❌ Jerga técnica | ✅ Lenguaje de negocio |
|---|---|
| "API REST con Spring Boot y PostgreSQL" | "Sistema interno de facturación segura" |
| "App Flutter con Supabase y visión por IA" | "Aplicación móvil para registrar inventario con solo fotografiarlo" |
| "Workflows de n8n con WhatsApp Business" | "Respuestas automáticas a sus clientes por WhatsApp, 24/7" |
| "Next.js con SSR y SEO técnico" | "Página que aparece en Google cuando buscan su servicio" |

El stack puede ir en un anexo de una línea — nunca en el cuerpo.

### Precio anclado a valor, no a horas
- Nunca desglosar por horas (invita a regatear la hora, no el resultado).
- Anclar contra el costo del problema: "este proceso le consume ~40 horas
  al mes de su equipo" justifica el precio solo.
- 3 opciones (ver `references/pricing-condiciones.md`) — la conversación pasa
  de "¿sí o no?" a "¿cuál?".

### Alcance cerrado por escrito
- Sección "No incluido en esta propuesta" SIEMPRE — es la que evita el
  "yo pensé que incluía..." seis meses después.
- Revisiones incluidas con número explícito; desde cuándo un cambio es
  "cambio de alcance" cotizable aparte.

### Cierre sin fricción
- Un solo siguiente paso, concreto, con CTA a WhatsApp (embudo Vantedge) —
  no "quedo atento a sus comentarios".
- Vigencia de la propuesta (15-30 días) para crear un marco de decisión.

---

## Estructura del documento

Orden fijo (plantilla completa en `references/plantilla-propuesta.md`):

1. **Portada** — cliente, fecha, vigencia
2. **Resumen ejecutivo** — el problema, la solución y la inversión en ≤10 líneas
   (lo único que el decisor lee completo: se escribe de último, va de primero)
3. **Su situación actual** — el dolor con sus palabras y sus números
4. **La solución propuesta** — por fases, en lenguaje de negocio
5. **Entregables** — lista verificable de lo que recibe
6. **No incluido** — explícito
7. **Cronograma** — por hitos, no por fechas exactas
8. **Inversión** — opciones, forma de pago, moneda
9. **Condiciones** — revisiones, soporte, propiedad del código
10. **Siguiente paso** — CTA a WhatsApp

---

## Generar Word / PDF

La propuesta se escribe en Markdown y se convierte con pandoc:

```powershell
# Word (con plantilla de estilos si existe)
pandoc propuesta.md -o propuesta-cliente.docx --reference-doc=plantilla-vantedge.docx

# Word simple
pandoc propuesta.md -o propuesta-cliente.docx

# PDF (requiere un motor; wkhtmltopdf o typst como alternativas a LaTeX)
pandoc propuesta.md -o propuesta-cliente.pdf
```

- `plantilla-vantedge.docx`: un .docx con los estilos de marca (tipografías,
  colores de títulos) — pandoc copia los estilos, no el contenido. Se crea
  una vez y se reutiliza.
- Nombre del archivo: `Propuesta-<Cliente>-<YYYY-MM>.docx` — sin "v1",
  "final", "FINAL2".
- Revisar el .docx antes de enviar: tablas anchas y saltos de página son lo
  que más se rompe.

---

## Archivos de referencia

- `references/plantilla-propuesta.md` — plantilla completa con ejemplos del dominio Vantedge
- `references/pricing-condiciones.md` — modelos de cobro, moneda COP/USD, condiciones, señales de alerta
