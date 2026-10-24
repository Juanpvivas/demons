# Implementation Plan: Barras de vida

**Feature ID**: `011-barras-de-vida` | **Planned Branch**: `codex/011-barras-de-vida` | **Date**: 2026-10-24 | **Spec**: [spec.md](spec.md)
**Input**: perfil confirmado, un incremento `011-I1` para ambos bandos.
**Note**: diseño preparado con Spec Kit y ejecutado por agentes según `docs/DEVELOPMENT_WORKFLOW.md`. Comportamiento aprobado funcionalmente en T008; cierre documental, CI y QA final de integración pendientes. Publicación pendiente.

## Summary

Añadir una `WorldHealthBar` compartida, hija directa `HealthBar` del root de cada actor. El actor comunica su salud existente por llamadas directas; la barra sólo presenta proporción y color. No se crea otro sistema de salud, señal global ni dato de balance.

## Technical Context

**Language/Version**: GDScript / Godot 4.x vigente del proyecto.
**Primary Dependencies**: `ProgressBar`, `StyleBoxFlat`, escenas actuales de Soldado y Enemigo.
**Storage**: ninguno; salud runtime existente y máximo leído de `UnitStats`/`EnemyStats`.
**Testing**: GUT, RED de comportamiento tras setup importable; GREEN, regresión completa y revisión visual.
**Target Platform**: Web en Chrome de computador y apps Android/iOS disponibles; PC nativo sólo desarrollo.
**Project Type**: juego 2D compartido entre destinos.
**Performance Goals**: conservar objetivo constitucional; sin reabrir Issue #30 ni campañas de FPS por decisión del usuario.
**Constraints**: no polling, timers, tweens, entrada ni mutación de estilos/stats compartidos; preservar `project.godot` local.
**Scale/Scope**: una barra reutilizable en dos actores; sin nuevos assets, autoloads ni refactors ajenos.

## Constitution Check

- I: datos de balance permanecen en Resources; presentación separada de autoridad jugable y del sprite animado.
- II: tester RED → QA RED → dev → tester GREEN/regresión → QA funcional → documentación; setup neutral no acredita comportamiento.
- III: mismo significado en Web de computador y apps nativas; tonos mates y entrada intacta.
- IV/V: conservar pooling; declarar caídas observadas y límites de cada entorno, sin certificar hardware/60 FPS con smoke o emulación. Publicación pendiente.
- Integración requiere fuente/build funcionales, documentación, CI y QA independiente; pendiente físico/renderer/paquete final se declara sin inventar aprobación.
- Revisión previa y posterior al diseño: sin excepciones nuevas; QA funcional T008 confirma el comportamiento. Documentación, CI y QA final de integración conservan su gate independiente.

## Project Structure

- `scenes/ui/WorldHealthBar.tscn`, `scenes/ui/world_health_bar.gd`: ProgressBar sin porcentajes, input ni foco; [contrato](contracts/world-health-bar.md).
- `scenes/units/Soldado.tscn`, `scenes/units/soldado.gd`, `scenes/enemies/EnemigoBase.tscn`, `scenes/enemies/enemigo.gd`: hijo HealthBar, inicialización/daño/retirada/reuso.
- `tests/unit/ui/test_world_health_bar.gd`, `tests/unit/units/test_soldado_health_bar.gd`, `tests/unit/enemies/test_enemigo_health_bar.gd`: componente y actores con estado UI real; sin getters geométricos.
- Esta carpeta: spec, plan, research, data-model, contrato, quickstart, checklist y tasks; T009 consolida el comportamiento aprobado en `docs/SPEC.md`/`docs/ARCHITECTURE.md` para revisión documental.

## Execution Design

1. T001 revisa preparación. T002 crea sólo clase/escena/hijos ocultos y métodos vacíos importables; tester verifica carga y QA neutralidad, sin cableado de actores.
2. T003/T004 prueban requisito ausente mediante estado UI real; un error de importación/parsing no cuenta como RED.
3. T005 integra llamadas síncronas: máximo al iniciar/reaparecer, actualización al daño y limpieza antes de señales de baja. Resolver HealthBar también antes de `_ready()`.
4. T006–T012 verifican regresión, aspecto y builds disponibles, QA, documentación, CI y draft PR. Un único incremento funcional; no se fusiona setup/RED aislado.
