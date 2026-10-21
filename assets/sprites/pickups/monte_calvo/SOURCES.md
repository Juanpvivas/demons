# Caja de munición de Monte Calvo — procedencia y uso

## Arte de 004-I3

`caja_municion.png` se produjo el 2026-10-21 para T023 mediante la herramienta
nativa OpenAI `image_gen` de Codex. El
[concepto horizontal propio](../../../../specs/005-cinco-carriles/references/visual-reference.md)
se usó solo como referencia de materiales y acabado pictórico, sin extraer
terreno, actores o interfaz. Representa una caja cerrada oliva mate, con
refuerzos y tres motivos de cartuchos de latón; no introduce cantidades,
insignias, texto o indicadores de alcance.

La primera generación tenía paneles ocres. Una edición dirigida con la misma
herramienta cambió el cuerpo a oliva, conservando forma, perspectiva y cartuchos.
El PNG versionado es la salida RGBA original seleccionada de esa edición,
**1254×1254**, sin recorte, repintado, extracción de fondo ni reempaquetado por
scripts. Conserva su alfa real de 0 a 255 y no contiene sombra, halo o terreno.

## Importación y encaje

La importación limita el lado mayor a **256**, con textura prevista **256×256**,
lossless, corrección de borde alfa y sin mipmaps. Equivale a 0,25 MiB RGBA8
estimados, sin afirmar VRAM medida. El consumidor usa filtro lineal y sin
repetición local, sin cambiar ajustes globales del proyecto.

`AmmoPickup.tscn` conserva el AnimatedSprite2D de un solo fotograma y aplica
solo escala visual **0,125** y offset **(0; −5,818182)**. La silueta principal
ocupa aproximadamente **27,4×17,6** unidades, centrada en la raíz; la opacidad
completa permanece dentro de **32×32**, incluidos los cartuchos. El lienzo
transparente no se utiliza como medida de la caja visible. La raíz, posición,
CircleShape2D de radio **20**, valor e interacción permanecen intactos.
La importación/carga, lectura sobre terreno y gestos tienen aprobación funcional
para integración T027 en Web de computador y apps Android Emulator/iPad Simulator.
Las [tareas de 004](../../../../specs/004-personajes-municion-monte-calvo/tasks.md)
mantienen entrega y publicación T039 pendiente, sin certificar hardware o Mobile.

## Condiciones de uso

Arte generado específicamente para este proyecto a petición de su titular,
usando la referencia propia descrita. No incorpora fotografías ni paquetes de
arte de terceros. Su uso en el juego y derivados queda sujeto a los términos
de generación de imágenes de OpenAI aplicables a la cuenta que lo produjo.
No se inventa una licencia externa ni se afirma exclusividad. Crédito de
procedencia: «Arte de la caja de munición generado con OpenAI image_gen,
dirección artística del proyecto Demonios de las Trincheras». No se ha
identificado atribución externa adicional en los materiales utilizados.

## Prompt final de la edición seleccionada

> Use case: precise-object-edit. Edit target: this isolated ammunition crate
> sprite. Change ONLY the main ochre-yellow wooden body panels to muted OLIVE
> DRAB GREEN painted wood. The body must unmistakably read as an olive military
> ammunition box, not yellow wood. Keep the three raised golden BRASS CARTRIDGE
> motifs bright and prominent; retain subdued brass latches, dark brown-olive
> metal straps, and pale matte edge highlights. Preserve shape, exact
> composition, hand-painted 2D material detail, centered position, box size and
> perspective. Preserve genuinely transparent alpha outside the silhouette;
> no shadow, glow, halo, background, ground, text or other new elements. One
> closed olive ammunition crate for 32x32-pixel display, strong readable
> contrast. Do not recolor the brass cartridges green.
