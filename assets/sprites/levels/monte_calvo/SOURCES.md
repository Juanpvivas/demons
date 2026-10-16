# Monte Calvo — procedencia del arte

Producción T005, 2026-10-15, herramienta nativa `image_gen` de Codex. Referencia
de estilo: `specs/002-monte-calvo-terreno-trincheras/references/monte-calvo-concept.png`.
No se extrajeron personajes o interfaz del concepto. No hubo edición de píxeles
por scripts ni uso de una API/CLI alternativa.

| Recurso | Dimensiones reales | Formato | Estimación RGBA8 sin mipmaps |
|---|---|---|---|
| `terreno.png` | 1254 × 1254 | RGB opaco | 5.999 MiB |
| `montanas.png` | 1536 × 1024 | RGBA | 6 MiB |
| `trincheras_atlas.png` | 1536 × 1024 | RGBA | 6 MiB |

Se pidió terreno de 1024 × 1024; el generador devolvió 1254 × 1254. Se conserva
el original producido, dentro del presupuesto de hasta 2048 por lado. El costo
anterior es una estimación conservadora de ancho × alto × 4, no VRAM medida.
La revisión de continuidad T005 detectó juntas al repetir 2 × 2; QA aprobó
la hoja solo para uso único **sin repetición**, con la decisión autorizada
por el orquestador. No se acredita tileabilidad. La composición T006 usa un
solo sprite opaco de 1920 × 1080 de mundo, filtro lineal local y repetición
desactivada. El margen cubre el rectángulo PC 1152 × 648 y la extensión
panorámica Android inferida de 1440 × 648 sin modificar coordenadas de juego.
La lectura e interacción de la composición siguen sujetas al tester/QA.

El panorama tiene alfa real 0..254. Aproximadamente el 68.62 % de sus píxeles
son completamente transparentes. La caja inclusiva con alfa ≥ 4 es
`x=0..1535, y=352..714`; el alfa residual 1..3 alcanza `y=19..1013`.
T006 usa región `Rect2(0,320,1536,424)`, margen de al menos 32 px respecto
a la región útil, escala `(1.25,0.37735849)` para un área de 1920 × 160 de
mundo. El panorama continúa sobre el margen de arte, sin repetirlo. Un
`Sprite2D` con `GradientTexture2D` vertical nativo, detrás del panorama,
aporta cielo azul grisáceo que se desvanece a transparente en 192 unidades;
así no aparece tierra sobre los picos. No incluye script, shader, input,
física, cámara, parallax o animación. La raíz conserva identidad y z=-10;
todos los elementos quedan en z efectivo -10 a -7, por debajo de actores.

## Atlas de trincheras — producción anticipada T010

T010 se produjo como WIP autorizado por el orquestador después de congelar
las capturas US1, mientras se completan las verificaciones T008/T009. Esta
anticipación no marca esas tareas globales como aprobadas. Después de la
aprobación del recurso aislado T010 por tester/QA, el orquestador autorizó
la composición estática T011 como WIP para revisión completa.

El PNG tiene alfa real 0..254 y aproximadamente 58.24 % de píxeles
completamente transparentes. Las seis piezas están separadas, pero el
generador no respetó celdas exactas de 512 × 512 ni sus márgenes propuestos:
se registran regiones variables en coordenadas del PNG para conservar piezas
completas. Las cajas de alfa ≥ 4 son inclusivas; las regiones usan x,y,w,h.

| Pieza | Región propuesta | Caja útil alfa ≥ 4 |
|---|---|---|
| Frente de madera y tierra | `(0,168,544,336)` | `(6,194)..(537,485)` |
| Sacos | `(540,256,520,240)` | `(544,274)..(1049,467)` |
| Esquina excavada | `(1056,112,480,424)` | `(1062,129)..(1535,515)` |
| Unión de madera y sacos | `(0,616,520,336)` | `(10,640)..(507,909)` |
| Rocas y hierba A | `(520,608,512,352)` | `(531,631)..(1007,922)` |
| Rocas y hierba B | `(1040,680,496,280)` | `(1063,710)..(1513,927)` |

