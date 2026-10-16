# Guía de producción — terreno y trincheras de Monte Calvo

**Tarea**: T002 · `docs-writer`, modo autoría · 2026-10-15.
**Estado**: autoría completada, borrador para QA. Incorpora la [línea base T001](../evidence/baseline.md), sus capturas PC y la máscara artística acordada. Dimensiones y pila visual autorizadas como propuesta de producción; el orquestador habilita las tareas dependientes tras la aprobación QA de T001 y T002. No acredita arte integrado ni verificaciones futuras.
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

## Tres hojas propuestas

Los tamaños son un presupuesto inicial revisable tras la revisión visual. Los tres PNG finales se producen en `assets/sprites/levels/monte_calvo/`; esta carpeta de referencias permanece excluida de importación mediante `.gdignore`.

| Hoja | Lienzo propuesto | Contenido y transparencia | Uso previsto |
|---|---|---|---|
| `terreno.png` | 1024×1024 | Opaco; tierra ocre/oliva con grano suave, sin horizonte, objetos o sombras direccionales grandes | Suelo continuo, repetible en ambos ejes, sin costuras ni patrón de cuadrícula reconocible |
| `montanas.png` | 1536×1024 | Transparente; panorama de montañas azul grisáceo, neblina pintada y transición alfa limpia; sin fondo rectangular opaco | Franja superior aproximada de mundo `y=0..160`; ajustar solo el sprite/región del arte al encuadre medido |
| `trincheras_atlas.png` | 1536×1024 | Transparente; piezas separadas de tierra, madera, sacos, piedras y hierba seca, con perspectiva y luz coherentes | Montar una posición amplia y detalles del marco con regiones estáticas compartidas |

Para el terreno, comprobar continuidad de los cuatro bordes y ausencia de manchas que delaten repetición. Mantener el ruido bajo en toda la hoja; la mayor riqueza del marco procede de piezas separadas. No hornear unidades, sombras de actores, cinco sendas, marcas de selección o elementos de UI.

Para montañas, el tamaño del lienzo no prescribe un quad transparente de pantalla completa. Tras generar el PNG, medir su región útil según el alfa real y registrar región, escala y posición del `Sprite2D`. Ajustar solo ese arte para cubrir el ancho lógico observado `0..1152` y ocupar la franja alta aproximada `y=0..160`, sin recortar los picos ni fijar de antemano una altura de recorte en la fuente. V1/V2 muestran la misma composición lógica; no se centra de nuevo el nivel ni se mueve el eje `x=576`. Una extensión hasta `x=1920` puede servir como margen conservador de arte, pero no es una necesidad causada por V2. Si otra proporción medida requiere mayor extensión, continuar el arte y el suelo hasta cubrirla sin crear un límite de juego. Una transición alfa pintada proporciona la atmósfera sin shader, partículas o niebla dinámica.

Propuesta para el atlas: seis celdas de 512×512 en tres columnas y dos filas, con margen transparente aproximado de 24 px para evitar sangrado. Piezas iniciales: frente de madera/tierra, segmento de sacos, esquina de excavación, unión de madera/sacos y dos grupos laterales de roca/hierba. Son componentes de una misma posición, no seis puestos. La composición final decide las regiones útiles y las registra con sus dimensiones; no dejar guías, rótulos o cuadrículas dentro del PNG.

## Integración visual prevista

Una escena estática `MonteCalvoVisual.tscn`, con raíz `Node2D` al origen, escala 1 y rotación 0. Instanciarla una vez como hijo directo del nivel. Pila acordada:

| Capa | Z relativo | Z efectivo con raíz -10 | Función |
|---|---:|---:|---|
| Suelo opaco | 0 | -10 | Cubrir la superficie visible y sus extensiones |
| Montañas con alfa | 1 | -9 | Conservar el horizonte sobre el suelo, solo en la franja superior |
| Bordes | 2 | -8 | Marco de tierra, rocas y hierba, con densidad controlada |
| Trincheras | 3 | -7 | Tierra excavada, madera frontal y sacos cerca de la defensa |

Todos los hijos mantienen z relativo y quedan debajo de los actores actuales en z=0. El suelo opaco no oculta el horizonte porque las montañas están encima. Su composición se ajusta con sprites y regiones, sin scripts, procesos, señales, `Control`, física, navegación, cámara propia, `CanvasLayer`, luces, shaders o parallax.

Conservar nombres, padres, rutas, posiciones y propiedades de todos los nodos existentes, incluido `TileMap`; no migrar a `TileMapLayer`. Conservar los sprites provisionales, pickups y la ausencia actual de HUD instanciado. El orden de dibujo no acredita por sí solo que funcionen clic y toque: esas pruebas corresponden al tester.

## Importación y costo inicial

Comenzar con PNG sin pérdidas y alfa limpio en montañas/atlas. Revisar halos a escala real; mantener la corrección de bordes alfa cuando corresponda. Configurar filtro y repetición solo en los `CanvasItem` del entorno; repetir únicamente el suelo si lo necesita la composición. No cambiar filtros globales, renderer Mobile, ETC2/ASTC, exportaciones o recursos de gameplay.

No activar compresión VRAM o mipmaps como supuesto universal: decidir según escala, artefactos y medición. Referencia técnica: [importación de imágenes de Godot](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html). Las regiones estáticas permiten reutilizar la hoja de trincheras sin duplicar su textura: [Sprite2D](https://docs.godotengine.org/en/stable/classes/class_sprite2d.html).

Estimación de las hojas propuestas como RGBA8 sin mipmaps: terreno 4 MiB, montañas 6 MiB y atlas 6 MiB; total 16 MiB. Es un cálculo de `ancho × alto × 4`, no memoria real medida ni tamaño de descarga. Reutilizar una textura no multiplica ese tamaño por cada sprite. Registrar dimensiones finales, importación y memoria real en la evidencia; perfilar transparencias y sobreposición antes de ampliar resolución o planos.

## Revisión y pendientes

- T001: reporte y capturas incorporados como fuente. Someter esta guía a QA y esperar la aprobación de ambas tareas antes de las dependientes de producción. La regresión de la línea base no valida arte todavía inexistente.
- Arte: comprobar paleta, materialidad, continuidad, horizonte, madera y sacos; excluir HUD, personajes, bandera, carteles, efectos y cinco carriles del concepto. No copiar la imagen completa como fondo.
- Integración: comparar los mismos estados antes/después y comprobar siluetas/munición sobre suelo, montañas y trincheras; verificar el contrato y el diff con la línea base.
- Interacción y regresión: seguir [quickstart](../quickstart.md). Esta tarea documental no ejecuta Godot/GUT ni sustituye su evidencia.
- Android: T001 detectó por USB un Xiaomi modelo `2107113SG`, producto `vili_eea`, en estado ADB `device`. No se instaló ni ejecutó build; falta acordarlo como referencia y medir viewport, toque, FPS, memoria y carga. No se declara compatibilidad por una captura PC.
- iOS y demás proporciones: T001 solo inventarió simuladores; no hay dispositivo iOS físico ni build probado. Conservar pendientes las comprobaciones no realizadas, distinguiendo simulador y dispositivo físico. La composición debe prever extensión y recorte sin cambiar mecánicas.

Guía informada por GodotPrompter `using-godot-prompter`, `2d-essentials`, `scene-organization`, `assets-pipeline` y `godot-testing`, contrastada con el código y las restricciones del proyecto. No se gradúan decisiones a `docs/SPEC.md` o `docs/ARCHITECTURE.md` en esta tarea; el cierre de la feature mantiene su propio gate.
