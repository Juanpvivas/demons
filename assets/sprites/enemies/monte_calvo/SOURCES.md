# Enemigo de Monte Calvo — procedencia y uso

Creado el 2026-10-17 para T014 de `004-personajes-municion-monte-calvo`
mediante la herramienta nativa `image_gen` de Codex. La referencia conceptual
del proyecto, `specs/002-monte-calvo-terreno-trincheras/references/monte-calvo-concept.png`,
y el atlas propio `assets/sprites/units/monte_calvo/soldado_atlas.png` se usaron
exclusivamente para orientar el acabado pictórico. No se extrajeron sus figuras,
terreno ni interfaz. La infantería gris/marrón con gorra y vista frontal es un
diseño separado del soldado oliva con casco; no fija una nacionalidad enemiga,
una insignia ni un modelo documental exacto de arma.

## Archivos y encaje

`enemigo_atlas.png` conserva sin editar píxeles la primera salida original
RGBA de la herramienta, de **1774 × 887**. La generación solicitó un atlas
aproximado de 1024 × 512 y devolvió dimensiones mayores. El PNG versionado
es también el original de producción; SHA-256:
`11aa07dbb81bcf6fb2a1f830b2bd667ef5a5a9640acaf0f3cbdcba26a4688d02`.
Tiene alfa real de 0 a 255 y ocho figuras aisladas. No hubo extracción,
recoloración, redibujo, recorte ni empaquetado posterior del PNG.

La importación limita el lado mayor a **1024**, produciendo una textura
prevista de **1024 × 512**: 2 MiB RGBA8 sin mipmaps como estimación, no memoria
medida. Ajustes: lossless, corrección de borde alfa y sin mipmaps.
El consumidor debe usar filtro lineal local y repetición desactivada.
La importación y carga se verifican por el tester al integrar el recurso;
esta descripción no las presenta como ya ejecutadas por desarrollo.

`enemigo_frames.tres` define ocho `AtlasTexture` con `filter_clip`, regiones
medidas en coordenadas de la textura importada y dos píxeles de margen
transparente. No supone una grilla exacta: el tercer paso cruza la división
horizontal aparente del atlas. Los márgenes reconstruyen un lienzo lógico
común de **384 × 288**, con apoyo en **(192, 264)**. Los puntos de apoyo
medidos en el PNG original son:

| Pose | Apoyo original x,y | Región importada x,y,ancho,alto |
|---|---|---|
| Avance 1 | 246,438 | 58,14,178,241 |
| Avance 2 | 679,441 | 309,19,166,238 |
| Avance 3 | 1115,448 | 561,19,164,242 |
| Avance 4 | 1549,440 | 817,24,167,232 |
| Contacto | 255,858 | 64,264,174,234 |
| Derrota 1 | 680,841 | 311,277,163,211 |
| Derrota 2 | 1101,845 | 554,332,166,158 |
| Derrota 3 | 1538,837 | 767,377,244,109 |

El encaje previsto conserva aproximadamente **48 unidades de altura opaca**
en el primer paso y el apoyo en raíz+(0,24), con escala visual uniforme
**0.20331601** y offset **(0,-1.957159)**. Estos valores corresponden solo al
hijo visual; no modifican el cuerpo 48×48 ni otras formas jugables. La caída
conserva el anclaje del actor con su cambio intencional de postura. Su lectura
sobre el escenario y entre bandos requiere revisión artística del conjunto.

| Clip | Fotogramas | Tiempo |
|---|---:|---|
| `advance` | 4 | Bucle de 0,60 s |
| `contact` | 1 | Postura sostenida, sin ataque |
| `defeat` | 3 | 0,40 s sin bucle |

Los recursos solo contienen imágenes. El impacto se compone en el presentador,
y la caída comparte frames con el efecto independiente. No hay terreno, HUD,
sombras, sangre, proyectiles, callbacks, física o datos de combate en el arte.

## Condiciones de uso

Arte generado específicamente para el proyecto a petición de su titular,
usando las dos referencias propias descritas. No se incorporaron fotografías
ni paquetes de arte de terceros. El uso del resultado en el juego y derivados
queda sujeto a los términos de generación de imágenes de OpenAI aplicables
a la cuenta que lo produjo. No se inventa una licencia de terceros ni se
afirma exclusividad. Crédito de procedencia: «Arte del enemigo generado con
OpenAI image_gen, dirección artística del proyecto Demonios de las Trincheras».
No se ha identificado atribución externa adicional en los materiales usados;
este registro de procedencia no constituye una revisión legal independiente.

## Prompt final

> Use case: stylized-concept. Asset type: production transparent sprite atlas
> for the 2D Godot game Demonios de las Trincheras. Input image 1 is the
> approved Monte Calvo concept, style reference only; image 2 is the Colombian
> soldier production atlas, painterly texture/edge treatment reference only,
> never an edit target. Primary request: create a NEW enemy infantry character
> in eight isolated poses, arranged as four columns and two rows, a landscape
> atlas approximately 1024 x 512. The SAME human character, proportions,
> outfit, weapon, light and scale in every pose. Elevated three-quarter FRONT
> view, facing down toward the bottom of the screen and the defended position,
> face visible, never facing away. Enemy wears a soft short-brim field cap,
> cool gray-brown padded jacket, slate-gray trousers, dark brown boots and
> simple brown chest ammunition pouches. Silhouette and gray/brown uniform
> clearly distinct from the olive helmeted Colombian soldier. Generic mid
> twentieth century infantry, one long wooden-stock rifle held across the
> chest with barrel diagonally down to viewer's left. Respectful human
> depiction. Style: hand-painted 2D game illustration, visible subtle brush
> texture, matte fabric/wood/metal, soft diffuse light, readable strong
> silhouette at small game size, restrained dark edge definition; match
> reference finish, no glossy 3D. Row 1 left to right: four consecutive walking
> cycle poses advancing toward bottom of screen, alternating left foot
> forward, passing feet, right foot forward, passing feet; modest march,
> not lunging or attacking. Row 2 left to right: stable CONTACT pose standing
> firmly with both feet braced and rifle held across chest, no strike; knees
> buckle as defeated; lowered to one knee and slumping; collapsed on side
> still. Defeat is non-graphic and calm, fully visible rifle remains with
> character. Composition: each figure fully visible, centered within its
> separate cell with ample transparent padding, no overlap, identical
> standing height and ground baseline for four walking frames and contact,
> consistent ground support/pivot through collapse. Actual transparent alpha
> for all empty space, no painted background. No shadows, terrain, UI, text,
> labels, grid lines, blood, insignia, flags, muzzle flash, projectiles,
> particles, checkerboard or watermark. Do not copy any scenery or HUD from
> the references.

La salida orientó el cañón hacia la derecha del espectador en vez de la
izquierda solicitada; conserva la vista frontal hacia la defensa y no se
retocó para invertirlo. La dirección del arma no cambia la dirección jugable.
