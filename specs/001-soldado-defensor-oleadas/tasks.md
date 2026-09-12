---

description: "Task list template for feature implementation"
---

# Tasks: Soldado Defensor con Munición y Moral

**Input**: Design documents from `/specs/001-soldado-defensor-oleadas/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/signals.md](./contracts/signals.md), [quickstart.md](./quickstart.md)

**Tests**: Incluidas explícitamente (pedido del usuario) — GUT, cubriendo como mínimo lo que exige `constitution.md` Principio II: cálculo de daño (fusil y machete), consumo/recolección de munición, acumulación de moral, condición de victoria/derrota, y generación de oleadas.

**Organization**: Tareas agrupadas por user story (P1/P2/P3 de `spec.md`) para permitir implementación y prueba independiente de cada una.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: se puede ejecutar en paralelo (archivos distintos, sin dependencias pendientes)
- **[Story]**: a qué user story pertenece (US1, US2, US3)
- Rutas de archivo exactas en cada descripción, según `plan.md` §Project Structure

## Path Conventions

Proyecto único Godot 4.7 (GDScript). Rutas relativas a `res://` — ver
`plan.md` §Project Structure para el árbol completo.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: inicialización del proyecto — nada de esto existe todavía en el repo.

- [X] T001 Crear la estructura de carpetas de `plan.md` §Project Structure: `scenes/{units,enemies,levels,ui}/`, `resources/{schemas,units,enemies,waves}/`, `autoloads/`, `core/`, `tests/unit/{units,enemies,systems}/`
- [X] T002 [P] Instalar el addon **GUT** (Godot Unit Testing) en `res://addons/gut/` y habilitarlo en Project Settings → Plugins — requerido por `constitution.md` Principio II y asumido por `docs/ARCHITECTURE.md` §6, pero todavía no está en el repo
- [X] T003 [P] Configurar en `project.godot` los `InputMap` actions necesarios para colocar/recolectar (ej. `select_cell`, `collect_pickup`) — sin teclas/toques hardcodeados, por `docs/ARCHITECTURE.md` §7

**Checkpoint**: proyecto listo para recibir código de las fases siguientes.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: infraestructura compartida que las 3 user stories necesitan. Nada de las fases 3-5 puede empezar hasta terminar esta.

**⚠️ CRITICAL**: no iniciar ninguna user story hasta que esta fase esté completa.

- [X] T004 [P] Crear `UnitStats` (`class_name UnitStats extends Resource`) en `resources/schemas/unit_stats.gd` con campos de `data-model.md` (`max_ammo`, `damage_per_shot`, `fire_rate`, `machete_base_damage`, `machete_moral_multiplier`, `moral_per_kill`, `deploy_ammo_cost`), todos `@export_range` por `docs/ARCHITECTURE.md` §4.3
- [X] T005 [P] Crear `EnemyStats` (`class_name EnemyStats extends Resource`) en `resources/schemas/enemy_stats.gd` con `max_health`, `move_speed`, `melee_damage`, `ammo_drop`, todos `@export_range`
- [X] T006 [P] Crear `WaveSpawnEntry` (`class_name WaveSpawnEntry extends Resource`) en `resources/schemas/wave_spawn_entry.gd` con `enemy_stats: EnemyStats`, `count`, `spawn_interval`
- [ ] T007 Crear `WaveData` (`class_name WaveData extends Resource`) en `resources/schemas/wave_data.gd` con `wave_number`, `spawn_entries: Array[WaveSpawnEntry]` (depende de T006)
- [ ] T008 [P] Crear autoload `EconomyManager` en `autoloads/economy_manager.gd`: `collected_ammo: int`, señales `ammo_pool_changed(new_amount)` y `ammo_pickup_spawned(pickup_id, position, amount)`, según `contracts/signals.md`
- [ ] T009 [P] Crear autoload `GameStateManager` en `autoloads/game_state_manager.gd`: `enum GameState {PLAYING, PAUSED, WON, LOST}`, señales `game_won`, `game_lost`, `game_state_changed(new_state)`
- [ ] T010 Registrar `EconomyManager` y `GameStateManager` como autoloads en `project.godot` (depende de T008, T009)
- [ ] T011 [P] Crear `ObjectPool` genérico en `core/object_pool.gd` por `docs/ARCHITECTURE.md` §4.5 (no autoload; reutilizable por enemigos y proyectiles)
- [ ] T012 [P] Crear `BoardManager` en `core/board_manager.gd` por `research.md` §5: `Dictionary[Vector2i, Node]` de celdas ocupadas, `is_cell_free(cell)`, `occupy_cell(cell, node)`, `free_cell(cell)`
- [ ] T013 [P] Test GUT `test_economy_manager.gd` en `tests/unit/systems/test_economy_manager.gd`: sumar/gastar munición, emisión de `ammo_pool_changed` — cubre "consumo/recolección de munición" de `constitution.md` Principio II (depende de T008; DEBE fallar antes de completar T008)
- [ ] T014 [P] Test GUT `test_board_manager.gd` en `tests/unit/systems/test_board_manager.gd`: `is_cell_free` refleja correctamente ocupación/liberación de celdas (depende de T012)

