---
name: project-001-soldado-defeat-gap
description: Gap crítico de diseño en 001-soldado-defensor-oleadas -- el soldado no puede ser derrotado en juego real por un Enemigo. Primera causa (colisión física) ya resuelta por autorización de T050-T054; segunda causa (Area2D de detección desincronizada) sigue AMBIGUA, pendiente de decisión humana antes de marcar T053 [X] o avanzar a T054/T044.
metadata:
  type: project
---

Durante `001-soldado-defensor-oleadas`, el edge case de derrota del `Soldado` (FR-013/Acceptance Scenario 3 de US3, `spec.md` línea 76) resultó tener **dos causas raíz distintas**, descubiertas en dos rondas separadas de auditoría:

## Causa 1 (T043, resuelta 2026-09-12): soldado sin mecanismo de derrota + bloqueo físico

Ver commit `ffe77bf` (graduado a `docs/SPEC.md` §10) y detalle ya registrado antes en esta misma memoria. **Resuelta**: la persona autorizó insertar T050-T054 en `tasks.md` (commit `b80413c`) para dar a `Soldado` salud, `take_damage()`, `soldier_defeated` y liberación de celda. T050 (`max_health` en `UnitStats`), T051 (tests) y T052 (`soldado.gd`: salud/take_damage/die) quedaron implementados y correctos según `qa-validator` (auditoría de la misma sesión, 2026-09-12): 18/19 tests de `test_soldado.gd` pasan, sin objeciones a T050/T052.

## Causa 2 (T053, AMBIGUA, sin resolver a 2026-09-12): `Area2D` de detección desincronizada

`qa-validator` auditó T053 (`enemigo.gd`: nuevo `Area2D` "RangoAtaque" para que el `Enemigo` ataque activamente al `Soldado`) y encontró, con evidencia empírica propia (no solo del reporte de `godot-tester` que lo detectó primero), un problema de motor no documentado antes en el proyecto:

- Un `Area2D` hijo de un `CharacterBody2D` que llama `move_and_slide()` cada `_physics_process` (como "RangoAtaque" sobre `Enemigo`) **nunca actualiza su lista interna de overlaps** (`get_overlapping_bodies()`) contra un `StaticBody2D` (`Soldado`) — a pesar de que `PhysicsDirectSpaceState2D.intersect_shape()` (consulta directa al motor, independiente del tracking del `Area2D`) confirma solapamiento geométrico real y sostenido.
- Consecuencia: `body_entered`/`body_exited` de "RangoAtaque" nunca disparan contra un `Soldado` real → `_process_melee_attack()` nunca encuentra objetivo → `Soldado.take_damage()` nunca se llama desde un `Enemigo` real → el soldado sigue siendo, en la práctica, indestructible en una partida real, aunque T051/T052 prueben (con llamadas directas a `take_damage()`) que el mecanismo en sí funciona.
- Se descartó que sea un test débil: el test (`test_soldier_is_defeated_by_a_real_enemy_attacking_within_rango_melee`, `tests/unit/units/test_soldado.gd:652`) usa un `Enemigo` real, no mocks, y tanto `godot-tester` como `qa-validator` reprodujeron la falla de forma independiente.
- Se descartó que sea un error trivial de geometría/offset: el cálculo de `dev-godot` (offset y tamaño de "RangoAtaque" vs "RangoMelee" del `Soldado`) es correcto y el patrón usado (`Area2D` + señales conectadas en `_ready()`) es exactamente el que exige `docs/ARCHITECTURE.md` §4.2 — y es el mismo patrón que sí funciona en sentido inverso (el `Soldado`, `StaticBody2D`, detecta correctamente al `Enemigo` en movimiento vía su propia "RangoMelee").

Veredicto de `qa-validator` para el conjunto T050-T053: **AMBIGUO — requiere decisión humana**. Las 4 alternativas esbozadas (sin resolver, ninguna elegida):

1. Invertir qué lado dispara la interacción: que el daño al `Soldado` se dispare desde su propia "RangoMelee" (que sí detecta de forma fiable, por ser dueña de ella un `StaticBody2D`), en vez de depender de una `Area2D` nueva sobre el `Enemigo` en movimiento.
2. Reemplazar la detección basada en `Area2D`/señales por consultas manuales a `PhysicsDirectSpaceState2D.intersect_shape()` cada `_physics_process` — funciona (verificado por `qa-validator`), pero es una desviación del único patrón hoy documentado en `ARCHITECTURE.md` §4.2 ("Área2D + señales conectadas solo en `_ready()`"), y ameritaría documentarse como excepción.
3. Resolver vía `collision_layer`/`collision_mask` (la decisión ya pendiente desde T043 en `docs/SPEC.md` §10) — podría o no resolver esto como efecto colateral, no verificado por nadie todavía.
4. Otro rediseño que la persona prefiera.

**Why:** El pipeline se detuvo aquí (después de T053, antes de T054/T044) porque avanzar sin resolver esto construiría T054 (liberar celda al derrotar) y T044 (conectar derrota→game_lost) sobre un mecanismo de ataque que nunca dispara en juego real — igual que la Causa 1, es una decisión de diseño/arquitectura de detección física que le corresponde a la persona, no al orquestador ni a los subagentes (no hay "opción más razonable" objetivamente correcta entre invertir la detección, usar polling de física, o tocar collision layers).

**How to apply:** Antes de retomar T053/T054/T044 en cualquier sesión futura, verificar primero si la persona ya resolvió esta ambigüedad (buscar en `tasks.md` cambios al texto de T053, un nuevo commit sobre `enemigo.gd`/`Soldado.tscn` con un mecanismo de detección distinto al descrito arriba, o una nota nueva en `docs/SPEC.md` §10 marcando esta pregunta como resuelta). Si no hay señal de resolución, volver a escalar con las 4 alternativas tal cual, no asumir ninguna. T050-T052 (commits `89d8ea0`, `fb0c500`, `332b338`) siguen correctos y no necesitan revisarse de nuevo salvo que cambien de contexto. Ver también [[feedback-no-speckit-implement-directo]] y [[reference-issue-1]].
