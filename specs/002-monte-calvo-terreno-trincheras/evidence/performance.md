# T015 — Rendimiento disponible: comparación Android antes/después

**Fecha**:2026-10-16UTC/2026-10-15Bogotá. **Rol**:`godot-tester`. Preparación de la comparación T015 por autorización del orquestador; **no es aprobación deT015 ni de la entrega**. La composición final se midió con el mismo protocolo de autoplay; los límites de aceptación global permanecen explícitos.

## Condiciones y método repetible

- Xiaomi2107113SG, Android14/API34, Adreno660; USB conectado, app horizontal2400×1080. Dispositivo disponible; antigüedad/categoría no verificada como referencia objetivo de la constitución.
- APK debug original del snapshot anterior al arte, identificado en [android-baseline.md](android-baseline.md), mismo package/versión/configuración/renderer **Mobile/Vulkan**. No se modificaron presets, firma, versión o ajustes.
- Se hizo `am force-stop` y lanzamiento frío `am start -W` del juego; retorno **0**, inicio01:13:37UTC. No se inyectó input ni se tocó la pantalla por parte del agente durante la medición. No se alteró el estado del juego para aumentar o reducir carga.
- Desde aproximadamente8s hasta38s tras el lanzamiento, se consultó cada1s `dumpsys SurfaceFlinger --latency` exclusivamente para la capaSurfaceView/BLAST del juego.31consultas, todas retorno0. Se leyó la segunda columna, timestamp de presentación, descartando0/sentinelas; se deduplicaron los buffers solapados.
- La primera lectura fijó el inicio en su timestamp válido más reciente; solo se incluyeron presentaciones desde ese punto. Así no se suman ventanas repetidas ni se incorporan los2s de historial previos al inicio. Separación máxima entre consultas:1.044s, menor que la ventana del buffer observado de~127frames.
- Se tomó `dumpsys meminfo com.juanpvivas.demons` aproximadamente a8s y38s. SonPSS/RSS totales del proceso, **noVRAM ni memoria de texturas**.

Datos brutos y comandos/resultados: `/private/tmp/monte-calvo-t001-0pulm9d5/performance-baseline/` (`latency-00..30.txt`, `present-timestamps.txt`, `intervals-ms.txt`, `meminfo-00.txt`, `meminfo-30.txt`, `launch.txt` y `summary.json`). [Resumen limpio](performance-baseline-summary.json), sin seriales ni datos ajenos a la app. No se guardanAPK ni logs grandes en el repositorio.

## Resultado baseline medido

| Métrica | Baseline sin arte | Arte final |
|---|---:|---|
| Ventana de presentación cubierta |30.001259s|30.002266s|
| Intervalos únicos |1814|1814|
| Intervalo medio |16.538732ms|16.539286ms|
| p95 |16.682812ms|16.637448ms|
| p99 |16.884323ms|16.832552ms|
| Máximo observado |17.075677ms|17.027291ms|
| Cadencia estimada de presentación |60.464FPS|60.462FPS|
| Intervalos>20ms / >33.334ms |0 / 0|0 / 0|
| PSS total, alrededor de8s |246,034KiB|250,613KiB|
| PSS total, alrededor de38s |240,741KiB|245,761KiB|
| RSS total, alrededor de8s |364,552KiB|368,608KiB|
| RSS total, alrededor de38s |359,656KiB|364,264KiB|

Los percentiles usan el elemento de rango inferior de los intervalos ordenados, sin interpolación. La cadencia es1000/intervalo medio, no un contadorFPS instrumentado en Godot. Esta muestra amplía la observación inicial de2.08s; ambas quedan registradas con su alcance distinto.

## Interpretación y pendientes

La muestra representa **autoplay sin interacción**, con combate inicial y la carga que sigue naturalmente. La línea basePC observó derrota alrededor de33.6s; no se instrumentó Android para asignar el instante exacto de su estado terminal. La ventana de8..38s puede incluir transición a derrota/continuación del motor; **no representa diez oleadas, partida ganada, carga máxima o gameplay típico sostenido**. Se repitió el mismo protocolo de autoplay después del arte para comparar condiciones próximas.

