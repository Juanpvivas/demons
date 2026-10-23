# Implementation Plan: Marcha enemiga

**Feature ID**: `008-marcha-enemiga` | **Planned Branch**: `codex/008-marcha-enemiga` | **Date**: 2026-10-23 | **Spec**: [spec.md](spec.md)
**Base**: `main` `90cc824`, PR #35 integrado. Un I1 visual; preparación APROBADA por QA. Spec Kit sólo prepara; los agentes ejecutan según el [flujo](../../docs/DEVELOPMENT_WORKFLOW.md).

## Summary

Crear un ciclo completo de ocho fases de avance, conservando el personaje pictórico actual. El [estudio de referencia](references/visual-reference.md) guía apoyos opuestos, pasos intermedios y balanceo. Cambiar sólo `advance` en el recurso compartido; mantener `contact`, `defeat`, encaje y lógica existentes. Arte y recursos usan inspección visual/importación, sin RED artificial.

## Technical Context

| Aspecto | Decisión |
|---|---|
| Motor y lenguaje | Godot 4.7.1; recursos `.tres` existentes, sin cambios previstos de GDScript |
| Dependencias/almacenamiento | Ninguna dependencia, API o persistencia nueva; PNG RGBA generado y metadatos de importación locales |
| Presentación | `AnimatedSprite2D` y `EnemigoVisual` actuales; clips compartidos de sólo lectura |
| Encaje inicial | Ocho fases en `advance`, ciclo vigente de 0,60 s; lienzo lógico 384×288 y apoyo (192,264), escala/offset de escena intactos |
| Arte | Atlas nuevo sólo para marcha, con transparencia; conservar atlas antiguo para contacto/caída |
| Testing | Importación/carga y revisión visual real, regresión existente dirigida y CI completa de la revisión exacta |
| Destinos | Web sólo en computador; apps Android/iOS instaladas cuando estén disponibles, identificando variantes y límites |
| Restricciones | Sin cambios jugables, renderer, presets, versiones o publicación; sin probes, benchmarks o nuevos lotes de rendimiento |

## Constitution Check

I: datos, lógica y visuales separados; stats intactos. II: no cambia comportamiento y no se fabrica RED; si aparece un cambio de selector/pool debe volver al orquestador para TDD. III: conservar estilo y consecuencias entre destinos. IV: conservar pooling y límites históricos; por decisión expresa del 2026-10-23 no se continúan mediciones de rendimiento ahora ni se certifica 60 FPS. V: QA de integración, CI y publicación siguen separados. No se modifica la constitución ni se marca cumplido un requisito físico.

## Project Structure

- `assets/sprites/enemies/monte_calvo/enemigo_marcha_atlas.png` y `.import`: arte nuevo, sin sobrescribir los atlas anteriores.
- `assets/sprites/enemies/monte_calvo/enemigo_lateral_frames.tres`: sustituir sólo el clip `advance`; regiones medidas sobre la textura importada, no una grilla supuesta.
- `assets/sprites/enemies/monte_calvo/SOURCES.md`: procedencia, prompt final y encaje realmente aprobado.
- `scenes/enemies/EnemigoBase.tscn`, `enemigo.gd`, `enemigo_visual.gd`, stats y pruebas existentes: conservar; son referencias de integración/regresión.
- Esta carpeta: [decisiones](research.md), [datos existentes](data-model.md), [contrato](contracts/advance-visual.md), [validación](quickstart.md) y [tareas](tasks.md).

## Complexity Tracking

No se introduce una capa, autoload, rig, shader, callback o autoridad nueva. La mejora cabe en arte y `SpriteFrames`. Un incremento aprobado termina en PR en borrador; archivos de evidencia nuevos permanecen fuera de Git.
