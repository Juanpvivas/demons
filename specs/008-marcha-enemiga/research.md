# Research: Decisiones de marcha

| Decisión | Motivo y alternativa descartada |
|---|---|
| Alternancia real | Dev y QA observaron que las cuatro poses actuales mantienen una zancada muy similar. Añadir variaciones de torso o duplicados no resuelve la petición. |
| Ocho fases en dos hojas | Cuatro poses de cada grupo permiten alternar los apoyos, con normalización de acabado/rifle y encaje común. Conservar contacto/caída en el atlas existente evita regenerar estados que la persona no pidió cambiar. |
| Referencia cinemática | El GIF de Metal Slug orienta ritmo corporal, pasos y equipo. El personaje y acabado siguen siendo los pictóricos de Monte Calvo. |
| Recurso, sin código nuevo | El presentador actual ya usa desplazamiento confirmado y no reinicia el mismo clip; no hay motivo identificado para cambiar el selector o el pool. |
| Regiones y anclaje medidos | La salida gráfica puede no ser una grilla exacta. Encajar sus siluetas con `AtlasTexture` evita recortes y movimientos espurios sin modificar el cuerpo. |
| Verificación proporcional | Los tests actuales cubren el selector con recursos artificiales; no acreditan el atlas final. Importación, bucle real y recorrido visual complementan esa regresión, sin tests de texto ni RED artificial. |
| Rendimiento pausado | La persona cierra por ahora ese trabajo tras el merge de PR #35. Esta mejora no ejecuta nuevos experimentos ni convierte las muestras históricas en certificación. |

Se consultaron las fuentes de preparación `demons-agent-tdd` y las guías GodotPrompter `using-godot-prompter`, `animation-system` y `assets-pipeline` para organizar recursos y terminología. T004 aprueba el arte, encaje y funcionamiento local de I1; el cierre de integración de la revisión exacta se registra en [tareas](tasks.md) y PR.

## Alcance funcional y visual de I1

El ciclo real se revisó ampliado y a tamaño de juego, incluyendo apoyos y uniones entre los dos grupos. La regresión semántica existente cubre selector, impacto, baja y reutilización; no se atribuye al test con frames artificiales la calidad del arte productivo.

Chrome de computador acredita avance de varios actores, contacto, derrota natural y «Volver a jugar». Android Emulator acredita varios actores y derrota natural, sin una captura propia específica de contacto. iPad Simulator acredita varios actores y contacto, sin Retry, impacto/caída o reutilización visuales propios. No se presenta una victoria manual contra los 100 enemigos ni se extrapolan esas rutas entre destinos.

Las apps internas usan variantes Compatibility de QA con el loader GUT heredado excluido; iOS usa un shell ARM64 de simulador con el paquete actualizado. Esos ajustes no entran en el PR ni certifican el empaquetado original, renderer Mobile o hardware físico. Los datos normales se preservaron/restauraron. No se ejecutó una campaña de rendimiento y 006 sigue pausado; publicación pendiente.
