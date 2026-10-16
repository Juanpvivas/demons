# Android — prueba humana con terreno y trincheras

**Fecha**:2026-10-16UTC/2026-10-15Bogotá. **Rol**:`godot-tester`. Xiaomi2107113SG, debug final local identificado en [performance.md](performance.md). Esta prueba se ejecutó **después** de la medición de rendimiento, en una sesión nueva; no se mezclan toques humanos con la muestra de autoplay.

Se reinició exclusivamente la app del juego con `am force-stop` / `am start -W`. **Retorno0, COLD**, inicio **01:22:20UTC**, ActivityTotalTime391ms/WaitTime402ms (no carga completa). Después, los toques los realizó físicamente la persona. El agente solo obtuvo capturas; no inyectóADB, modificó saldo/estado o alteró ajustes.

| Captura solicitada | Finalización real desde lanzamiento | Observación visual |
|---|---:|---|
| [8s](android-human-final-08s.png) |9.799s|Soldado inicial blanco, enemigos ypickupamarillo sobre el terreno|
| [18s](android-human-final-18s.png) |19.986s|Soldado inicial naranja y otro blanco a su izquierda, próximos al frente decorativo|
| [28s](android-human-final-28s.png) |30.001s|Unidades en distintas posiciones, con actores dibujados delante del entorno|
| [40s](android-human-final-40s.png) |42.068s|Varias unidades visibles en posiciones distintas, sin cambios del escenario|

Todas las capturas son2400×1080 y retornaron0. El retraso de1.8–2.1s de la transferencia se registra; no se presentan como capturas exactas del frame8/18/28/40. [Eventos sin identificadores de dispositivo](android-human-final-events.json). Las imágenes muestran solo el juego, sin números de serie o datos de otrasapps.

## Confirmación humana e interpretación acotada

La persona confirmó: **«Recogí, desplegué y no se duplicó».** El orquestador transmitió la frase al tester. Las capturas corroboran nuevos soldados visibles sobre el suelo y cerca de las trincheras; sus placeholders se distinguen por encima de la decoración. Junto al [baseline humano sin arte](android-human-baseline.md), hay evidencia de actividad de recolección/despliegue en ambas versiones y una observación humana final de ausencia de duplicación en su prueba.

No se registraron instantes/coordenadas de cada toque, celda, saldo previo o posterior. Por eso **«no se duplicó» no discrimina por sí solo celda ocupada frente a fondos insuficientes**. Con cuatro pickupsde3 y un despliegue de10 podría quedar saldo2, pero ese saldo es solo un ejemplo de ambigüedad: **no se afirma que fuera el estado observado**. I2/I3tienen escenarios controladosGREENenGUT, pero su matriz completa de entrada física sigue pendiente.

La frase tampoco demuestra que el evento concreto de recoger no provocara un despliegue adicional(I4), ni acredita toque en todos los bordes/áreas decoradas(I9). No se infiere correspondencia de cada nueva unidad a un toque específico o ausencia de solapamiento en la misma celda a partir de cuatro capturas aisladas. No se pide repetir esta sesión válida para convertir esas inferencias en hechos.

## Resultado disponible y límites

Prueba física final válida como evidencia humana parcial: persona pudo recoger y desplegar con el arte visible y confirmó que no vio duplicación. El orden visual de actores/pickups sobre el entorno se mantiene en las capturas; eso no sustituye una matriz controlada de picking. PCV1/V2están en[us3.md](us3.md), la suite183/183en[regression.md](regression.md), y rendimiento/limitaciones en[performance.md](performance.md).

Quedan pendientes la matriz completa de clicOSPC/toque Android, escenarios físicos discriminados por estado y coordenadas, iOS físico, carga/VRAM reales y verificación sostenida sobre dispositivo objetivo contrastado. No se modificaron gameplay, tests, proyecto, exportaciones, firma o versión; no se marcaron tareas ni se creó commit. La aprobación global corresponde aQA/orquestador y no se atribuye a esta confirmación parcial.
