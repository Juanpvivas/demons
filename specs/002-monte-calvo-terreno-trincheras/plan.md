# Implementation Plan: Monte Calvo — terreno y trincheras, iteración visual 1

**Feature ID**: `002-monte-calvo-terreno-trincheras` | **Branch**: `codex/002-monte-calvo-terreno-trincheras` | **Date**: 2026-10-15 | **Spec**: [spec.md](spec.md)

**Input**: especificación preparada con el preset `demons-agent-tdd` 1.0.1. Plantilla de plan resuelta mediante `setup-plan.sh --json`, con `FEATURE_DIR` de esta feature.

**Estado**: implementación por agentes autorizada por la persona el 2026-10-15 y en curso. Spec Kit preparó este documento; los agentes implementan, prueban y validan según [el flujo compartido](../../docs/DEVELOPMENT_WORKFLOW.md). Las dependencias y aprobaciones de tareas siguen vigentes; este estado no certifica resultados de ejecución.

## Summary

Renovar primero el suelo y el horizonte de Monte Calvo y después integrar trincheras decorativas de tierra, madera y sacos según [la imagen aprobada](references/visual-reference.md). Crear una escena visual estática independiente, por detrás de los actores, sin tocar lógica, geometría o entradas desde las tareas artísticas. Conservar el avance central actual y los personajes provisionales. La adenda del 2026-10-16 separa un único arreglo previo necesario para I4.

La conservación de mecánicas (US2) es un requisito de cada entrega: MVP = terreno US1 + comprobación US2; iteración completa = añadir trincheras US3 + repetir las comprobaciones afectadas. Los cinco carriles y el HUD del concepto quedan fuera.

## Technical Context

**Language/Version**: proyecto Godot 4.7, CI con Godot 4.7.1; GDScript existente conservado salvo el arreglo separado T020. La nueva escena visual no necesita script.
**Primary Dependencies**: nodos nativos `Node2D`, `Sprite2D` y recursos de textura/atlas; `TileMap` existente permanece intacto. Sin addons nuevos.
**Storage**: PNG y ajustes `.import` versionados; `.godot/` sigue excluido. Sin persistencia o datos de balance nuevos.
**Testing**: GUT existente y seis regresiones de input T019–T021, importación headless y revisión del diff; ratón PC, gestos de SO en Android Emulator para I1–I4/I9, toque humano Xiaomi y gesto sobre app iOS Simulator diferenciados. Ejecución por tester, revisión independiente por QA; resultados y limitaciones en `evidence/`.
**Target Platform**: PC, Android e iOS; V3 conserva Xiaomi físico para interacción humana y rendimiento, con subcobertura Android Emulator complementaria; V4 se valida en iOS Simulator autorizado, sin acreditar hardware iOS. Matriz en [quickstart.md](quickstart.md).
**Project Type**: juego 2D de defensa con un nivel concreto.
**Performance Goals**: mantener 60 FPS estables en gameplay típico del Xiaomi 11T Pro físico (`2107113SG`), referencia provisional autorizada solo para 002; medir antes/después, memoria de texturas y posibles problemas de transparencia. La referencia nominal global permanece vigente; sin animaciones o procesamiento ambiental por frame.
**Constraints**: conservar todo el [contrato visual/jugable](contracts/visual-boundary.md), geometría 96×96, recorrido central, posiciones existentes, `canvas_items`/`expand`, renderer Mobile y exportaciones.
**Scale/Scope**: tres hojas de textura iniciales y una escena visual separada; una única instancia añadida a Monte Calvo. Sin HUD, personajes, balance, IA o migraciones de motor.

## Constitution Check

Revisión documental previa a investigación y posterior al diseño; no equivale a aprobación de la futura implementación.

