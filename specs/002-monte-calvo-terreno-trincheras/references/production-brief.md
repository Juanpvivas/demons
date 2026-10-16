# Guía de producción — terreno y trincheras de Monte Calvo

**Tarea**: T002, autoría aprobada por QA; actualización documental tras T005 · `docs-writer` · 2026-10-15.
**Estado**: guía vigente con la [línea base T001](../evidence/baseline.md), sus capturas PC y la máscara artística acordada. T005 aprobó los PNG de suelo/montañas y el uso del suelo como hoja única sin repetición; la integración, continuidad y lectura aún deben verificarse en T006/T007. No acredita arte integrado ni verificaciones futuras.
**Rama**: `codex/002-monte-calvo-terreno-trincheras`.

Aplicar [spec](../spec.md), [plan](../plan.md), [contrato](../contracts/visual-boundary.md) y [referencia aprobada](visual-reference.md). Esta guía produce instrucciones de arte, no imágenes, escenas, cambios de reglas o evidencia de ejecución.

## Dirección y composición

Pintura 2D de tierra ocre con sombras oliva, madera mate, sacos de arena terrosos y montañas azul grisáceo con distancia atmosférica pintada. Pincelada visible a escala del entorno, materiales reconocibles y luz difusa coherente entre las tres hojas. Evitar brillo de render 3D, fotorrealismo y pixel art.

Componer una ladera continua, con el centro tranquilo y el marco algo más detallado. El recorrido real es central, `x=576`, desde el spawn en `y=50` hacia la defensa en `y=650`. No introducir líneas que parezcan cinco carriles, cuadrícula, casillas, límites de despliegue o rutas alternativas.

La posición defendida se representa como una masa amplia y legible cerca de `y≈580..650`, con madera frontal, tierra excavada y sacos. No convertirla en cinco puestos separados. Mantener legibles el recorrido, el soldado inicial y los pickups, aunque el arte esté debajo. El decorado no otorga cobertura, no bloquea el movimiento y no cambia dónde puede colocarse una unidad.

Cubrir el rectángulo lógico visible y prever margen de continuidad para proporciones diferentes. La [medición T001](../evidence/baseline.md) confirma que V1 (ventana 1152×648) y V2 (ventana 1920×1080) muestran el mismo rectángulo lógico 1152×648: V2 aplica escala de pantalla `1.666667`, no muestra más mundo. La extensión del arte no representa un límite jugable. No mover el tablero, actores, cámara o entrada para encajar la composición.

| Comparación fuente | V1, 1152×648 | V2, 1920×1080 |
|---|---|---|
| Inicial, aproximadamente 0,23 s | [Captura inicial](../evidence/pc-v1-0.png) | [Captura inicial](../evidence/pc-v2-0.png) |
| Combate y pickups, aproximadamente 8 s | [Captura de combate](../evidence/pc-v1-1.png) | [Captura de combate](../evidence/pc-v2-1.png) |

Estas imágenes muestran el viewport renderizado del juego anterior al arte, con fondo gris y actores/pickups provisionales. Sus tiempos no representan equivalencia exacta de frames ni interacción manual acreditada. La línea base registra importación y GUT 183/183, además de una derrota natural observada; no demuestra clic, toque o rendimiento móvil.

## Coordenadas y máscara de protección

Todas las coordenadas siguientes son de **mundo**, procedentes de las escenas, del contrato y de la [geometría protegida T001](../evidence/baseline.md). El tester midió `canvas_transform` identidad en V1/V2: V1 conserva escala 1 y V2 escala de stretch/pantalla `1.666667` sobre el mismo rectángulo lógico 1152×648. No confundir píxeles físicos de captura con coordenadas de mundo.

| Elemento preservado | Coordenadas / extensión contractual | Consecuencia artística |
|---|---|---|
| Spawn y avance enemigo | `(576,50)`; avance en +Y hacia `y=650` | Conservar continuidad y contraste a lo largo del recorrido central |
| Enemigo inicial | Centro `(576,50)`, cuerpo/sprite 48×48; caja `x=552..600`, `y=26..74` | Montañas y textura superior suaves detrás de su silueta |
| Soldado inicial | Centro `(576,500)`, cuerpo/sprite 48×48; caja `x=552..600`, `y=476..524` | Evitar bordes, manchas blancas o sombras negras que compitan con el actor provisional |
| Área defendida | Centro `(576,650)`, rectángulo 960×64; `x=96..1056`, `y=618..682` | Usar su posición como referencia visual; conservar su geometría y aceptar el recorte propio de cada ventana |
| Despliegues nuevos | Celdas 96×96, posición calculada por el TileMap existente; el centro de la celda (6,5) es `(624,528)`, distinto del soldado inicial | No centrar al soldado inicial de nuevo ni dibujar casillas; preservar lectura en cualquier celda que ya admita despliegue |
| Munición | Sprite actual 32×32 y radio de picking actual 20 | Evitar acentos amarillos pequeños que parezcan pickups; no cambiar sprite, radio o input |

