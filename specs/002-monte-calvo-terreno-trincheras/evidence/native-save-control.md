# Control diagnóstico del guardado de telemetría Android

**Fuente:** `a473585ca62e3d35fa1d81d47e052646826032c3`, rama `codex/002-monte-calvo-terreno-trincheras`. Control solicitado por QA para investigar la muestra de 54 FPS. Requiere revisión independiente; no aprueba SC-007.

## Método

Una sola sesión automática en el Xiaomi físico por USB, sin interacción. En una copia temporal de `native-final`, el único cambio fue mover el umbral de guardado síncrono del observador de **35 a 45 segundos**. Gameplay, reloj, handlers, entrada, recursos, renderer Mobile/Vulkan, proyecto y presets permanecieron intactos. La espera observada duró **47,005 s**. No hubo eventos inyectados, participación humana ni borrado global de logcat. Solo se capturó el PID propio. No se repitieron GUT ni otros benchmarks.

Xiaomi `2107113SG`, Android 14, Adreno 660, ventana 2400 × 1080 y viewport lógico 1440 × 648. El teléfono estaba despierto, con batería al 100 %, alimentación conectada y temperatura reportada de 34 °C. Se conservaron las preferencias de orientación.

## Observación

| Muestra | Humano original: guarda a 35 s | Control: guarda a 45 s |
|---|---|---|
| FPS a 34 / 35 / 36 / 37 s | 60 / 61 / 54 / 61 | 61 / 60 / 60 / 61 |
| Máximo de proceso en esas muestras | 114,607 ms | 16,833 ms |
| FPS a 45 / 46 / 47 s | 61 / 60 / 61 | 60 / 55 / no registrada |
| Proceso a 46 s | 18,340 ms | 111,074 ms |
| Estado en ambas ventanas | PLAYING | LOST |
| Filas al guardar el JSON | 2099 | 2695 |

El original guardó a 35,000 s y registró 54 FPS / 114,607 ms de proceso a 36,003 s. El control guardó a 45,002 s y registró 55 FPS / 111,074 ms a 46,002 s. La caída se desplazó diez segundos junto con el guardado del instrumento. **Esto es consistente con sobrecarga de serialización y escritura del observador.** Los estados diferentes impiden tratarlo como comparación equivalente de gameplay o excluir concluyentemente otros picos del juego.

## Límites

- El control ya estaba LOST en la muestra de 34,003 s; el humano seguía PLAYING. No se convierten muestras posteriores a derrota en rendimiento de combate.
- La última muestra por segundo del control fue 46,002 s. No se registró una muestra a 47 s; no se inventa recuperación posterior ni se repitió la sesión para obtenerla.
- El JSON por frame termina a 45,002 s antes de la escritura síncrona. Los datos posteriores proceden del log, con muestras por segundo. `delta_ms` es el delta del motor, no una traza independiente de presentación física.
- Entre las muestras por segundo del control posteriores a 5 s, el único valor inferior a 60 fue 55 a 46,002 s. Esto no prueba ausencia de picos entre muestras.
- Este Xiaomi no es la referencia constitucional nominal de gama media de los últimos tres años. No se extrapola a otros modelos ni se certifican 60 FPS estables.

## Restauración y setup

Se reinstaló el APK normal desde una copia de `corrected-final`: **367/367 archivos** coinciden con su manifest antes y después de exportar. No contiene scripts ni nodos de observación. `install -r` terminó con **EXIT 0 / Success** y la consulta posterior de PID dio **EXIT 1 y salida vacía**. El APK normal quedó cerrado y no se abrió después de restaurarlo.

APK normal SHA-256: `ca5c8a276970ca05ede0cb7d599bc75b77352374768c003aa6d7012343cfdf89`. Los dos APK verificaron firmas v2/v3. No se cambiaron firma, versión, presets ni configuración del dispositivo.

Ambas importaciones y exportaciones retornaron 0. Cada export conserva un mensaje de setup ya conocido: «Cannot set object script». Los APK verificaron y el control emitió la instrumentación esperada, sin coincidencias de error crítico en su log; no se reparó ni ocultó el aviso.

## Archivos

[Resumen con muestras, líneas y hashes](native-save-control-summary.json), [procedencia y restauración](native-save-control-provenance.json), [log del control](native-save-control.log), [JSON guardado](native-save-control-telemetry.json), [ejecuciones ADB](native-save-control-adb-executions.json), [único delta](native-save-control-duration.diff) y [fuente del instrumento como texto](native-save-control-telemetry-source.txt).

Se conserva una [copia exacta del raw humano original](native-save-control-original-human.log) para verificar las líneas citadas. El [log humano previamente versionado](native-android-final-human.log) es un filtrado de 207 líneas Godot, todas presentes exactamente en el raw de 440 líneas. Sus hashes difieren por ese filtrado; el [JSON humano](native-android-final-human-telemetry.json) sí coincide byte por byte con el original. Ninguno de los archivos humanos originales se sobrescribió.

No se modificó producción, otros reportes ni tareas, y no se creó ningún commit desde este control.
