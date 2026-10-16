# Soldado de Monte Calvo — procedencia y uso

Creado el 2026-10-16 para T004 de `004-personajes-municion-monte-calvo`
mediante la herramienta nativa `image_gen` de Codex. La referencia de estilo es
`specs/002-monte-calvo-terreno-trincheras/references/monte-calvo-concept.png`,
aportada por el proyecto. No se extrajeron sus personajes, interfaz o terreno.
El recurso representa al soldado colombiano base; no requiere modelo histórico
exacto de arma ni añade insignias o nacionalidades nuevas.

## Archivos y transformaciones

`soldado_atlas.png` conserva sin edición de píxeles la segunda salida RGBA
original de la herramienta, de **1774 × 887**. Se solicitaron 1024 × 512,
pero tanto la generación como la edición dirigida devolvieron dimensiones
mayores. El original se conserva; la importación nativa limita el lado mayor
a **1024**, con textura de producción de **1024 × 512** (2 MiB RGBA8,
sin mipmaps; estimación, no memoria medida). Las regiones de los fotogramas
se expresan en las coordenadas de esa textura de producción.

La importación es lossless, con corrección del borde alfa y sin mipmaps.
El consumidor debe mantener filtro lineal y repetición desactivada en el hijo
visual. El original tiene alfa real de 0 a 255 y ocho figuras aisladas;
se conserva toda su transparencia sin extracción por scripts.

`soldado_frames.tres` contiene ocho `AtlasTexture` con recorte de filtro.
Sus regiones corresponden a la textura importada de 1024 × 512, no a una
grilla supuesta del original. Los márgenes reconstruyen un lienzo lógico
común de 384 × 256; el punto de apoyo está en (192, 232). La escala
del hijo visual es (0.23076923, 0.23076923), con apoyo en y=24 respecto de la
raíz y altura neutral aproximada de 48 unidades. La raíz y física no cambian.
Los cuatro fotogramas de derrota conservan ese apoyo con la caída intencional.

| Presentación | Fotogramas | Duración |
|---|---:|---:|
| `rifle_idle` | 1 | Continua |
| `rifle_shot` | 1 | 0,16 s |
| `melee_idle` | 1 | Continua |
| `melee_attack` | 1 | 0,24 s |
| `defeat` | 4 | 0,40 s |

Los clips solo contienen texturas: no hay pistas, callbacks de gameplay,
proyectiles, audio, terreno o interfaz incrustados. Los impactos y la moral
se compondrán sobre la imagen viva mediante el presentador separado.

## Condiciones de uso

Arte generado específicamente para este proyecto a petición de su titular;
sin fotografías, paquetes de arte o archivos de terceros incorporados.
Su uso en el juego y derivados queda sujeto a los términos de generación
de imágenes de OpenAI aplicables a la cuenta que lo produjo. No se añade una
licencia de terceros ni se atribuye exclusividad o una licencia inexistente.
Crédito de procedencia: «Arte del soldado generado con OpenAI image_gen,
dirección artística del proyecto Demonios de las Trincheras». No se ha
identificado una atribución externa adicional en los materiales utilizados.

## Prompts finales

Generación, con el concepto únicamente como referencia de estilo:

> Production transparent sprite atlas, exactly 1024 by 512 pixels, four
> columns and two rows, eight isolated poses of one Colombian infantryman.
> Muted olive fatigues, worn steel helmet, small brown backpack and boots;
> elevated three-quarter back view facing up toward the threat. Matte
> hand-painted 2D brush texture, diffuse daylight, readable at 48 × 48.
> Top row: rifle idle, aimed rifle shot with shoulder recoil, machete idle
> with rifle stowed, clear machete chopping pose. Bottom row: knees buckle,
> lower to one knee, collapse onto side, lie still. Stable scale and support,
> fully visible distinct weapons, transparent margins. No blood, insignia,
> text, labels, grid, HUD, terrain, other characters, projectiles, muzzle
> flash, shadow, checkerboard or watermark. Genuine transparent alpha.

Edición dirigida de la primera salida, conservando el diseño:

> Resample the complete eight-pose atlas to exactly 1024 × 512. Preserve
> every silhouette and weapon, olive matte painterly style, four-by-two
> layout and transparent alpha. Change only resolution; do not redraw,
> crop, rearrange, add or remove anything. No background or text.

La herramienta repintó sutilmente la edición y conservó dimensiones mayores;
esta segunda salida es el original de producción, sin retoque posterior.
