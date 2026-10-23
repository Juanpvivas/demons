# Research: Decisiones de marcha

| Decisión | Motivo y alternativa descartada |
|---|---|
| Alternancia real | Dev y QA observaron que las cuatro poses actuales mantienen una zancada muy similar. Añadir variaciones de torso o duplicados no resuelve la petición. |
| Atlas de ocho fases | Permite apoyo, descenso, paso y elevación de cada pierna. Conservar contacto/caída en el atlas existente evita regenerar estados que la persona no pidió cambiar. |
| Referencia cinemática | El GIF de Metal Slug orienta ritmo corporal, pasos y equipo. El personaje y acabado siguen siendo los pictóricos de Monte Calvo. |
| Recurso, sin código nuevo | El presentador actual ya usa desplazamiento confirmado y no reinicia el mismo clip; no hay motivo identificado para cambiar el selector o el pool. |
| Regiones y anclaje medidos | La salida gráfica puede no ser una grilla exacta. Encajar sus siluetas con `AtlasTexture` evita recortes y movimientos espurios sin modificar el cuerpo. |
| Verificación proporcional | Los tests actuales cubren el selector con recursos artificiales; no acreditan el atlas final. Importación, bucle real y recorrido visual complementan esa regresión, sin tests de texto ni RED artificial. |
| Rendimiento pausado | La persona cierra por ahora ese trabajo tras el merge de PR #35. Esta mejora no ejecuta nuevos experimentos ni convierte las muestras históricas en certificación. |

Se consultaron las fuentes de preparación `demons-agent-tdd` y las guías GodotPrompter `using-godot-prompter`, `animation-system` y `assets-pipeline` para organizar recursos y terminología. Las decisiones son de preparación: aún no hay arte, encaje o funcionamiento nuevo aprobados.
