# Implementation Plan: Soldado Defensor con Munición y Moral

**Branch**: `001-soldado-defensor-oleadas` | **Date**: 2026-09-11 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-soldado-defensor-oleadas/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Un soldado colocable defiende una posición: dispara automáticamente con fusil
a un único objetivo prioritario (carril frontal + diagonales adyacentes) con
munición limitada, transiciona a combate cuerpo a cuerpo con machete al
agotarla (daño escalado por la moral acumulada), y los enemigos derrotados
sueltan munición recolectable que el jugador usa para recargar soldados o
desplegar nuevos, mientras resiste oleadas crecientes sin dejar que un
enemigo alcance la posición defendida.

**Enfoque técnico**: esta feature no introduce patrones nuevos de proyecto —
implementa el MVP descrito en `docs/SPEC.md` §6 usando exactamente los
patrones ya fijados en `docs/ARCHITECTURE.md` (autoloads mínimos, `Resource`
para todo dato de balance, señales para comunicación, GDScript, GUT para
tests, pooling de enemigos/proyectiles). Las decisiones específicas de esta
feature que `ARCHITECTURE.md` no cubre en detalle (fórmula de daño de
machete, mecánica exacta de recolección de munición, oleadas como datos vs.
procedurales, validación de colocación en grid) se resuelven en
[research.md](./research.md).

## Technical Context

**Language/Version**: GDScript (Godot 4.7) — por defecto según
`constitution.md` Restricciones Técnicas; nada en esta feature justifica C#
(sin sistemas de rendimiento crítico identificados todavía).

**Primary Dependencies**: Motor Godot 4.7 (Mobile renderer). Testing: GUT
(Godot Unit Testing), ya versionado en `res://addons/gut/` según
`ARCHITECTURE.md` §6.

**Storage**: N/A — esta feature no requiere persistencia entre sesiones
(sin guardado de partida en su alcance).

**Testing**: GUT, `res://tests/unit/{units,enemies,systems}/`, estructura
por dominio según `ARCHITECTURE.md` §6.

**Target Platform**: Android, iOS, PC (Windows/macOS/Linux) — las tres por
igual, según `constitution.md` Restricciones Técnicas.

**Project Type**: Proyecto Godot único (no aplica la separación
frontend/backend ni mobile+API de las opciones genéricas del template).

**Performance Goals**: 60 FPS estables en el dispositivo de referencia
(Android gama media, `constitution.md` Principio IV). Pooling obligatorio
para enemigos y proyectiles (`ARCHITECTURE.md` §4.5).

**Constraints**: Todo stat de balance (munición, daño, moral, velocidad,
composición de oleadas) vive en `Resource` (`.tres`), nunca hardcodeado
(`constitution.md` Principio I). Tiempo máximo de carga de nivel:
`TODO(PERFORMANCE_LOAD_TIME_TARGET)` — sigue pendiente de benchmarking en
`constitution.md`; no bloquea esta feature, se mide una vez exista un nivel
jugable.

**Scale/Scope**: MVP de una sola feature — 1 nivel (`Nivel_MonteCalvo`), 1
tipo de soldado, al menos 1 tipo de enemigo, hasta ~10 oleadas medibles
(SC-005). No incluye variantes de unidad ni progresión entre niveles (fuera
de alcance, ver `docs/SPEC.md` §9).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Evaluación | Estado |
|---|---|---|
| I. Calidad de Código | Todo stat (`UnitStats`, `EnemyStats`, `WaveData`) se define como `Resource` (`.tres`) en `resources/`, con el molde en `resources/schemas/` (§4.3). Lógica de gameplay (economía, daño, detección) vive en `soldado.gd`/`enemigo.gd`/autoloads, separada de animación (`AnimatedSprite2D`). Un solo lenguaje (GDScript) en todo el sistema. | ✅ PASS |
| II. Estándares de Testing | Cobertura obligatoria identificada: cálculo de daño (fusil y machete), consumo/recolección de munición, acumulación de moral, condición de derrota, generación de oleadas — todas sin dependencia de renderizado, testeable con GUT. Se listan como tareas de test explícitas en `tasks.md` (fase siguiente). | ✅ PASS |
| III. Consistencia de UX | Cada transición de estado relevante (fusil→machete, impacto recibido, oleada por llegar) tiene contrato de señal explícito (ver `contracts/signals.md`) para que la UI/audio reaccione — ninguna transición queda silenciosa. Input abstraído vía `InputMap`, sin lógica dependiente de touch vs. mouse. | ✅ PASS |
| IV. Requisitos de Rendimiento | Enemigos reciclados vía `ObjectPool` (`core/object_pool.gd`, ya definido). Sin instanciación/destrucción por oleada. Tiempo de carga de nivel queda con el mismo TODO pendiente que ya tiene la constitución — no es una violación nueva introducida por esta feature. | ✅ PASS (con TODO heredado, no bloqueante) |

