# T001 — Línea base anterior al arte de Monte Calvo

**Fecha**: 2026-10-15. **Responsable**: `godot-tester`. **Modo**: verificación de arte/setup; no hay lógica nueva ni evidencia RED que generar. **Rama**: `codex/002-monte-calvo-terreno-trincheras`. **Revisión**: `e7f2ca968fd199cc20969d4f3565f4853425bdbe` más los documentos nuevos de esta feature, todavía sin commit durante la ejecución.

Resultado disponible para QA: importación correcta y suite existente **183/183 pruebas**, **496 aserciones**, sin fallos; capturas PC V1/V2 del viewport renderizado y smoke observado hasta derrota natural. No se acredita entrada manual ni validación móvil o rendimiento Android. Este reporte no marca T001 ni aprueba la entrega visual.

## Entorno y conservación

- macOS 26.6.2, build 25G83; GPU Apple M5 Pro (Apple9).
- Motor `/Applications/Godot_mono.app/Contents/MacOS/Godot`: `4.7.1.stable.mono.official.a13da4feb`; consulta de versión, retorno **0**.
- Renderer de ejecución **Mobile / Forward Mobile**, driver **Metal 4.0**; no se cambió `project.godot` ni se usó otro renderer.
- GodotPrompter consultado: índice, `godot-testing`, `2d-essentials` y `scene-organization` (también `assets-pipeline` durante la preparación). Se aplicó verificación visual y regresión existente, sin tests artificiales para sprites.
- Snapshot anterior a importación y arte: `/private/tmp/monte-calvo-t001-0pulm9d5/`. Incluye copia aislada del proyecto jugable (`project/`), escena original (`baseline-scene.tscn`), configuración (`baseline-project.godot`) y hashes. Es material temporal local; no se incluye caché ni proyecto duplicado en el repositorio.
- [Manifest SHA-256](protected-sha256.json): **97 archivos** de `project.godot`, `export_presets.cfg`, `scenes/`, `core/`, `autoloads/`, `resources/` y `tests/`, incluidos scripts, escenas y Resources. Al cerrar este reporte: **97/97 idénticos**, sin modificaciones de gameplay o pruebas. El manifest permite la comparación posterior; la futura instancia visual cambiará deliberadamente el archivo del nivel y requerirá comparación semántica de sus nodos originales.
- Evidencia excluida de importación mediante `.gdignore`. No se añadieron harnesses al proyecto de producción.

## Importación y GUT

Desde la raíz, con el motor indicado:

```text
Godot --headless --path . --import --quit-after 2 --log-file <evidence>/import-baseline.log
Godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs=true -gexit --log-file <evidence>/gut-baseline.log
```

`Godot` representa la ruta absoluta anterior y `<evidence>` este directorio. Ambos comandos finales devolvieron **0**. [Importación final](import-baseline.log): completó escaneo e inicialización sin errores. [GUT completo](gut-baseline.log): GUT 9.7.1; **15 scripts, 183 pruebas aprobadas, 496 aserciones, 37.017 s, 0 fallos**. Cubre las áreas obligatorias existentes: daño, munición, moral, victoria/derrota y oleadas; incluye tablero, economía, nivel, spawner y HUD aislado. Esto no demuestra que el HUD esté integrado en el nivel.

GUT informa **3 warnings preexistentes en esta línea base**:

1. Ignora `tests/unit/systems/test_double_pooled_node.gd` porque es helper y no extiende `GutTest`.
2. `test_enemigo.gd`: 7 hijos sin liberar.
3. `test_soldado_enemigo_integration.gd`: 3 hijos sin liberar.

Se conservan sin modificar pruebas ni implementación. El primer intento de importación con sandbox retornó 0 pero mostró bloqueo al guardar preferencias del editor y al abrir el servidor local de C#; está en [import-baseline-sandbox.log](import-baseline-sandbox.log). Se repitió con permisos normales de Godot y solo el resultado final limpio se considera válido. Ese fallo de entorno **no es RED**.

## Capturas PC y medidas reales