No se afirma60FPS estables constitucionales a partir de esta ventana, aunque no hubo intervalos>20ms aquí. SurfaceFlinger mide presentación; faltan tiemposCPU/GPU de Godot, perfiles sostenidos/temperatura y más carga. El estado térmico, brillo y actividad ajena al juego no se controlaron ni midieron; el orden antes/después y la firma debug limitan cualquier inferencia de causalidad o rendimiento de producción.

Pendientes: memoria de texturas/VRAM real, carga completa hasta gameplay, resto de condiciones/plataformas de la matriz y veredicto deQA. Los tiempos de Activity anteriores no sustituyen carga completa. La importación y la suite final se registran de forma separada en regression.md.

## Medición final y trazabilidad del APK

Exportación localdebug e instalación`adb install -r` retornaron **0**, sin cambiar package`com.juanpvivas.demons`, versionCode1/versionName1.0, firma o configuración. APKfinaltemporal`/private/tmp/monte-calvo-t001-0pulm9d5/final-android.apk`, **34767152bytes**, SHA-256`5eb379caf9ec5a64be571e75612064d9f748eaf1f9f4f92749cd8b2306ae8647`. Logs de exportación fuera del repositorio; no se publicó el build. Estado de origen: [final-sha256.json](final-sha256.json).

La repetición comparable final inició **01:19:34UTC**, leyó31buffers entre aproximadamente8..38s, todos retorno0. [Resumen final](performance-final-summary.json); datos brutos en`/private/tmp/monte-calvo-t001-0pulm9d5/performance-final/`. No hubo inyección de entrada ni modificación de estado. El orquestador indicó a la persona dejar el teléfono sin tocar durante la medición; no se instrumentó registro continuo de eventos humanos. Las capturas disponibles de una sesión final previa muestran un único soldado inicial, sin indicios de unidades extra en esas imágenes; no acreditan ausencia continua de toque.

Hubo un intento final previo con capturas antes de la ventana de medición. Esa transferencia retrasó la primera lectura a9.693s y produjo28.397s de cobertura; **no se usó para la columna final comparable**. Se conserva en`performance-final-preliminary/`fuera del repositorio y se repitió una sola vez omitiendo capturas previas. Las capturas [fase inicial](android-final-initial.png) y [avance/combate](android-final-combat.png) provienen de ese intento previo y son válidas para render2400×1080, sin usarlas para afirmar equivalencia de tiempos o interacción. El momento exacto de captura no se instrumentó; las solicitudes eran alrededor de2s y7.5s, con el retraso documentado.

Comparación disponible: intervalo medio 16.538732→16.539286ms; diferencia **+0.000555ms**. PSSa~8s aumentó **+4,579KiB** y a~38s **+5,020KiB**. En ambas ventanas no hubo intervalos>20ms. Se registra una muestra de presentación comparable sin caída perceptible de cadencia; **no demuestra ausencia de regresión bajo toda carga ni permite atribuir el deltaPSS exclusivamente a texturas**.

Las texturas estimadas comoRGBA8sinmipmaps suman~17.999MiB, más un gradiente16×256 (~16KiB). Es presupuesto teórico, distinto dePSS/RSS yVRAM real. Los11sprites del atlas comparten una hoja; no se multiplicó el costo de esa textura por11en el cálculo.

PCV1/V2están cubiertos visualmente en[us3.md](us3.md), sin benchmarkPC. Android físico tiene render/cadencia/PSS disponibles y prueba humana por separado; iOS físico **no disponible y pendiente**, sin nuevas configuraciones/exploración. Faltan carga completa,VRAM real, medición sostenida bajo carga representativa y referencia de dispositivo objetivo contrastada. No se certifican60FPSestables constitucionales ni se marcaT015como globalmente completa con estos datos.

