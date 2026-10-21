# Data Model: Cinco carriles horizontales

Modelo de la feature: I1 y movimiento/contacto I2 integrados en `main`
mediante los PR #24 y [#25](https://github.com/Juanpvivas/demons/pull/25) (`c1f43d2`).
I3 está integrado mediante [PR #26](https://github.com/Juanpvivas/demons/pull/26)
(`8c4cab4`). I4, aprobado funcionalmente en T055, está integrado en `main` mediante
[PR #27](https://github.com/Juanpvivas/demons/pull/27).
La publicación sigue pendiente; las [tareas](tasks.md) mantienen el estado de entrega y PR.
Selección, transacción de recarga y `RETURNING` corresponden a I3;
I4 añade presentación lateral sin mutar esos datos. Filas internas 0…4;
UI 1…5 de arriba abajo.
[Contrato de conducta](contracts/horizontal-combat.md).

## Configuración compartida de solo lectura

| Entidad/campo | Valor de producción y validación |
|---|---|
| `LaneBoardConfig.design_rect` | `Rect2(0,0,1152,648)`; encuadre completo |
| `cell_size` | `Vector2i(96,96)`; TileSet conserva tamaño |
| `home_cells` | `(1,1),(1,2),(1,3),(1,4),(1,5)`, exactamente cinco y únicas |
| Orígenes derivados del grid | `(144,144),(144,240),(144,336),(144,432),(144,528)` |
| Entradas | `(1008,144/240/336/432/528)` según fila |
| Bandas de fila | y∈`[96+96r,192+96r)` para r 0…4 |
| Zona defendida | `Rect2(48,96,48,480)`, Area vertical sin bloqueo; detecta entrada real de cuerpo enemigo |
| Márgenes | Superior y 0…96, inferior y 576…648; sin plazas nuevas |
| `UnitStats.advance_speed/return_speed` | Dos campos `@export_range` propios, `.tres` 40/40; independientes del enemigo. I2 usa avance; I3 activa regreso físico |
| Resources existentes | Stats/oleadas compartidos e inmutables; demás valores conservados de research |

Solo `home_cells` son plazas de despliegue; resto del campo sirve para rutas
u objetivos. Borde derecho/inferior de celda pertenece a la siguiente según
TileMap, sin redondeos distintos para ratón/toque. Filas extremas no tienen
vecina exterior. Geometría de nivel editable en Resource, sin estado mutable.

Zona de derrota actúa al entrar cuerpo 48×48, no por píxel del sprite ni
cuando centro llega a x 48. Trinchera x 144 está fuera; un enemigo bloqueado por
su defensor no la alcanza. Márgenes reservan controles respetando safe area
sin ocultar plazas. Cámara centra rectángulo completo sin mover actores.

## Estado por partida

- `BoardManager`: `home_cell→soldado`, entrada estable durante movimiento.
  Nivel valida whitelist antes de ocupar/gastar; baja libera origen.
- Selección de nivel: `(home_cell, actor_id/instance)` opcional. Validar que
  sigue siendo el dueño vivo antes de ordenar; baja invalida selección/orden.
  Reemplazo no hereda acción antigua dirigida al dueño anterior.
- `WaveSpawner`: cursor 0…4 inicial 0; cola/Timer existentes; pool; metadatos
  por activación `(generation, lane_id, origin, counted_defeat)`.
- `INITIAL`: fila 2 interna(3 UI), t0, stats base; sin consumir cursor ni
  notificar baja de oleada. `WAVE`: fila siguiente del cursor; sí notifica
  baja una vez. Ambos pertenecen al mismo pool. Cursor avanza solo tras spawn
  WAVE realmente activado; se conserva entre oleadas y reinicia con partida.

## Soldado por instancia

Vida/carga/moral existentes, `home_cell`, `home_position`, `lane_id`, modo de
arma `RIFLE/MELEE`, estado de movimiento y blancos con identidad/activación.
Cooldowns y presentación pertenecen al actor, nunca al Resource compartido.
I2 implementa cuerpo móvil, `HOME/ADVANCING/MELEE_CONTACT/WAITING/DEAD` y
consultas físicas por tick; `home_cell` corresponde a `_grid_cell` y no cambia
durante la salida y el regreso. I3 activa `RETURNING` según la tabla.

| Movimiento | Conducta | Transiciones |
|---|---|---|
| `HOME` | Fijo; fusil con carga; vacío sin blanco espera | Vacío+frontal→`ADVANCING`; recarga válida dentro→fusil sin viaje |
| `ADVANCING` | +X a 40, sin daño fuera de rango | Rango/contacto→`MELEE_CONTACT`; sin frontal→`WAITING`; recarga→`RETURNING` |
| `MELEE_CONTACT` | Fijo, machete a un frontal de su fila | Pierde blanco→avance/espera; recarga→`RETURNING` |
| `WAITING` | Fijo, sin frontal | Nuevo frontal→avance/contacto; recarga→`RETURNING` |
| `RETURNING` | −X a 40, carga llena, ninguna ofensiva | Llegada física→`HOME`/fusil; muerte→`DEAD` |
| `DEAD` | Sin movimiento/ataque/órdenes, moral 0 | Baja única libera origen; efecto visual independiente |

Última bala cambia inmediatamente a machete; si elimina al único objetivo,
no sale sin otro frontal. Todo estado vivo recibe daño vigente, también en
retorno. Bloqueo no autoriza atravesar, cambiar de fila o teletransportarse.
Último tick de regreso limita movimiento a distancia restante; tolerancia
numérica de llegada ≤0,01 unidades, sin salto o oscilación.

**Transacción de I3 aprobada para integración:** recarga aceptada bloquea reentrada antes de
callbacks de reserva: valida vivo/carga 0/PLAYING/no retorno/fondos, cobra costo 10 una vez y repone carga 10
sin cambiar vida/moral. Rechazo no cambia saldo/carga/posición; cualquier
guard transitorio se revierte. Muerte en retorno no reembolsa ni resucita,
y libera plaza sin esperar la caída.

`reload()` delega a `request_reload()` y comparte todas sus precondiciones.
El guard precede cualquier señal; tras el gasto se revalidan vida/partida antes
de reponer carga o iniciar regreso. `get_reload_state()` expone identidad,
hogar/fila, carga/capacidad, moral, vida, arma/movimiento, costo y elegibilidad;
`reload_state_changed` permite al HUD observar cambios sin decidir el gasto.

## Enemigo por activación

Vida, fila, posición, progreso −X, velocidad horizontal, origen INITIAL/WAVE,
generación/targetability y notificación de baja/cruce. Reset reemplaza todos
los datos y limpia movimiento/contacto/presentación. Misma referencia de nodo
no es prueba de mismo blanco si cambia su activación.

Baja genera snapshot neutro/drop 3/retiro una vez; solo WAVE cuenta en
WaveManager. Capturar contexto antes de listeners síncronos de pool/oleadas.
INITIAL → WAVE → INITIAL en otra fila no arrastra origen, objetivos, generación,
tintes o callbacks. Conexiones y registro visual una vez por instancia física;
API genérica de `ObjectPool` sin cambios.