Se usó una copia aislada byte idéntica del juego. Un observador temporal externo al repositorio (`/private/tmp/monte-calvo-t001-0pulm9d5/observe.gd` y `observe_v2.gd`) cargó la escena original, leyó estados/señales y guardó `ViewportTexture.get_image()` tras `frame_post_draw`. No añadió fondos, soldados, munición, daño ni alteró velocidad, oleadas o lógica. Son capturas del viewport real renderizado, **no capturas de una interacción manual**. V2 terminó con retorno **0**. V1 registra la observación hasta90 s y la salida prevista por el observador; tras la interrupción del turno, su identificador de proceso ya no estaba disponible para recuperar el código de retorno. No se le atribuye un código no observado.

Invocaciones válidas, desde la raíz (mismo ejecutable):

```text
Godot --path /private/tmp/monte-calvo-t001-0pulm9d5/project --script /private/tmp/monte-calvo-t001-0pulm9d5/observe.gd --windowed --resolution 1152x648 --position 100,100 --log-file <evidence>/pc-v1.log -- prefix=pc-v1
Godot --path /private/tmp/monte-calvo-t001-0pulm9d5/project --script /private/tmp/monte-calvo-t001-0pulm9d5/observe_v2.gd --windowed --resolution 1920x1080 --position 100,100 --log-file <evidence>/pc-v2.log -- prefix=pc-v2
```

| Medida | V1 | V2 |
|---|---|---|
| Ventana y PNG | 1152×648 | 1920×1080 |
| Rectángulo lógico `get_visible_rect()` | (0,0), 1152×648 | (0,0), 1152×648 |
| `canvas_transform` | Identidad | Identidad |
| `stretch_transform` / `screen_transform` | Identidad | Escala uniforme 1.666667, origen (0,0) |
| Renderer / driver | Mobile / Metal | Mobile / Metal |
| Soldado inicial / celda | (576,500) / (6,5) | (576,500) / (6,5) |
| Posición defendida | (576,650) | (576,650) |

V2 **no muestra más mundo**: amplía el mismo espacio lógico. El PNG V2 sitúa visualmente al soldado alrededor de (960,833.33) píxeles por la escala; esto es geometría renderizada y no un clic acreditado. El evento de ratón/toque y su transformación se comprobarán con entrada real durante la integración. No cambiar viewport, cámara, posiciones o tablero para acomodar el arte.

Capturas inspeccionadas: fondo gris actual, enemigo rojo oscuro de 48×48 y soldado blanco de 48×48; pickups amarillos de 32×32 en combate. No hay HUD visible.

| Estado | V1 | V2 |
|---|---|---|
| Inicial, ~0.23 s | [1152×648](pc-v1-0.png) | [1920×1080](pc-v2-0.png) |
| Combate y pickups, ~8 s | [1152×648](pc-v1-1.png) | [1920×1080](pc-v2-1.png) |
| Cuerpo a cuerpo, ~20 s | [1152×648](pc-v1-2.png) | No capturado en V2 |
| Tras derrota, ~40 s | [1152×648](pc-v1-3.png) | No capturado en V2 |

[Telemetría V1](pc-v1.log) y [telemetría V2](pc-v2.log) incluyen tamaños, transformaciones, actores, munición, moral, oleada y estado. Los tiempos son observaciones, no un objetivo de rendimiento ni equivalencia exacta de frames entre ejecuciones.

## Geometría protegida para la guía de producción

Medidas de la escena y recursos originales, conservadas por hashes y observación:

- `Tablero`: transform identidad, TileSet **96×96**, sin celdas pintadas ni límites de región de despliegue. No dibujar cinco carriles ni nuevas casillas o fronteras funcionales.
- Eje de aparición y avance actual **x=576**; aparición configurada **(576,50)**; avance **+Y**. Soldado inicial **(576,500)**, celda **(6,5)**. Su posición no es el centro de esa celda: el centro para un despliegue nuevo en (6,5) es **(624,528)**; conservar ambos comportamientos.
- Collider/placeholder de actores **48×48**: soldado inicial **x552..600, y476..524**; spawn de enemigo **x552..600, y26..74**. Pickups: sprite32×32 y radio de picking20, con centros observados sobre x576.
- Detección del soldado: rectángulo144×240 con offset(0,-144); melee64×64 con offset(0,-32). Son geometría existente, no decoración ni límites de dibujo. Mantener contraste bajo detrás de unidades/pickups y a lo largo del eje; el resto del tablero sigue recibiendo input según sus reglas actuales.
- Defensa: centro **(576,650)**, rectángulo960×64: **x96..1056, y618..682**. Su extremo inferior ya queda fuera del rect lógico PC de altura648. Es una condición previa; no moverla ni agregar una zona jugable o recorte nuevo.
- El encuadre no permite derivar un área de despliegue limitada. Las franjas de protección visual son decisiones artísticas de bajo ruido, sin colisiones ni bloqueo de input.