**Checkpoint**: fundación lista — las user stories pueden empezar.

---

## Phase 3: User Story 1 - Defensa automática de un soldado (Priority: P1) 🎯 MVP

**Goal**: un soldado colocado dispara automáticamente a un único objetivo prioritario (carril frontal + diagonales), agota munición, y transiciona a machete con daño escalado por moral — sin ninguna acción del jugador por evento.

**Independent Test**: un solo soldado frente a un solo enemigo que avanza — dispara automáticamente, agota munición, transiciona a machete sin intervención del jugador (`spec.md`).

### Tests for User Story 1 (GUT — pedidos explícitamente) ⚠️

> Escribir estos tests PRIMERO; deben FALLAR antes de implementar.

- [ ] T015 [P] [US1] Test `test_soldado.gd` en `tests/unit/units/test_soldado.gd`: daño de fusil por disparo, consumo de munición por disparo, transición automática RIFLE→MELEE al llegar a 0 munición, daño de machete = `machete_base_damage + moral * machete_moral_multiplier` (incluyendo caso moral=0 con daño base > 0), acumulación de moral **solo** por eliminación (no por impacto sin matar) — cubre "cálculo de daño" y "acumulación de moral" de `constitution.md` Principio II (depende de T004)
- [ ] T016 [P] [US1] Test `test_enemigo.gd` en `tests/unit/enemies/test_enemigo.gd`: recepción de daño, muerte al llegar salud a 0, emisión de `enemy_defeated(ammo_dropped)` con el valor de `stats.ammo_drop` (depende de T005)

### Implementation for User Story 1

