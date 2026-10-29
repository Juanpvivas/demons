# Contrato — Recarga por hogar

**Estado**: comportamiento de `012-I1` aprobado funcionalmente en T008 sobre `ba122ef`; seguimiento de integración/documentación/CI en [tasks.md](../tasks.md) y [PR #50](https://github.com/Juanpvivas/demons/pull/50). [Requisitos y límites](../spec.md), [Issue #49](https://github.com/Juanpvivas/demons/issues/49). Publicación con gate separado.

## Interfaz mínima y setup neutral

- Nivel: `request_trench_reload(home_cell: Vector2i, expected_instance_id: int) -> bool`.
- HUD: `get_trench_reload_button(home_cell: Vector2i) -> Button` para observar el control real, o `null` si no existe un control registrado para ese hogar.
- HUD: `register_trench_reload(home_cell: Vector2i, soldier: Soldado, world_anchor: Vector2) -> void` y `unregister_trench_reload(home_cell: Vector2i) -> void`; `world_anchor` es el centro global fijo del hogar, no la posición del actor.
- HUD: `signal trench_reload_requested(home_cell: Vector2i, soldier_instance_id: int)`.
- Cámara de Monte Calvo: `signal framing_changed`, emitida después de aplicar el encuadre y `force_update_scroll()`; HUD actualiza su geometría tras ese cambio, además de leer el encuadre vigente al registrar hogares.

T002 añadió sólo firmas importables: petición `false`, getter `null`, registros vacíos y señales nuevas sin emitir/conectar; conservó la recarga anterior para el RED posterior. Ese setup neutral es histórico y no describe el comportamiento entregado por T005. La consulta actual observa el Button real, sin una interfaz de prueba paralela.

## Estado observable de cada botón tras implementación

| Condición actual | Presentación/acción |
|---|---|
| Dueño válido vivo con carga cero, partida activa y elegible | Visible/habilitado; «Recargar», estilo heredado, mínimo 112×48 |
| Dueño vivo con carga cero sin fondos | Visible/deshabilitado; sin orden/gasto |
| Dueño vivo con carga cero durante PAUSED, estado terminal o aceptación de orden | Visible/deshabilitado; el overlay terminal conserva su precedencia de entrada |
| RETURNING normal tras reposición de carga | Oculto por carga positiva; si un estado de prueba tiene RETURNING/carga cero, visible/deshabilitado por `can_reload()` |
| Carga positiva, muerte, baja o ausencia de dueño | Acción oculta/inválida; controles ocultos no interceptan el tablero |
| Cierre, menú o intento retirado | Invalidar intenciones y vínculos; sin acción del intento anterior |

Visibilidad depende de dueño vivo/carga cero/cierre; habilitación deriva de `can_reload()`. El estado se sincroniza inicialmente y con `reload_state_changed`, economía y partida; el gasto síncrono puede deshabilitar antes de que la reposición oculte. No timer, tween ni espera añadida. No más de cinco controles; registro repetido no duplica nodos ni conexiones, reemplazar dueño desconecta al anterior.

## Autoridad y protección de identidad

Una intención captura hogar e ID de dueño de su vínculo; no consulta la selección ni busca un dueño nuevo al ejecutar un callback viejo. El nivel devuelve `false` sin cobrar ante cierre/partida no activa, hogar no configurado, ocupante inexistente/inválido/muerto, ID distinto o discrepancia entre hogar del actor y celda. Sólo después delega a la API vigente `request_reload()` del ocupante y retorna su resultado.

`can_reload()`/`request_reload()` conservan vivo/PLAYING/carga cero/fondos/sin aceptación o RETURNING, coste `UnitStats.deploy_ammo_cost` y reposición `stats.max_ammo`. El guard del actor precede callbacks/gasto: no trasladar la economía al HUD ni añadir un segundo cobro. Mantener salud/moral, regreso por fila, vulnerabilidad y ausencia de ofensiva hasta HOME. La selección existente queda informativa; retirar la conexión y el botón anteriores al entregar el comportamiento, sin dos acciones visibles.

## Geometría y entrada

HUD CanvasLayer contiene la capa de botones; hogar global→canvas HUD usa transformaciones vigentes del viewport/canvas, con actualización tras encuadre inicial y resize. No seguir al actor ni alterar encuadre/zoom de cámara, grid o física; la señal de encuadre sólo notifica su actualización existente. Rectángulos reales permiten comprobar mínimo, posición, no solape y área segura; no getters geométricos sustitutos.

Buttons consumen el gesto con GUI/`MOUSE_FILTER_STOP`, incluidos los deshabilitados; el contenedor decorativo deja pasar entrada fuera de los controles. Ratón/toque no deben duplicar intención o propagarse a `_unhandled_input`/picking. Sobre botón prevalece UI; fuera de su rectángulo se conserva el comportamiento pickup→selección/despliegue. Muerte/reemplazo y cierre invalidan callbacks capturados incluso si los controles son reutilizados.

## Oráculos de verificación

GUT observa Buttons reales, estado del actor/ocupante, saldo, selección y señales; envía entrada por viewport para demostrar consumo, no sólo `pressed.emit()`. Cubrir cinco hogares, dos órdenes independientes, fondos, eventos repetidos/reentrantes, IDs antiguos, cierre/Retry y resize con transformación no identidad. Una pulsación aceptada implica un cobro; rechazos cero efectos adicionales. La colocación y lectura visual finales requieren además smoke real por destino, sin extrapolar headless a renderer/input nativo.