## Sesión humana separada

Después de terminar las mediciones se reinició la app para la [prueba humana final](android-human-final.md). La confirmación de recolección/despliegue y ausencia observada de duplicación se limita a esa sesión; no se incorpora a las cifras de autoplay ni completa la matriz física controlada.

## Reanudación 2026-10-16 — mediciones Godot y referencia provisional002

La [comparación física actual](native-device-performance.md) sustituye los huecos de medición de esta preparación: mismo arregloI4/observer/viewport antes ydespués, dosautoplays, análisisPLAYING5–30s. GodotFPS mínimo60 ambos; delta p9516.667ms y máximo16.667→24.453ms; renderGPU p50 0.473→2.648ms/p950.480→2.852ms; texturas12,656,000→31,886,720bytes, PSS267001→278675KiB. Carga deactividadAndroid613/487ms y primerpost-draw motor1054/1240ms tienen alcances distintos y cachésnocontroladas; no se declara cargafríacompleta certificada.

Se añade sin nuevaejecución la [sesión humana≈50s](native-human-performance.md), con recolección/despliegue y su serie cruda. Se preserva54FPS/TIME_PROCESS114.607ms a36s. El [control único del guardado](native-save-control.md) desplaza serialización35→45s y la caída a46s/55FPS/111.074ms;34–37s informan61/60/60/61FPS. ControlyaLOST frente ahumanoPLAYING: limita inferencia, sin ocultarlo. No se afirma cero caídas ni ausencia de todos los frames largos.

La persona autorizó el **Xiaomi11TPro/2107113SG de2021 como referencia provisional exclusiva de002** (constitución1.2.0). QA aprobóSC-007 para ese alcance al revisar comparación, sesión humana y control del instrumento; no extrapola a otrosmóviles ni cambia el objetivo60FPS. [APKnormal restaurado/sin abrir](native-save-control.md), sin observer ni etiquetas. T015 completo sigue pendiente de consolidación y matricesPC/iOS; hardwareiOS no probado. [V4simulador](native-ipad-setup.md) usa Compatibility/AppleSoftwareRenderer para imagen/input y no se compara como rendimiento de un iPhone físico.

### V4 y pendiente de cierre — 2026-10-16

[iPadSimulator](native-ipad-setup.md) ya tiene el mínimo de entrada aprobado por QA, incluida [I4 BASE/FINAL](native-ipad-final-i4-human.md), con render Compatibility temporal/AppleSoftwareRenderer. Sus lecturas5–8FPS no se usan para SC-007 ni se comparan con el Xiaomi físico Mobile/Vulkan. La aceptación SC-007 exclusiva de002/Xiaomi provisional conserva el [control de guardado](native-save-control.md), el valle crudo54/55FPS y el frame24,453ms: no significa cero caídas, certificación de otro móvil o carga fría absoluta. No se hicieron más benchmarks. La consolidación global T015 espera ratón PC y revisión final de [matriz](native-validation-matrix.md), sin convertir esa espera en una carencia de rendimiento ya medida.

### Estado vigente de matriz y entrega — 2026-10-16

QA ya aprobó los mínimos de [ratónPC BASE/FINAL](native-pc-arte-cd-human.md) y [V4iPad](native-ipad-setup.md), además deAVD/muestreoXiaomi. Por tanto, la espera de ratón descrita en la actualización anterior está resuelta; [matriz consolidada](native-validation-matrix.md) y evidencia deT015 quedan listas para auditoría T016, sin otro benchmark. SC-007 conserva exclusivamente el dictamen002/Xiaomi provisional ya recibido, no cero caídas o certificación de otrasplataformas. Carga fríaabsoluta, memoriaexclusiva exactaGPU y hardwareiOS siguen sin certificación, sin convertirlos en métricasinventadas. Los54/55FPS, pico24,453ms, seleccionesPLAYING y controlLOSTsiguen íntegros.
