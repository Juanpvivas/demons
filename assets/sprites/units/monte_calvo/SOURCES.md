# Soldado de Monte Calvo — procedencia y uso

## 009-I1 — Corrida de salida y regreso

Los cuatro atlas nuevos se generaron y editaron con la herramienta nativa OpenAI `image_gen`, conservando la identidad y el acabado pictórico del atlas lateral de 005-I4. Las referencias animadas guían el movimiento y el apoyo opuesto de 008 guía la anatomía; no se incorpora el personaje de otra referencia. El alcance funcional/visual local está aprobado en T004; el cierre de integración y la revisión exacta se mantienen en las [tareas de 009](../../../../specs/009-carrera-soldado-colombiano/tasks.md) e Issue [#38](https://github.com/Juanpvivas/demons/issues/38). Publicación pendiente.

| Original | Dimensiones originales → importadas | Poses utilizadas |
|---|---|---|
| `soldado_carrera_machete_atlas.png` | 1774×887 → 848×424 | Cuatro de la fila superior; fila inferior sin referencias |
| `soldado_carrera_machete_opuesta_atlas.png` | 1536×1024 → 588×392 | Las cuatro figuras |
| `soldado_carrera_regreso_atlas.png` | 1774×887 → 832×416 | Cuatro de la fila superior; fila inferior sin referencias |
| `soldado_carrera_regreso_opuesta_atlas.png` | 1536×1024 → 588×392 | Las cuatro figuras |

Cada recorrido combina su hoja base A y su hoja opuesta B: **A0,A1,B2,B3,B0,B1,A2,A3** (IDs 0,1,6,7,4,5,2,3), ocho exposiciones iguales de 75 ms y ciclo de 0,60 s. Los IDs indican procedencia, no orden temporal. B3→B0 y A3→A0 enlazan alcance y apoyo de la misma pierna. La salida conserva machete en mano y fusil guardado; el regreso conserva sólo fusil bajo, reflejado hacia −X por el presentador vigente.

`soldado_lateral_frames.tres` reconstruye un lienzo lógico de 384×288 con apoyo (192,264). Las regiones y márgenes se miden por figura sobre la textura importada, sin suponer una grilla exacta; la referencia de casco queda en x225 y el suelo en y264 para estabilizar el ciclo. Se conservan escala 0,3936942, offset (0,−59,038979), altura corporal cercana a 72 unidades y pies raíz+y24. Los otros seis clips, el atlas anterior, escena, material, lógica y stats no cambian.

Los PNG son copias byte exactas de las salidas seleccionadas. Generación, ajustes de identidad/equipo y extracción de transparencia se realizaron con `image_gen`; no hubo recorte, repintado, escalado, montaje o extracción alfa por código. La importación nativa es lossless, con límite de lado 848/588/832/588, corrección de borde alfa y sin mipmaps. El filtro lineal y repetición desactivada del hijo visual se conservan. Los originales RGBA tienen transparencia real (alfa 0–254); el RGB de los píxeles alfa cero no es un fondo visible.

La hoja opuesta del machete deriva de poses anatómicas guiadas, adaptadas al colombiano y su identidad pictórica. Las hojas de regreso derivan de la misma identidad con cambio a fusil bajo; se retiró el fusil dorsal duplicado mediante edición nativa y se extrajeron los restos externos del alfa antes de seleccionar la salida. Las cuatro hojas completas se conservan para no alterar los originales seleccionados.

### Prompts finales de las salidas seleccionadas

Los prompts describen lo solicitado a la herramienta; el número de figuras realmente usado es el de la tabla anterior. No se emplean sus filas descartadas para fingir alternancia.

#### `soldado_carrera_machete_atlas.png`

> Use case: historical-scene.
> Asset type: production transparent 2D sprite atlas for Demonios de las Trincheras.
> Input image 1 is CHARACTER IDENTITY, CLOTHING, EQUIPMENT, WEAPONS AND PAINTERLY STYLE REFERENCE ONLY. Create new motion drawings of the same Colombian infantryman, matching especially the second row of Image 1. Do not reproduce the other rows.
> Primary request: exactly EIGHT distinct anatomically connected phases of a restrained running/jogging cycle toward RIGHT (+X), machete held LOW in the same near hand throughout, wooden-stock rifle slung securely on the back, small brown pack, matte olive fatigues, worn dark olive steel helmet and brown boots. Same face, body proportions, helmet silhouette, pack, straps, rifle length and machete length in every frame.
> Layout: transparent wide landscape image, exactly FOUR columns by TWO rows of eight isolated complete figures, read chronologically left-to-right top row then left-to-right bottom row. Each figure must occupy its own generous cell, full head, boots and entire weapons visible. Ample empty transparent gutters and outer margins. No overlap. All figures face right with the same slight elevated side perspective as Image 1.
> Running anatomy, fixed camera and stable body center: one continuous eight-phase cycle showing BOTH legs taking turns as the support leg. Distinguish foreground near leg from background far leg by overlap and subtly darker far cloth. TOP ROW: 1 near/foreground leg reaches FORWARD and heel makes contact while far leg trails behind; 2 same near leg supports the weight with slight knee compression while far heel lifts; 3 near foot passes UNDER the hip toward the rear as the far knee swings FORWARD, knee flexed; 4 far leg reaches FORWARD toward its imminent contact, near leg pushes off behind. BOTTOM ROW: 5 far/background leg makes FORWARD contact while near leg trails; 6 same far leg supports the weight with slight knee compression while near heel lifts; 7 far foot passes UNDER hip toward rear while near knee swings FORWARD, knee flexed; 8 near leg reaches FORWARD toward its imminent contact as far leg pushes off behind. Frame 8 must naturally close into frame1 with the SAME near leg making contact. Frame4 closes into frame5 with the SAME far leg making contact. Do NOT repeat the same leading-leg stride eight times. Do NOT use reflected duplicate poses.
> Torso leans slightly forward and remains coherent with a small natural double compression, no exaggerated bob, jump, squash/stretch or hovering. Machete and rifle stay attached coherently to the same hands/straps, machete low/non-striking, restrained shoulder/pack movement. Running in place drawings, stable ground baseline, no motion trails.
> Style: crisp readable matte hand-painted textured 2D sprite, exactly match Image1's subdued olive/brown military palette and painterly finish; legible at roughly72 pixels tall, not pixel art, not glossy3D, not cartoon redesign.
> Genuine transparent alpha in ALL empty areas. No ground, shadows, backdrop, labels, numbering, text, lines, grid, insignia, flags, blood, muzzle flashes, projectiles, extra characters or watermark. Preserve complete boots and weapons without cropping. Output only this eight-pose atlas.

#### `soldado_carrera_machete_opuesta_atlas.png`

> Use case: identity-preserve.
> Asset: normalize FOUR existing sprites to match another sheet's character identity, not a new pose sheet.
> IMAGE1 is the EDIT TARGET B, four figures2×2. IMAGE2 is the exact appearance reference A: its TOP ROW. These sheets must alternate as one eight-frame animation of ONE Colombian infantryman.
> Keep B's exact four poses and ALL lower-body anatomy unchanged: every hip/knee/ankle/boot position and silhouette, foreground thigh overlap, far-leg-forward contacts/pass/reach, ground baselines, directionRIGHT, figure placement and scale. Never replace B's far-leg-forward anatomy with A's near-leg-forward gait. Do not mirror.
> Correct ONLY B's appearance differences relative to A. Copy A's same adult face/nose/chin/eye proportions, slightly more compact facial features, plain darker olive worn helmet with restrained highlights, flatter matte painterly finish, same olive fatigues and small brown pack/belt pouches/straps/boots. B currently has extra cargo/side pouches and a more realistic, cooler gray-green fabric look; normalize to A's simpler identical equipment, warmer muted olive cloth and matching edge/brush texture. Preserve leg shapes/overlap even if their cloth shading or pocket details are normalized. Same face/helmet/clothing/equipment among all four B figures.
> Weapons: use exactly A's slung wooden rifle (same wood/metal tones, length and placement on back relative to helmet/body) and A's LOW broad curved machete (same blade curve/width/length relative to soldier height, dark handle, smooth matte steel). Keep near-hand anchor and existing arm/leg poses. Do not enlarge or shrink body to compensate; adjust weapons only as necessary to match A.
> Keep2×2 layout, complete bodies/boots/full weapons and transparent gutters. Preserve genuine alpha: empty pixels remain alpha0, soldier interiors opaque, no added halo/shadow/ground/background. No text/labels/grid/insignia/flags/blood/effects/watermark. Output the complete normalized four-pose B sheet.

#### `soldado_carrera_regreso_atlas.png`

> Use case: precise-object-edit.
> Edit target: the attached EIGHT-pose Colombian soldier atlas, four columns by two rows.
> Keep the complete atlas layout, body scale, faces, helmets, olive fatigues, packs, ALL eight exact lower-body poses, anatomical overlaps, hip/knee/ankle/boot positions and direction RIGHT unchanged. Do not swap legs or redesign the gait.
> Correct ONLY the arm/weapon integration in every figure:
> - Each soldier has exactly ONE rifle: the wooden rifle held LOW across his lower torso with muzzle angled down-right. REMOVE any second rifle or orphaned rifle barrel/stock remaining on his BACK behind the pack/head/hips. Keep the small brown backpack/straps, no long gun on back.
> - Exactly TWO ARMS and TWO HANDS per figure. The NEAR hand grips the rear trigger/stock area of the lowered rifle. The FAR forearm connects naturally from far shoulder down to ONE supporting hand wrapping the fore-end. Ensure there is no separate third free/clenched hand left above the gun in addition to the support grip below. Keep one coherent wrist and anatomically natural wraparound fingers for the far support hand.
> - The machete is stowed unobtrusively, no blade in hands. Rifle design, length, wood/metal color and low nonoffensive angle remain the same. No aiming, firing or strike.
> Preserve the same matte painterly style, clothing and body proportions, eight figure positions, complete boots and full rifles, generous transparent gutters. Genuine alpha0 empty background and opaque characters, no added shadows/aura/ground/text/grid/labels/othercontent. Change no leg anatomy or pose.

#### `soldado_carrera_regreso_opuesta_atlas.png`

> Use case: background-extraction.
> Edit target: this exact FOUR-figure transparent sprite sheet. Preserve every existing soldier and pose. Do not redraw or alter any body, arm, hand, rifle, head, helmet, boot, clothing, color or position.
> The current PNG has unwanted semi-opaque BROWN BACKGROUND PATCHES, including along the LEFT OUTER EDGE, ABOVE/BETWEEN the two TOP figures, in the CENTRAL GUTTER between figures, along the RIGHT OUTER EDGE and BELOW the figures. Remove ALL these background islands completely. Set all empty background pixels to alpha0, including brown/gray areas outside the precise soldier silhouettes, inside leg gaps, gutters and margins. Keep each soldier cut out as its own isolated fully opaque figure with clean antialiased silhouette edges only. No retained soft halo or alpha blobs.
> There must be exactly FOUR isolated soldier silhouettes in2×2, no other visible or semi-transparent components. Preserve all figures, entire lowered rifles, backpacks and boots fully visible. No repainting, color changes, body reconstruction, shadows, ground, added content, text or watermark. Return only the cleaned alpha cutout sheet.


## Antecedente de 005-I4 — Arte lateral (2026-10-20)

`soldado_lateral_atlas.png` se generó con OpenAI `image_gen`, usando el
[concepto horizontal aprobado](../../../../specs/005-cinco-carriles/references/visual-reference.md)
como referencia de estilo. Contiene 16 poses nuevas hacia +X. En esa entrega, el regreso
reflejaba cuatro pasos de fusil bajo hacia −X; 009 sustituye sólo los dos
ciclos móviles descritos arriba. El resto de estas poses permanece vigente.

| Recurso/encaje | Valor |
|---|---|
| Original RGBA → textura importada | 1411×1115 → 1024×809; ≈3,16 MiB |
| Frames | `soldado_lateral_frames.tres`; lienzo lógico 384×288, apoyo (192,264) |
| Hijo visual | Escala 0,3936942; offset (0,−59,038979); altura neutra ≈72; pies raíz+y24 |
| Poses quietas/ataques | `rifle_idle`, `rifle_shot` (0,16 s), `melee_idle`, `melee_attack` (0,24 s) |
| Desplazamiento de 005-I4 | `melee_march` y `returning`, 4 pasos/0,60 s originales, sustituidos por 009; `returning_idle`, 1 pose conservada |
| Caída | `defeat`, 4 poses/0,40 s |

Los cambios de escala/offset afectan sólo al hijo visual; el cuerpo conserva
48×48. Los frames compartidos son de solo lectura y no contienen callbacks,
daño, economía o geometría jugable. La marcha exige desplazamiento confirmado;
un regreso bloqueado conserva fusil bajo sin pasos. El snapshot guarda la
orientación actual de caída y el reset recupera la orientación autorada.

Los atlas laterales de 005-I4, aprobados funcionalmente en T055, están
integrados en `main` mediante [PR #27](https://github.com/Juanpvivas/demons/pull/27).
La publicación sigue pendiente; las [tareas de 005](../../../../specs/005-cinco-carriles/tasks.md)
mantienen el estado de entrega y PR.
Los PNG conservan los píxeles y el alfa de la salida seleccionada, sin recorte,
repintado o empaquetado por scripts. Importación lossless, límite de lado 1024,
corrección de borde alfa y sin mipmaps; filtro lineal y sin repetición locales.
Las regiones se miden por silueta en la textura importada, sin suponer grilla.
La memoria indicada es estimación RGBA8, no VRAM medida. La procedencia y las
condiciones de uso del arte generado descritas abajo siguen vigentes.

Prompt final (generación):

> Use case: historical-scene. Production transparent sprite atlas for the 2D game Demonios de las Trincheras. Input image is approved style/composition reference ONLY. Create NEW isolated Colombian infantryman sprites, exactly 4 columns by 4 rows, 16 complete figures, evenly spaced with ample transparent gutters. Same character/proportions/height throughout. Olive fatigues, worn steel helmet, brown boots and small pack, wooden-stock rifle, broad utilitarian machete. Side view with a slight elevated three-quarter perspective, ALL figures face RIGHT (+X), head and gun profile clearly facing right. Matte hand-painted textured 2D illustration, restrained military palette and diffuse daylight, crisp readable silhouette at 72 pixels tall; not glossy 3D, not pixel art. Row1 left to right: rifle ready standing and aiming horizontally right; confirmed rifle shot slight shoulder recoil no muzzle flash; machete idle rifle stowed; machete clear forward chopping strike rifle stowed. Row2: four consecutive walking steps toward right WITH MACHETE in hand and rifle stowed, alternating legs. Row3: four consecutive walking steps toward right WITH RIFLE LOWERED nonoffensive, machete stowed, barrel pointed down; these poses will be mirrored at runtime for return journey. Row4: four consecutive calm non-graphic defeat poses facing right: knees buckle, kneeling slump, collapse onto right side, fully lying still; rifle stays with character. Stable standing ground baseline within each grid cell; complete head-to-boots figures and entire weapons visible, no overlap between cells. Genuine transparent alpha in ALL empty space, no ground shadow. No scenery, trench, UI, text, labels, gridlines, blood, insignia, flags, fire, projectiles, particles, checkerboard or watermark. Do not copy HUD or characters from reference; match painterly material finish and readable side-on composition.


## Antecedente de 004 — atlas anterior

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
