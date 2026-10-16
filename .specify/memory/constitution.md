<!--
Sync Impact Report
- Version change: 1.1.0 → 1.2.0 (MINOR).
- Motivo: decisión explícita de la persona (2026-10-16): «Usar el Xiaomi como
  referencia provisional para 002», conservando el objetivo de 60 FPS y QA.
- Principio modificado: IV. Requisitos de Rendimiento, sin cambio de título.
  Se amplía materialmente la guía de referencia con una excepción limitada a
  la aceptación de 002: Xiaomi 11T Pro, modelo 2107113SG, generación 2021.
- Se conservan 60 FPS estables y la referencia nominal global de gama media
  Android de los últimos ~3 años. No se exime estabilidad ni se certifican
  otros teléfonos, la feature 003, iOS o plataformas emuladas.
- Secciones añadidas/eliminadas: ninguna; se añade un párrafo acotado a IV.
- Referencias sincronizadas: spec.md, plan.md, quickstart.md y
  contracts/visual-boundary.md de specs/002-monte-calvo-terreno-trincheras/.
- Plantilla activa resuelta; fuentes de preparación del preset consultadas.
  Templates y comandos leen la constitución en ejecución y no se modifican.
- Revisión documental aprobada por QA el 2026-10-16; aceptación del rendimiento
  todavía pendiente. La decisión de dispositivo no convierte una medición
  corta en aprobación.
- Se conservan los cuatro principios, la ratificación inicial y la enmienda
  1.1.0 de 2026-10-15 sobre Spec Kit, agentes, TDD y QA independiente.
- TODO diferido sin cambios: PERFORMANCE_LOAD_TIME_TARGET, pendiente de medir
  en dispositivo Android de referencia.
-->

# Demonios de las Trincheras Constitution

## Core Principles

### I. Calidad de Código
El balance y los stats de unidades y enemigos DEBEN vivir en archivos `Resource`
(`.tres`) desacoplados del código, nunca como valores hardcodeados dentro de
scripts — esto ya se estableció como decisión técnica en el spec del juego y es
innegociable a medida que crece el roster de soldados y enemigos. La lógica de
gameplay (economía, daño, detección de objetivos) DEBE mantenerse separada de
la lógica puramente visual/de animación, para que cada una se pueda modificar
sin romper la otra. Todo código nuevo DEBE seguir una guía de estilo consistente
(GDScript style guide oficial de Godot, o las convenciones estándar de C# si se
usa ese lenguaje) y no se mezclan ambos lenguajes dentro de un mismo sistema sin
justificación explícita. Ninguna funcionalidad se integra a la rama principal
sin una revisión propia (auto-revisión o revisión de otra persona) que confirme
que sigue estas reglas.
**Razón**: el proyecto ya pasó por varias iteraciones de diseño del sistema de
economía; sin esta disciplina, cada cambio de balance obligaría a tocar código
en vez de solo datos, y el riesgo de romper mecánicas ya validadas crece rápido.

### II. Estándares de Testing
La lógica de gameplay que no depende de renderizado (cálculo de daño, consumo y
recolección de munición, acumulación de moral, condiciones de victoria/derrota,
generación de oleadas) DEBE tener pruebas automatizadas (usando GUT — Godot Unit
Testing — u otro framework de testing compatible con Godot 4.x). Ningún build se
comparte con testers externos sin pasar antes un "smoke test" manual: el juego
abre, el nivel carga, y se puede jugar de principio a fin sin errores críticos ni
cierres inesperados. Todo cambio de balance (daño, costos, cadencia de oleadas)
DEBE validarse con al menos una sesión de playtesting manual antes de mergear.
Para cambios de comportamiento, el desarrollo DEBE seguir TDD: el tester
escribe y ejecuta una prueba que falle por el requisito ausente (RED), el
agente de desarrollo implementa y el tester confirma GREEN y la regresión
pertinente. Errores de entorno/importación no constituyen RED. QA valida de
forma independiente antes de aprobar la implementación. Una tarea dedicada
solo a pruebas RED puede aprobarse por su fallo esperado válido, sin aprobar
el comportamiento aún pendiente. Arte o documentación sin lógica nueva se
validan con criterios pertinentes, sin fabricar pruebas o fallos artificiales.
El detalle operativo está en `docs/DEVELOPMENT_WORKFLOW.md`.
**Razón**: el sistema de economía dual (munición + moral) tiene varias reglas de
interacción no triviales (ej. qué pasa con la moral acumulada al recargar); sin
pruebas, los cambios futuros pueden reintroducir bugs de balance ya resueltos.

### III. Consistencia de Experiencia de Usuario
La interacción de colocación de unidades, lectura de recursos (munición, moral)
y retroalimentación de combate DEBEN comportarse de forma consistente entre
Android, iOS y PC, adaptando el input (touch vs. mouse/teclado) sin cambiar la
lógica ni el significado de las acciones. Todo cambio de estado relevante para
el jugador (soldado sin munición pasando a machete, enemigo recibiendo daño,
oleada por llegar) DEBE comunicarse con retroalimentación visual y/o sonora
clara — no se permiten transiciones de estado silenciosas que dejen al jugador
sin entender qué pasó. El tono narrativo e histórico (homenaje respetuoso al
Batallón Colombia) DEBE mantenerse consistente en todo texto, arte y audio de
UI; no se introduce contenido que trivialice o glorifique gratuitamente la
violencia del contexto histórico real.
**Razón**: es un tower defense donde la lectura rápida del estado del tablero es
el corazón de la jugabilidad, y el proyecto tiene un compromiso narrativo con
una historia real que debe respetarse en cada punto de contacto con el jugador.

