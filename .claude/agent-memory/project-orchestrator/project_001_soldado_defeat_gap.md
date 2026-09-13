---
name: project-001-soldado-defeat-gap
description: Gap crítico de diseño en 001-soldado-defensor-oleadas -- el soldado no podía ser derrotado en juego real por un Enemigo. AMBAS causas raíz quedaron resueltas y aprobadas por qa-validator (T050-T053, commit 564457e marca las 4 tareas [X]). No reabrir salvo regresión nueva.
metadata:
  type: project
---

Durante `001-soldado-defensor-oleadas`, el edge case de derrota del `Soldado` (FR-013/Acceptance Scenario 3 de US3, `spec.md` línea 76) resultó tener **dos causas raíz distintas**, descubiertas en dos rondas separadas de auditoría. **Ambas están cerradas a 2026-09-12.**

## Causa 1 (T043, resuelta 2026-09-12): soldado sin mecanismo de derrota + bloqueo físico

Ver commit `ffe77bf` (graduado a `docs/SPEC.md` §10). La persona autorizó insertar T050-T054 en `tasks.md` (commit `b80413c`) para dar a `Soldado` salud, `take_damage()`, `soldier_defeated` y liberación de celda.

## Causa 2 (T053, RESUELTA 2026-09-12): `Area2D` de detección desincronizada — decisión tomada: invertir el detector

`qa-validator` auditó una primera implementación de T053 (commit `abdf835`: `enemigo.gd` con `Area2D` "RangoAtaque" propia) y encontró, con evidencia empírica propia (`PhysicsDirectSpaceState2D.intersect_shape()` confirmando solapamiento geométrico real y sostenido), un hallazgo de motor **reutilizable para cualquier feature futura de este proyecto**:

> Un `Area2D` hijo de un `CharacterBody2D` que llama `move_and_slide()` cada `_physics_process` **nunca actualiza su lista interna de overlaps** (`get_overlapping_bodies()`) contra un `StaticBody2D`, aunque `intersect_shape()` confirme solapamiento real — `body_entered`/`body_exited` de esa `Area2D` nunca disparan en juego real.

Este hallazgo ya está graduado a **`docs/ARCHITECTURE.md` §4.2** (regla práctica: la `Area2D` detectora de una interacción debe vivir en el lado estático de la interacción, no en el nodo que se mueve con `move_and_slide()`) y a **`docs/SPEC.md` §10** (cierre del gap). No hace falta volver a buscar esta explicación en memoria — está en los documentos de proyecto.

**Decisión tomada por la persona** (de las 4 alternativas escaladas): **opción 1, invertir qué lado dispara la interacción**. El daño al `Soldado` lo dispara la propia `Area2D` "RangoMelee" del `Soldado` (`StaticBody2D`, detección fiable desde T023), no una `Area2D` nueva del lado del `Enemigo` en movimiento.

**Segunda implementación (commit `0f9dd75`, aprobada por `qa-validator` sin objeciones)**:
- `enemigo.gd`/`EnemigoBase.tscn`: se eliminó por completo la `Area2D` "RangoAtaque" y su lógica. `Enemigo` solo expone `get_melee_damage() -> int` (retorna `stats.melee_damage`).
- `soldado.gd`: `_process_incoming_melee_damage(delta)`, corre siempre en `_physics_process` (independiente de `_mode` RIFLE/MELEE — un enemigo adyacente daña al soldado aunque todavía tenga munición), usando `_melee_candidates` (misma lista que ya alimenta el ataque saliente a machete desde T023). Daño a **todos** los candidatos presentes en RangoMelee, no solo `_current_melee_target` (supuesto explícito, avalado por `qa-validator`: el Edge Case dice "los enemigos" en plural y ninguna FR restringe a un único atacante). Cadencia fija `_INCOMING_MELEE_ATTACK_INTERVAL = 1.0` (1 golpe/segundo por enemigo — supuesto de implementación, sin campo de cadencia en `EnemyStats`).
- `godot-tester` encontró y corrigió un bug de test preexistente en T051 (`ca30dc6`: `assert_signal_emitted` sobre un `Soldado` ya liberado de memoria tras 400 frames — no es un bug de implementación) y agregó un test discriminante para el supuesto "daño a todos los candidatos" (`qa-validator` lo verificó parcheando temporalmente `soldado.gd` para confirmar que el test sí falla si se limita a un único objetivo).
- Documentación: `docs-writer` graduó todo lo anterior en `docs/SPEC.md` §10 y `docs/ARCHITECTURE.md` §4.2/§5 (commit `1b52023`).

**Why:** Este archivo se conserva (en vez de borrarse) porque el hallazgo de motor sigue siendo relevante para cualquier `Area2D` nueva que se agregue a un `CharacterBody2D` en movimiento en features futuras de este proyecto — aunque ya está graduado a `ARCHITECTURE.md`, esta entrada da el contexto narrativo completo (las 2 rondas de auditoría, las 4 alternativas descartadas) por si hace falta justificar la regla ante alguien que pregunte "por qué".

**How to apply:** No reabrir T050-T053 salvo que aparezca una regresión real y nueva (ej. un test que antes pasaba y ahora falla) — todas fueron aprobadas por `qa-validator` con evidencia propia, no solo con el reporte de los agentes anteriores. Si una feature futura de este proyecto necesita que un nodo en movimiento (`CharacterBody2D`/`move_and_slide()`) detecte algo vía `Area2D`, consultar primero `docs/ARCHITECTURE.md` §4.2 antes de repetir el patrón que falló aquí. Ver también [[feedback-no-speckit-implement-directo]] y [[reference-issue-1]].