- [ ] T017 [P] [US1] Crear `resources/units/soldado_base_stats.tres` instanciando `UnitStats` con valores iniciales de balance (depende de T004)
- [ ] T018 [P] [US1] Crear `resources/enemies/enemigo_infanteria_base.tres` instanciando `EnemyStats` con valores iniciales de balance (depende de T005)
- [ ] T019 [P] [US1] Crear `scenes/units/Soldado.tscn`: `StaticBody2D` raíz + `AnimatedSprite2D` + `Area2D` "DeteccionRango" + `Area2D` "RangoMelee" + `CollisionShape2D`, por `docs/ARCHITECTURE.md` §5
- [ ] T020 [US1] `scenes/units/soldado.gd`: estado runtime (`stats: UnitStats` exportado, `_current_ammo`, `_current_morale`, `_mode: SoldierMode`, `_current_target`), inicialización desde `stats` en `_ready()`, `@onready` a las `Area2D` hijas (depende de T017, T019)
- [ ] T021 [US1] `soldado.gd`: selección/seguimiento de objetivo vía `body_entered`/`body_exited` de "DeteccionRango" — lista de candidatos, prioridad = enemigo más avanzado, sin dividir fuego (FR-002), por `research.md` §1 (depende de T020)
- [ ] T022 [US1] `soldado.gd`: disparo automático a `_current_target` con cadencia `stats.fire_rate`, decremento de `_current_ammo`, emisión `ammo_depleted` al llegar a 0 (depende de T021)
- [ ] T023 [US1] `soldado.gd`: transición automática a `MELEE` al recibir `ammo_depleted`, emisión `mode_changed`, ataque contra enemigos en "RangoMelee" con el daño calculado en T015 (depende de T022)
- [ ] T024 [US1] `soldado.gd`: acumulación de moral (`_current_morale += stats.moral_per_kill`) al confirmar una eliminación propia, emisión `moral_changed` (depende de T023)
- [ ] T025 [P] [US1] Crear `scenes/enemies/EnemigoBase.tscn`: `CharacterBody2D` raíz + `AnimatedSprite2D` + `CollisionShape2D`, por `docs/ARCHITECTURE.md` §5
- [ ] T026 [US1] `scenes/enemies/enemigo.gd`: estado runtime (`stats: EnemyStats`, `_current_health`), avance con `move_and_slide()`, recepción de daño, muerte y emisión `enemy_defeated(ammo_dropped, position)` (depende de T018, T025)
- [ ] T027 [US1] Crear `scenes/levels/Nivel_MonteCalvo.tscn` mínimo (un `TileMap` simple, un soldado colocado a mano, spawn manual de un enemigo) — suficiente para el Independent Test de esta user story (depende de T020, T026)
- [ ] T028 [US1] Conectar animaciones placeholder (disparo/machete/muerte) a `mode_changed`/`enemy_defeated` en `soldado.gd`/`enemigo.gd` — feedback visual mínimo por `constitution.md` Principio III (depende de T023, T026)

**Checkpoint**: US1 completamente funcional y testeable de forma independiente.

---

## Phase 4: User Story 2 - Recolección de munición y reabastecimiento (Priority: P2)

**Goal**: los enemigos derrotados sueltan munición recolectable que el jugador usa para recargar soldados existentes o desplegar nuevos.

**Independent Test**: derrotar un enemigo, verificar que suelta munición recolectable, confirmar que sirve tanto para recargar como para desplegar (`spec.md`).

### Tests for User Story 2 (GUT) ⚠️

- [ ] T029 [P] [US2] Ampliar `test_economy_manager.gd` (`tests/unit/systems/test_economy_manager.gd`): rechazo (`deploy_or_reload_rejected`) al intentar gastar más munición de la disponible — cubre FR-011 (depende de T013)
- [ ] T030 [P] [US2] Ampliar `test_soldado.gd` (`tests/unit/units/test_soldado.gd`): recargar un soldado en modo `MELEE` lo vuelve a `RIFLE` **conservando** `_current_morale` (depende de T015)

### Implementation for User Story 2

- [ ] T031 [US2] Crear `scenes/levels/AmmoPickup.tscn` + `ammo_pickup.gd` (`Area2D` + sprite): recolección explícita por tap/click (no por proximidad), por `research.md` §3 (depende de T008)
- [ ] T032 [US2] `enemigo.gd`: al emitir `enemy_defeated`, instanciar `AmmoPickup` en su posición vía `EconomyManager.ammo_pickup_spawned` (depende de T026, T031)
- [ ] T033 [US2] `EconomyManager`: métodos `try_spend_ammo(amount)` / `add_ammo(amount)`, emitiendo `deploy_or_reload_rejected(reason)` cuando la munición disponible es insuficiente (depende de T008)
- [ ] T034 [US2] `soldado.gd`: método público `reload()` que gasta munición vía `EconomyManager.try_spend_ammo()` y, si tiene éxito, vuelve a `RIFLE` conservando `_current_morale` (depende de T020, T033)
- [ ] T035 [US2] `nivel_monte_calvo.gd`: interacción de despliegue de soldado nuevo en celda vacía, consultando `BoardManager.is_cell_free()` y `EconomyManager.try_spend_ammo(stats.deploy_ammo_cost)` (depende de T012, T027, T033)
- [ ] T036 [US2] Crear `scenes/ui/HUD.tscn` + `hud.gd`: contador global de munición recolectada (escucha `ammo_pool_changed`) y mensaje visible al recibir `deploy_or_reload_rejected` (depende de T008)

