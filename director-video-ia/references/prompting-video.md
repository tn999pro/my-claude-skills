# Prompts de video por etiquetas

Un prompt corto deja huecos y el modelo los llena a su criterio (cámara rara, acción plana, ambiente equivocado). Un prompt ordenado en bloques le habla de una cosa a la vez y reduce la improvisación.

## Las etiquetas
| Etiqueta | Qué describe | Errores comunes |
|---|---|---|
| `CHARACTER` | Quién está, cómo se ve, cómo se mueve, estado emocional (emocionado, tranquilo, asustado; camina despacio, corre) | Solo el nombre, sin comportamiento |
| `ENVIRONMENT` | Lugar, hora del día, luz, clima, sensación | Tratarlo como decorado |
| `STORYLINE` | Acción concreta y su progresión (corre → salta al borde → golpe) | Una acción vaga ("corre") |
| `AESTHETIC` | Look (cinematográfico, natural, saturado o no), paleta hex, lente, movimiento y velocidad de cámara | Olvidar la cámara |
| `ACTION SEQUENCE` | Solo modelos multishot: planos en orden dentro de una generación | Usarlo en modelos de un solo plano |
| `NEGATIVE` | Lo que no debe aparecer | No ponerlo y que salga texto o manos deformes |

Si hay first frame o fichas de referencia, `CHARACTER` y `ENVIRONMENT` pueden ser más cortos (la imagen ya los define) y el peso pasa a `STORYLINE` y `AESTHETIC`. Si el storyboard ya está en la imagen de referencia, basta un prompt breve que pida seguir los paneles y mantener consistencia con las fichas.

## Plantilla en texto
```
[CHARACTER]
…
[ENVIRONMENT]
…
[STORYLINE]
…
[AESTHETIC]
… Cámara: … Paleta: #…, #…
[NEGATIVE]
no text, no watermark, no logos, no subtitles, [no people / no hands si es solo producto], no music
```

## Plantilla en JSON (modelos que aprovechan prompts estructurados)
```json
{
  "character": "…",
  "environment": "…",
  "storyline": "…",
  "aesthetic": {"look": "…", "palette": ["#…", "#…"], "camera": "…", "lens": "…"},
  "action_sequence": [
    {"shot": "plano general", "action": "…"},
    {"shot": "primer plano", "action": "…"}
  ],
  "audio": {"dialogue": "…", "sfx": "…", "music": false},
  "negative": ["text", "watermark", "logos"]
}
```

## Ejemplo — producto (ferretería, imagen→video)
```
[STORYLINE] El taladro inalámbrico reposa sobre el banco; la luz se intensifica sobre el mandril mientras partículas de aserrín flotan en el haz. El mandril gira dos vueltas y se detiene.
[AESTHETIC] Comercial cinematográfico, contraste alto, colores sobrios. Dolly in lento desde plano medio a detalle del mandril, 5 s. Luz lateral dura de ventana, tarde. Paleta #1C1C1C, #E8A33D, #C9C2B6.
[NEGATIVE] no text, no logos, no watermark, no hands, no people, no music
```

## Ejemplo — UGC con diálogo (imagen→video)
```
[CHARACTER] La mujer de la imagen, emocionada pero natural, habla a la cámara del celular que sostiene con el brazo derecho, gesticula con la mano libre.
[ENVIRONMENT] Su sala, tarde, luz de ventana.
[STORYLINE] Dice en español colombiano, con energía: "Les juro que no sabía que esto existía. Mírenlo." y gira levemente el teléfono hacia el producto en la mesa.
[AESTHETIC] Video vertical grabado con celular, leve movimiento de mano, sin look de estudio.
[NEGATIVE] no text, no subtitles, no logos, no music, no distorted hands
```

## Productos con texto: patrones de primer y último cuadro
Cuando el modelo admite primer y último cuadro (p. ej. Veo en Flow, "Fotogramas"), úsalos para que el producto no tenga que ser reinventado. Probado con Veo 3.1 Fast: si las imágenes de entrada tenían la etiqueta correcta, el video la conservó.

**Transición de luz** (revelación): primer cuadro = versión oscura de la imagen madre; último cuadro = imagen madre iluminada.
```
La luz cálida de un farol entra lentamente desde la izquierda y recorre el frasco hasta iluminar por completo la etiqueta. El frasco y su etiqueta permanecen inmóviles y sin cambios. Cámara fija. Partículas de polvo en el haz de luz. Comercial de lujo, contraste alto.
NEGATIVE: no text changes, no camera rotation, no new objects, no music
```

**Producto inmóvil** (plano héroe): la misma imagen como primer **y** último cuadro.
```
Humo denso sube lentamente desde la base y envuelve el frasco sin cubrir la etiqueta. Un destello suave recorre el vidrio. El frasco y su etiqueta permanecen inmóviles y sin cambios. Cámara fija con un leve dolly in.
```

Reglas:
- Escribe siempre "el producto y su etiqueta permanecen inmóviles y sin cambios".
- El movimiento lo dan la luz, el humo, las partículas y el foco. Evita órbitas, giros del producto o paneos amplios: cada ángulo nuevo obliga a inventar la etiqueta.
- Si una toma sin cuadros sale casi estática, pide el movimiento de forma explícita y medible ("dolly in lento de plano medio a detalle", "la llama crece").

## Parámetros por toma
- Relación de aspecto: 9:16 (Reels/TikTok) o 16:9.
- Duración: 3–6 s para comerciales cortos; el límite real depende del modelo.
- Resolución: 720p para pruebas; 1080p/4K solo en la versión aprobada (el costo en créditos puede triplicarse).
- Audio: actívalo solo si la toma lleva voz/SFX del modelo; si la música va en post, pide `no music`.

## Cómo iterar el prompt
Cambia una variable a la vez y di exactamente qué falló ("salta en vez de correr", "el rostro queda muy lejos") en lugar de reescribir todo.