**Resultado**: sin violaciones. No se requiere `Complexity Tracking`.

## Project Structure

### Documentation (this feature)

```text
specs/001-soldado-defensor-oleadas/
├── plan.md              # Este archivo (/speckit-plan)
├── research.md          # Fase 0 (/speckit-plan)
├── data-model.md        # Fase 1 (/speckit-plan)
├── quickstart.md         # Fase 1 (/speckit-plan)
├── contracts/
│   └── signals.md        # Fase 1 (/speckit-plan) — contrato de señales entre sistemas
├── checklists/
│   └── requirements.md   # Ya existente (/speckit-specify)
└── tasks.md              # Fase 2 (/speckit-tasks — NO se crea en este comando)
```

### Source Code (repository root)

Estructura ya fijada por `docs/ARCHITECTURE.md` §2 (proyecto completo); esta
feature solo añade los archivos concretos listados abajo, dentro de esos
mismos directorios — no crea directorios nuevos de alto nivel:

```text
res://
├── scenes/
│   ├── units/
│   │   ├── Soldado.tscn        # StaticBody2D raíz (ARCHITECTURE.md §5)
│   │   └── soldado.gd
│   ├── enemies/
│   │   ├── EnemigoBase.tscn    # CharacterBody2D raíz
│   │   └── enemigo.gd
│   ├── levels/
│   │   ├── Nivel_MonteCalvo.tscn
│   │   └── nivel_monte_calvo.gd   # instancia BoardManager, WaveSpawner
│   └── ui/
│       ├── HUD.tscn
│       └── hud.gd
├── resources/
│   ├── schemas/
│   │   ├── unit_stats.gd       # class_name UnitStats extends Resource
│   │   ├── enemy_stats.gd      # class_name EnemyStats extends Resource
│   │   └── wave_data.gd        # class_name WaveData extends Resource
│   ├── units/
│   │   └── soldado_base_stats.tres
│   ├── enemies/
│   │   └── enemigo_infanteria_base.tres
│   └── waves/
│       └── nivel_montecalvo_oleada_01.tres ... _NN.tres
├── autoloads/
│   ├── economy_manager.gd      # pool global de munición recolectada
│   ├── wave_manager.gd         # secuencia de oleadas del nivel activo
│   └── game_state_manager.gd   # victoria/derrota, estado de partida
├── core/
│   ├── object_pool.gd          # ya definido en ARCHITECTURE.md — se usa, no se rediseña
│   └── board_manager.gd        # NUEVO: grid de ocupación + validación de colocación
└── tests/
    └── unit/
        ├── units/test_soldado.gd
        ├── enemies/test_enemigo.gd
        └── systems/
            ├── test_economy_manager.gd
            ├── test_wave_manager.gd
            └── test_game_state_manager.gd
```

**Structure Decision**: proyecto único (opción 1 genérica del template),
usando exactamente los directorios de `docs/ARCHITECTURE.md` §2. Única
adición no prevista explícitamente en ese documento es `core/board_manager.gd`
(justificación en `research.md` — encaja en la descripción existente de
`core/` como "lógica compartida no-autoload" reutilizable entre niveles
futuros, no requiere modificar `ARCHITECTURE.md`).

## Complexity Tracking

*Sin violaciones de la Constitution Check — tabla no aplica para esta feature.*

## Constitution Check (post-diseño)

Re-evaluada tras completar `research.md`, `data-model.md` y
`contracts/signals.md`: ninguna decisión de diseño introdujo un patrón
nuevo de alcance de proyecto (la única adición, `core/board_manager.gd`,
encaja en el precedente ya existente de `core/` para lógica compartida
no-autoload — no requiere modificar `docs/ARCHITECTURE.md`). Los cuatro
principios siguen en ✅ PASS sin cambios respecto a la evaluación
pre-diseño.
