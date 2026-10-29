# Contrato — Recarga por hogar

**Estado**: revisión visual en preparación T013 en adelante. T001–T012 aprobaron el botón anterior; no aprueban este efecto. [Requisitos vigentes](../spec.md), [tareas](../tasks.md), [Issue #49](https://github.com/Juanpvivas/demons/issues/49), [PR #50](https://github.com/Juanpvivas/demons/pull/50). Publicación conserva gate separado.

## Interfaces y compatibilidad

- Nivel: `request_trench_reload(home_cell: Vector2i, expected_instance_id: int) -> bool`, sin cambio de autoridad.
- HUD: `get_trench_reload_button(home_cell: Vector2i) -> Button` sigue devolviendo el control GUI real, o `null` sin vínculo. El nombre se conserva por compatibilidad; ya no significa un botón decorado visible.
- HUD: `register_trench_reload(home_cell: Vector2i, soldier: Soldado, world_anchor: Vector2, parts: Array[Sprite2D] = []) -> void`, con cuarto argumento opcional para conservar llamadas de tres argumentos; `unregister_trench_reload(home_cell: Vector2i) -> void`.
- Nivel entrega las dos piezas `PosteriorN` y `ParapetoN` del hogar configurado. `world_anchor` sigue siendo HOME global fijo, nunca la posición del soldado.
- HUD conserva `trench_reload_requested(home_cell: Vector2i, soldier_instance_id: int)`. Cámara conserva `framing_changed` después de `force_update_scroll()`; no cambia encuadre/zoom.
- Componente `TrenchReloadControl extends Button`: `bind_trench_parts(parts: Array[Sprite2D]) -> void`, `set_reload_state(needs_reload: bool, can_reload: bool) -> void`; `GlowState { NORMAL, DIM, PULSING }`, `glow_state` y `glow_strength` son su estado/fuerza reales de presentación, no una interfaz paralela de pruebas. La fuerza aplicada pinta las copias visuales.

T002 añadió firmas neutrales para el RED de la primera entrega; ese setup es histórico. La revisión usa el getter/Button existente sin otro setup funcional. Las pruebas pueden comprobar ausencia de las nuevas capacidades mediante aserciones guardadas; no deben precargar una clase inexistente ni contar errores de parser/import como RED.

## Estado observable vigente

| Condición del dueño/vínculo | Acción GUI | Brillo de trinchera |
|---|---|---|
| Vivo, carga cero, PLAYING y `can_reload()` | Zona habilitada sobre la trinchera | `PULSING`, rojo suave variable |
| Vivo, carga cero, sin fondos | Zona deshabilitada que consume el gesto | `DIM`, rojo tenue estático, sin Tween |
| Vivo, carga cero, PAUSED/terminal/aceptación/RETURNING no elegible | Zona deshabilitada; overlay terminal prevalece | `DIM`, sin pulso de disponibilidad |
| Carga positiva; RETURNING normal con carga repuesta | Zona oculta/no intercepta | `NORMAL`, fuerza cero |
| Dueño muerto/ausente, baja, reemplazo previo o cierre | Acción anterior inválida y retirada | `NORMAL`; detener/retirar efectos anteriores |

El HUD deriva `needs_reload` de dueño vivo/carga cero/hogar vigente/no cierre y `can_reload` de autoridad del actor más PLAYING actual. El componente refleja ambos sin economía propia. La sincronización ocurre al registrar y por señales de dueño, fondos y partida. PAUSED no implica por sí mismo `SceneTree.paused`: el cambio de estado debe detener explícitamente el pulso. Añadir fondos/reanudar sólo pulsa si sigue siendo elegible. Sin demora entre reposición de carga y normalización.

## Presentación local y ciclo

El Button tiene texto vacío y `StyleBoxEmpty` en normal, hover, pressed, disabled y focus: nunca aparece rectángulo, borde, cartel ni palabra «Recargar». Se conserva control GUI real y mínimo táctil 112×48.

Cada control enlaza las dos piezas existentes y crea una sola vez dos copias Sprite2D aditivas como hijas locales, con las mismas texturas/alpha y expansión leve 1.03. No hay bitmap nuevo, shader, bloom ni iluminación global. Las piezas originales conservan su modulate/material, transforms y z efectivo −4/+1; la oclusión actor/parapeto y las barras no se alteran. El brillo no es una capa de HUD sobre el soldado.

Una sola animación Tween por hogar elegible, ligada al control, interpola su fuerza real con transición suave de 0.6 s subida y 0.6 s bajada. No `TIME`, polling de estado ni recreación por frame/ciclo. Repetir el mismo estado no reinicia ni acumula Tween/copias; pasar a DIM detiene la animación y fija fuerza tenue. NORMAL, desregistro, salida del árbol/cierre y rebinding detienen el Tween y normalizan/retiran copias. Reemplazar dueño retira el control antiguo para cancelar también press→reemplazo→release. Un hogar no modifica recursos visuales mutables de otro.

## Autoridad e identidad

La intención captura hogar e ID de dueño; no depende de selección ni busca un sucesor al ejecutar un callback viejo. El nivel rechaza sin gasto cierre/partida no activa, hogar no configurado, ocupante inválido/muerto, ID distinto o discrepancia de hogar; sólo entonces delega a `Soldado.request_reload()`.

El actor conserva elegibilidad, guard previo a callbacks/gasto, coste `UnitStats.deploy_ammo_cost`, reposición `stats.max_ammo`, salud/moral y regreso por fila vulnerable sin ofensiva hasta HOME. No segundo cobro ni economía en el HUD. El panel conserva fila/carga/moral/regreso y cero botones de recarga.

## Geometría y frontera de entrada

En producción, derivar la unión mundial de los rectángulos reales de `PosteriorN`/`ParapetoN` con sus transformaciones. La geometría actual es aproximadamente `Rect2(HOME + Vector2(-64, -28), Vector2(128, 64))`, con HOME dentro y 32 unidades entre filas vecinas; el parapeto está contenido en la pieza posterior. Sin `parts`, usar ese rectángulo mundial como fallback compatible para montajes aislados de HUD.

Proyectar ese rectángulo mundo→canvas HUD vigente, ampliar alrededor de su centro hasta el mínimo 112×48 si hace falta y limitarlo al área segura, sin mover/escalar el arte, el tablero o la cámara. Recalcular al registrar y tras encuadre aplicado/resize. El hotspot debe contener el punto HOME proyectado y corresponder a la propia trinchera, no al antiguo rectángulo flotante superior; comprobarlo con HOME real y transformación no identidad, no sólo pulsando el centro calculado del Button.

La frontera es el rectángulo del control real: dentro de una zona activa/vacía, habilitada o deshabilitada, GUI/`MOUSE_FILTER_STOP` consume el gesto sin pickup/selección/despliegue debajo. Fuera, el contenedor decorativo deja pasar y se conserva pickup→selección/despliegue. Dueño cargado y ausencia de dueño no interceptan la selección normal. Ratón/toque con emulación realizan una sola orden; no ampliar al carril completo ni invadir al vecino. El pulso jamás mueve el hotspot.

## Oráculos de verificación

GUT observa Button/rectángulo real, partes/copia/material/Tween reales, fuerza que pinta, ocupante, saldo, selección y señales; entrada por viewport además de callbacks. Cubrir cinco hogares, normal/tenue/pulso, transición y repetición de estado, pausa sin SceneTree pause, fondos, recarga/regreso, muerte/reemplazo/cierre/Retry, identidad obsoleta y resize no identidad. El acabado pictórico/brillo y la lectura requieren además observación real por destino; headless no acredita renderer, gesto nativo ni FPS. La prueba humana Xiaomi del botón anterior conserva su alcance histórico.
