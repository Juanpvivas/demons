# Research: Soldado Defensor con Munición y Moral

Todos los `NEEDS CLARIFICATION` de nivel de producto ya se resolvieron en
`spec.md` (sección `Clarifications` + `Assumptions`). Este documento cubre
únicamente las decisiones **técnicas** de esta feature que
`docs/ARCHITECTURE.md` no fija en detalle — se documentan aquí en vez de
generalizarlas al documento de proyecto completo, siguiendo la relación
descrita en `ARCHITECTURE.md` §8 (un patrón se "gradúa" a ese documento solo
si aplica a todo el proyecto, no a una sola feature).

## 1. Selección y seguimiento del objetivo prioritario

**Decision**: la `Area2D` "DeteccionRango" del `Soldado` (ya definida en
`ARCHITECTURE.md` §5) emite `body_entered`/`body_exited`; `soldado.gd`
mantiene una `Array[Enemigo]` de candidatos actualmente dentro del área,
sin volver a escanear la escena cada frame. El objetivo activo se
recalcula solo en tres momentos: al entrar un enemigo nuevo, al salir el
enemigo actualmente targeteado, o al morir el enemigo actualmente
targeteado. La regla de prioridad (enemigo más avanzado hacia la posición
defendida, `spec.md` Assumptions) se aplica sobre esa lista pequeña, no
sobre todos los enemigos del nivel.

**Rationale**: cumple la regla de `godot-code-review`/`ARCHITECTURE.md` de
no hacer trabajo de detección dentro de `_process()`; el costo de
recalcular prioridad es proporcional a enemigos dentro del área de un
soldado (típicamente 1-3), no al total de enemigos activos.

**Alternatives considered**: escanear todos los enemigos del nivel cada
frame por distancia — rechazado, no escala con oleadas grandes y viola el
principio de Rendimiento de la constitución.

## 2. Fórmula de daño del machete según moral

**Decision**: `machete_damage = machete_base_damage + current_morale *
machete_moral_multiplier`, con `machete_base_damage` y
`machete_moral_multiplier` como campos `@export_range` en `UnitStats` (no
hardcodeados). Esto resuelve la pregunta abierta de `docs/SPEC.md` §10
("Fórmula exacta de daño en modo machete según moral acumulada") con una
fórmula lineal simple; los valores numéricos exactos quedan para
playtesting (`constitution.md` Principio II ya exige sesión de playtesting
manual antes de mergear cualquier cambio de balance).

**Rationale**: una fórmula lineal es la más simple que satisface FR-005
("el daño DEBE calcularse en función de la moral") y el edge case de daño
base mínimo cuando la moral es cero (`spec.md` Edge Cases) — con
`machete_base_damage > 0` ese caso queda cubierto sin lógica especial.

**Alternatives considered**: fórmula exponencial/escalonada — rechazada
por ahora, agrega complejidad sin requisito que la justifique; puede
revisarse tras playtesting si el lineal se siente plano.

## 3. Mecánica de recolección de munición soltada

**Decision**: la munición soltada por un enemigo derrotado se representa
como una pickup (`Area2D` + sprite) que el jugador recolecta con una
acción explícita (tap/click sobre ella), no por proximidad automática.

**Rationale**: consistencia entre touch (Android/iOS) y mouse (PC) sin
cambiar el significado de la acción (`constitution.md` Principio III) — una
recolección "automática por cercanía" es ambigua en touch (no hay cursor
que "esté cerca"), mientras que un tap/click es la misma acción discreta en
ambas plataformas. También le da al jugador control explícito sobre el
ritmo de la economía, coherente con el patrón de referencia (recolección de
"sol" en Plants vs. Zombies, citado en `docs/SPEC.md` §3).

**Alternatives considered**: recolección automática al pasar un soldado o
el "cursor" cerca — rechazada por la ambigüedad de "cercanía" en touch y
porque le quita al jugador el control deliberado sobre cuándo capturar el
recurso.

## 4. Definición de oleadas: datos vs. procedural

**Decision**: cada oleada es un `WaveData` (`.tres`) autorado individualmente
en `resources/waves/`, no generado por fórmula procedural en código. El
`WaveManager` (autoload) consume una `Array[WaveData]` en orden.

**Rationale**: es la lectura directa de `ARCHITECTURE.md` §2
(`resources/waves/ # definición de oleadas por nivel (.tres)`) y del
principio de Calidad de Código (balance = editar `.tres`, nunca tocar
scripts). Autorar oleadas a mano también le da control total a diseño sobre
el incremento "perceptible" de dificultad que exige SC-005, sin depender de
ajustar constantes de una fórmula a ciegas.

**Alternatives considered**: generación procedural de oleadas (fórmula de
crecimiento en `wave_manager.gd`) — rechazada para el MVP; se puede
introducir más adelante como una fuente adicional de `WaveData` generada en
runtime, sin romper el contrato del `WaveManager` (sigue consumiendo
`WaveData`, solo cambia su origen).

## 5. Validación de colocación y ocupación del tablero

**Decision**: nuevo `core/board_manager.gd` (no autoload, instanciado por
`Nivel_MonteCalvo.tscn`) mantiene un diccionario `{Vector2i: Soldado}` de
celdas ocupadas. Antes de desplegar un soldado (FR-001, FR-010), el nivel
consulta `board_manager.is_cell_free(cell)`; al derrotar un soldado, se
libera su celda (`spec.md` Edge Cases: "libera esa posición del tablero").

**Rationale**: `ARCHITECTURE.md` §4.5 ya establece el precedente de que
lógica compartida no-autoload y reutilizable entre features/niveles futuros
vive en `core/` (igual que `ObjectPool`) — un grid de ocupación de tablero
es exactamente ese tipo de utilidad, y un nivel futuro (post-MVP) la
reutilizaría sin cambios. No se declara autoload porque el estado de
ocupación es por-nivel, no global de la partida completa.

**Alternatives considered**: usar el propio `TileMap` de Godot con
metadata de celda para trackear ocupación — rechazada por ahora: acopla la
lógica de validación a la API de `TileMap` en vez de a una estructura de
datos simple testeable con GUT sin necesidad de escena.

## Resumen

Ningún `NEEDS CLARIFICATION` queda abierto para Fase 1. Las cinco
decisiones de arriba son consistentes con `docs/ARCHITECTURE.md` y
`constitution.md`; ninguna requiere una entrada en `Complexity Tracking`.