**Checkpoint**: US1 + US2 funcionan juntas (defensa + economía).

---

## Phase 5: User Story 3 - Resistir oleadas crecientes (Priority: P3)

**Goal**: oleadas sucesivas de dificultad creciente; la partida termina en derrota si un enemigo alcanza la posición defendida, o en victoria al completar todas las oleadas.

**Independent Test**: partida completa donde las oleadas son perceptiblemente más difíciles y termina en derrota si un enemigo llega a la posición defendida (`spec.md`).

### Tests for User Story 3 (GUT) ⚠️

- [ ] T037 [P] [US3] Test `test_wave_manager.gd` en `tests/unit/systems/test_wave_manager.gd`: secuencia de oleadas, emisión de `wave_started`/`wave_completed`/`all_waves_completed` — cubre "generación de oleadas" de `constitution.md` Principio II (depende de T007; DEBE fallar antes de implementar `wave_manager.gd`)
- [ ] T038 [P] [US3] Test `test_game_state_manager.gd` en `tests/unit/systems/test_game_state_manager.gd`: `game_lost` al recibir `reached_defended_position`, `game_won` al recibir `all_waves_completed` — cubre "condiciones de victoria/derrota" de `constitution.md` Principio II (depende de T009)

### Implementation for User Story 3

- [ ] T039 [P] [US3] Crear autoload `WaveManager` en `autoloads/wave_manager.gd`: consume `Array[WaveData]`, emite `wave_started`/`wave_completed`/`all_waves_completed` (depende de T007)
- [ ] T040 [US3] Registrar `WaveManager` como autoload en `project.godot` (depende de T039)
- [ ] T041 [P] [US3] Crear 3 a 10 `resources/waves/nivel_montecalvo_oleada_0N.tres` con dificultad creciente en composición/cantidad, por `research.md` §4 — cubre SC-005 (depende de T007, T018)
- [ ] T042 [US3] `nivel_monte_calvo.gd`: `WaveSpawner` (`Timer` + cola de spawns por `WaveSpawnEntry`), instanciando enemigos vía `ObjectPool` (depende de T011, T026, T039)
- [ ] T043 [US3] `Nivel_MonteCalvo.tscn`: `Area2D` de "posición defendida" que, al detectar `body_entered` de un `Enemigo`, hace que este emita `reached_defended_position()` (depende de T026, T027)
- [ ] T044 [US3] `GameStateManager`: escuchar `reached_defended_position` → `game_lost`; escuchar `all_waves_completed` → `game_won` (depende de T009, T039, T043)
- [ ] T045 [US3] `hud.gd`: feedback de "oleada por llegar" (`wave_started`) y pantallas de victoria/derrota (`game_won`/`game_lost`) (depende de T036, T044)

**Checkpoint**: las tres user stories funcionan juntas — MVP completo de la feature.

---

## Phase Final: Polish & Cross-Cutting Concerns

- [ ] T046 [P] Ejecutar los 3 escenarios de [quickstart.md](./quickstart.md) como smoke test manual y documentar resultados — exigido por `constitution.md` Principio II antes de compartir un build
- [ ] T047 [P] Revisar todo el código nuevo contra `docs/ARCHITECTURE.md` (tipo de nodo raíz, `@onready`, señales conectadas solo en `_ready()`, regla dato/estado del `Resource`, `queue_free()` vs `free()`)
- [ ] T048 Graduar hacia `docs/SPEC.md` cualquier decisión de balance final (constantes de `UnitStats`/`EnemyStats` ajustadas en playtesting), si corresponde
- [ ] T049 [P] Ejecutar la suite completa de GUT y confirmar 0 fallos antes de considerar la feature lista para PR

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sin dependencias — puede empezar de inmediato
- **Foundational (Phase 2)**: depende de Setup — bloquea las 3 user stories
- **User Stories (Phase 3-5)**: todas dependen de Foundational; pueden avanzar en paralelo si hay capacidad, o en orden de prioridad P1 → P2 → P3
- **Polish (Fase Final)**: depende de que las user stories que se quieran entregar estén completas

