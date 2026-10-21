# Research: Decisiones para I1

Preparación desde `5d50cb0`, sin ejecutar pruebas ni mediciones. Las hipótesis siguientes proceden de la revisión de sólo lectura de dev-godot y el protocolo de godot-tester, no de resultados nuevos. Se consultaron `using-godot-prompter` y `godot-optimization`; cada ejecutor consulta además sus skills específicas.

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