## Smoke e interacciones

En V1, sin interacción ni mutación del estado por el observador, se observó combate automático, consumo de munición de10 a0, incremento de moral por bajas con rifle, cambio a melee, pickups de3, paso a la oleada2 y muerte del soldado. `GameStateManager` pasó a **LOST (3) a los33.617 s**, y la captura posterior de40 s conserva ese resultado. La observación terminó a90 s. La producción no muestra pantalla de derrota; el observador registra la señal/estado existente. No se atribuye una victoria manual, una partida con diez oleadas ganada ni una pausa automática al estado terminal.

La suite existente comprobó escenarios separados de victoria y derrota y los comportamientos de despliegue libre/con fondos, ocupación, fondos insuficientes, recolección, muerte/liberación y reutilización. La recarga se verifica por los métodos existentes en GUT: no se inventó un control en pantalla. Estos resultados son regresión automatizada, **no prueba manual de picking ni alineación con stretch**.

No hay clic real acreditado para I1–I4/I9 ni nuevos soldados desplegados en las capturas. Quedan por repetir con arte e interacción real los estados previos y coordenadas pantalla/mundo/celda exigidos en `quickstart.md`. No se detiene la producción de arte por no simular esos resultados ahora.

## Dispositivos y límites

- Primera consulta `adb devices -l` (herramienta instalada en el Android SDK local): retorno **0**, lista vacía. ADB inició su daemon local normal; no se instaló ni ejecutó build. Una segunda consulta al cerrar el reporte retornó **0** y detectó por USB un **Xiaomi modelo2107113SG**, producto`vili_eea`, dispositivo`vili`, en estado **device** (ADB autorizado). Se omite el número de serie. No se instaló ni ejecutó build, ni se midieron todavía viewport, toque o rendimiento del teléfono.
- `xcrun devicectl list devices`: retorno **0**, solo equipos marcados **simulated** (iPhone17, iPhone17Pro e iPhone18Pro); no se detectó iOS físico.
- `xcrun simctl list devices available`: la consulta con permisos normales de Xcode retornó **0**; existían simuladores iPhone17Pro/iOS26.5 e iPhone18Pro/iOS27 ya encendidos. No se iniciaron ni instalaron builds. Los intentos iniciales de inventario sin permisos de caché/servicios de Xcode fallaron por entorno y no cuentan como validación.
- **V3 Android físico y V4 iOS con toque: pendientes.** No hay capturas móviles ni medida de carga/VRAM/FPS. El Xiaomi conectado es candidato disponible; falta acordarlo como referencia y registrar sus condiciones de ejecución. Los simuladores no sustituyen esa evidencia física. No se declara60FPS estables.
- Una consulta a UI nativa tardó varios minutos y al terminar la sesión PC ya había cerrado; mostró el administrador de proyectos. No se usa como prueba de gameplay o input.

## Intento de observador descartado

[observer-setup-failed.log](observer-setup-failed.log) corresponde a un primer harness temporal que referenciaba tipos del juego antes de registrar autoloads. Produjo errores de compilación del observador/dependencias y una escena sin actores funcionales; **no es fallo del juego, RED válido, prueba de regresión ni evidencia visual válida**. Se corrigió únicamente el script temporal externo y se cerró ese proceso. Sus capturas se sustituyeron por las de las sesiones válidas descritas arriba; ninguna captura descartada acredita resultados.

## Entrega a QA

Solo se escribieron evidencia y `.gdignore` en este directorio; no se editaron implementación ni tests. QA debe valorar esta entrega como **línea base PC y registro de limitaciones**, sin aprobar móviles, criterios finales de rendimiento, picking manual o la integración futura. Los pendientes permanecen explícitos para T008/T012/T014/T015 y para el orquestador. No se marca ninguna tarea desde este rol.
