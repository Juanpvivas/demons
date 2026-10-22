# Implementation Plan: Menú de inicio y nueva partida

**Feature ID**: `007-menu-inicio-reinicio` · **Date**: 2026-10-21 · **Spec**: [spec.md](spec.md) · **Issue**: [#32](https://github.com/Juanpvivas/demons/issues/32)
**Planned Branch**: preparación en `codex/007-preparacion`; incremento funcional posterior desde `main` actualizado, preparado por el orquestador.
**Estado**: Preparación revisada y lista para ejecución por agentes; implementación, pruebas y publicación pendientes.

## Summary

Una raíz persistente `GameRoot` presenta el menú pictórico sin montar el nivel. «Jugar» crea Monte Calvo; el HUD conserva la autoridad terminal de `GameStateManager` y emite intenciones de repetir o volver al menú. La raíz retira completamente el intento anterior antes de montar otro. Se entrega el ciclo completo de las tres historias en un único incremento funcional; no se incorpora pausa o progresión.

## Technical Context

| Aspecto | Decisión |
|---|---|
| Lenguaje/motor | GDScript y Godot 4.7.1, arquitectura existente; sin C# ni dependencia nueva |
| Presentación | `Control`/contenedores y señales; reutilizar arte estático de Monte Calvo |
| Estado | Autoloads existentes; raíz dueña de escenas, sin nuevo autoload o framework FSM |
| Almacenamiento | Sólo estado temporal; sin persistencia ni servicios externos |
| Pruebas | GUT, escenas/Managers reales y fixture terminal separado de producción |
| Destinos | Web de computador; APK Android y app nativa iOS disponibles |
| Rendimiento | Comparación pertinente antes/después en entornos disponibles; 60 FPS físicos y artefacto final pendientes de publicación |
| Restricciones | Balance, 1 inicial + 99 de oleadas, pooling durante combate, renderer/presets/versiones/workflows vigentes |

## Constitution Check

Revisado antes de investigación y nuevamente sobre el diseño; no se propone excepción.

| Principio | Tratamiento del plan |
|---|---|
| I — Código/datos | Composición local, presentación separada, Resources de balance intactos |
| II — Pruebas | Setup invocable → RED semántico del tester → dev → GREEN/regresión → QA → documentación |
| III — UX | Menú inerte, exclusividad de gesto, botones accesibles y misma consecuencia por destino |
| IV — Rendimiento | Sin combate oculto; pools por intento, comparación sin ocultar caídas; certificación física separada |
| V — Gates | QA de preparación no aprueba implementación; PR en borrador, integración y publicación distintas |

## Project Structure

Documentos de esta feature: [research](research.md), [modelo](data-model.md), [contrato](contracts/match-flow.md), [quickstart](quickstart.md) y [tareas](tasks.md).

| Archivos previstos | Responsabilidad |
|---|---|
| `scenes/game/GameRoot.tscn`, `scenes/game/game_root.gd` | Raíz persistente, dueño único del menú/nivel y transiciones |
| `scenes/ui/MainMenu.tscn`, `scenes/ui/main_menu.gd` | Presentación estática, título y señal de «Jugar» |
| `project.godot` | Cambiar entrada a `GameRoot` sólo tras RED del arranque real |
| `scenes/ui/HUD.tscn`, `scenes/ui/hud.gd` | Reutilizar resultado existente, añadir dos intenciones y foco |
| `scenes/levels/nivel_monte_calvo.gd`, `scenes/levels/wave_spawner.gd` | Encauzar intenciones y cierre local sin cambiar combate |
| `autoloads/game_state_manager.gd`, `autoloads/wave_manager.gd` | Estado no jugable y cancelación silenciosa de oleadas |
| `tests/unit/game/test_game_root.gd`, `tests/unit/ui/test_main_menu.gd` | Flujo, arranque inerte, multicíclos, controles y gesto consumido |
| `tests/unit/{systems,ui,levels}/` existentes | Regresión de Managers, HUD, oleadas, encuadre y entrada |

## Secuencia de implementación prevista

1. Orquestador comprueba documentos y rama; `dev-godot` crea sólo esqueleto cargable/API del contrato, métodos sin comportamiento y sin cambiar la entrada. QA verifica el límite del setup antes de RED.
2. Tester obtiene RED ejecutando aserciones sobre entrada real, inicio y cierre/reset. Un archivo ausente, parser roto o importación fallida no es RED; no reconstruir RED de comportamiento histórico.
3. Desarrollo conecta el ciclo US1 → US2 → US3 por grupos secuenciales. El cierre establece estado no jugable, invalida intenciones viejas, cancela oleadas, desconecta/retira nivel y espera su liberación efectiva antes de otro `start_new_match()`.
4. Tester confirma GREEN y regresiones de cada grupo; QA valida independientemente. Presentación pictórica usa inspección visual proporcionada, sin pruebas artificiales de arte.
5. Antes de entregar I1: suite completa, importación/exportaciones aplicables, flujo por UI y rendimiento en matriz disponible; docs consolida sólo comportamiento aprobado y QA emite dictamen de integración final.

## Entrega y límites

Preparación e I1 usan `Refs #32`; el Issue no se cierra mientras falte aceptación. Ninguna tarea funcional se marca por esta preparación. El PR queda en borrador y no se fusiona automáticamente. [Quickstart](quickstart.md) distingue victoria de fixture de producción y requisitos de publicación; 004/T039, 005/T071 y 006 pendientes permanecen intactos. No hay registros nuevos de evidencia en Git. El paquete de preparación supera orientativamente 400 líneas porque reúne especificación, diseño, contrato, validación y tareas de un único ciclo; separarlo en PR sin decisiones independientes añadiría entregas sin valor funcional.
