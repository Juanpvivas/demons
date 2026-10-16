---
description: "Godot feature task plan with role ownership and RED/GREEN dependencies"
---

# Tasks: [FEATURE NAME]

**Input**: `specs/[###-feature-name]/spec.md` y `plan.md`; referencias aplicables en `research.md`, `data-model.md`, `contracts/` y `quickstart.md`.

**Flujo**: `docs/DEVELOPMENT_WORKFLOW.md` (ruta desde la raíz del repositorio).
Spec Kit prepara estas tareas. El orquestador coordina su ejecución con los agentes.

**Pruebas**: la cobertura automatizada de lógica de gameplay exigida por la
constitución es obligatoria cuando cambie ese comportamiento, aunque el spec
no repita la exigencia. Agregar otras pruebas cuando aporten verificación de
un comportamiento o riesgo concreto. No fabricar RED para arte, documentos o
configuración sin comportamiento testeable; indicar su verificación pertinente.

## Formato y aprobación

- Formato: `- [ ] T001 [P?] [US1?] Descripción con ruta exacta`.
- `[P]` solo para trabajo independiente, en archivos distintos y sin dependencias pendientes entre sí.
- `[US1]`, `[US2]`, etc. identifican la historia; no agregar etiquetas nuevas.
- Indicar rol, dependencias y evidencia esperada en la descripción o en la sección de la tarea.
- `[X]` significa aprobación de `qa-validator`, registrada por el orquestador.
  En una tarea RED, la aprobación confirma un fallo esperado válido, no una implementación terminada.

## Organización y rutas

Agrupar por historia de usuario, en orden de prioridad y con dependencias
explícitas. Usar las carpetas reales de `docs/ARCHITECTURE.md`: `scenes/`,
`resources/`, `autoloads/`, `core/`, `tests/unit/` por dominio y `docs/`.

<!--
Las tareas siguientes son ejemplos. Reemplazarlas con tareas concretas de la
feature; conservar solo las fases necesarias. Cada ID debe ser único y las
dependencias deben permitir una ejecución sin ciclos. No conservar estos
personajes, rutas o escenarios si no pertenecen al alcance solicitado.
-->

## Fase 1: Preparación y prerrequisitos

**Objetivo**: disponer de contratos y entorno de pruebas antes de guiar comportamiento nuevo.

- [ ] T001 Verificar con godot-tester que el runner GUT y el entorno de `tests/unit/` funcionan; documentar evidencia sin modificar gameplay
- [ ] T002 Definir con dev-godot el contrato mínimo de `resources/schemas/unit_stats.gd` requerido por la historia, sin implementar el comportamiento que guiará la prueba RED

**Control**: si una prueba no puede ejecutarse por falta de interfaz o harness,
planear primero el prerrequisito mínimo. Un error de parser/importación/configuración
no constituye por sí solo evidencia RED del escenario solicitado.

## Fase 2: Historia de usuario 1 — [Título] (Prioridad: P1)

**Objetivo**: [resultado observable del jugador].

**Criterio independiente**: [acceptance scenario y forma de verificarlo].

### Prueba RED

- [ ] T003 [US1] godot-tester: escribir en `tests/unit/units/test_soldado.gd` el escenario [US1/AC1] de consumo de munición; ejecutar y registrar el fallo esperado por comportamiento pendiente; depende de T001 y T002

**Control RED**: `qa-validator` confirma que el test verifica el contrato y que
falla por el comportamiento todavía ausente. Tras `APROBADO`, el orquestador
puede marcar T003 `[X]` y `docs-writer` registra esa evidencia como RED.
La implementación T004 continúa pendiente.

### Implementación y comprobación GREEN

- [ ] T004 [US1] dev-godot: implementar el comportamiento [US1/AC1] en `scenes/units/soldado.gd`; godot-tester verifica GREEN y regresiones pertinentes, qa-validator revisa de forma independiente y docs-writer documenta; depende de T003 aprobada

**Control GREEN**: solo se aprueba T004 cuando el comportamiento cumple el spec
y sus pruebas pasan. Una prueba que ya pasa antes de implementar se evalúa como
comportamiento existente o cobertura de regresión; no se rompe código para fabricar RED.

## Fase 3: Historia de usuario 2 — [Título] (Prioridad: P2)

**Objetivo**: [resultado observable].

**Criterio independiente**: [escenario propio y dependencias con US1, si existen].

- [ ] T005 [US2] godot-tester: añadir el escenario RED [US2/AC1] en `tests/unit/systems/test_economy_manager.gd`; registrar el fallo esperado válido; depende de T001 y del contrato mínimo disponible
- [ ] T006 [US2] dev-godot: implementar [US2/AC1] en `autoloads/economy_manager.gd`; godot-tester verifica GREEN, qa-validator revisa y docs-writer documenta; depende de T005 aprobada

## Fase 4: Trabajo visual o documental, cuando aplique

- [ ] T007 [US1] dev-godot: integrar el terreno autorizado en `scenes/levels/Nivel_MonteCalvo.tscn`; verificar lectura, posiciones y entrada según el spec con los roles correspondientes; sin RED artificial si no cambia comportamiento testeable
- [ ] T008 docs-writer, modo autoría: preparar el cambio de `docs/ARCHITECTURE.md` a partir de sus fuentes y decisiones aprobadas; qa-validator revisa el borrador antes del marcado por el orquestador; depende de las tareas que documenta

**Verificación**: definir capturas, inspección de recursos o playtesting relevante
para el alcance. Si el trabajo visual modifica comportamiento, incluir su
cobertura automatizada pertinente en lugar de tratarlo como una excepción.

## Fase final: Verificación y cierre

- [ ] T009 godot-tester: ejecutar la suite completa de GUT de `tests/unit/` antes del PR y documentar regresiones, fallos y cobertura; depende de las tareas de comportamiento terminadas
- [ ] T010 Ejecutar con el rol responsable los escenarios pertinentes de `specs/[###-feature-name]/quickstart.md`, incluyendo smoke test y verificaciones en dispositivo cuando la constitución los exija; documentar evidencia para QA
- [ ] T011 docs-writer: consolidar decisiones aprobadas y evidencia final en `docs/SPEC.md` y `docs/ARCHITECTURE.md`; depende de la aprobación de las verificaciones finales

## Dependencias y ejecución

- Para cada comportamiento: prerrequisitos mínimos → tester RED → QA del RED →
  dev-godot → tester GREEN → QA de entrega → documentación.
- La tarea RED nunca depende de su implementación/GREEN; esta sí depende de RED aprobada.
- Las tareas solo de tests van a godot-tester; las documentales a docs-writer;
  el orquestador decide la ruta pertinente para setup, arte y verificaciones.
- No paralelizar el RED y el GREEN del mismo comportamiento, ni tareas que
  compartan archivos. Las historias independientes pueden avanzar en paralelo
  únicamente si cumplen estas condiciones.
- El orquestador es quien registra `[X]` tras el veredicto; Spec Kit y dev-godot
  nunca aprueban tareas por su cuenta.

## Estrategia de entrega

Completar primero una historia utilizable y verificarla antes de ampliar el
alcance. Al finalizar, el orquestador coordina documentación, verificaciones
pendientes y PR en borrador vinculado al Issue. No ejecutar implementación,
pruebas ni publicación de una entrega desde la generación de tareas Spec Kit.
