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

`AmmoPickup.tscn` conserva el AnimatedSprite2D de un solo fotograma. La
corrección T040–T043 eleva su escala visual de **0,125 a 0,15625**
(+25 %), manteniendo offset **(0; −5,818182)**. La geometría medida en la misma
textura y escalada por 1,25 ocupa **34,84375×26,40625** unidades con alfa>0 y
**34,21875×22,03125** con alfa>0,5, centrada en la raíz y dentro de **40×40**.
El lienzo transparente no se utiliza como medida de la caja visible. La raíz,
posición, CircleShape2D de radio **20**, valor e interacción permanecen intactos.
El pulso suave de brillo se reproduce con recursos de escena y conserva alfa
de modulación 1 y la transparencia original, sin cambiar PNG/importación ni
añadir GDScript, shader o halo. Su ciclo está en el
[contrato visual](../../../../specs/004-personajes-municion-monte-calvo/contracts/visual-presentation.md#5-arte-huella-y-procedencia).
La importación/carga, lectura sobre terreno y gestos tienen aprobación funcional
para integración T027 y, para la nueva presentación, T043 en Web de computador
y apps Android Emulator/iPad Simulator. El smoke con varias cajas no cuantifica
el coste del pulso; las métricas anteriores no lo certifican.
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

El prompt conserva el tamaño de generación previsto antes de T040; el aumento
posterior se aplica en la escena, sin editar el PNG.

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
