# Tasks: Barras de vida

**Input**: [spec.md](spec.md), [plan.md](plan.md), [contrato](contracts/world-health-bar.md). **Entrega**: `011-I1`, ambos bandos; Issue [#42](https://github.com/Juanpvivas/demons/issues/42); integrado en `main` mediante el [PR #43](https://github.com/Juanpvivas/demons/pull/43) (`c75ecb0`).
**Flujo**: `docs/DEVELOPMENT_WORKFLOW.md`. Sólo orquestador marca [X] tras QA; RED aprobado no entrega gameplay. Resultados al PR/temporales, sin archivos de evidencias nuevos en Git. Publicación pendiente.

## Fase 1: Preparación y contrato neutral

- [X] T001 project-orchestrator + qa-validator: revisar `specs/011-barras-de-vida/`, checklist, cobertura FR/SC y dependencias; registrar QA de preparación antes de ejecutar.
- [X] T002 dev-godot: crear sólo interfaz neutral importable `scenes/ui/world_health_bar.gd`, `scenes/ui/WorldHealthBar.tscn` e hijos HealthBar ocultos en `scenes/units/Soldado.tscn`/`scenes/enemies/EnemigoBase.tscn`, con métodos vacíos set_health/clear, sin comportamiento ni cableado de actores; godot-tester confirma carga y qa-validator neutralidad; depende de T001 aprobada.

## Fase 2: US1 — Vida visible de ambos bandos (P1)

**Objetivo/criterio independiente**: AC1–5 y SC-001–004; cada barra refleja vida y límites, conserva combate y completa su ciclo sin residuos.
- [X] T003 [US1] godot-tester: escribir/ejecutar RED en `tests/unit/ui/test_world_health_bar.gd`, `tests/unit/units/test_soldado_health_bar.gd` y `tests/unit/enemies/test_enemigo_health_bar.gd`: proporción/colores, inicial 30/30 y 15/15 desde stats, daño, independencia, recarga, baja antes de callbacks, pool pre-ready, máximo distinto y reuso síncrono; fallo por requisito ausente, nunca importación; depende de T002 aprobada.
- [X] T004 [US1] qa-validator: revisar en sólo lectura los RED de T003 y `specs/011-barras-de-vida/contracts/world-health-bar.md`; emitir veredicto que distinga RED de implementación; depende de T003.
- [X] T005 [US1] dev-godot: implementar barra/estilos y conexiones directas de inicialización, daño, baja y reuso en `scenes/ui/world_health_bar.gd`, `scenes/ui/WorldHealthBar.tscn`, `scenes/units/soldado.gd` y `scenes/enemies/enemigo.gd`; sin tocar tests ni balance; depende de T004 aprobada.
- [X] T006 [US1] godot-tester: confirmar GREEN de T003 y regresión GUT completa de `tests/unit/`, incluidos recarga, combate y fin/reinicio; reportar comandos/resultados/límites para QA y PR; depende de T005.
- [X] T007 [US1] godot-tester: ejecutar `specs/011-barras-de-vida/quickstart.md`, import/build y smoke visual en Chrome de computador y apps Android/iOS disponibles; verificar casco, tonos, corrida/regreso, HUD/input, muerte/pool, pausa/resize/menú/Retry; preservar datos locales, declarar destinos pendientes y caídas observadas sin campaña FPS; depende de T006 GREEN.
- [X] T008 [US1] qa-validator: contrastar `specs/011-barras-de-vida/spec.md`, código, tests y resultados T006/T007; emitir QA funcional independiente con entornos y límites, devolviendo fallos reales al rol; depende de T006/T007.

## Fase final: Documentación, CI y entrega

- [X] T009 docs-writer: documentar comportamiento aprobado y composición compartida en `docs/SPEC.md` y `docs/ARCHITECTURE.md`, mantener `specs/011-barras-de-vida/` coherente sin marcar tareas; depende de T008 aprobada.
- [X] T010 project-orchestrator: publicar rama y verificar CI de `.github/workflows/ci.yml` y build aplicable `.github/workflows/export-web.yml` sin distribución; entregar resultados a QA; depende de T009.
- [X] T011 qa-validator: revisar documentación, CI y alcance `specs/011-barras-de-vida/`; emitir APROBADO PARA INTEGRACIÓN sólo si cumple fuente/GREEN/build/docs/CI, declarando publicación pendiente; depende de T010.
- [X] T012 project-orchestrator: consolidar trazabilidad/veredictos en `specs/011-barras-de-vida/tasks.md` y PR en borrador vinculado al Issue; cerrar Issue sólo si alcance funcional completo, conservar gates de publicación, sin merge automático; depende de T011 aprobada.

**Dependencias**: T001→T002→T003→T004→T005→T006→T007→T008→T009→T010→T011→T012. Sin [P] en esta cadena; lecturas independientes pueden prepararse sin alterar el orden ni archivos del rol activo.
**Estrategia**: MVP = US1 completa; un único PR funcional con RED/GREEN/QA/documentación/CI, sin fusionar setup o RED solos. Sólo el orquestador registra las aprobaciones; integración no autoriza publicación.