Hay residuos alfa 1..3 en amplias zonas transparentes; la caja alfa > 0
no representa por sí sola el límite visible de cada objeto. El máximo del
componente continuo de la esquina a alfa ≥ 16 es x=1527, dejando margen
al final del lienzo; la región propuesta conserva también su alfa tenue.
Usar recorte de filtro en cada región y revisar a escala real sobre el
terreno; estas medidas no acreditan por sí solas ausencia de halos.

El uso previsto es una posición amplia cerca de y=580..650, con segmentos
compartidos detrás de actores. No dibujar cinco puestos o filas de carril.
Las rocas/hierba enmarcan el suelo fuera del eje tranquilo, sin representar
límites de colocación.

## Composición T011

Las seis regiones anteriores son los seis `AtlasTexture` finales de la
escena. Comparten el PNG y mantienen `filter_clip=true`, filtro lineal local
y repetición desactivada. La posición de cada sprite se ajusta a su caja
visible, no al origen de la celda transparente original:

| Sprite | Pieza | Posición de mundo | Escala del arte |
|---|---|---|---|
| `RocasIzquierdas` | Rocas A | `(2,290)` | `(0.24,0.2)` |
| `RocasDerechas` | Rocas B | `(1033,356)` | `(0.24,0.2)` |
| `RocasIzquierdasBajas` | Rocas B | `(0,500)` | `(0.22,0.18)` |
| `RocasDerechasBajas` | Rocas A | `(1034,502)` | `(0.24,0.2)` |
| `FrenteIzquierdo` | Frente | `(92.28,548)` | `(0.62,0.33)` |
| `UnionCentral` | Unión | `(418,554)` | `(0.62,0.33)` |
| `FrenteDerecho` | Frente | `(725,548)` | `(0.62,0.33)` |
| `SacosIzquierda` | Sacos | `(114,548)` | `(0.6,0.22)` |
| `SacosDerecha` | Sacos | `(735,548)` | `(0.6,0.22)` |
| `EsquinaIzquierda` | Esquina | `(91,553)` | `(0.23,0.235)`, espejo horizontal |
| `EsquinaDerecha` | Esquina | `(946,553)` | `(0.23,0.235)` |

El frente es una única masa continua de madera/tierra/sacos aproximada
x=92..1058, y=552..653. La madera se ve principalmente entre y≈585..642,
sin desplazar la defensa y=650; su recorte inferior se conserva. Parte del
arte se eleva hacia y=552 para que los materiales se lean en el viewport
de 648 de alto. El corredor x=480..672 queda sin rocas ni piezas laterales;
solo lo cruza el frente decorativo bajo todos los actores al final del
recorrido. El soldado inicial y=500 permanece separado del borde superior
visible de la trinchera. El despliegue continúa sujeto a las reglas previas.

Los 19 nodos de la escena permanecen juntos porque componen un solo entorno
estático autorado, con capas y atlas compartido; separarlos en escenas por
sprite añadiría archivos sin reutilización independiente. No existe lógica,
input, física, navegación o animación en este subárbol. La lectura real con
actores/pickups, picking y recorte pertenece a T012 y sus reportes; esta
composición no acredita por sí sola esos resultados.

## Prompts de generación

### Terreno

Use case: stylized-concept. Asset type: production 2D game ground texture,
1024x1024 square, fully opaque, seamlessly tileable along all four edges.
Input image: style reference ONLY, do not reproduce the scene, UI, actors,
lanes or layout. Primary request: a continuous patch of softly hand-painted
dry earth for the Monte Calvo game environment, matching the muted ochre soil
and olive shadows of the reference. View directly down at flat terrain. Paint
warm muted earth, gentle broad color variation and restrained small grit;
very sparse tiny stones and dry fibers blended into the surface. Low spatial
noise and low contrast EVERYWHERE so bright provisional actors and ammunition
sprites remain legible anywhere on this surface. All regions equally quiet;
no notable focal rocks or dark blobs. Diffuse overcast illumination, no
directional cast shadows. Professional cohesive painterly 2D illustration,
matte materials, broad subtly visible brushwork at game scale; not
photographic, not pixel art, not glossy 3D. Exact intended output: just the
square dirt material filling the complete image, no transparent edges.
Constraints: texture must repeat cleanly with continuous edges in X and Y,
no vignette, no horizon, no mountains, no grass border, no frame, no paths,
no lanes, no grid, no trenches, no sandbags, no wood, no soldiers, no enemies,
no crates, no pickups, no weapons, no lettering, no UI, no text, no watermark.

