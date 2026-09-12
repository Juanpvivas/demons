extends Node
## Autoload: dueño único del pool global de munición recolectada por el
## jugador (`data-model.md` — "Munición recolectada"; `docs/ARCHITECTURE.md`
## §4.1). Ningún otro nodo debe mantener su propia copia de `collected_ammo`
## ni compararla manualmente — `ammo_pool_changed` es la única fuente de
## verdad (`contracts/signals.md`, Invariantes de contrato).
##
## T033: `try_spend_ammo`/`add_ammo` son el único punto de entrada para
## mutar `collected_ammo` desde fuera de este autoload (recolección de
## pickups vía `add_ammo`, recarga/despliegue vía `try_spend_ammo`, FR-009/
## FR-010/FR-011). `deploy_or_reload_rejected` se emite aquí (no en
## `Soldado`) porque `EconomyManager` es la única fuente de verdad sobre si
## hay fondos suficientes (`tasks.md` T033); `contracts/signals.md` la lista
## en la tabla de `Soldado` por dónde se origina la intención del jugador,
## pero quien decide y emite el rechazo es este autoload.

## Pool global y compartido de munición recolectada (FR-008). Runtime,
## nunca un `Resource` — no es un valor base/máximo compartido entre
## instancias, es el estado vivo de la partida.
var collected_ammo: int = 0

## Emitida ante cualquier cambio al pool de munición recolectada
## (recolección, gasto en recarga/despliegue). Escucha: HUD (contador
## global, FR-015).
signal ammo_pool_changed(new_amount: int)

## Emitida cuando un enemigo derrotado generó una pickup recolectable en
## el tablero. Escucha: sistema de recolección por tap/click.
signal ammo_pickup_spawned(pickup_id, position: Vector2, amount: int)

## Emitida cuando se intenta gastar munición recolectada (recarga o
## despliegue) sin fondos suficientes (FR-011). Escucha: HUD (mensaje al
## jugador, T036).
signal deploy_or_reload_rejected(reason: String)

## Intenta gastar `amount` del pool global. Si hay fondos suficientes,
## descuenta y emite `ammo_pool_changed`, retornando `true`. Si no,
## `collected_ammo` queda sin modificar, se emite
## `deploy_or_reload_rejected` y retorna `false` (FR-009/FR-010/FR-011).
func try_spend_ammo(amount: int) -> bool:
	if collected_ammo < amount:
		deploy_or_reload_rejected.emit("Munición insuficiente")
		return false
	collected_ammo -= amount
	ammo_pool_changed.emit(collected_ammo)
	return true

## Suma `amount` al pool global de munición recolectada (recolección de
## pickups, FR-008) y emite `ammo_pool_changed`.
func add_ammo(amount: int) -> void:
	collected_ammo += amount
	ammo_pool_changed.emit(collected_ammo)
