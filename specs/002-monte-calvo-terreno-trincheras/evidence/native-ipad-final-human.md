# V4 iPad Simulator — sesión humana final con arte

**I1/I3 y ruta touch/mouse observados; I2/I4/I9 discriminantes no demostrados en esta sesión.** La confirmación «Completé los seis pasos» se registra como relato, sin sustituir PRE/POST.

Se recuperó sin recargar, detener o rotar la app: [raw](native-ipad-final-human.log), [derivado](native-ipad-final-human-derived.json), [hashes de app realmente instalada](native-ipad-final-human-installed-proof.json), [captura de objetivo](native-ipad-final-human-current.png)/[metadatos](native-ipad-final-human-capture.json). Una sesión nuevaINITIAL688ms,28PRE/28POST, raw57572bytes/SHA`e3a403983d1ac083790c6a7c70b3659268ff328cea258685994bd6c7d174f1f4`. Se conservan los avisos de mouse_get_position; no se afirma runtime sin errores. No se usaFPSdel simulador paraSC007.

iPadPro13M5/iPadOS27.0, Compatibility/OpenGL3/AppleSoftwareRenderer, binarioarm64 compilado desde4.7.1tag sinparches; scriptdeproducción4e89dce…/observerc628…/logger estándar temporal según [proveniencia](native-ipad-setup.md). Viewport1152×864, canvasidentidad, render2752×2064/stretch2.388889. Las coordenadas del observer son viewport lógico=mundo; celda=floor(posición/96). EjemploA(244.47,539.58) corresponde aproximadamente a píxelrender(584,1289), mundoigual y celda2,5; píxeles se derivan delstretch, no son coordenadasglobalesmacOS registradas. El frontend fue girado por la persona, sin eventosCG/TCC/modificación dejuego por tester.

| Caso | PRE→POST | Resultado |
|---|---|---|
| I3, A libre seq3/4 y5/6 | `(234.84,524.93)`/celda2,5, reserva0→0, soldados1→1, PLAYING | PASS observado |
| Recogidas seq7/8–13/14 | 0→3→6→9→12, sin unidad adicional, PLAYING | Recogida real; todos pre<10 |
| I1, A seq15/16 | `(244.47,539.58)`, celda2,5 libre,12→2 y1→2, nuevo centro240,528, PLAYING | PASS observado: costo10 y una unidad |
| I4, seq17/18 | `(587.72,462.14)`,2→8; dospickups de3solapados,1→1soldados, PLAYING | Parcial: pre<10; no caso discriminante de fondos suficientes |
| I2, A seq19/20 | Celda2,5ocupada,8→8/1→1, estadoLOST | NOT DEMONSTRATED: fondos<10 y fuera dePLAYING |
| I9, últimosgestos | Incluye `(140.23,220.60)`/celda1,2,8→8/1→1, LOST | NOT DEMONSTRATED: fuera dePLAYING y sinfondos |

Cada par mouse/touch deigualposición y≤40ms se trata como **un gesto humano sobre simulador**, no dos clics independientes ni toque físicoiOS. El PRE más temprano y POST más tardío conserva el efecto total. Los depósitos solapados mantienen su suma real, sin reduciramount para obtener un resultado deseado. El soldado inicial murióentre gestos; el recuento se conserva en cada par y no se atribuye al arte.

Esta sesión no reproduce un fallo de lógica: faltan estados discriminantes paraI2/I4/I9. [AVD antes/después](native-avd-input.md) los cubre en su vía autorizada sin rellenar silenciosamente casillas deV4. Comparación humanaBASE con mismoarreglo/logger y cualquier mínimo finalpendiente se coordinan por el orquestador antes de volver a iniciar; no hay reintento automático. HardwareiOS permanece no probado.
