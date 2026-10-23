# Implementation Plan: Carrera del soldado colombiano

**Feature ID**: `009-carrera-soldado-colombiano` | **Planned Branch**: `codex/009-carrera-soldado-colombiano` | **Date**: 2026-10-23 | **Spec**: [spec.md](spec.md)
**Base**: `main` `a88e7c5`, PR #37 integrado. Issue [#38](https://github.com/Juanpvivas/demons/issues/38). Preparación según `demons-preparation`; implementación y QA corresponden a los agentes del [flujo](../../docs/DEVELOPMENT_WORKFLOW.md).

## Summary

I1 renueva únicamente `melee_march` y `returning`: ocho fases por ciclo con apoyos opuestos y cierre continuo, conservando 0,60 s, el soldado pictórico actual y las reglas existentes. Ver [decisiones](research.md), [contrato](contracts/run-visual.md) y [referencias](references/visual-reference.md).

## Technical Context

| Aspecto | Decisión |
|---|---|
| Motor/lenguaje | Godot 4.7.1, `SpriteFrames` y `AnimatedSprite2D` existentes; sin GDScript nuevo previsto |
| Arte | Dos atlas RGBA dedicados, uno con machete/fusil guardado y otro con fusil bajo; ocho fases completas por clip, importaciones versionadas |
| Encaje | Lienzo lógico 384×288, apoyo (192,264); conservar escala 0,3936942 y offset (0,−59,038979) del hijo visual, pies raíz+y24 |
| Reproducción | Ciclo 0,60 s; regiones/márgenes medidos sobre texturas importadas, orientación original derecha y espejo vigente sólo en regreso |
| Dependencias/datos | Sin dependencia, API, persistencia, autoload, rig, shader o autoridad nuevos |
| Verificación | Render real ampliado/a tamaño de juego, importación/carga, regresión pertinente y CI completa de la revisión exacta |
| Destinos | Web sólo en computador; Android/iOS como apps instaladas disponibles, declarando variantes y límites |
| Restricciones | Sin gameplay, escenas, stats, renderer, presets, versiones, distribución ni mediciones de rendimiento |

## Constitution Check

I: conservar separación visual/lógica y stats. II: arte sin RED artificial; cualquier cambio de selector, movimiento o estado vuelve al orquestador para TDD. III: mismo arte y significado de estados entre destinos. IV: conservar pooling y requisitos físicos históricos; 006 sigue pausado, sin certificar 60 FPS. V: revisar integración con QA independiente y CI; publicación pendiente. La propuesta no introduce excepciones constitucionales antes ni después del diseño.

## Project Structure

- `assets/sprites/units/monte_calvo/soldado_carrera_machete_atlas.png`, `soldado_carrera_regreso_atlas.png` y sus `.import`: nuevos originales transparentes, sin sobrescribir el atlas anterior.
- `assets/sprites/units/monte_calvo/soldado_lateral_frames.tres`: sustituir sólo referencias de los dos ciclos móviles; conservar el resto de clips, incluido `returning_idle`.
- `assets/sprites/units/monte_calvo/SOURCES.md`: consolidar procedencia, prompts y encaje final después de QA.
- `scenes/units/Soldado.tscn`, `soldado.gd`, `soldado_visual.gd`, stats y enemigo 008: referencias de integración, sin cambios previstos.
- Esta carpeta contiene [datos](data-model.md), [quickstart](quickstart.md), preparación y tareas. La fuente de plantillas sigue en el preset propio, sin reinstalarlo.

## Complexity Tracking

Un único I1 permite revisar la identidad de los dos recorridos y su encaje conjunto. Arte binario e importaciones se declaran aparte del tamaño manual del PR; no se crea una capa nueva ni se suben evidencias nuevas a Git.