La máscara es una **guía de densidad y contraste del dibujo**, no una textura de bloqueo, colisión o zona de exclusión jugable. El eje central y las siluetas anteriores deben conservar contraste; la protección se extiende a cualquier soldado o pickup colocado junto al decorado. No basta con despejar solo el soldado inicial.

Máscara artística propuesta y acordada para producción: corredor de **bajo detalle `x=480..672`, `y=0..648`**, equivalente a dos celdas de ancho alrededor del eje `x=576`. Es una decisión de composición sobre el espacio lógico medido, no una zona detectada en el juego ni una medida tomada de la imagen de concepto. Mantener además **bajo contraste general fuera del corredor**, pues el despliegue no está restringido a él.

La masa de trinchera usa como referencia horizontal `x=96..1056` y franja aproximada `y=580..650`, conservando la lectura de la defensa que se extiende hasta `y=682`. El borde inferior puede quedar recortado en V1/V2 porque el rectángulo lógico termina en `y=648`; es una condición previa documentada en T001, por lo que no se desplaza la defensa o la cámara para mostrarlo completo. La trinchera frontal puede atravesar visualmente el eje, siempre detrás de actores y con bajo contraste local; no debe simular una puerta obligatoria ni un obstáculo.

## Hojas de producción

Los PNG finales se producen en `assets/sprites/levels/monte_calvo/`; esta carpeta de referencias permanece excluida de importación mediante `.gdignore`. T005 produjo suelo y montañas; T010 produjo el atlas como trabajo anticipado, sin sustituir los gates de aceptación pendientes. La [verificación de texturas](../evidence/visual-structure.md) y la [del atlas](../evidence/atlas.md) registran tamaños, importación y limitaciones de composición.

| Hoja | Lienzo real o propuesto | Contenido y transparencia | Uso previsto |
|---|---|---|---|
| `terreno.png` | Real: 1254×1254; propuesta inicial: 1024×1024 | RGB opaco; tierra ocre/oliva con grano suave, sin horizonte u objetos | Una sola hoja, sin repetición; cubrir el encuadre mediante escala/región del arte, sin juntas ni patrón de cuadrícula |
| `montanas.png` | Real: 1536×1024 | Transparente; panorama de montañas azul grisáceo y neblina pintada | Franja superior aproximada de mundo `y=0..160`; ajustar solo el sprite/región del arte al encuadre medido |
| `trincheras_atlas.png` | Real: 1536×1024 | Transparente; seis piezas separadas de tierra, madera, sacos, piedras y hierba seca | Posición amplia y detalles del marco mediante seis regiones variables compartidas |

El [ensayo de repetición 2×2](../evidence/assets-us1-tiling.png) mostró juntas; T005 no acredita tileabilidad. La decisión aprobada es usar el terreno **una sola vez, con repetición desactivada**, cubriendo el encuadre y sus márgenes mediante escala o región del sprite, sin mover tablero, cámara o actores. La propuesta de integración usa un área de arte 1920×1080 de mundo como margen conservador, no como tamaño del viewport lógico. T006/T007 deben comprobar continuidad sin huecos ni juntas y lectura en los encuadres reales: FR-002 y FR-010 se conservan íntegros. Si el margen no basta, ajustar el recurso o su composición; no reactivar repetición sobre esta hoja sin corregirla y validarla.

Mantener el ruido bajo en toda la superficie; la mayor riqueza del marco procede de piezas separadas. No hornear unidades, sombras de actores, cinco sendas, marcas de selección o elementos de UI.

Para montañas, el tamaño del lienzo no prescribe un quad transparente de pantalla completa. Tras generar el PNG, medir su región útil según el alfa real y registrar región, escala y posición del `Sprite2D`. Ajustar solo ese arte para cubrir el ancho lógico observado `0..1152` y ocupar la franja alta aproximada `y=0..160`, sin recortar los picos ni fijar de antemano una altura de recorte en la fuente. V1/V2 muestran la misma composición lógica; no se centra de nuevo el nivel ni se mueve el eje `x=576`. Una extensión hasta `x=1920` puede servir como margen conservador de arte, pero no es una necesidad causada por V2. Si otra proporción medida requiere mayor extensión, continuar el arte y el suelo hasta cubrirla sin crear un límite de juego. Una transición alfa pintada proporciona la atmósfera sin shader, partículas o niebla dinámica.

Añadir detrás del panorama un cielo azul grisáceo estático mediante `Sprite2D` y `GradientTexture2D` nativos, con transición alfa hacia el suelo. Evita que el terreno opaco aparezca por encima de los picos a través de la transparencia del panorama. Comparte la capa de montañas, se dibuja antes que ellas y no añade PNG, script, animación, shader, input o cámara. Su continuidad y transición quedan pendientes de la comprobación de integración.

