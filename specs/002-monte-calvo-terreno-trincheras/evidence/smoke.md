# T014 — Smoke de partida del estado final

**Rol**:`godot-tester`. **Fecha**:2026-10-15Bogotá. EstadoT011 [hashes](final-sha256.json), Godot4.7.1mono, Mobile/Metal. Las sesionesPCV1/V2 cargaron la escena real desde una copia aislada byte idéntica y corrieron42s. El observador externo solo leyó estado/señales y capturó el viewport; no añadió munición, soldados, daño o tiempos acelerados. **Ambas retornaron0**.

| Hecho observado | V1 | V2 |
|---|---:|---:|
| Paso natural a oleada2 |14.147s|14.785s|
| EstadoLOST(3) |33.648s|34.607s|
| Captura posterior |[40.187s](final-v1-3.png)|[40.502s](final-v2-3.png)|

[LogV1](final-v1.log), [logV2](final-v2.log). Durante la partida se observó rifle, agotamiento10→0, moral máxima3, cambio aMELEE, pickupsde3 y muerte del soldado. El máximo de soldados vivos observado fue1; no se registró despliegue nuevo en este autoplay. TrasLOSTel motor continúa mostrando lo que la implementación actual procesa; no se añadió pausa ni pantalla de derrota/HUD.

La partida termina naturalmente en derrota, igual que el baselineV1(33.617s), con pequeñas diferencias temporales entre ejecuciones. Las sesiones finales compartieron máquina con las pruebas de regresión/runtime, por lo que esos tiempos no son un benchmark de carga o simulación determinista. No se diagnostica una regresión de balance por diferencias inferiores al segundo sin controlar frames.

## Escenarios separados de victoria y derrota

La [suite completa183/183](regression.md) pasó los escenarios de nivel `test_enemigo_real_que_alcanza_posicion_defendida_termina_la_partida_en_derrota_de_punta_a_punta` y `test_completing_all_configured_real_waves_transitions_the_real_gamestatemanager_to_won_end_to_end`, además de los sistemas de estado y oleadas. Es cobertura automatizada del estado/sus señales, no una partida ganada manualmente con las diez oleadas y economía naturales.

No se forzó una victoria en el smoke ni se reparó el juego para obtenerla. La [comparación humana finalAndroid](android-human-final.md) está disponible y es parcial; no acredita una partida ganada ni la matriz física completa. EntradaOSPC y casos discriminados de picking permanecen pendientes. iOSfísico y criterios finales de rendimiento se mantienen separados en [performance.md](performance.md). Este reporte entrega smoke observado y sus límites paraQA; no marcaT014niaprueba la feature por sí solo.
