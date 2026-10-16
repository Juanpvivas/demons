# Validación nativa 002 — comparación física, 2026-10-16

Estado: comparación física y SC-007 aprobados por QA para la referencia provisional exclusiva002; T015 y la feature conservan sus pendientes de matrizPC/iOS.

## Fuente y método

Dos copias temporales, anterior al arte y final, con **el mismo arreglo I4** de `a473585ca62e3d35fa1d81d47e052646826032c3`, script `4e89dce236868c4203079e06937b5c8dbcbbd564382f373d2216d4aa8c700d7f`. La línea base histórica fallida se conserva por separado. [Manifiesto APK](native-android-build-manifest.json), [proveniencia completa](native-observer-provenance.json), [exportaciones](native-exports.json), [ejecuciones físicas](native-android-executions.json).

Se reutiliza sin cambios el [observador003 aprobado](native-observer-base.gd), SHA `c628c721ec12ba7c922545787134bae6b86808dbdc9d0c5669945b4e3d15fc90`, y se extiende con [lecturas de telemetría002](native-observer-telemetry.gd), SHA `2fbdb3c09e002b9d35cf85da77ef20bd715b266a824341c4f793729372578634`. Sus etiquetas tienen `MOUSE_FILTER_IGNORE` y `FOCUS_NONE`; no consumen/injectan eventos, no cambian estado, recompensas, tiempos, geometría ni pausas. Solo la copia añade un nodo observador y activa medición del viewport. El coste de etiquetas, muestreo por frame y escritura diagnóstica está presente en ambas variantes. No se añade HUD al producto.

Dispositivo físico **Xiaomi 11T Pro (2107113SG), Android14, Snapdragon888/Adreno660**, Godot `4.7.1.stable.mono.official.a13da4feb`, **Mobile/Vulkan**. Pantalla `2400×1080`; viewport lógico `1440×648`, stretch `1.666667`, sin transform de canvas. No se añadieron límites al tablero. Se conservaron `accelerometer_rotation=1/user_rotation=0`; no se inyectaron toques ni se grabó video. No hay `INPUT_PRE` en ninguno de los logs; se observó un soldado y la partida llegó naturalmente a derrota después de la ventana analizada.

Una ejecución por variante, en orden anterior→final. Instalación debug temporal, lectura de telemetría y PSS: retorno0. APKs firmados y verificación local0. `am start -W` reportó COLD/613ms y COLD/487ms, respectivamente: son tiempos de actividad Android, **no carga fría certificada hasta gameplay**. Caché del sistema y condiciones térmicas no controladas. Un intento inicial usó el nombre histórico de actividad incorrecto, sin proceso ni capturas; se descartó como preparación fallida. La actividad resuelta real es `com.godot.game.GodotAppLauncher`.

## Resultados

Análisis de **5 a30 segundos, solo estado PLAYING**: 1506 muestras antes y1513 después. Filas completas conservadas en [anterior](native-android-baseline-telemetry.json) y [final](native-android-final-telemetry.json), con [resumen calculado](native-android-profile-summary.json). Las muestras posteriores a derrota no forman parte de esta tabla.

| Lectura | Anterior al arte | Arte final |
|---|---:|---:|
| FPS informados por Godot, mínimo / mediana | 60 /61 | 60 /60 |
| Delta de proceso p95 / máximo (ms) | 16.667 /16.667 | 16.667 /24.453 |
| Tiempo de proceso p50 /p95 (ms) | 16.923 /22.753 | 16.619 /18.281 |
| Tiempo de física p50 /p95 (ms) | 2.371 /3.934 | 2.098 /5.274 |
| Preparación de render CPU p50 /p95 (ms) | 0.040 /0.059 | 0.042 /0.060 |
| Render del viewport CPU p50 /p95 (ms) | 0.554 /1.275 | 0.656 /1.444 |
| Render del viewport GPU p50 /p95 (ms) | 0.473 /0.480 | 2.648 /2.852 |
| Memoria de texturas informada (bytes) | 12,656,000 | 31,886,720 |
| Memoria de video informada (bytes) | 39,220,288 | 64,742,464 |
| PSS total tras la ventana (KiB) | 267,001 | 278,675 |
| Primer post-draw, reloj del motor (ms) | 1054 | 1240 |
| Ready del observador→post-draw (ms) | 17.634 | 18.018 |