### User Story Dependencies

- **US1 (P1)**: solo depende de Foundational — sin dependencia de otras stories
- **US2 (P2)**: depende de Foundational; se integra con `Soldado`/`Enemigo` de US1 pero es testeable de forma independiente (economía en aislado vía `EconomyManager`)
- **US3 (P3)**: depende de Foundational; se integra con `Enemigo` de US1 y el nivel de US2, pero el `WaveManager`/`GameStateManager` son testeables de forma independiente

### Dentro de cada User Story

- Tests GUT se escriben y deben FALLAR antes de la implementación correspondiente
- Resource schemas/instancias antes que las escenas que los usan
- Escenas (`.tscn`) antes que la lógica (`.gd`) que asume su estructura de nodos
- Historia completa antes de pasar a la siguiente en orden de prioridad

### Parallel Opportunities

- T002, T003 (Setup) en paralelo
- T004, T005, T006, T008, T009, T011, T012 (Foundational, archivos distintos) en paralelo; T007, T010 esperan sus dependencias
- T013, T014 (tests foundational) en paralelo entre sí
- Dentro de US1: T015/T016 (tests) en paralelo; T017/T018/T019/T025 (recursos/escenas) en paralelo; la cadena T020→T021→T022→T023→T024 es secuencial (mismo archivo `soldado.gd`)
- Dentro de US2: T029/T030 en paralelo
- Dentro de US3: T037/T038 en paralelo; T039/T041 en paralelo

---

## Parallel Example: User Story 1

```bash
# Tests en paralelo:
Task: "Test test_soldado.gd en tests/unit/units/test_soldado.gd"
Task: "Test test_enemigo.gd en tests/unit/enemies/test_enemigo.gd"

# Recursos y escenas en paralelo:
Task: "Crear resources/units/soldado_base_stats.tres"
Task: "Crear resources/enemies/enemigo_infanteria_base.tres"
Task: "Crear scenes/units/Soldado.tscn"
Task: "Crear scenes/enemies/EnemigoBase.tscn"
```

---

## Implementation Strategy

### MVP First (solo User Story 1)

1. Completar Fase 1: Setup
2. Completar Fase 2: Foundational (crítico — bloquea todo lo demás)
3. Completar Fase 3: User Story 1
4. **DETENERSE Y VALIDAR**: correr Escenario 1 de `quickstart.md` de forma independiente
5. Recién ahí considerar demo/entrega parcial

### Incremental Delivery

1. Setup + Foundational → base lista
2. US1 → validar con Escenario 1 de `quickstart.md` → MVP jugable (un soldado se defiende solo)
3. US2 → validar con Escenario 2 → economía completa
4. US3 → validar con Escenario 3 → juego completo (oleadas + victoria/derrota)
5. Cada story agrega valor sin romper las anteriores

---

## Notes

- `[P]` = archivos distintos, sin dependencias pendientes entre sí
- `[US1]`/`[US2]`/`[US3]` mapean cada tarea a su user story para trazabilidad
- Los tests deben fallar antes de implementar (TDD, pedido explícito del usuario para esta feature)
- Commitear después de cada tarea o grupo lógico — el pipeline de agentes (`dev-godot` → `godot-tester` → `qa-validator` → `docs-writer`) opera tarea por tarea, no por fase completa
- Evitar: tareas vagas, conflictos de archivo simultáneos, dependencias cruzadas entre stories que rompan su independencia
