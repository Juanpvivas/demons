# Implementation Plan: Monte Calvo — terreno y trincheras, iteración visual 1

**Feature ID**: `002-monte-calvo-terreno-trincheras` | **Branch**: `codex/002-monte-calvo-terreno-trincheras` | **Date**: 2026-10-15 | **Spec**: [spec.md](spec.md)

**Input**: especificación preparada con el preset `demons-agent-tdd` 1.0.1. Plantilla de plan resuelta mediante `setup-plan.sh --json`, con `FEATURE_DIR` de esta feature.

**Estado**: implementación por agentes autorizada por la persona el 2026-10-15 y en curso. Spec Kit preparó este documento; los agentes implementan, prueban y validan según [el flujo compartido](../../docs/DEVELOPMENT_WORKFLOW.md). Las dependencias y aprobaciones de tareas siguen vigentes; este estado no certifica resultados de ejecución.

## Summary

Renovar primero el suelo y el horizonte de Monte Calvo y después integrar trincheras decorativas de tierra, madera y sacos según [la imagen aprobada](references/visual-reference.md). Crear una escena visual estática independiente, por detrás de los actores, sin tocar lógica, geometría o entradas. Conservar el avance central actual y los personajes provisionales.

La conservación de mecánicas (US2) es un requisito de cada entrega: MVP = terreno US1 + comprobación US2; iteración completa = añadir trincheras US3 + repetir las comprobaciones afectadas. Los cinco carriles y el HUD del concepto quedan fuera.

## Technical Context

**Language/Version**: proyecto Godot 4.7, CI con Godot 4.7.1; GDScript existente sin cambios previstos. La nueva escena visual no necesita script.
**Primary Dependencies**: nodos nativos `Node2D`, `Sprite2D` y recursos de textura/atlas; `TileMap` existente permanece intacto. Sin addons nuevos.
**Storage**: PNG y ajustes `.import` versionados; `.godot/` sigue excluido. Sin persistencia o datos de balance nuevos.
**Testing**: GUT existente, importación headless y revisión del diff; comprobaciones visuales y de mouse/touch reales. Ejecución por tester, revisión independiente por QA; resultados y limitaciones en `evidence/`.
**Target Platform**: PC, Android e iOS; matriz en [quickstart.md](quickstart.md).
**Project Type**: juego 2D de defensa con un nivel concreto.
**Performance Goals**: mantener 60 FPS típicos en Android de referencia; medir antes/después, memoria de texturas y posibles problemas de transparencia. Sin animaciones o procesamiento ambiental por frame.
**Constraints**: conservar todo el [contrato visual/jugable](contracts/visual-boundary.md), geometría 96×96, recorrido central, posiciones existentes, `canvas_items`/`expand`, renderer Mobile y exportaciones.
**Scale/Scope**: tres hojas de textura iniciales y una escena visual separada; una única instancia añadida a Monte Calvo. Sin HUD, personajes, balance, IA o migraciones de motor.

## Constitution Check

Revisión documental previa a investigación y posterior al diseño; no equivale a aprobación de la futura implementación.

| Principio / regla | Resolución del plan | Estado de preparación |
|---|---|---|
| I. Separación visual/lógica y datos en Resource | Escena visual sin script; todos los scripts y Resources de balance conservados | Conforme |
| II. Pruebas y TDD | Arte sin comportamiento nuevo: inspección y regresión existentes, sin RED artificial; cualquier ampliación lógica requiere su propio ciclo RED/GREEN | Conforme |
| III. UX coherente entre mouse y touch | Misma transformación de coordenadas e input; evidencia real en matriz, contraste y no oclusión | Conforme |
| IV. Rendimiento | Entorno estático y pocas texturas compartidas; medición en Android y registro de memoria al ejecutar | Conforme en diseño; medición pendiente |
| Spec Kit prepara, agentes ejecutan | Tareas con propietario, dependencia y evidencia; QA independiente; solo orquestador marca `[X]` | Conforme |
| Alcance y trabajo histórico | No modificar feature 001 ni corregir carencias actuales de HUD/recarga; conservar IDs y pruebas | Conforme |

No se solicita excepción a la constitución. El objetivo de tiempo de carga aún no definido por el proyecto no se inventa en esta feature; se registrarán medidas comparables.

## Project Structure

### Documentation (this feature)