| Principio / regla | Resolución del plan | Estado de preparación |
|---|---|---|
| I. Separación visual/lógica y datos en Resource | Escena visual sin script; arreglo I4 aislado en el script del nivel, sin tocar Resources o arte | Conforme; preparación de adenda aprobada por QA |
| II. Pruebas y TDD | Arte sin RED artificial; defecto previo I4 separado en T019 RED → T020 desarrollo → T021 GREEN/regresión → T022 QA | Conforme; ciclo nativo pendiente |
| III. UX coherente entre mouse y touch | Misma transformación de coordenadas e input; evidencia real en matriz, contraste y no oclusión | Conforme |
| IV. Rendimiento | Entorno estático y pocas texturas compartidas; medición física en Xiaomi 11T Pro, referencia provisional exclusiva de 002 según decisión humana y constitución 1.2.0; 60 FPS estables sin rebaja | Enmienda documental para QA; rendimiento no aprobado desde el plan |
| Spec Kit prepara, agentes ejecutan | Tareas con propietario, dependencia y evidencia; QA independiente; solo orquestador marca `[X]` | Conforme |
| Alcance y trabajo histórico | No modificar feature 001 ni corregir carencias actuales de HUD/recarga; conservar IDs y pruebas | Conforme |

La preparación original no solicitaba excepción constitucional. Posteriormente, el 2026-10-16 la persona autorizó el Xiaomi 11T Pro como referencia provisional exclusiva de 002; la constitución 1.2.0 documenta esa excepción de dispositivo y conserva la referencia nominal global, los 60 FPS estables y QA. No se modifica el objetivo de estabilidad ni se certifican otros teléfonos, 003 o iOS. La enmienda documental se entrega para revisión QA y no aprueba mediciones. El objetivo de tiempo de carga aún no definido por el proyecto no se inventa en esta feature; se registrarán medidas comparables.

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
├── Suelo (Node2D, z relativo 0; una hoja de terreno sin repetición)
├── FondoMontanas (Node2D, z relativo 1)
│   ├── Cielo (Sprite2D, GradientTexture2D estática nativa)
│   └── Panorama (Sprite2D, montañas con alfa)
├── Bordes (Node2D, z relativo 2)
└── Trincheras (Node2D, z relativo 3)
```

Ningún descendiente sube al plano de actores, tiene script, input o física. El entorno comparte el espacio de mundo existente, sin `CanvasLayer` o cámara propios. Ajustar solo posiciones y escalas del arte; no alterar el nivel, `Tablero` o actores para acomodarlo.

T005 aprobó el terreno real de 1254×1254 exclusivamente como hoja única sin repetición: el ensayo 2×2 mostró juntas. Cubrir la superficie visible y márgenes mediante escala/región de ese arte, sin cambiar coordenadas jugables. Las montañas con transparencia se dibujan encima, acotadas a una franja superior aproximada de mundo `y=0..160`; un cielo estático nativo detrás del panorama evita tierra por encima de los picos. Bordes y trincheras quedan encima de ambos; el conjunto mantiene z efectivo de -10 a -7. La composición y sus márgenes se contrastan con las capturas reales de T001; T006/T007 aún deben acreditar continuidad sin huecos/juntas y lectura. Se conservan FR-002 y FR-010, sin certificar la integración por la aprobación de los PNG. Detalle y evidencia en [la guía de producción](references/production-brief.md).

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

[tasks.md](tasks.md) conserva las 18 tareas originales con sus IDs, estados e historial, y propone T019–T022 para el arreglo aislado de I4. La preparación Spec Kit no despacha implementación; el orquestador coordina su ejecución y solo marca tareas tras `APROBADO`.

## Adenda de preparación — 2026-10-16

Preparación aprobada por QA; no equivale a aprobación de T019 ni del arreglo nativo. Consultar el [registro del orquestador en tasks.md](tasks.md) para el estado vigente de cada tarea. El diagnóstico del tester, anterior al cambio, ejecutó las mismas seis pruebas de 003 en copias nativas sin/con arte: importaciones 0, cuatro controles PASS y dos FAIL de I4, 28/36 aserciones en ambos casos (reserva 12→5 y soldado extra). Puede adoptarse como RED T019 tras conservar logs/manifests y revisión QA; no es TDD histórico de T001 ni exige repetirlo por rutina.

1. **T019** conserva el diagnóstico nativo y las seis pruebas exactas de `4a2915c` (SHA-256 `ac55c141e87f74939d3432dccf89caa62a888b149e0db69df4f8ae1ef9e34dbd`), antes de cualquier cambio productivo. Los cuatro controles ya GREEN permanecen como regresión; no se fabrica un fallo para ellos.
2. Tras RED aprobado, **T020** aplica únicamente `scenes/levels/nivel_monte_calvo.gd` de esa revisión (SHA-256 `4e89dce236868c4203079e06937b5c8dbcbbd564382f373d2216d4aa8c700d7f`). No filtrar el mouse emulado: también debe poder desplegar en celda libre sin pickup. No copiar configuración o exportación Web.
3. **T021** verifica las mismas seis pruebas y regresión completa nativas, hashes/invariantes y comparación con/sin arte con el mismo script corregido. **T022** revisa RED/GREEN y el diff acotado. T008/T009 solo pueden aceptarse después de T022.
4. V4 utilizará iOS Simulator con modelo/runtime, tamaño y método de gesto registrados; hardware iOS no probado. V3 conserva interacción humana Xiaomi y comparación física de rendimiento. El 11T Pro de 2021 no cumple la referencia nominal de gama media de los últimos ~3 años; después de registrar esa limitación, la persona lo autorizó como referencia provisional exclusiva de 002. La enmienda 1.2.0 conserva 60 FPS estables y QA para SC-007; no se extrapola desde simulador ni se aprueba por antigüedad del equipo.

**Aclaración de método Android, aprobada por QA (2026-10-16)**: conforme a la autorización de emuladores, el tester añade una subcobertura controlada de I1–I4/I9 en el AVD disponible. Los gestos pasan por el sistema operativo Android y la app visible; si se usa ADB, se dirige únicamente al serial identificado del emulador, nunca al Xiaomi. Se comparan las copias sin/con arte con el mismo arreglo I4 y se registran AVD/API, renderer, resolución, transformaciones, coordenadas y estado previo/posterior. V3 sigue siendo físico: su prueba humana y sus mediciones se reportan aparte. GUT, AVD y Xiaomi no se presentan como evidencias intercambiables; no se declara ningún caso superado desde esta aclaración ni se modifica SC-007. Procedimiento en [quickstart](quickstart.md#3-matriz-de-pantallas-y-lectura).

Los hashes de T001 (`e7f2ca9`) y del arte WIP (`b670d86`) no se reescriben. Se añaden manifests del arreglo: única diferencia productiva permitida, script del nivel; únicas pruebas nuevas, archivo de input y su UID. La comparación visual usa copias sin/con arte con el mismo arreglo, dejando el diagnóstico original separado. Fuentes aprobadas en 003: `4a2915c` y reportes `specs/003-web-itchio/evidence/t015-red.md`, `t017-w03-red.md`, `t017-green.md` consultables mediante Git; sus resultados Web no acreditan aceptación nativa de 002. No se afirma autorización humana explícita del backport ni se confunde la aprobación de preparación con la aceptación del arreglo.

## Integration and verification limits

- En las tareas artísticas solo se autoriza añadir recursos y el subárbol visual; el diff de `Nivel_MonteCalvo.tscn` conserva íntegros los nodos anteriores y sus propiedades. T019–T022 delimitan la única excepción lógica separada.
- El tester captura ventanas y coordenadas reales antes de dibujar/componer. No asumir un viewport fijo o una cuadrícula finita a partir de la imagen.
- Si el art frame no coincide con el encuadre actual, ajustar el arte y su margen; cualquier cambio de cámara, stretch, transformación o restricción de input requiere otro alcance.
- Si aparece un fallo previo, registrar y separar su resolución; no debilitar pruebas ni modificar lógica para que una tarea artística pase.
- La revisión de documentación no acredita importación, capturas, FPS, ejecución de pruebas ni experiencia en dispositivos. Esas evidencias pertenecen a los agentes al implementar.

## Complexity Tracking

Sin violaciones que justificar. Se rechazan expresamente el controlador visual, migración de TileMap, iluminación/parallax y generación procedural por no ser necesarios para esta primera iteración.
