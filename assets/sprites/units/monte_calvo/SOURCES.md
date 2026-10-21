# Soldado de Monte Calvo — procedencia y uso

## 005-I4 — Arte lateral (2026-10-20)

`soldado_lateral_atlas.png` fue generado con la herramienta nativa OpenAI `image_gen`, usando el concepto horizontal aprobado como referencia de estilo. 16 poses nuevas laterales hacia +X; el regreso usa sus cuatro pasos de fusil bajo reflejados hacia −X en runtime. Se conserva el atlas anterior como arte histórico. Original RGBA 1411×1115; importación limitada a1024 (textura prevista1024×809,≈3,16MiB RGBA8). Lienzo lógico384×288, apoyo(192,264), escala visual0,3936942 y offset(0,−59,038979): altura neutra≈72 y apoyo en raíz+y24. Son ajustes del hijo visual; el cuerpo48×48 conserva su tamaño. Regiones medidas por silueta, sin asumir una grilla regular. Clips: rifle_idle/shot, melee_idle/attack, melee_march4 pasos/0,60s, returning4 pasos/0,60s, returning_idle1 pose y defeat4/0,40s.

El PNG conserva los píxeles y el alfa originales de la salida seleccionada; no hubo recorte, repintado o empaquetado por scripts. Importación lossless, fix_alpha_border y sin mipmaps; filtro lineal/sin repetición locales. Las cifras de memoria son estimaciones, no mediciones. Recursos de frames compartidos de solo lectura; no contienen daño, economía, callbacks o geometría jugable. Procedencia y condiciones de uso propias del arte generado descritas abajo se conservan.

Prompt final (generación):

> Use case: historical-scene. Production transparent sprite atlas for the 2D game Demonios de las Trincheras. Input image is approved style/composition reference ONLY. Create NEW isolated Colombian infantryman sprites, exactly 4 columns by 4 rows, 16 complete figures, evenly spaced with ample transparent gutters. Same character/proportions/height throughout. Olive fatigues, worn steel helmet, brown boots and small pack, wooden-stock rifle, broad utilitarian machete. Side view with a slight elevated three-quarter perspective, ALL figures face RIGHT (+X), head and gun profile clearly facing right. Matte hand-painted textured 2D illustration, restrained military palette and diffuse daylight, crisp readable silhouette at 72 pixels tall; not glossy 3D, not pixel art. Row1 left to right: rifle ready standing and aiming horizontally right; confirmed rifle shot slight shoulder recoil no muzzle flash; machete idle rifle stowed; machete clear forward chopping strike rifle stowed. Row2: four consecutive walking steps toward right WITH MACHETE in hand and rifle stowed, alternating legs. Row3: four consecutive walking steps toward right WITH RIFLE LOWERED nonoffensive, machete stowed, barrel pointed down; these poses will be mirrored at runtime for return journey. Row4: four consecutive calm non-graphic defeat poses facing right: knees buckle, kneeling slump, collapse onto right side, fully lying still; rifle stays with character. Stable standing ground baseline within each grid cell; complete head-to-boots figures and entire weapons visible, no overlap between cells. Genuine transparent alpha in ALL empty space, no ground shadow. No scenery, trench, UI, text, labels, gridlines, blood, insignia, flags, fire, projectiles, particles, checkerboard or watermark. Do not copy HUD or characters from reference; match painterly material finish and readable side-on composition.



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
del hijo visual, tras la corrección I1 de 004 aprobada funcionalmente en T036,
es (0.34615385, 0.34615385), con offset (0, -34.666667), apoyo en y=24 respecto
de la raíz y altura opaca neutra aproximada de 72 unidades. La raíz y física
de 48×48 no cambian. Este ajuste de escala y offset no modifica el PNG,
sus recortes ni el lienzo lógico.
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
se componen sobre la imagen viva mediante el presentador separado.

## Material de legibilidad — corrección I1 de 004

`soldado_readability.gdshader` y `soldado_readability.tres` son código y
configuración originales creados por el agente `dev-godot` en Codex para el
proyecto en T034, 2026-10-16. No incorporan un shader de terceros ni generan
otra imagen. El material compartido
de solo lectura aclara moderadamente los tonos medios y aplica un borde mate
oscuro interior a la silueta. Conserva el alfa original, sin ampliar la figura
ni crear halo; las muestras vecinas se limitan a la región del atlas. El tinte
por instancia sigue afectando a la imagen para comunicar daño y moral sin
mutar parámetros compartidos. El snapshot neutro conserva este estilo para
la caída y el efecto limpia la referencia entre usos. Las condiciones del
arte generado que siguen se refieren al PNG original, sin añadir una licencia
de terceros al material.

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
