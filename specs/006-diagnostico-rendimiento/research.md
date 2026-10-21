# Research: Decisiones para I1

La preparación partió de `5d50cb0`, sin pruebas ni mediciones en esa etapa. Las hipótesis de la tabla proceden de la revisión de sólo lectura de dev-godot y el protocolo de godot-tester. Se consultaron `using-godot-prompter` y `godot-optimization`; cada ejecutor consulta además sus skills específicas.

| Decisión | Motivo y alternativa descartada |
|---|---|
| Tres destinos separados | Software/emulación no predicen hardware. No mezclar la muestra Android 1152×648 con la caída a 2400×1080 ni considerar el simulador como un iPad físico. |
| Fixture render constante + producción aparte | La población dinámica y los snapshots vacíos invalidaron comparaciones previas. La escena congelada no mide CPU del gameplay ni acredita una partida de producción. |
| Repeticiones alternadas y oráculo independiente | Tres ventanas por variante y mismo manifiesto permiten observar dispersión. El expected no se obtiene de la misma función que se quiere validar. |
| Probe pequeño/optativo | Se versiona sólo cálculo, validación y lectura reutilizables; montaje/collector de experimentos en temporales. Sin framework ni instrumentación activa en el juego normal. |
| Primer candidato: shader de legibilidad | La revisión encontró una lectura central y cuatro vecinas. En alfa central cero, el cálculo de borde no aporta color visible; un salto condicional puede evitar esas lecturas conservando salida. El compilador puede aplanarlo: medir antes de afirmar ahorro. |
| Otros costes como hipótesis | Consultas físicas/colisiones y animaciones por caja son posibilidades; no se modifican en I1 por intuición. El pulso y tamaño actuales permanecen. |
| Separar pacing/foco de coste | Los ~150 ms casi constantes de iOS justifican probar foco/límite/vsync en una copia diagnóstica, sin modificar el producto ni atribuirlo aún al shader. |
| Monitores con significado explícito | `TIME_PROCESS` es tiempo de completar el frame; no Self de GDScript ni tiempo GPU aislado. Cero/ausencia puede significar no disponible y las actualizaciones pueden ser más lentas que cada frame. |

Se mantienen los límites e hipótesis históricas de [SPEC §8](../../docs/SPEC.md#8-arte-y-estilo-visual). El coste CPU/GPU se atribuye sólo con profiler apropiado o experimento que lo aísle; en otro caso se informa coste de frame/presentación sin dividirlo artificialmente. Memoria de motor/render no es RSS ni coste causal exclusivo del PNG.

## Decisión de T009: entregar diagnóstico sin parche

Las nuevas comparaciones Web no distinguen ganancia al retirar el material ni coste del observador respecto a la dispersión/cadencia. Esto no demuestra coste cero del shader. Android muestra deriva entre repeticiones y sólo permite descripción; no se atribuye su diferencia al material. El bloqueo del Mac impidió nuevas ejecuciones iOS. Se conserva el shader, el pulso, el tamaño, las reglas y los presets; T008/SC-001 nativos y US2 siguen pendientes.

En el motor exacto `a13da4feb8d8aefc283c3763d33a2f170a18d541`, `window_is_focused()` devuelve `true` fijo en Android y AppleEmbedded; sin contexto RenderingDevice, el getter de vsync devuelve `VSYNC_ENABLED` y su setter no actúa. Fuentes primarias: [Android](https://github.com/godotengine/godot/blob/a13da4feb8d8aefc283c3763d33a2f170a18d541/platform/android/display_server_android.cpp#L581) y [AppleEmbedded](https://github.com/godotengine/godot/blob/a13da4feb8d8aefc283c3763d33a2f170a18d541/drivers/apple_embedded/display_server_apple_embedded.mm#L607). Por ello, un informe mecánicamente válido no acredita foco/vsync efectivos ni comparabilidad causal nativa. La siguiente medición requiere una observación independiente que resuelva esa limitación; no se cambia renderer o motor para ocultarla.

El instrumento permanece optativo y aprobado para integración; la estabilización del producto no está acreditada. Resultados, dispersión, picos, intentos inválidos y límites se resumen en el PR, con registros fuera de Git. La corrección de una espera arbitraria en una prueba histórica estabiliza el test, no el rendimiento del juego.
