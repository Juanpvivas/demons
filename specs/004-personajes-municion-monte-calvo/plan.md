# Implementation Plan: Personajes y munición de Monte Calvo

**Feature ID**: `004-personajes-municion-monte-calvo`  
**Planned Branch**: pendiente del orquestador; una rama por incremento.  
**Date**: 2026-10-16 | **Spec**: [spec.md](spec.md)

Preparación documental revisada, incluidas las [tareas](tasks.md); implementación
pendiente. No acredita pruebas ejecutadas, arte generado o entrega aprobada.
El setup de Spec Kit resolvió 004; su campo BRANCH es identificador de feature.
La rama Git observada fue `codex/003-web-itchio`; no se cambia aquí.

## Summary

Reemplazar las tres formas provisionales por soldado colombiano, infantería
enemiga y caja pictóricos. Presentación en los AnimatedSprite2D existentes,
con poses y acciones que observan el combate real. Retirada jugable inmediata;
derrota visible mediante snapshot y efecto independiente adquirido de un pool
del nivel. La animación nunca aplica daño ni decide recursos o resultados.

## Technical Context

**Language/Version**: GDScript, proyecto Godot 4.7; Web estándar oficial 4.7.1 con
templates coincidentes. Sin actualización de motor o dependencias.

**Primary Dependencies**: AnimatedSprite2D, SpriteFrames, AtlasTexture, Tween,
ObjectPool y GUT 9.7.1 existentes; sin addons/autoloads/AnimationTree nuevos.

**Storage**: PNG RGBA originales, importación, SpriteFrames.tres y procedencia;
estado visual efímero por instancia, sin esquemas de stats o persistencia nuevos.

**Testing**: GUT para comportamiento visual/ciclo; revisión artística, carga,
input real, smoke y medición. Runner existente `tools/ci/run_gut.py`.

**Target Platform**: Web escritorio/móvil y apps Android/iOS, separadamente.
PC nativo solo desarrollo/pruebas. Renderer/presets/input/cámara intactos.

**Project Type**: juego 2D Godot.

**Performance Goals**: 60 FPS estables en Xiaomi 11T Pro físico `2107113SG` de
2021, referencia provisional exclusiva de 004 (constitución 2.2.0), y medición
Web separada; carga fría/caliente, frame times y memoria frente a baseline.

**Constraints**: actores 48×48, caja 32×32/collider radio 20 y física intactos.
Texturas importadas de ejecución hasta 1024² por actor y caja hasta 256²:
máximo 8.25 MiB RGBA8 estimados, sin equivaler a VRAM real. El PNG original del
soldado conserva 1774×887; su importación limita la textura a 1024×512 y los
recortes usan esas coordenadas. Compartir frames de derrota con el efecto.

**Scale/Scope**: un diseño por bando, dos modos del soldado, una caja, dos
presentadores y un pool visual mínimo; sin HUD, audio, proyectiles o terreno.

## Constitution Check

| Gate | Antes de investigación | Después del diseño |
|---|---|---|
| I: Resources/separación/GDScript | Aplicable | Balance protegido; presentación observacional |
| II: TDD y QA independiente | Nueva lógica visual testeable | RED → dev → GREEN → QA; arte sin RED artificial |
| III: lectura y respeto histórico | Estados existentes | Silueta/armas y feedback, matriz por entorno |
| IV: 60 FPS y pooling | Nueva medición necesaria | Pool de efectos; Xiaomi físico provisional autorizado para 004 |
| Flujo de preparación y PR pequeños | Spec Kit solo prepara | Tres incrementos completos; futura ejecución por roles |

Sin NEEDS CLARIFICATION de diseño. La constitución 2.2.0 recoge la autorización
explícita del 2026-10-16 para usar el Xiaomi físico provisional exclusivamente en
004; la referencia nominal global permanece vigente. Antes de medir, identificar
y obtener acceso a ese equipo. Su ausencia deja pendiente SC-007. La autorización
no aprueba resultados: se requieren nuevas mediciones y QA, sin heredar 002/003
ni certificar equipos menos potentes o iOS. Web y nativo se miden por separado
también en el mismo Xiaomi. El umbral constitucional de carga permanece pendiente,
sin inventarlo. Cada entorno no probado deja pendiente su aceptación.