### IV. Requisitos de Rendimiento
El juego DEBE mantener 60 FPS estables durante gameplay típico en el dispositivo
de referencia objetivo (gama media Android de los últimos ~3 años). Enemigos,
proyectiles y efectos en pantalla DEBEN usar pooling de objetos en vez de
instanciar/destruir constantemente, para evitar caídas de framerate durante
oleadas grandes. El tiempo de carga de un nivel NO DEBE exceder
TODO(PERFORMANCE_LOAD_TIME_TARGET) — valor pendiente de definir tras medir en
el dispositivo de referencia. Cualquier funcionalidad que arriesgue el
framerate objetivo (partículas, cantidad simultánea de enemigos) DEBE probarse
en el dispositivo de gama más baja soportada antes de mergear, no solo en PC.

**Referencia provisional exclusiva de la feature 002 (2026-10-16):** por decisión
explícita de la persona, el Xiaomi 11T Pro físico, modelo `2107113SG` de 2021,
se admite como dispositivo de referencia provisional para aceptar
`002-monte-calvo-terreno-trincheras`. Se DEBEN conservar los 60 FPS estables
durante gameplay típico y la revisión independiente de QA sobre las mediciones
y sus limitaciones. Esta autorización cambia solo la referencia de esa feature;
no aprueba el rendimiento observado ni exime estabilidad. La referencia nominal
global de gama media Android de los últimos ~3 años permanece vigente. No se
extrapola esta aceptación provisional a otros teléfonos, a la feature 003,
a iOS ni al rendimiento de emuladores o simuladores.

**Razón**: como es un juego 2D pensado para escalar a hordas de enemigos en
pantalla, el rendimiento en el hardware más débil del público objetivo (móviles
de gama media/baja) es lo que determina si el juego es jugable, no el
rendimiento en la máquina de desarrollo.

## Restricciones Técnicas

- Motor: Godot 4.x, licencia MIT — no se introduce dependencia de pago
  obligatoria para el desarrollo ni la publicación del juego.
- Lenguaje: GDScript por defecto para prototipado; C# permitido solo en
  sistemas donde el rendimiento lo justifique, documentando la razón.
- Plataformas objetivo: Android, iOS, PC (Windows/macOS/Linux) — toda decisión
  técnica nueva debe considerarse contra las tres antes de adoptarse.
- Datos de balance (unidades, enemigos, oleadas) definidos como `Resource`
  (`.tres`), nunca hardcodeados en scripts de lógica.

## Flujo de Trabajo de Desarrollo

- Spec Kit se usa para **preparación**: especificación (`speckit-specify`),
  aclaraciones (`speckit-clarify`), planificación (`speckit-plan`), tareas
  (`speckit-tasks`), checklists y análisis de consistencia (`speckit-analyze`).
  No implementa gameplay ni ejecuta pruebas, y no aprueba tareas. El comando
  heredado `speckit-implement` solo informa de la entrega a los agentes.
- La **ejecución** corresponde a los agentes del proyecto, coordinados por
  `project-orchestrator`: tester RED → desarrollo → tester GREEN → QA →
  documentación. El orquestador clasifica las tareas de pruebas,
  implementación, arte y documentación según
  `docs/DEVELOPMENT_WORKFLOW.md`. En Claude Code, el punto de entrada es
  `/implementar-feature <feature-id>`; otras herramientas usan delegación
  equivalente. Solo el orquestador marca `[X]` después de `APROBADO` de QA.
- El diseño general en `docs/SPEC.md` sirve de referencia para los specs de
  cada feature. Una lista generada de tareas no prueba implementación ni
  sustituye su validación independiente.
- Ningún cambio de balance o mecánica central se implementa directamente sin
  pasar, al menos informalmente, por una revisión contra esta constitución.

## Governance

Esta constitución tiene precedencia sobre cualquier otra práctica o decisión
ad hoc del proyecto. Toda enmienda DEBE documentarse con un Sync Impact Report
(como el de este documento) y versionarse siguiendo semver:
- MAJOR: eliminación o redefinición incompatible de un principio existente.
- MINOR: adición de un nuevo principio o expansión material de una guía
  existente.
- PATCH: aclaraciones, redacción, correcciones sin cambio de sentido.

Todo plan (`/speckit-plan`) o tarea (`/speckit-tasks`) generado DEBE verificar
cumplimiento con los principios de esta constitución antes de considerarse
listo para implementar. Cualquier complejidad técnica que viole un principio
DEBE justificarse explícitamente en el documento correspondiente (plan o spec)
o rechazarse.

**Version**: 1.2.0 | **Ratified**: 2026-08-13 | **Last Amended**: 2026-10-16
