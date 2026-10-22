# Implementation Plan: Diagnóstico y estabilización del rendimiento

**Feature ID**: `006-diagnostico-rendimiento` · **Branch**: `codex/006-i2-estabilizacion` · **Date**: 2026-10-21 · **Spec**: [spec.md](spec.md)
**Issue**: [#30](https://github.com/Juanpvivas/demons/issues/30). I1 integrado por PR #31; I2 conserva `Refs #30` y el Issue abierto.

## Summary

El alcance previsto de I1 es medición reproducible y la primera corrección de presentación cuyo coste se confirme. T009 aprueba para integración sólo el instrumento y el diagnóstico limitado: Web no distingue ganancia; Android tiene deriva y observabilidad insuficiente de foco/vsync; tres ventanas posteriores de iPad Simulator/software rondan 150–151 ms por frame y siguen siendo descriptivas por la misma limitación de observación efectiva. La hipótesis del shader no queda confirmada y no se aplica un parche. Bases nativas T008/SC-001 y US2 siguen pendientes, sin declarar US1 completa. El [protocolo](contracts/profiling-protocol.md) es la fuente única de condiciones, API y aceptación.

I2 continúa sobre `main` `2272aa2`: B es esa revisión y C la misma fuente más
una intervención temporal. La [adenda I2](contracts/profiling-protocol.md#adenda-i2-componente-gpu-web)
añade un preflight acotado de timer queries GPU WebGL2 en el contexto de Godot,
con cobertura pre/post draw demostrada y control del observador. Ese carril no
sustituye al probe ni acredita FPS físicos. El lote requiere autorización tras
preflight; T009-I2 deberá emitir un nuevo dictamen antes de cualquier T010.
Preparación, preflight, medición y candidata son etapas distintas; no se afirma
un ahorro ni se completan los pendientes nativos o de publicación.

## Technical Context

| Aspecto | Decisión |
|---|---|
| Lenguaje/motor | GDScript y shader existentes, Godot 4.7.1; sin actualizar motor/addons |
| Dependencias | GUT 9.7.1 y herramientas de exportación existentes; sin dependencias nuevas |
| Persistencia | Ninguna del producto; resultados de ejecución en temporales o CI |
| Testing | GUT para el instrumento nuevo; regresión/visual/entrada y medición para el parche |
| Destinos | Chrome/macOS, APK API 36 Android Emulator y `.app` iPad Simulator; PC nativo sólo diagnóstico |
| Objetivo | Detectar/reducir un coste repetible; 60 FPS físicos y paquete final siguen en publicación |
| Alcance | `tools/performance/probe.gd`, su prueba y un bloque de `soldado_readability.gdshader` si se justifica |
| Límites | Sin cambios de resolución, física, reglas, arte, pulso, presets ni distribución; sólo copias temporales para ablaciones |

## Constitution Check

Antes de investigar y tras diseño: I, separación/datos conservados; II, instrumento con RED → dev → GREEN y QA, shader equivalente con verificación visual sin RED artificial; III, misma lectura/entrada y matriz nativa; IV, perfilado y regresiones declaradas sin acreditar hardware; V, integración independiente de publicación. Ninguna desviación diseñada. Las aprobaciones T039 de 004 y T071 de 005 permanecen pendientes; no se hereda Xiaomi para 006 ni se solicita reconexión.

## Project Structure

- Preparación: este directorio (`spec`, `plan`, `research`, `data-model`, protocolo, `quickstart`, tareas/checklist).
- Herramienta optativa: `tools/performance/probe.gd`, sin autoload, referencia desde escenas productivas ni ejecución por defecto.
- Prueba: `tests/unit/systems/test_performance_probe.gd`; no assertions de FPS en CI ni de texto de assets.
- Candidata condicional: `assets/sprites/units/monte_calvo/soldado_readability.gdshader`.
- Documentación final: `docs/SPEC.md`, `docs/ARCHITECTURE.md`, `README.md` si aporta estado útil y encabezados de `specs/004-personajes-municion-monte-calvo/tasks.md` bajo el orquestador.

## Ejecución por agentes

T001 fija base/Issue/contratos. T002 crea sólo interfaz invocable; T003/T004 prueban RED válido. T005/T006 implementan/verifican el instrumento y T007 aprueba su uso. T008/T009 diagnostican antes de autorizar un parche. Al no autorizarlo T009, la entrega limitada continúa por T013/T014 (documentación/revisión) y T015 (PR en borrador), dejando T008 y T010–T012 pendientes en su alcance no acreditado. La corrección del determinismo de una prueba histórica no es una optimización del producto ni TDD retroactivo. No ejecutar implementación ni tests desde Spec Kit.

No hay paralelismo sobre el checkout/motor. La investigación de sólo lectura puede avanzar en paralelo. Las muestras antiguas son contexto, nunca la nueva base. Si no hay causa/mejora confirmadas, no se marca US2 completada; se informa al orquestador para delimitar el resultado diagnóstico. No se cambia de hipótesis ni se amplía el parche sin actualizar alcance/QA.
