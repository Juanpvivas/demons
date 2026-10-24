# Implementation Plan: Disparos visibles

**Feature ID**: `010-disparos-visibles` | **Planned Branch**: `codex/010-disparos-visibles` | **Date**: 2026-10-23 | **Spec**: [spec.md](spec.md) | **Issue**: [#40](https://github.com/Juanpvivas/demons/issues/40)

Spec Kit prepara estos documentos mediante `demons-preparation`; la ejecución corresponde a los agentes de [DEVELOPMENT_WORKFLOW](../../docs/DEVELOPMENT_WORKFLOW.md).

## Summary

Un disparo confirmado solicita un snapshot por valor antes del daño síncrono. Un efecto 2D cosmético, con destello cálido mate y trazadora breve, lo representa desde un pool separado del de bajas. El actor conserva daño instantáneo, munición, cadencia y blancos. Un solo incremento **010-I1** entrega el ciclo TDD, revisión visual, documentación y PR en borrador.

## Technical Context

**Language/Version**: GDScript, Godot 4.7.1; GUT 9.7.1 existente.
**Primary Dependencies**: `Soldado`, `SoldadoVisual`, `CombatVisualEffects`, `ObjectPool`, `GameStateManager` y nivel actuales; sin dependencias nuevas.
**Storage**: ninguno; snapshots efímeros con dos `Vector2`.
**Testing**: GUT de productor/efecto/servicio/ciclo; revisión visual real y smoke por destino disponible; CI de la revisión exacta.
**Target Platform**: Web en computador y apps Android/iOS; PC nativo sólo desarrollo/pruebas.
**Project Type**: juego 2D compartido; presentación observadora del combate existente.
**Performance Goals**: pooling obligatorio; duración visual total ≤0,20 s activo. El objetivo físico de publicación sigue pendiente; Issue #30 permanece pausado, sin probes ni nuevas campañas de rendimiento.
**Constraints**: sin proyectil físico, audio, rebalance, cambio de corrida/atlas/materiales ni UI adicional. Preservar `project.godot` local de la persona; usar copias aisladas para variantes QA.
**Scale/Scope**: cinco soldados iniciales y reemplazos, disparos frontales/diagonales y simultáneos; una escena de efecto nueva y extensión del servicio local existente.

## Constitution Check

| Principio | Antes/después del diseño |
|-----------|--------------------------|
| I: separación y compatibilidad | Conforme: snapshot de hecho, presentación sin autoridad; GDScript/code-native, stats y recursos existentes intactos. |
| II: TDD y regresión | Planificado: interfaz neutra → RED real → QA del RED → desarrollo → GREEN/regresión → QA. Carga/importación fallida no cuenta como RED. |
| III: feedback y destinos | Conforme al diseño: lectura pictórica, entrada intacta; resultados Web de computador y apps nativas separados. |
| IV: efectos reciclados | Conforme al diseño: segundo `ObjectPool`, reset por activación; no se declara rendimiento aprobado ni se reabre #30. QA declara anomalías observadas durante pruebas funcionales. |
| V: gates separados | Planificado: build/CI/documentación y APROBADO PARA INTEGRACIÓN; publicación pendiente sin distribución. |

No hay ambigüedades críticas de producto que requieran aclaración formal. Los contratos resuelven por decisión técnica el origen visual y la vida del efecto tras victoria/derrota. Esta comprobación prepara el diseño; no acredita ejecución ni QA.

## Project Structure

```text
specs/010-disparos-visibles/
  spec.md, plan.md, research.md, data-model.md, quickstart.md, tasks.md
  contracts/rifle-shot-visual.md
  checklists/requirements.md
scenes/units/soldado.gd, soldado_visual.gd
scenes/visuals/combat_visual_effects.gd
scenes/visuals/RifleShotVisualEffect.tscn, rifle_shot_visual_effect.gd
scenes/levels/nivel_monte_calvo.gd
tests/unit/units/test_soldado_rifle_effects.gd
tests/unit/systems/test_rifle_visual_effects.gd
tests/unit/game/test_game_root.gd
docs/SPEC.md, docs/ARCHITECTURE.md
```

**Structure Decision**: extender la presentación observadora local de `docs/ARCHITECTURE.md` §4.7. Sin autoload, cambios de pool genérico, escena de proyectil jugable ni arte raster nuevo.

## Execution Design

- Consultar GodotPrompter pertinente antes de implementar/revisar: señales/composición, `2d-essentials` con custom drawing, `animation-system`, pooling y testing/revisión. El flujo del repositorio prevalece sobre recetas genéricas.
- La boquilla pertenece a `SoldadoVisual.capture_rifle_shot_snapshot(target_world)`. `Soldado` captura y emite una vez después de consumir la bala y antes de `take_damage`; no retiene al blanco en el efecto.
- `RifleShotVisualEffect` dibuja flash y trazo con primitivas 2D, alpha descendente y reloj propio. Se elige inicialmente 0,16 s total; nunca exceder 0,20 s activo. Validar anclaje y estilo a tamaño de juego.
- `CombatVisualEffects` registra cada actor una vez y precalienta diez efectos de fusil; puede crecer. Sus conteos existentes siguen describiendo bajas. WON/LOST bloquean peticiones nuevas y dejan terminar las confirmadas; PAUSED congela el progreso. `close_match()`/MENU/Retry limpian antes de deshabilitar hijos y no reabren ese servicio.
- El setup inicial sólo declara interfaces y stubs inertes. Tester demuestra después un fallo de comportamiento ejecutable; desarrollo no resuelve el efecto antes de ese RED.
- QA funcional, documentación y gate final se realizan en el mismo incremento. No versionar logs/capturas ni usar estos documentos como historial de ejecuciones.

## Complexity Tracking

Sin excepciones de arquitectura. El incremento agrupa contrato, productor, efecto/pool y pruebas porque forman un único feedback utilizable; si supera el tamaño orientativo del flujo, el orquestador justifica su cohesión y elimina cambios ajenos antes del PR.
