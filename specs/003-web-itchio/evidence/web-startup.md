# T005 — Primer arranque Web de Monte Calvo

Fecha local: 2026-10-15; registros de navegador en UTC del 2026-10-16.
Rama `codex/003-web-itchio`, HEAD documental `b29c6f8`, juego base `b670d86`.
Resultado del tester: **PASS W01** en Chrome escritorio, pendiente del
veredicto independiente de QA. No acredita interacción US2 ni entrega final.

## Ejecución y primer fallo preservado

Motor estándar portable `4.7.1.stable.official.a13da4feb`, templates de la
misma versión descritos en [toolchain.md](toolchain.md). Se ejecutó desde la
raíz, usando el binario local referido allí:

```text
Godot --headless --path . --import --quit-after 2 --log-file <evidence>/web-import.log
Godot --headless --path . --export-release Web build/web/index.html --log-file <evidence>/web-export.log
```

Importación inicial **retorno 0**, con caché de desarrollo disponible; no se
presenta como importación limpia nueva. La importación limpia y GUT 183/183
de T002 se conservan en [baseline.md](baseline.md), sin repetir la suite por
el cambio de preset.

El primer export con `export_filter="scenes"` retornó **0**, pero omitió
dependencias cargadas desde GDScript: BoardManager, ObjectPool, WaveSpawner,
WaveData/WaveSpawnEntry, AmmoPickup y las diez oleadas. El PCK tenía 38
archivos. Chrome mostró errores de análisis/carga y no inició combate. Es un
fallo de configuración de exportación, **no evidencia RED de gameplay**.

Se conservan [log de export](web-export-attempt1.log),
[inventario PCK](web-pck-attempt1.json),
[inspección PCK](web-pck-inspection-attempt1.log),
[consola](web-attempt1-console.json) y [captura](web-attempt1.jpg).
La inspección nativa también retornó 0 pese a errores de autoload; el código
de salida por sí solo no acreditó éxito. La salida completa anterior queda
en `/private/tmp/demons-web-baseline-2j6an1k9/web-attempt1/`.

Dev corrigió el filtro a `all_resources` y exclusiones explícitas. Se repitió
solo el export necesario: **retorno 0**, [log corregido](web-export.log).
No se modificó implementación ni pruebas por el tester.

## PCK y paquete inicial

Se montó el PCK en un directorio temporal vacío con `--main-pack`, mediante
un inspector temporal fuera del repositorio; no se listó el proyecto fuente
como sustituto del paquete. La segunda inspección retornó **0**, sin errores:
[log](web-pck-inspection.log), [lista completa](web-pck-inventory.json).

- **78 archivos**: clases globales, autoloads, BoardManager/ObjectPool,
  WaveSpawner, AmmoPickup, escenas, tres texturas y diez oleadas presentes.
  Las escenas/Resources usan las remap y recursos binarios de Godot.
- Ninguna ruta de tests, addons/GUT, specs, docs, tools, configuración de
  agentes/Spec Kit/CI, `build/`, SOURCES.md ni credenciales en el listado real.
- `index.html`, JS, WASM, PCK, iconos y worklets presentes. Servidor limitado a
  `build/web`, ligado a `127.0.0.1:8060`; nunca se sirvió la raíz del repositorio.
- ZIP **de inspección** `build/web-t005-inspection.zip`: index.html en raíz,
  12 miembros, 14 863 752 bytes. Carpeta actual: 44 552 333 bytes.
  [Manifest de tamaños/hashes](web-export-manifest.json).
- Este reexport generó tres sidecars `.png.import` al reexaminar la salida
  previa. No son necesarios para el navegador. T009/T010 deben producir e
  inspeccionar una salida limpia sin estos residuos, revisar licencias y
  servir el ZIP extraído. **Este ZIP no es la entrega final**.

## Tres cargas reales en Chrome

Chrome **155.0.8059.84**, pestaña visible, servidor HTTP local. Se usaron
recargas completas del documento, creando partidas nuevas sin clics/taps de
gameplay. Mismo perfil; **no se vació la caché del navegador**. La primera
carga corregida volvió a transferir recursos HTTP 200; las siguientes
revalidaron con 304. No se llama a esto una medición de caché fría.

| Carga | Inicio UTC | Canvas real/CSS | Resultado y evidencia |
|---|---|---|---|
| 1 | 03:25:36.904 | 1152×648 / 1152×648; origen 0,0 | Arte, enemigos y munición visibles; [datos/consola](web-load1.json), [captura](web-load1-1152x648.jpg) |
| 2 | 03:26:12.358 | 960×540 / 960×540; origen 0,0 | Combate y pickups visibles a escala 5/6; [datos/consola](web-load2.json), [captura](web-load2-960x540.jpg) |
| 3 | 03:26:32.521 | 960×540 / 960×540; origen 0,0 | Nueva partida y combate sin fallo crítico; [datos/consola](web-load3.json), [captura](web-load3-960x540.jpg) |

Las tres consolas nuevas contienen únicamente identificación del motor,
**WebGL 2.0 / Compatibility**, y `single-threaded, no GDExtension support`;
sin errores críticos ni recursos ausentes. Se filtran por inicio de cada
documento para no confundir los errores históricos del primer intento.
[Tramo de red preservado de la tercera carga](web-network-observed.log):
HTML, PNG, JS, WASM, PCK, icono y ambos worklets responden 304 correctamente.
No se requirió COOP/COEP, service worker ni extensiones.

La frase DOM «Your browser does not support the canvas tag» es el texto
alternativo dentro del canvas; las capturas y el renderer confirman que el
canvas sí funciona. Se restauró el viewport temporal y se dejó abierto el
preview `http://127.0.0.1:8060/`.

## Conservación y límites

[Comparación verificable](web-invariants.json) contra los 110 hashes T002:
**108/110 idénticos**; solo cambian `project.godot` y `export_presets.cfg`,
las dos configuraciones autorizadas. Escenas, scripts, arte, Resources y
pruebas permanecen idénticos. InputMap y todos los valores de presets nativos
Android/iOS se conservan; se compararon claves/valores ignorando comentarios.
Renderer global `mobile` conservado; única adición de rendering:
`renderer/rendering_method.web="gl_compatibility"`.

W06 queda **parcial**: render en ambos tamaños comprobado, clic posterior a
resize aún NOT RUN. W02–W05, W07–W12, iframe, Android Web, otros navegadores,
rendimiento, ZIP final/CI y difusión quedan pendientes de sus tareas. No se
atribuyen FPS estables ni soporte universal. No hubo carga en itch.io ni
cambio de estados históricos de 002.