El atlas real contiene frente de madera/tierra, sacos, esquina excavada, unión de madera/sacos y dos grupos de roca/hierba. El generador no respetó las seis celdas propuestas de 512×512; T011 utiliza seis regiones variables que conservan las piezas completas, con recorte de filtro. Las regiones y posiciones reales están en [SOURCES.md](../../../assets/sprites/levels/monte_calvo/SOURCES.md) y se contrastan en [atlas.md](../evidence/atlas.md). Son componentes de una misma posición, sin guías o cuadrículas dentro del PNG. La masa visible compuesta ocupa aproximadamente `x=92..1058`, `y=552..653`; la madera se lee principalmente en `y≈585..642`, conservando el recorte inferior de la defensa y su posición original.

## Integración visual prevista

Una escena estática `MonteCalvoVisual.tscn`, con raíz `Node2D` al origen, escala 1 y rotación 0. Instanciarla una vez como hijo directo del nivel. Pila acordada:

| Capa | Z relativo | Z efectivo con raíz -10 | Función |
|---|---:|---:|---|
| Suelo opaco | 0 | -10 | Cubrir la superficie visible y sus extensiones |
| Cielo estático y montañas con alfa | 1 | -9 | Cielo nativo detrás del panorama; conservar el horizonte sobre el suelo en la franja superior |
| Bordes | 2 | -8 | Marco de tierra, rocas y hierba, con densidad controlada |
| Trincheras | 3 | -7 | Tierra excavada, madera frontal y sacos cerca de la defensa |

Todos los hijos mantienen z relativo y quedan debajo de los actores actuales en z=0. El suelo opaco no oculta el horizonte porque cielo y montañas están encima, con el cielo detrás de los picos. Su composición se ajusta con sprites y regiones, sin scripts, procesos, señales, `Control`, física, navegación, cámara propia, `CanvasLayer`, luces, shaders o parallax.

Conservar nombres, padres, rutas, posiciones y propiedades de todos los nodos existentes, incluido `TileMap`; no migrar a `TileMapLayer`. Conservar los sprites provisionales, pickups y la ausencia actual de HUD instanciado. El orden de dibujo no acredita por sí solo que funcionen clic y toque: esas pruebas corresponden al tester.

## Importación y costo inicial

Comenzar con PNG sin pérdidas y alfa limpio en montañas/atlas. Revisar halos a escala real; mantener la corrección de bordes alfa cuando corresponda. Configurar filtro solo en los `CanvasItem` del entorno y mantener repetición desactivada en suelo y panorama. No cambiar filtros globales, renderer Mobile, ETC2/ASTC, exportaciones o recursos de gameplay.

No activar compresión VRAM o mipmaps como supuesto universal: decidir según escala, artefactos y medición. Referencia técnica: [importación de imágenes de Godot](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html). Las regiones estáticas permiten reutilizar la hoja de trincheras sin duplicar su textura: [Sprite2D](https://docs.godotengine.org/en/stable/classes/class_sprite2d.html).

Estimación conservadora de las hojas como RGBA8 sin mipmaps: terreno real 1254×1254, aproximadamente 5,999 MiB; montañas reales, 6 MiB; atlas real, 6 MiB; total aproximado de 17,999 MiB. Es un cálculo de `ancho × alto × 4`, no memoria real medida ni tamaño de descarga; no incluye la textura nativa del cielo. Reutilizar una textura no multiplica ese tamaño por cada sprite. Registrar dimensiones finales, importación y memoria real en la evidencia; perfilar transparencias y sobreposición antes de ampliar resolución o planos.

## Revisión y pendientes

- T001/T002 aprobadas como línea base y guía, respectivamente. T005 aprueba las hojas y el uso único sin repetición, con limitaciones registradas; no aprueba continuidad, lectura o interacción de la integración. La regresión de la línea base no sustituye esas comprobaciones.
- Arte: comprobar paleta, materialidad, continuidad, horizonte, madera y sacos; excluir HUD, personajes, bandera, carteles, efectos y cinco carriles del concepto. No copiar la imagen completa como fondo.
- Integración: comparar los mismos estados antes/después y comprobar siluetas/munición sobre suelo, montañas y trincheras; verificar el contrato y el diff con la línea base.
- Interacción y regresión: seguir [quickstart](../quickstart.md). Esta tarea documental no ejecuta Godot/GUT ni sustituye su evidencia.
- Android: T001 detectó por USB un Xiaomi modelo `2107113SG`, producto `vili_eea`, en estado ADB `device`. No se instaló ni ejecutó build; falta acordarlo como referencia y medir viewport, toque, FPS, memoria y carga. No se declara compatibilidad por una captura PC.
- iOS y demás proporciones: T001 solo inventarió simuladores; no hay dispositivo iOS físico ni build probado. Conservar pendientes las comprobaciones no realizadas, distinguiendo simulador y dispositivo físico. La composición debe prever extensión y recorte sin cambiar mecánicas.

Guía informada por GodotPrompter `using-godot-prompter`, `2d-essentials`, `scene-organization`, `assets-pipeline` y `godot-testing`, contrastada con el código y las restricciones del proyecto. No se gradúan decisiones a `docs/SPEC.md` o `docs/ARCHITECTURE.md` en esta tarea; el cierre de la feature mantiene su propio gate.
