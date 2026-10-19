# Implementation Plan: Personajes y munición de Monte Calvo

**Feature ID**: `004-personajes-municion-monte-calvo`  
**Execution Branch**: `codex/004-i1-soldado`; una rama por incremento.
**Date**: 2026-10-16 | **Spec**: [spec.md](spec.md)

La preparación inicial se ejecutó en I1, aprobado sobre `87a39c6`. La corrección
de legibilidad/encuadre delimitada en T031 está aprobada funcionalmente en T036.
I2/I3 y el seguimiento de consolidación/entrega figuran en las [tareas](tasks.md).

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
ObjectPool y GUT 9.7.1 existentes; cámara local Camera2D para T031 y material de
estilo compartido inmutable; sin addons/autoloads/AnimationTree nuevos.

**Storage**: PNG RGBA originales, importación, SpriteFrames.tres y procedencia;
estado visual efímero por instancia, sin esquemas de stats o persistencia nuevos.

**Testing**: GUT para comportamiento visual/ciclo; revisión artística, carga,
input real, smoke y medición. Runner existente `tools/ci/run_gut.py`.

**Target Platform**: Web solo en navegador de computador y apps Android/iOS
instaladas, por decisión de la persona del 2026-10-19 (constitución 3.0.0).
Android Emulator usa APK; iOS Simulator usa `.app`, sin acreditar un IPA físico.
PC nativo solo desarrollo/pruebas. Renderer/presets/InputMap y semántica de input
intactos; cámara local acotada a la corrección T031, sin zoom.

**Project Type**: juego 2D Godot.

**Performance Goals**: 60 FPS estables en Xiaomi 11T Pro físico `2107113SG` de
2021, referencia provisional exclusiva de 004 (enmienda 2.2.0 conservada en la
constitución 3.0.0), y medición Web en computador separada; carga fría/caliente,
frame times y memoria frente a baseline. El emulador autorizado no sustituye
las mediciones físicas pendientes.

**Constraints**: cuerpos de actores 48×48, grid 96×96, detectores y caja
32×32/collider radio 20 intactos. El soldado cambia solo en su hijo visual:
altura opaca neutra objetivo aproximada de 72 unidades, pie raíz+y24 y pivote
estable ≤1 unidad; al menos 32 CSS px opacos en CSS 794×305, reconocible sin
overlay y en grises con luz/contorno mate discreto, sin anillos o HUD.
Reutilizar atlas, sin exigir regeneración del PNG. Conservar material autorado
inmutable en snapshot neutro y reset, sin tintes/pulsos transitorios filtrados.
Camera2D sin zoom centra mundo x=576 al 50 % del viewport lógico (error ≤1),
con origen vertical efectivo del canvas y=0. No imponer position.y=0 ni
limit_left=0: el margen izquierdo muestra mundo negativo en pantallas anchas.
Conservar la composición iPad 1152×864; equilibrar Xiaomi nativo 1440×648 y
viewports anchos extendiendo solo cielo/panorama/suelo decorativos a la
izquierda con texturas existentes. No mover trincheras, actores o grid.
CSS 794×305 y Web aproximadamente 1684×648 corresponden a referencias
históricas de I1; no requieren continuar pruebas de navegador móvil.
Texturas importadas de ejecución hasta 1024² por actor y caja hasta 256²:
máximo 8.25 MiB RGBA8 estimados, sin equivaler a VRAM real. El PNG original del
soldado conserva 1774×887; su importación limita la textura a 1024×512 y los
recortes usan esas coordenadas. Compartir frames de derrota con el efecto.

**Scale/Scope**: un diseño por bando, dos modos del soldado, una caja, dos
presentadores y un pool visual mínimo; sin HUD, audio, proyectiles o rediseño
del terreno. T031 autoriza solo el ajuste de cámara y cobertura descritos arriba.

## Constitution Check

| Gate | Antes de investigación | Después del diseño |
|---|---|---|
| I: Resources/separación/GDScript | Aplicable | Balance protegido; presentación observacional |
| II: TDD y QA independiente | Nueva lógica visual testeable | RED → dev → GREEN → QA; arte sin RED artificial |
| III: lectura y respeto histórico | Estados existentes | Silueta/armas y feedback, matriz por entorno |
| IV: 60 FPS y pooling | Nueva medición necesaria | Pool de efectos; Xiaomi físico provisional autorizado para 004 |
| Flujo de preparación y PR pequeños | Spec Kit solo prepara | Tres incrementos completos; futura ejecución por roles |

Sin NEEDS CLARIFICATION de diseño. La constitución 3.0.0 conserva la autorización
explícita del 2026-10-16 para usar el Xiaomi físico provisional exclusivamente en
004; la referencia nominal global permanece vigente. Desde el 2026-10-19 no
será posible obtener nuevas pruebas físicas y se continúa con APK en Android
Emulator, sin pedir reconexión del teléfono. SC-007 físico sigue pendiente. La autorización
no aprueba resultados: se requieren nuevas mediciones y QA, sin heredar 002/003
ni certificar equipos menos potentes o iOS. Web solo en computador y apps
nativas se miden por separado; no se continúan pruebas de navegador móvil.
El umbral constitucional de carga permanece pendiente,
sin inventarlo. Cada entorno no probado deja pendiente su aceptación.

## Project Structure

Documentación preparada: spec, plan, research, data-model, quickstart, contrato y
[tasks](tasks.md) en esta carpeta. No crear archivos nuevos de evidencias;
resultados de ejecución al PR.

Rutas del diseño; las del soldado y servicio están integradas en I1, mientras
las del enemigo y la caja corresponden a los incrementos pendientes:

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
su análisis inicial conservan su historia. La excepción acotada T031 responde
al nuevo feedback sin ampliar gameplay: QA documental T032 → RED T033 → desarrollo
T034 → GREEN/visual T035 → QA funcional T036 → documentación T037 → QA final T038.
La corrección completó los gates hasta QA funcional T036 con validación propia,
sin sustituirlos por la aprobación histórica de I1. El estado de consolidación
y entrega se conserva en las tareas y el PR. No se inicia I2.
