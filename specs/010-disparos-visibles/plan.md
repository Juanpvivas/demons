# Implementation Plan: Disparos visibles

**Feature ID**: `010-disparos-visibles` | **Planned Branch**: `codex/010-disparos-visibles` | **Date**: 2026-10-23 | **Spec**: [spec.md](spec.md) | **Issue**: [#40](https://github.com/Juanpvivas/demons/issues/40)

Spec Kit prepara estos documentos mediante `demons-preparation`; la ejecución corresponde a los agentes de [DEVELOPMENT_WORKFLOW](../../docs/DEVELOPMENT_WORKFLOW.md).

## Summary

Un disparo confirmado solicita un snapshot por valor antes del daño síncrono. Un efecto 2D cosmético lo representa desde un pool separado del de bajas. La revisión autorizada del 2026-10-24 duplica destello/trazadora, muestra 0,30 s de recorrido y 0,10 s de desvanecido, y amplía el extremo frontal de 264 a 396 mediante stats. El actor conserva daño instantáneo, munición, cadencia y prioridad de blancos elegibles. Continúa **010-I1** en el mismo [PR #41 en borrador](https://github.com/Juanpvivas/demons/pull/41), con nuevo ciclo TDD/QA pendiente; T001–T012 conservan el resultado del perfil inicial.

## Technical Context

**Language/Version**: GDScript, Godot 4.7.1; GUT 9.7.1 existente.
**Primary Dependencies**: `Soldado`, `SoldadoVisual`, `UnitStats`/`.tres`, `CombatVisualEffects`, `ObjectPool`, `GameStateManager` y nivel actuales; sin dependencias nuevas.
**Storage**: ninguno; snapshots efímeros con dos `Vector2`.
**Testing**: GUT de alcance/productor/efecto/servicio/ciclo; revisión visual real, sesión manual de balance y smoke por destino disponible; CI de la revisión exacta.
**Target Platform**: Web en computador y apps Android/iOS; PC nativo sólo desarrollo/pruebas.
**Project Type**: juego 2D compartido; presentación observadora del combate existente.
**Performance Goals**: pooling obligatorio; duración visual total 0,40 s activo. El objetivo físico de publicación sigue pendiente; Issue #30 permanece pausado, sin probes ni nuevas campañas de rendimiento.
**Constraints**: sólo cambia el alcance frontal autorizado; sin proyectil físico, audio, retardo del daño, otros cambios de balance, cambio de corrida/atlas/materiales ni UI adicional. Preservar `project.godot` local de la persona; usar copias aisladas para variantes QA.
**Scale/Scope**: cinco soldados iniciales y reemplazos, disparos frontales/diagonales y simultáneos; una escena de efecto nueva y extensión del servicio local existente.

## Constitution Check

| Principio | Antes/después del diseño |
|-----------|--------------------------|
| I: separación y compatibilidad | Conforme al diseño: snapshot de hecho y presentación sin autoridad; alcance base en Resource de sólo lectura, geometría propia por actor y GDScript/code-native compatible. |
| II: TDD y regresión | Planificado para la revisión: RED real con APIs existentes → QA del RED → desarrollo → GREEN/regresión y playtesting de balance → QA. Carga/importación fallida no cuenta como RED. |
| III: feedback y destinos | Conforme al diseño: lectura pictórica, entrada intacta; resultados Web de computador y apps nativas separados. |
| IV: efectos reciclados | Conforme al diseño: segundo `ObjectPool`, reset por activación; no se declara rendimiento aprobado ni se reabre #30. QA declara anomalías observadas durante pruebas funcionales. |
| V: gates separados | Planificado: build/CI/documentación y APROBADO PARA INTEGRACIÓN; publicación pendiente sin distribución. |

La persona confirmó el perfil de tamaño, alcance y duración. Los contratos conservan daño inmediato y endpoints capturados; el tiempo de recorrido sólo gobierna presentación. Esta comprobación prepara la revisión; no acredita su implementación ni QA.

## Project Structure

```text
specs/010-disparos-visibles/
  spec.md, plan.md, research.md, data-model.md, quickstart.md, tasks.md
  contracts/rifle-shot-visual.md
  checklists/requirements.md
scenes/units/soldado.gd, soldado_visual.gd
resources/schemas/unit_stats.gd, resources/units/soldado_base_stats.tres
scenes/visuals/combat_visual_effects.gd
scenes/visuals/RifleShotVisualEffect.tscn, rifle_shot_visual_effect.gd
scenes/levels/nivel_monte_calvo.gd
tests/unit/units/test_soldado_rifle_effects.gd
tests/unit/units/test_horizontal_targeting.gd
tests/unit/systems/test_rifle_visual_effects.gd
tests/unit/game/test_game_root.gd
docs/SPEC.md, docs/ARCHITECTURE.md
```

**Structure Decision**: extender la presentación observadora local de `docs/ARCHITECTURE.md` §4.7. Sin autoload, cambios de pool genérico, escena de proyectil jugable ni arte raster nuevo.

## Execution Design

- Consultar GodotPrompter pertinente antes de implementar/revisar: señales/composición, `2d-essentials` con custom drawing, `animation-system`, pooling y testing/revisión. El flujo del repositorio prevalece sobre recetas genéricas.
- La boquilla pertenece a `SoldadoVisual.capture_rifle_shot_snapshot(target_world)`. `Soldado` captura y emite una vez después de consumir la bala y antes de `take_damage`; no retiene al blanco en el efecto.
- `RifleShotVisualEffect` conserva primitivas 2D y reloj propio: destello 26×12 de silueta y 0,14 s; trazadora de hasta 92 unidades, núcleo de 2,4 y halo de 6, con la paleta cálida mate vigente. La cabeza comienza en el cañón y alcanza el destino capturado en 0,30 s; mantiene intensidad durante el avance y desvanece en 0,10 s. El segmento se recorta a cañón/destino; vida total 0,40 s. Validar tamaño, anclaje y recorrido a escala de juego.
- El extremo frontal se configura en `UnitStats.rifle_range` y `soldado_base_stats.tres` con 396; el tramo comienza en 24 y conserva altura 192. `Soldado` deriva una forma propia por instancia y amplía la consulta física sin mutar Resource o forma compartidos. Conserva filtros de frente/fila/diagonales contiguas, solape corporal y prioridad actuales.
- `CombatVisualEffects` registra cada actor una vez y precalienta diez efectos de fusil; puede crecer. Sus conteos existentes siguen describiendo bajas. WON/LOST bloquean peticiones nuevas y dejan terminar las confirmadas; PAUSED congela el progreso. `close_match()`/MENU/Retry limpian antes de deshabilitar hijos y no reabren ese servicio.
- El setup neutro de T002 y el RED inicial son históricos. Esta revisión no necesita otro esqueleto: las APIs existentes permiten demostrar RED mediante un disparo frontal fuera del alcance anterior y una activación que debe sobrevivir a 0,20 s. El recorrido y tamaño tienen verificación visual proporcional, sin añadir APIs sólo para inspeccionar el dibujo.
- QA funcional, documentación y gate final se realizan en el mismo incremento. No versionar logs/capturas ni usar estos documentos como historial de ejecuciones.

## Complexity Tracking

Sin excepciones de arquitectura. El incremento agrupa contrato, productor, efecto/pool y pruebas porque forman un único feedback utilizable; si supera el tamaño orientativo del flujo, el orquestador justifica su cohesión y elimina cambios ajenos antes del PR.