```text
specs/002-monte-calvo-terreno-trincheras/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── tasks.md
├── contracts/visual-boundary.md
├── references/visual-reference.md
├── references/monte-calvo-concept.png
├── references/.gdignore  # referencia documental fuera del escaneo de Godot
└── checklists/requirements.md
```

La evidencia de ejecución se registra en `evidence/`; cada reporte distingue resultados reales y comprobaciones pendientes. La guía de producción T002 se incorpora en `references/production-brief.md` y requiere revisión QA antes de producir arte.

### Source Code (repository root; proposed changes, not created)

```text
assets/sprites/levels/monte_calvo/
├── montanas.png (+ .import)
├── terreno.png (+ .import)
└── trincheras_atlas.png (+ .import)
scenes/levels/
├── MonteCalvoVisual.tscn       # nuevo subárbol de presentación
└── Nivel_MonteCalvo.tscn       # única escena existente que integra el hijo nuevo
```

**Structure Decision**: ampliar el dominio de sprites y conservar el nivel actual. No crear sistemas de terreno, Resources de balance, scripts o autoloads para una composición estática.

Árbol propuesto del entorno:

```text
MonteCalvoVisual (Node2D, transform identidad, z_index=-10)
├── Suelo (Node2D, z relativo 0; sprites compartidos si hace falta continuidad)
├── FondoMontanas (Sprite2D, z relativo 1)
├── Bordes (Node2D, z relativo 2)
└── Trincheras (Node2D, z relativo 3)
```

Ningún descendiente sube al plano de actores, tiene script, input o física. El entorno comparte el espacio de mundo existente, sin `CanvasLayer` o cámara propios. Ajustar solo posiciones y escalas del arte; no alterar el nivel, `Tablero` o actores para acomodarlo.

El suelo opaco cubre toda la superficie visible. Las montañas con transparencia se dibujan encima, acotadas a una franja superior aproximada de mundo `y=0..160`, para conservar el horizonte sin dejar huecos de fondo. Bordes y trincheras quedan encima de ambos; el conjunto mantiene z efectivo de -10 a -7. La composición y sus márgenes se contrastan con las capturas reales de T001.

## Phase 0 — Research

Completada como investigación documental en [research.md](research.md): comparación de la referencia, inventario real, escena mínima, importación, límites de input y validación proporcional. La imagen se recuperó del chat y se copió íntegra a documentación; no es un recurso del juego.

## Phase 1 — Design & Contracts

- [data-model.md](data-model.md): entidades visuales y datos existentes que se preservan, sin nuevas clases de gameplay.
- [visual-boundary.md](contracts/visual-boundary.md): contrato de integración interna, geometría y límites verificables. No hay API externa en esta feature.
- [quickstart.md](quickstart.md): línea base, matrices, regresión y criterios de evidencia futura; no contiene resultados simulados.
- Primera entrega: terreno/montañas con lectura aprobada antes de ampliar a trincheras.
- Segunda entrega: atlas decorativo y trincheras, más repetición de las comprobaciones afectadas.
- Cierre: regresión completa, smoke de partida, resultados de victoria/derrota, pantallas/dispositivos y aprobación independiente.

## Phase 2 — Agent Task Preparation

[tasks.md](tasks.md) ya contiene las 18 tareas preparadas con historias US1, US2 y US3, propietarios, rutas y dependencias. La preparación Spec Kit no despacha implementación; el orquestador coordina ahora su ejecución autorizada y solo marca tareas tras `APROBADO`.

## Integration and verification limits

- Solo se autoriza añadir recursos y el subárbol visual; el diff de `Nivel_MonteCalvo.tscn` conserva íntegros los nodos anteriores y sus propiedades.
- El tester captura ventanas y coordenadas reales antes de dibujar/componer. No asumir un viewport fijo o una cuadrícula finita a partir de la imagen.
- Si el art frame no coincide con el encuadre actual, ajustar el arte y su margen; cualquier cambio de cámara, stretch, transformación o restricción de input requiere otro alcance.
- Si aparece un fallo previo, registrar y separar su resolución; no debilitar pruebas ni modificar lógica para que una tarea artística pase.
- La revisión de documentación no acredita importación, capturas, FPS, ejecución de pruebas ni experiencia en dispositivos. Esas evidencias pertenecen a los agentes al implementar.

## Complexity Tracking

Sin violaciones que justificar. Se rechazan expresamente el controlador visual, migración de TileMap, iluminación/parallax y generación procedural por no ser necesarios para esta primera iteración.