## Project Structure

Documentación preparada: spec, plan, research, data-model, quickstart, contrato y
[tasks](tasks.md) en esta carpeta. No crear archivos nuevos de evidencias;
resultados de ejecución al PR.

Rutas previstas, no creadas durante preparación:

```text
assets/sprites/units/monte_calvo/      # soldado_atlas.png/.import, soldado_frames.tres, SOURCES.md
assets/sprites/enemies/monte_calvo/    # enemigo_atlas.png/.import, enemigo_frames.tres, SOURCES.md
assets/sprites/pickups/monte_calvo/    # caja_municion.png/.import, SOURCES.md
scenes/units/soldado_visual.gd
scenes/enemies/enemigo_visual.gd
scenes/visuals/DeathVisualEffect.tscn
scenes/visuals/death_visual_effect.gd
scenes/visuals/combat_visual_effects.gd
tests/unit/units/test_soldado_visual.gd
tests/unit/enemies/test_enemigo_visual.gd
tests/unit/systems/test_combat_visual_effects.gd
```

Integrar en Soldado.tscn/soldado.gd, EnemigoBase.tscn/enemigo.gd, AmmoPickup.tscn,
nivel_monte_calvo.gd y wave_spawner.gd. Conservar escenas/scripts por dominio de
[arquitectura](../../docs/ARCHITECTURE.md). Presentadores en el hijo visual actual;
servicio Node del nivel, sin mover detectores/colliders o modificar ObjectPool.

## Phase 0 / Phase 1

[research.md](research.md) recoge decisiones locales y skills consultadas.
[Contrato](contracts/visual-presentation.md), data-model y quickstart delimitan
estado, orden de eventos, escenarios, matriz y protocolo futuro.
Si RED requiere interfaces inexistentes, desarrollo prepara setup mínimo
explícito asignado: señales/firmas y escena vacía cargable, sin resolver poses,
efectos o reset. Después tester exige aserción semántica fallida; parseo,
importación o asset inexistente no son RED. Fixtures no imponen estética.

## Incrementos de entrega

| Incremento | Resultado completo | Verificación propia |
|---|---|---|
| I1/US1 | Soldado pictórico, modos/acciones, daño/moral/derrota y mínimo pool visual compartido | Casos soldado, independencia y ciclo de efecto; regresión/input, QA y docs |
| I2/US2, depende I1 | Enemigo pictórico, avance/contacto real, daño/derrota y reset reutilizando servicio | Casos enemigo, diez ciclos y dos instancias; regresión/input, QA y docs |
| I3/US3, depende I2 | Caja legible y cierre de integración de los tres elementos | Economía/input, suite completa, smoke y gates visuales/rendimiento por entorno, QA/docs |

Cada comportamiento conserva tester RED → dev → tester GREEN → QA → docs.
Arte tiene inspección visual/carga proporcional y regresión, sin RED artificial.
I3 no pospone QA/regresión pertinentes de I1/I2. Un Issue por feature, rama
por incremento del orquestador, PR en borrador; Refs intermedios y Closes final.
Orientación 400 líneas manuales/20 archivos por diff, declarando binarios y
generados aparte. I1 incluye solo infraestructura mínima inseparable de la
derrota inmediata; si excede, dividir un resultado artístico independiente
con QA o justificar indivisibilidad, nunca dividir un ciclo RED/GREEN.

## Complexity Tracking

Sin violaciones: el pool visual evita cadáveres físicos y crear/destruir efectos.
Sin nueva FSM jugable, bus global, stats o controles. Las [tareas](tasks.md) y
su análisis documental están revisados. La preparación queda lista para entregar
al orquestador; no inicia la ejecución.
