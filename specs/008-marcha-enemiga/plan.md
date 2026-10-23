# Implementation Plan: Marcha enemiga

**Feature ID**: `008-marcha-enemiga` | **Planned Branch**: `codex/008-marcha-enemiga` | **Date**: 2026-10-23 | **Spec**: [spec.md](spec.md)
**Base**: `main` `90cc824`, PR #35 integrado. I1 en `f05d9e6` conserva su aprobación histórica de integración; la corrección de continuidad tiene validación funcional y visual local en T013. El cierre de integración y la revisión exacta se registran en [tareas](tasks.md) y el mismo [PR #37 en borrador](https://github.com/Juanpvivas/demons/pull/37). Spec Kit sólo prepara; los agentes ejecutan según el [flujo](../../docs/DEVELOPMENT_WORKFLOW.md).

## Summary

I1 incorpora un ciclo completo de ocho fases de avance, conservando el personaje pictórico actual. El [estudio de referencia](references/visual-reference.md) guía apoyos opuestos, pasos intermedios y balanceo. Cambiar sólo `advance` en el recurso compartido; mantener `contact`, `defeat`, encaje y lógica existentes. Arte y recursos usan inspección visual/importación, sin RED artificial.

Las [referencias adicionales](references/visual-reference.md) orientan la continuidad del cuerpo y de los apoyos. El orden validado localmente en T013 intercala poses de ambas hojas para enlazar el alcance con el contacto del mismo pie; conserva ocho exposiciones iguales de 75 ms, identidad pictórica y reglas vigentes.

## Technical Context

| Aspecto | Decisión |
|---|---|
| Motor y lenguaje | Godot 4.7.1; recursos `.tres` existentes, sin cambios previstos de GDScript |
| Dependencias/almacenamiento | Ninguna dependencia, API o persistencia nueva; dos PNG RGBA originales de imagegen y metadatos de importación locales |
| Presentación | `AnimatedSprite2D` y `EnemigoVisual` actuales; clips compartidos de sólo lectura |
| Encaje inicial | Ocho fases en `advance`, ciclo vigente de 0,60 s; lienzo lógico 384×288 y apoyo (192,264), escala/offset de escena intactos |
| Arte | Dos atlas nuevos para marcha, con transparencia: cuatro poses seleccionadas de la fila superior del primero y cuatro opuestas del segundo; conservar atlas antiguo para contacto/caída |
| Testing | Importación/carga y revisión visual real, regresión existente dirigida y CI completa de la revisión exacta |
| Destinos | Web sólo en computador; apps Android/iOS instaladas cuando estén disponibles, identificando variantes y límites |
| Restricciones | Sin cambios jugables, renderer, presets, versiones o publicación; sin probes, benchmarks o nuevos lotes de rendimiento |

## Constitution Check

I: datos, lógica y visuales separados; stats intactos. II: no cambia comportamiento y no se fabrica RED; si aparece un cambio de selector/pool debe volver al orquestador para TDD. III: conservar estilo y consecuencias entre destinos. IV: conservar pooling y límites históricos; por decisión expresa del 2026-10-23 no se continúan mediciones de rendimiento ahora ni se certifica 60 FPS. V: QA de integración, CI y publicación siguen separados. No se modifica la constitución ni se marca cumplido un requisito físico.

## Project Structure

- `assets/sprites/enemies/monte_calvo/enemigo_marcha_atlas.png`, `enemigo_marcha_opuesta_atlas.png` y sus `.import`: conservar los dos PNG originales completos, sin edición de píxeles ni sobrescribir atlas anteriores. Sus límites de importación son 1024 y 720, respectivamente: texturas 1024×512 y 720×480 para igualar el encaje, sin modificar escala/offset de escena.
- `assets/sprites/enemies/monte_calvo/enemigo_lateral_frames.tres`: sustituir sólo el clip `advance`; regiones medidas sobre cada textura importada, no una grilla supuesta. Sólo se referencian las cuatro poses elegidas del primer atlas; su fila inferior queda sin uso.
- `assets/sprites/enemies/monte_calvo/SOURCES.md`: procedencia, prompt final y encaje realmente aprobado.
- `scenes/enemies/EnemigoBase.tscn`, `enemigo.gd`, `enemigo_visual.gd`, stats y pruebas existentes: conservar; son referencias de integración/regresión.
- Esta carpeta: [decisiones](research.md), [datos existentes](data-model.md), [contrato](contracts/advance-visual.md), [validación](quickstart.md) y [tareas](tasks.md).

## Complexity Tracking

No se introduce una capa, autoload, rig, shader, callback o autoridad nueva. La mejora cabe en arte y `SpriteFrames`. Un incremento aprobado termina en PR en borrador; archivos de evidencia nuevos permanecen fuera de Git.
