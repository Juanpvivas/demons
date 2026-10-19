<!--
Sync Impact Report
- Version change: 2.2.0 → 3.0.0 (MAJOR).
- Motivo: decisión explícita de la persona del 2026-10-19: Web solo en
  navegador de computador; Android/iOS solo como aplicaciones instaladas
  (APK/IPA). Se detienen las nuevas pruebas en navegadores móviles, incluidos
  emuladores y simuladores. No se añade un bloqueo de acceso por código.
- MAJOR porque se redefine de forma incompatible el alcance de plataformas
  del principio III: Web móvil deja de ser destino y matriz de aceptación.
  No es una aclaración de redacción ni una expansión de soporte.
- III y Restricciones Técnicas distinguen Web en computador y apps nativas
  Android/iOS. IV aplica la matriz Web a computadores; conserva íntegros
  60 FPS físicos, pooling y el umbral de carga aún pendiente.
- Se conservan GDScript compartido, itch.io como primer portal y PC nativo
  para desarrollo/pruebas. No se habilitan dependencias C#/.NET excluyentes.
- Se conservan las referencias físicas provisionales exclusivas de 002
  (enmienda 1.2.0, integrada en 2.1.0) y 004 (enmienda 2.2.0): Xiaomi 11T Pro
  2107113SG de 2021, sin certificar resultados ni otros equipos. La falta de
  nuevas pruebas físicas de 004 y la autorización de Android Emulator no
  eximen SC-007 ni acreditan hardware desde emuladores/simuladores.
- Documentos activos alineados: AGENTS.md, README, SPEC, ARCHITECTURE,
  DEVELOPMENT_WORKFLOW, WEB_EXPORT y spec/plan/research/modelo/contrato/
  quickstart/checklist de 004.
  El orquestador alinea las descripciones pendientes de tasks.md sin cambiar
  casillas. No se alteran gameplay, pruebas, renderer ni export presets.
- Los documentos y evidencias de 001, 002 y 003 y las aprobaciones históricas
  de 004 conservan sus versiones, resultados y límites. El navegador móvil
  histórico no se convierte en prueba nativa ni se presenta como fallo nuevo.
- Sin cambios en TDD, QA independiente, separación Spec Kit/agentes o
  ratificación inicial. Esta enmienda no aprueba la entrega I2/004 ni una
  excepción a sus requisitos nativos pendientes.
- Templates y comandos de preparación leen la constitución en ejecución;
  no requieren regeneración por esta integración documental.
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
(GDScript style guide oficial de Godot). El código compartido del juego DEBE
seguir siendo exportable a Web, Android e iOS, sin depender de C#/.NET ni de
extensiones que excluyan alguno de esos destinos. Ninguna funcionalidad se integra a la rama principal
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
Web (navegador solo en computador), Android e iOS nativos, adaptando el
input (touch vs. mouse/teclado cuando corresponda) sin cambiar la
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
en el dispositivo de gama más baja soportada antes de mergear. Una ejecución
en el editor o en un navegador de computador no sustituye esa medición.
Las features Web DEBEN registrar además carga y rendimiento en los navegadores
y computadores de su matriz de aceptación; no se extrapolan los resultados
del ejecutable nativo al navegador del mismo dispositivo.

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

**Referencia provisional exclusiva de la feature 004 (2026-10-16):** por decisión
explícita de la persona («Utiliza el xiaomi»), el Xiaomi 11T Pro físico, modelo
`2107113SG` de 2021, se admite como dispositivo de referencia provisional para
aceptar `004-personajes-municion-monte-calvo`. Esta autorización es independiente
de la excepción de 002 y DEBE conservar los 60 FPS estables durante gameplay
típico, nuevas mediciones de 004 y revisión independiente de QA sobre sus
limitaciones. No aprueba resultados ni certifica teléfonos menos potentes.
La referencia nominal global de gama media Android de los últimos ~3 años
permanece vigente. La autorización no se extiende a otras features, otros
teléfonos, iOS ni emuladores/simuladores. Las comprobaciones Web históricas del
Xiaomi conservan su alcance separado de las nativas; desde el 2026-10-19 no
se requieren ni se continúan pruebas de navegador móvil. Esta reducción del
alcance Web no exime las mediciones físicas nativas pendientes.

**Razón**: como es un juego 2D pensado para escalar a hordas de enemigos en
pantalla, el rendimiento en el hardware más débil del público objetivo (móviles
de gama media/baja) es lo que determina si el juego es jugable, no el
rendimiento en la máquina de desarrollo.

## Restricciones Técnicas

- Motor: Godot 4.x, licencia MIT — no se introduce dependencia de pago
  obligatoria para el desarrollo ni la publicación del juego.
- Lenguaje del juego compartido: GDScript. No introducir C#/.NET como
  dependencia del juego exportado mientras impida el destino Web; una futura
  excepción requiere demostrar compatibilidad y enmendar esta constitución.
- Plataformas objetivo: Web solo en navegador de computador, y Android/iOS
  como aplicaciones nativas instaladas (APK/IPA), con ratón o toque según
  corresponda. No se prueban navegadores Android/iOS, tampoco en emuladores o
  simuladores; en iOS Simulator se usa su app nativa `.app`, no un IPA de
  dispositivo. itch.io es el primer portal Web previsto. No se publican
  instaladores Windows/macOS/Linux como producto.
  El editor y la ejecución nativa local en PC siguen disponibles para desarrollo
  y pruebas. Toda decisión técnica nueva debe considerar los tres destinos.
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

**Version**: 3.0.0 | **Ratified**: 2026-08-13 | **Last Amended**: 2026-10-19
