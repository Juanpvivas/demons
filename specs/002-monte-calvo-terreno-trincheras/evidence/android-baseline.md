# Android — complemento de T001 anterior al arte

**Fecha**: 2026-10-15. **Rol**: `godot-tester`. No sustituye el [baseline PC](baseline.md) ni su revisión de QA. No se repitió GUT ni se cambió el juego. Este dispositivo está disponible para comparación antes/después; su antigüedad/categoría no se han contrastado y no se lo acredita como referencia objetivo de la constitución.

## Build y dispositivo

- Xiaomi, modelo **2107113SG**, producto`vili_eea`/dispositivo`vili`; Android14/API34, SoC`SM8350`, ABI`arm64-v8a`, GPU **Qualcomm Adreno660**. Se omiten identificadores y números de serie.
- Resolución física consultada:1080×2400; la app se ejecuta horizontal y las capturas son **2400×1080** (~20:9).
- Plantillas locales Godot`4.7.1.stable.mono`, AndroidSDK y Java ya estaban disponibles. No se descargaron ni instalaron herramientas globales.
- Se copió `export_presets.cfg` sin alterarlo al snapshot byte idéntico anterior al arte. Después de exportar, los **97/97 archivos protegidos** del snapshot conservan sus hashes originales.
- Se exportó con el preset existente **Android**, debug, package`com.juanpvivas.demons`, versionCode1/versionName1.0, firma debug existente. `project.godot`, presets, versión y firmas no fueron editados.
- APK temporal: `/private/tmp/monte-calvo-t001-0pulm9d5/baseline-android.apk`; tamaño **30121366 bytes**; SHA-256`94751b36a9014f9387eaaea05df8eea6535c9ce04fbc2f65bc7bb065b96a11cf`. APK, copia del proyecto y logs grandes quedan fuera del repositorio.
- El paquete no estaba instalado antes. Exportación e instalación local retornaron **0** (`Success`; instalación5615ms). No se publicó ni distribuyó el build.

Comandos relevantes (mismas herramientas locales registradas en baseline):

```text
Godot --headless --path <snapshot>/project --export-debug Android <snapshot>/baseline-android.apk --log-file <snapshot>/export-android.log
adb install <snapshot>/baseline-android.apk
adb shell am force-stop com.juanpvivas.demons
adb shell am start -W -n com.juanpvivas.demons/com.godot.game.GodotAppLauncher
adb exec-out screencap -p
```

Todos los comandos finales anteriores retornaron0. Un primer `am start` encontró la app ya abierta y no se usa para medir carga. En el arranque frío controlado siguiente, Android reportó **COLD, TotalTime333ms, WaitTime341ms**: mide arranque de la Activity, **no tiempo hasta gameplay plenamente cargado**. Ese objetivo permanece sin medir.

## Ejecución y encuadre

[Log de motor seleccionado](android-baseline.log): Godot4.7.1mono, **Vulkan1.1.128 / Forward Mobile / Adreno660**. La app carga la escena y dibuja actores y pickups. No se cambió el renderer. Se observan mensajes no fatales de la plantilla/driver (`Unable to load System.Security.Cryptography.Native.Android`, swap behavior y pequeños GraphicBuffer4×4); se conservan como condición de la línea base. No se alteró implementación para silenciarlos.

- [Captura inicial disponible](android-baseline-initial.png),2400×1080, con soldado y enemigo.
- [Captura durante combate](android-baseline-combat.png),2400×1080, aproximadamente8s después del último lanzamiento, con actores y pickups.
- No hay HUD añadido. No hay arte del nuevo terreno en estas capturas.
- La escala observable de los placeholders es aproximadamente80px por48unidades: sugiere factor1.666667 y encuadre lógico **1440×648**, más ancho que PC. Es **inferencia geométrica de la captura**, no lectura de `Viewport.get_visible_rect()` en Android. No se ha instrumentado ni cambiado el juego para obtener esa telemetría. La posición aparente del soldado conserva el eje físico alrededor de(960,833), derivado de(576,500).

## Entrada por toque: bloqueo concreto

Se intentaron toques Android mediante `adb shell input tap` en(200,900) — celda libre con fondos iniciales0 — y(960,833) — soldado inicial. Ambos retornaron **255**. Una consulta posterior confirmó:

```text
java.lang.SecurityException: Injecting input events requires the caller (or the source of the instrumentation, if any) to have the INJECT_EVENTS permission.
```

Los eventos **no se inyectaron**. No se acredita rechazo por fondos, ocupación, recolección ni despliegue con toque. No se cambiaron permisos o ajustes de seguridad para superar el bloqueo. Es posible continuar con toque humano y evidencia coordinada; sigue pendiente V3/I1–I4/I9 con entrada real. Las capturas no sustituyen ese resultado.

## Muestra de presentación de frames

Se consultó la capa `SurfaceView`/BLAST de **esta app** mediante `dumpsys SurfaceFlinger --latency`, tras unos8s de ejecución. La consulta final retornó0; el primer intento usó una capa sin escapar los paréntesis y falló por sintaxis de shell, sin valor de medición. El intento corregido produjo [timestamps](android-baseline-frame-latency.tsv) y [resumen](android-baseline-frame-summary.json).

- **126 intervalos**, ventana **2.083848s**.
- Intervalo medio **16.538473ms**; p95 **16.548490ms**; máximo **16.554322ms**.
- Cadencia estimada de presentación **60.465FPS**;0intervalos por encima de20ms en esta muestra.

Son tiempos de **presentación de SurfaceFlinger**, no tiempos CPU/GPU medidos por Godot. Una ventana de2.08s con pocos actores no demuestra60FPS estables, carga típica sostenida, comportamiento térmico o rendimiento de la futura decoración. No se midieron memoria de texturas/VRAM ni carga completa. Para T015 hay que repetir condiciones y ampliar duración/carga antes de cualquier conclusión de rendimiento.

## Estado entregado

Baseline Android real disponible para comparar visualmente. Pendientes: viewport lógico medido directamente, input humano/picking, carga completa, memoria y rendimiento sostenido antes/después; iOS físico sigue pendiente. No se marca ninguna tarea ni se solicita aprobar estos pendientes por el simple hecho de que la app arrancó.
