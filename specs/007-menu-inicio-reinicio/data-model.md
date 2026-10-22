# Modelo de estado de una sesión

Modelo del ciclo implementado; [contrato operativo](contracts/match-flow.md). La aceptación por entorno y artefacto se conserva en el seguimiento de la feature. No se persiste ningún dato ni se modifican Resources de balance.

| Dueño | Estado/dato | Regla |
|---|---|---|
| `GameRoot` | Referencia a menú y nivel actual | Cero niveles en menú; como máximo uno activo |
| `GameRoot` | `transition_pending`, generación del intento | Una transición aceptada; eventos de otra generación se descartan |
| `GameStateManager` | `MENU`, `PLAYING`, `PAUSED`, `WON`, `LOST` | MENU=4 conserva los valores existentes; sin resultado fuera de PLAYING |
| `WaveManager` | Secuencia, índice y contadores | Cancelar vacía/restaura; no completar una oleada al cancelar |
| Nivel | Tablero, soldados, spawner/pools, cajas, efectos, selección | Propiedad del intento; retirar todo antes de crear otro |
| `EconomyManager` | Reserva global | Reset vigente a cero al crear partida; no recompensas de intentos retirados |

## Transiciones permitidas

| Origen | Intención | Destino |
|---|---|---|
| Apertura | Inicialización de raíz | MENU, sin nivel |
| MENU | `request_start()` | PLAYING de un intento nuevo |
| PLAYING | Condición terminal vigente | WON o LOST del mismo intento |
| WON/LOST | `request_retry()` | Cierre → PLAYING de un intento nuevo |
| WON/LOST | `request_menu()` | Cierre → MENU, sin nivel |
| Transición pendiente u origen ajeno | Intención repetida/tardía | Sin efecto |

`PAUSED` conserva compatibilidad histórica, sin controles ni transiciones nuevas de pausa en 007. El cierre usa MENU como estado no jugable aunque el destino sea repetir; sólo después de liberar el árbol anterior puede el nivel nuevo entrar en PLAYING.

## Invariantes de reinicio

- Cinco soldados cargados con salud/moral iniciales vigentes, plazas/selección nuevas y reserva cero.
- Un inicial en fila 3 y 99 enemigos de oleadas autoradas; cursor WAVE vuelve a fila 1 sin que el inicial lo consuma.
- Ningún blanco, orden de regreso, timer, conexión vieja, caja, efecto o resultado anterior continúa en el intento nuevo.
- Una sola autoridad de resultado (`GameStateManager`); no se fuerza WON para navegar.