### Montañas

Use case: stylized-concept. Asset type: a production transparent 2D mountain
panorama sprite for Godot, landscape canvas 1536x1024. Input image role:
STYLE reference ONLY, specifically its distant cool mountains and mist.
Generate only a clean isolated panoramic strip of overlapping mountains, in
muted blue-grey and desaturated olive-grey, hand-painted soft atmospheric
perspective. Broad low Korean hill ridges, several distant layers, calm
diffuse cloudy daylight suggested within the painted ridges. View across
the hills as a distant backdrop in the reference. Composition: panorama
stretches continuously from the LEFT image edge to the RIGHT image edge;
mountain strip occupies approximately the middle half of the canvas height,
with flat clear space above and a soft painterly haze-to-alpha fade BELOW.
ALL space outside the mountains must be genuinely TRANSPARENT ALPHA,
including entire sky and lower foreground, not painted grey or white. Keep
delicate ridge silhouettes and soft atmospheric transition at the bottom,
crop nothing at left/right except continuation of the mountain panorama
itself. Shallow relief and low local contrast, soft brushwork, matte
illustrated 2D finish, matching reference, not photorealistic, not pixel art,
not glossy 3D. The resulting useful mountain band will be placed across a
1152-wide game world and compressed into the upper 160 world units; keep
silhouette clearly legible as wide hills at small scale. Constraints: NO
dirt battlefield, no paths, no lanes, no buildings, no trees in foreground,
no ground baseline, no rocks, no trench, no wooden props, no people, no
soldiers, no enemies, no smoke/fire, no UI, no text, no watermark, no frame,
no drop shadow. Return just the mountains with real transparent surroundings
and the clean alpha fade; do not draw a transparency checkerboard.

### Trincheras

Use case: stylized-concept. Asset type: production 2D game sprite atlas,
1536x1024 landscape, TRUE TRANSPARENT ALPHA background. Input image 1:
reference ONLY for Monte Calvo hand-painted trenches, weathered wood,
sandbags, rocks, dry grass, diffuse light and elevated shallow 3/4 camera.
Input image 2: reference ONLY for matching muted ochre/olive earth palette.
Generate SIX SEPARATE modular environment components, arranged in three
equal columns and two equal rows of approximately 512x512 each. NO visible
grid lines or labels. Leave at least 32 transparent pixels on every side of
EACH cell, no object crosses a cell boundary or overlaps another. Centers of
the six cells: top row (256,256), (768,256), (1280,256); bottom row (256,768),
(768,768), (1280,768). Each component must be fully visible, modestly wide,
completely isolated on genuine alpha. TOP LEFT: one wide horizontal trench
front segment, rough muted brown timber retaining boards, three short
upright supports, low irregular excavated ochre earth behind, about
420x230px. TOP MIDDLE: one wide gently irregular low stack of weathered khaki
sandbags, two staggered courses, matte cloth seams, no bunker opening,
about 420x160px. TOP RIGHT: one open trench corner joining excavated earthen
edge and timber retaining boards, shallow L shape with no roof, about
400x300px. BOTTOM LEFT: one short joining section of timber boards and a
few sandbags on excavated earth, about 400x230px; this is a connector, not a
complete fortified position. BOTTOM MIDDLE: a low side-border cluster of
muted grey-brown rocks and restrained dry olive grass, about 360x240px.
BOTTOM RIGHT: a different low cluster of small muted rocks and sparse dry
grass, about 360x220px. Match the reference's restrained detailed painterly
2D illustration with matte materials and diffuse daylight, moderate low
contrast, slightly dark irregular edges, broad brushwork that reads at
small game scale. Keep all components in the same camera angle and light
direction. These pieces will form ONE wide defended position near the screen
bottom, not separate lanes or forts. Constraints: no soldiers, no enemies,
no characters, no weapons, no ammunition crates, no pickups, no flags, no
signs, no lettering, no UI, no text, no arrows, no borders, no cell outlines,
no checkerboard, no smoke, no fire, no light effects, no backdrop, no flat
rectangular dirt panels, no cast shadows outside the isolated objects, no
glossy 3D, no photography, no pixel art. Entire background and gaps must be
truly transparent; preserve clean alpha edges around wood, earth and fine
grass.
