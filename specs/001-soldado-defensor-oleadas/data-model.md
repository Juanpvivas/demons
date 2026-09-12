# Data Model: Soldado Defensor con Munición y Moral

Todas las entidades siguen la regla de límite dato/estado de
`docs/ARCHITECTURE.md` §4.3: los `Resource` (`schemas/`) son valores
base/máximos de solo lectura y compartidos; el estado que cambia en juego
vive en variables propias del script del `Node` correspondiente.

## Resources (moldes de datos — `resources/schemas/`)

### UnitStats

Base/máximos para un tipo de soldado. Instancias concretas en
`resources/units/*.tres` (ej. `soldado_base_stats.tres`).

| Campo | Tipo | Notas |
|---|---|---|
| `max_ammo` | `int` (`@export_range`) | Munición máxima al desplegar o recargar. FR-003. |
| `damage_per_shot` | `int` (`@export_range`) | Daño de cada disparo de fusil. |
| `fire_rate` | `float` (`@export_range`) | Disparos por segundo mientras hay objetivo y munición. |
| `machete_base_damage` | `int` (`@export_range`) | Daño mínimo de machete con moral cero (ver `research.md` §2 y Edge Case de `spec.md`). |
| `machete_moral_multiplier` | `float` (`@export_range`) | Escala el daño de machete por punto de moral acumulada. FR-005. |
| `moral_per_kill` | `float` (`@export_range`) | Moral ganada por cada eliminación mientras hay munición. FR-006. |
| `deploy_ammo_cost` | `int` (`@export_range`) | Costo en munición recolectada para desplegar un soldado nuevo de este tipo (`spec.md` Assumptions: igual a una recarga completa → normalmente `= max_ammo`). |

### EnemyStats

Base/máximos para un tipo de enemigo. Instancias en `resources/enemies/*.tres`.

| Campo | Tipo | Notas |
|---|---|---|
| `max_health` | `int` (`@export_range`) | Vida total. |
| `move_speed` | `float` (`@export_range`) | Velocidad de avance hacia la posición defendida. |
| `melee_damage` | `int` (`@export_range`) | Daño infligido a un soldado en modo machete al alcanzarlo (`spec.md` Edge Case: soldado derrotado en cuerpo a cuerpo). |
| `ammo_drop` | `int` (`@export_range`) | Munición que suelta al ser derrotado. FR-007. |

### WaveData

Una oleada autorada (ver `research.md` §4). Instancias en
`resources/waves/*.tres`, referenciadas en orden por el nivel.

| Campo | Tipo | Notas |
|---|---|---|
| `wave_number` | `int` (`@export`) | Orden dentro de la secuencia del nivel; informativo/depuración. |
| `spawn_entries` | `Array[WaveSpawnEntry]` (`@export`) | Composición de la oleada (ver sub-recurso abajo). |

**`WaveSpawnEntry`** (sub-`Resource`, mismo archivo `wave_data.gd` o
`wave_spawn_entry.gd` en `resources/schemas/`):

| Campo | Tipo | Notas |
|---|---|---|
| `enemy_stats` | `EnemyStats` (`@export`) | Qué tipo de enemigo spawnear. |
| `count` | `int` (`@export_range`) | Cuántos de este tipo en esta entrada. |
| `spawn_interval` | `float` (`@export_range`) | Segundos entre spawns sucesivos de esta entrada. |

## Nodes (estado runtime)

### Soldado (`scenes/units/Soldado.tscn` + `soldado.gd`)

`StaticBody2D` raíz (ver `ARCHITECTURE.md` §5 — unidad estacionaria).

| Variable | Tipo | Notas |
|---|---|---|
| `stats` | `UnitStats` (`@export`) | Referencia al `Resource` base — solo lectura, nunca mutado. |
| `_current_ammo` | `int` | Estado runtime, inicializado desde `stats.max_ammo`. |
| `_current_morale` | `float` | Acumulada por eliminación (FR-006); persiste entre recargas (`spec.md` Assumptions); se pierde solo si el soldado es derrotado. |
| `_mode` | `enum SoldierMode {RIFLE, MELEE}` | Definido en `ARCHITECTURE.md` §4.4. |
| `_current_target` | `Enemigo` (nullable) | Objetivo activo — ver `research.md` §1. Implementado como `Node2D` + despacho dinámico (`Object.call()`) porque `Enemigo` no existía como clase cuando se escribió `soldado.gd`; ahora que sí existe (T025/T026), sigue sin tipar directamente — observación no bloqueante de `qa-validator` en T027/T028, marcada con `TODO (T047)` en la cabecera y en los dos puntos de llamada de `scenes/units/soldado.gd` para revisarla en la fase de Polish. |
| `_grid_cell` | `Vector2i` | Celda ocupada en el `BoardManager` del nivel. |

**Transiciones de estado** (`_mode`):
- `RIFLE → MELEE`: automática cuando `_current_ammo` llega a `0` (FR-004).
- `MELEE → RIFLE`: al recargar (`_current_ammo` vuelve a `> 0`), conservando `_current_morale` (FR-009, `spec.md` Assumptions).

**Señales emitidas** (ver `contracts/signals.md` para firmas completas):
`ammo_depleted`, `mode_changed`, `moral_changed`, `soldier_defeated`.

### Enemigo (`scenes/enemies/EnemigoBase.tscn` + `enemigo.gd`)

`CharacterBody2D` raíz (avanza con `move_and_slide()`).

| Variable | Tipo | Notas |
|---|---|---|
| `stats` | `EnemyStats` (`@export`) | Solo lectura. |
| `_current_health` | `int` | Runtime, inicializado desde `stats.max_health`. |

**Señales emitidas** (ver `contracts/signals.md` para firmas completas):
`enemy_defeated(ammo_dropped: int, position: Vector2)`,
`reached_defended_position()`.

### Munición recolectada (estado, no clase — vive en `EconomyManager`)

| Variable | Tipo | Notas |
|---|---|---|
| `collected_ammo` | `int` | Pool global único y compartido (FR-008, `spec.md` Assumptions). Ningún otro nodo mantiene copia propia (`ARCHITECTURE.md` §4.1). |

### Posición defendida

No es una clase — es una `Area2D` de límite en `Nivel_MonteCalvo.tscn`; al
recibir `body_entered` de un `Enemigo`, ese enemigo emite
`reached_defended_position()`, que `GameStateManager` escucha para terminar
la partida en derrota (FR-013).

## Relaciones

```
UnitStats (1) ←--- (N) Soldado         [Resource compartido, solo lectura]
EnemyStats (1) ←--- (N) Enemigo        [Resource compartido, solo lectura]
WaveData (1) ---→ (N) WaveSpawnEntry ---→ (1) EnemyStats
BoardManager (1) ---→ (0..N) Soldado   [por celda ocupada, no ownership de ciclo de vida]
EconomyManager (1) ---→ (1) collected_ammo   [pool global único]
```

## Validaciones derivadas de los requisitos

- FR-001 / FR-010: `BoardManager.is_cell_free(cell)` DEBE ser `false` para rechazar despliegue en celda ocupada.
- FR-011: desplegar/recargar exige `EconomyManager.collected_ammo >= costo`; si no, la acción se rechaza y se informa al jugador (ver `contracts/signals.md`, señal de rechazo).
- FR-002: `Soldado._current_target` nunca apunta a más de un `Enemigo` a la vez (invariante, no hay array de objetivos simultáneos).
