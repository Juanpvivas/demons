# Entrada física Android 002 — primera sesión corregida, 2026-10-16

**Evidencia parcial; I2 e I4 discriminantes todavía pendientes.** No se sustituye la matriz T008 por la declaración humana.

La persona inició por sí misma el APK final instrumentado ya instalado y confirmó «Completé la secuencia». Se recuperó el buffer de **su proceso sin recargar, reiniciar o inyectar gestos**. Fuente `a473585`, script fijo `4e89dce…`, APK `37b465acac5f194954994e496e796e7bc65f397a1cfe1864bb84360a9d8388f3`, observer aprobado y telemetría descritos en [comparación nativa](native-device-performance.md). Captura [actual de nuestra app](native-android-final-human-current.png), [log propio](native-android-final-human.log), [eventos exactos](native-android-final-human-events.json), [derivado de gestos](native-android-final-human-derived.json).

Se recuperaron118eventos,26PRE y26POST. Cada par mouse/touch contiguo de idénticas coordenadas se trata como **un gesto físico con mouse emulado**, no dos toques. Para el cambio total se usa PRE más temprano y POST más tardío. Todos los pares citados conservan estado PLAYING.

| Caso | PRE→POST real | Resultado acotado |
|---|---|---|
| I3, insuficiente; seq1/2 | `(266.70,493.44)`, celda2,5 libre; reserva0→0, soldados1→1; señal de fondos insuficientes | PASS observado |
| Recolecciones seq9/10–17/18 | Reserva0→6→9→12, sin soldado extra; todos comienzan bajo10 | Recolección real; no discrimina I4 con fondos suficientes |
| Supuesto B, seq19/20 a30.747s | `(578.70,526.44)`, celda6,5 **libre**, soldados0→1, reserva12→2; nuevo centro624,528 | Despliegue permitido; **no prueba celda ocupada I2**. El soldado inicial ya murió |
| Recolección seq23/24 | `(582.90,448.44)`, reserva5→14; desaparecen3pickups de3 solapados; soldados1→1 | Suma9 legítima; pre<10, **no acredita I4 discriminante** |
| I1, A libre seq25/26 | `(235.50,505.44)`, celda2,5; reserva14→4, soldados1→2; nuevo centro240,528 y celda ocupada | PASS observado; costo10 y una sola unidad |
| I5/I6 observación | Inicial576,500/celda6,5; después celda6,5 libre y reutilizada en seq19/20 | Ubicación y reutilización observadas; regresión controlada de muerte/liberación enGUT |

Pendiente físico mínimo para I2/I4: un toque a una celda que **en ese PRE siga ocupada**, con reserva≥10, y un pickup con reserva≥10 sin gasto/unidad adicional. La sesión no muestra esos estados; no hay fallo reproducido por esta carencia de cobertura. I9 fuera del centro ilustrado y comparación de gestos antes/después también siguen pendientes. No se añaden límites al tablero ni se modifica gameplay para facilitar la prueba. El orquestador coordina la siguiente acción humana; no se reinicia o reemplaza la app por rutina.