El incremento observado de texturas es **19,230,720bytes**; PSS aumenta11,674KiB. Los contadores de textura/video son asignaciones informadas por el renderizador, no una auditoría de memoria exclusiva del controlador. PSS abarca todo el proceso instrumentado. `TIME_PROCESS` mide duración de proceso del motor, no uso exclusivo de CPU. Los tiempos GPU son lecturas reales no nulas del viewport Vulkan. No se comparan estas cifras con backends de simuladores.

Se observa un coste mayor de GPU y memoria tras incorporar arte, manteniendo 60–61FPS informados durante la muestra corta. No es una sesión típica sostenida de diez oleadas ni demuestra ausencia de frames largos: el máximo final fue24.453ms. No se deduce causalidad de la diferencia de tiempos de carga entre dos únicos arranques.

## Evidencia visual y límites

Capturas sin gestos: [antes8s](native-android-baseline-8s.png), [antes18s](native-android-baseline-18s.png), [antes30s](native-android-baseline-30s.png); [final8s](native-android-final-8s.png), [final18s](native-android-final-18s.png), [final30s](native-android-final-30s.png). Actores y pickups conservan ubicación/escala; montañas y trinchera renderizan sin huecos o halos negros evidentes en estas vistas. La legibilidad está cubierta visualmente; esto no acredita picking físico.

El [11T Pro](https://www.mi.com/sg/product/xiaomi-11t-pro/specs/) pertenece a la [generación de septiembre2021](https://www.mi.com/es/service/support/sales2021/serie-xiaomi-11t.html). **No es la referencia nominal constitucional de gama media de los últimos~3años**; Android14 no cambia esa generación. La persona autorizó este Xiaomi como referencia provisional exclusiva002 y QA aprobóSC-007 después de revisar comparación, sesión humana y [control del guardado](native-save-control.md); no es aprobación automática ni inferencia de conservadurismo por antigüedad. Faltan matrices de gestos nativos V1/V3 y V4; las pruebas automatizadas189/189 se documentan aparte en [T021](t021-green.md).

## iOS Simulator: bloqueo real de entorno

Antecedente: V4 **no se ejecutó en el primer intento**; el bloqueo original se resolvió después según [preparación iPad actual](native-ipad-setup.md). Se exportaron ambas composiciones con Compatibility **solo en copias temporales**, siguiendo la [limitación oficial del simulador](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_ios.html); el proyecto/preset y Mobile de producción permanecieron intactos. El auxiliar compiló únicamente la anterior, Debug/arm64/genéricoSimulator/sin firma: **EXIT65**. La biblioteca Godot del simulador es realmente x86_64-only aunque el Info.plist del xcframework anuncia arm64+x86_64; el linker ignora2307objetos y no resuelve `_main`. El paquete estándar oficial ya disponible presenta la misma arquitectura real. Xcode27.0/SDKSimulator27.0 ofrece22destinos concretos disponibles arm64, además de2placeholders y ninguno x86_64/Rosetta. No se repitió un build idénticamente bloqueado de la composición final; no hubo instalación, launch o gesto iOS.

[Resumen auxiliar y hashes](ios-simulator-build-summary.json), [extracto crítico del linker](ios-simulator-linker-excerpt.log). Fuente completa temporal `/private/tmp/demons-ios-sim-build-002-gvvh8iow/build-baseline.log`, SHA `4e756607dd93856826676ea30b442bfa46580aee180ec2e0e62eec7e3273bed1`. Los55archivos de cada export permanecieron idénticos al manifiesto tras el intento. No se descargó ni instaló runtime/toolchain; iOS físico y su renderer Mobile continúan no probados.

Actualización posterior: el orquestador autorizó al auxiliar intentar una plantilla Simulator arm64 local desde el tag oficial4.7.1, sin parches y con dependencias temporales, para resolver el defecto de empaquetado [upstream122379](https://github.com/godotengine/godot/issues/122379). Ese intento aún no aporta una app o validación V4; no sustituye el bloqueo anterior ni se atribuye un resultado antes de ejecutarlo.

Estado posterior de V4: bibliotecaarm64 local desde tagoficial sinparches permitióbuild/render; [registroiPad](native-ipad-setup.md). La sesiónhumana permanecependiente, sin deducirPASSde compilar. [Complemento humano Android](native-human-performance.md) y [controlúnico](native-save-control.md) conservan el valle de54/55FPS y su interpretación, sin nuevas mediciones por rutina.
