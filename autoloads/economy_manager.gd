extends Node
## Autoload: dueño único del pool global de munición recolectada por el
## jugador (`data-model.md` — "Munición recolectada"; `docs/ARCHITECTURE.md`
## §4.1). Ningún otro nodo debe mantener su propia copia de `collected_ammo`
## ni compararla manualmente — `ammo_pool_changed` es la única fuente de
## verdad (`contracts/signals.md`, Invariantes de contrato).
##
## T008 (Foundational): solo la estructura base. La lógica de gasto/recarga
## (`try_spend_ammo`/`add_ammo`, señal `deploy_or_reload_rejected`) se agrega
## en T033 — no implementada todavía.

## Pool global y compartido de munición recolectada (FR-008). Runtime,
## nunca un `Resource` — no es un valor base/máximo compartido entre
## instancias, es el estado vivo de la partida.
var collected_ammo: int = 0

## Emitida ante cualquier cambio al pool de munición recolectada
## (recolección, futuro gasto en recarga/despliegue). Escucha: HUD
## (contador global, FR-015).
signal ammo_pool_changed(new_amount: int)

## Emitida cuando un enemigo derrotado generó una pickup recolectable en
## el tablero. Escucha: sistema de recolección por tap/click.
signal ammo_pickup_spawned(pickup_id, position: Vector2, amount: int)
