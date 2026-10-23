# Research: Decisiones de diagnóstico

La preparación de I1 partió de `5d50cb0`, sin pruebas ni mediciones en esa etapa. Las hipótesis de la tabla proceden de la revisión de sólo lectura de dev-godot y el protocolo de godot-tester. Se consultaron `using-godot-prompter` y `godot-optimization`; cada ejecutor consulta además sus skills específicas.

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

Las nuevas comparaciones Web no distinguen ganancia al retirar el material ni coste del observador respecto a la dispersión/cadencia. Esto no demuestra coste cero del shader. Android muestra deriva entre repeticiones y sólo permite descripción; no se atribuye su diferencia al material. Tras resolver el bloqueo inicial del Mac, tres ventanas de iPad Simulator/Apple Software Renderer registran medias de 150,12–150,92 ms por frame. Son descriptivas: foco/vsync efectivos no disponibles, condiciones esperadas vacías e informe del probe inválido de forma intencional; los intervalos y el resumen proceden del collector independiente. No acreditan una base causal ni explican ese rendimiento. Se conserva el shader, el pulso, el tamaño, las reglas y los presets; T008/SC-001 nativos y US2 siguen pendientes.

En el motor exacto `a13da4feb8d8aefc283c3763d33a2f170a18d541`, `window_is_focused()` devuelve `true` fijo en Android y AppleEmbedded; sin contexto RenderingDevice, el getter de vsync devuelve `VSYNC_ENABLED` y su setter no actúa. Fuentes primarias: [Android](https://github.com/godotengine/godot/blob/a13da4feb8d8aefc283c3763d33a2f170a18d541/platform/android/display_server_android.cpp#L581) y [AppleEmbedded](https://github.com/godotengine/godot/blob/a13da4feb8d8aefc283c3763d33a2f170a18d541/drivers/apple_embedded/display_server_apple_embedded.mm#L607). Por ello, un informe mecánicamente válido no acredita foco/vsync efectivos ni comparabilidad causal nativa. La siguiente medición requiere una observación independiente que resuelva esa limitación; no se cambia renderer o motor para ocultarla.

El instrumento permanece optativo y aprobado para integración; la estabilización del producto no está acreditada. Resultados, dispersión, picos, intentos inválidos y límites se resumen en el PR, con registros fuera de Git. La corrección de una espera arbitraria en una prueba histórica estabiliza el test, no el rendimiento del juego.

## Decisión de T009-I2: diagnóstico GPU limitado sin T010

I2 partió de `2272aa2`. El carril de componente midió GPU elapsed del tramo GL
de render mediante queries reales en el contexto WebGL2 de Godot, separado de
comparabilidad global/FPS. B conservó el shader autorado; A retiró vecinos y
cálculo de borde sólo en la copia experimental, cambiando el aspecto. A no es
una candidata visualmente equivalente ni un ahorro entregado.

El perfil completo aceptado usó override CSS/backing 2182×1276, lógica 1152×673,
DPR y scale 1. No equivale al default con DPR 2: intentos incompletos bajo otras
políticas permanecen separados y no aportan tiempos a esta conclusión.
El control de geometría y su restitución siguen la [adenda](contracts/profiling-protocol.md#adenda-i2-componente-gpu-web).

La mediana de las medias GPU por corrida fue aproximadamente 4,239 ms en B y
4,173 ms en A; la diferencia de 0,066 ms queda dentro de la dispersión y los
rangos se solapan. El p95 GPU favoreció A en las tres repeticiones: esa señal
de cola se conserva, pero no acredita ahorro medio general, ganancia de FPS
o un cuello dominante. El tramo incluye render y trabajo compartido del
observador; no aísla cuatro lecturas frente al cálculo de borde ni cubre todas
las poses, caída o combate de producción.

Se conservaron peores colas de reloj wall al final, también en el control mínimo,
y una variación de unos 4,02 MiB en el monitor de memoria de render. No se infiere
causa, fuga o crecimiento sostenido; ese monitor no es RSS ni VRAM física.
La comparación detallado/mínimo no demuestra un observador gratuito ni fija
una cota completa de perturbación. El probe sigue inválido por pacing efectivo
no disponible; las series externas no rellenan su informe ni relajan sus ocho
condiciones. DOM y RAF tampoco acreditan presentación o VSync físicos.

QA aprobó este diagnóstico limitado, sin autorizar T010. Producto, probe,
pruebas y presets permanecen intactos; no corresponde fabricar RED de una
optimización inexistente. Se restituyó el default de viewport y se retiraron
los recursos propios; apps/datos normales se conservaron, sin instalación nativa.
T008/SC-001 nativos, US2/T010–T012, T039/T071 y publicación siguen pendientes;
Issue #30 permanece abierto. El siguiente experimento propuesto es material
completo ON/OFF con media GPU como métrica principal, incluyendo batching;
requiere nueva autorización y no forma parte del alcance ejecutado de I2.

## Prioridad posterior al merge de I2 — 2026-10-23

La persona fusionó el [PR #35](https://github.com/Juanpvivas/demons/pull/35) y dejó
el trabajo de rendimiento hasta aquí por ahora, sin continuar pruebas o
validaciones de ese ámbito. La prioridad pasa a la [marcha enemiga de 008](../008-marcha-enemiga/spec.md).
El experimento de material completo queda propuesto, sin ejecución prevista en
esta etapa. Se conservan la evidencia histórica, el Issue #30 abierto y los
pendientes nativos/US2 y de publicación; esta decisión no los certifica ni
modifica la constitución.
