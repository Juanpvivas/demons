<!--
Sync Impact Report
- Version change: 4.2.0 → 4.3.0 (MINOR).
- Motivo: confirmación humana explícita del 2026-10-31 de la beta acotada
  1.0.3/build 6, preparación en PR #62 y seguimiento en Issue #61.
- MINOR: añade una autorización consumible a V sin sustituir II/IV/V ni
  reutilizar las excepciones ya consumidas de 1.0.1/build 4 y 1.0.2/build 5.
- Sólo difiere instalación/smoke físicos completos y medición de 60 FPS y
  referencias físicas aplicables; conserva pendientes de #61 y #53 y pausa 006.
- Autoriza integrar PR #62 tras QA y un upload exitoso por destino sobre el
  SHA nuevo exacto de main con QA/CI: Firebase grupo demons; TestFlight sólo
  carga/procesamiento VALID, sin correos, invitaciones o revisión externa.
- Fuente/GREEN/regresión/build, configuración/renderer, firma/empaquetado/
  identificadores/versión y guards siguen obligatorios antes de cada upload.
- No registra QA de publicación, IPA aprobado o envíos todavía inexistentes.
  Referencias proporcionales en AGENTS, flujo, arquitectura y notas 1.0.3.
- Secciones anteriores y sus informes históricos conservados literalmente;
  sin cambios de fuente, workflows, secretos, pruebas, tareas o renderer.
-->

<!--
Sync Impact Report
- Version change: 4.1.1 → 4.2.0 (MINOR).
- Motivo: autorización explícita de la persona el 2026-10-30 para la beta
  excepcional 1.0.2/build 5, integración por Squash and merge del PR #52 y
  un envío exitoso por destino a Firebase App Distribution y TestFlight;
  seguimiento en Issue #51.
- MINOR: añade una autorización acotada y consumible a V, sin sustituir los
  principios II/IV/V ni renovar la excepción consumida de 1.0.1/build 4.
- Difiere sólo instalación/smoke físicos completos y medición de 60 FPS y
  referencia IV/005. No completa 004/T039, 005/T071 o SC-007 ni reanuda 006.
- Conserva fuente/GREEN/regresión, build/CI, configuración y renderer,
  firma/empaquetado/identificadores/versionado antes de cada upload, QA
  independiente, revisión exacta de main y despacho manual autorizado.
- La firma Android fija y sus controles fueron autorizados por separado;
  esta excepción no dispensa fallos del firmante ni reduce guards.
- Alinear referencias breves en AGENTS, arquitectura y flujo. Sin cambios
  de fuente, workflows, secretos, pruebas o tareas por esta enmienda;
  sección 1.0.1 e informes históricos conservados literalmente.
-->

<!--
Sync Impact Report
- Version change: 4.1.0 → 4.1.1 (PATCH).
- Aclarar la trazabilidad de la misma beta autorizada 1.0.1/build 4: preparación
  en PR #47 y su corrección de filtros de exportación nativos en Issue #46.
  La revisión corregida requiere QA y CI nuevos; no hereda el veredicto anterior.
- Un intento que falla antes del upload no consume el envío excepcional.
  Se mantiene un envío exitoso por destino y se identifica la SHA exacta de
  main en cada veredicto/ejecución, con verificadores previos equivalentes.
- Sin ampliar versión, canales, gameplay, renderer, diferimientos físicos,
  reglas generales ni tareas 004/T039 y 005/T071 pendientes.
-->

<!--
Sync Impact Report
- Version change: 4.0.0 → 4.1.0 (MINOR).
- Motivo: autorización explícita de la persona el 2026-10-29 para la beta
  excepcional 1.0.1/build 4, su integración por PR #47 y sus envíos a Firebase
  App Distribution y TestFlight, con seguimiento en Issue #46.
- MINOR: se añade una excepción acotada y consumible al principio V; no se
  sustituye el gate general ni se autoriza otro build, revisión o canal.
- Sólo se difieren las verificaciones físicas completas de instalación/smoke,
  rendimiento/60 FPS y referencia de 005; permanecen pendientes, sin ampliar
  la excepción Xiaomi de 004 ni completar 004/T039 o 005/T071.
- Se conservan fuente, pruebas/build/CI, renderer, firma/empaquetado/versionado,
  QA independiente, revisión exacta de main y despacho manual autorizado.
  La verificación de paquetes previa al upload sigue siendo obligatoria.
- Alinear referencias breves en AGENTS, arquitectura y flujo. Sin cambios de
  gameplay, balance, destinos Web, reglas generales ni evidencias históricas.
-->

<!--
Sync Impact Report
- Version change: 3.0.0 → 4.0.0 (MAJOR).
- Motivo: decisión explícita de la persona del 2026-10-19 de separar
  integración de código y publicación, y preparar un único PR 004-I2 + 005-I1.
- MAJOR porque IV deja de exigir la medición física antes del merge y la
  exige antes de publicar/distribuir; no se reduce el objetivo de 60 FPS.
- Se añade el principio V: integración con TDD, GREEN/regresión, compilación,
  QA funcional independiente, documentación y CI; publicación con aceptación
  adicional del artefacto, plataforma, renderer y hardware de destino.
- QA distingue APROBADO PARA INTEGRACIÓN de APROBADO PARA PUBLICACIÓN.
  Ninguno se obtiene por esta enmienda. Fallos reales funcionales, de fuente
  o compilación bloquean integración; hardware/certificación pendientes
  bloquean publicación y no se dan por cumplidos desde emulación/software.
- Se conservan III y la decisión 3.0.0: Web solo en computador, Android/iOS
  como apps instaladas; no continuar pruebas en navegador móvil.
- Se conservan las referencias físicas provisionales exclusivas de 002 y
  004, sus aprobaciones históricas y límites. SC-007/60 FPS siguen pendientes
  donde no hay nueva medición; 005 no hereda Xiaomi ni resultados anteriores.
- Alinear AGENTS, workflow, roles QA/orquestador, arquitectura de distribución
  y preparación activa de 004/005. Los checkboxes históricos no se alteran
  por cambiar la política. Los despliegues externos requieren gate explícito;
  integrar en main no publica builds ni autoriza su distribución.
- Transición excepcional: un PR en borrador desde codex/005-i1-tablero contra
  main reúne 004-I2 y 005-I1; Refs #18 y Refs #22, sin cerrar las features.
  Se conserva historial y se justifica tamaño; no hay merge automático.
- Sin cambios de gameplay, balance, TDD, pooling, renderer o export presets.
  Las plantillas leen constitución/flujo en ejecución; no se regeneran.
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
sin revisión independiente de QA que confirme estas reglas y el gate de
integración del principio V.
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
en el dispositivo de gama más baja soportada antes de publicar o distribuir
el artefacto. Una ejecución en el editor, emulador/simulador o navegador de
computador no sustituye esa medición física. Antes de integrar, se comparan
carga y rendimiento en los entornos disponibles y QA evalúa las diferencias
observadas y su riesgo; no se ocultan caídas ni se exige a un renderer software
que certifique el objetivo del hardware. La falta de medición física deja
pendiente publicación, sin eximir pruebas funcionales o compilación.
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

### V. Integración y Publicación Separadas

**Integración** incorpora un incremento funcional a `main`, que es una rama de
desarrollo y no una certificación de release. Exige alcance definido, RED →
desarrollo → GREEN para cambios de comportamiento, regresión pertinente,
compilación/exportación aplicable, entrada y smoke funcional en los entornos
disponibles, documentación coherente, CI correcto y revisión independiente
**APROBADO PARA INTEGRACIÓN**. Arte y documentación usan verificación
proporcional. Un error real de fuente, build o funcionamiento del alcance
integrado impide esa aprobación; la falta de hardware o de certificación del
renderer/paquete final por sí sola no impide integrar. QA declara el alcance,
variantes y pendientes; un requisito de publicación pendiente nunca se marca
como probado ni una feature completa por haber integrado parte de su código.

**Publicación** incluye distribuir builds a testers externos, Firebase App
Distribution, TestFlight, itch.io o tiendas. Requiere además validar el artefacto
exacto, su configuración y renderer de destino, instalación/firma/versionado,
smoke completo, matriz de publicación y rendimiento físico exigido por IV/SC
aplicables, con revisión independiente **APROBADO PARA PUBLICACIÓN** y
autorización explícita de la persona para distribuir. Un APK de QA en
Compatibility o una `.app` de simulador con renderizado software no certifican
Mobile, GPU/hardware, el empaquetado final ni 60 FPS físicos. Los artefactos de
CI para revisión interna tampoco constituyen una publicación del juego.

Ningún merge o push a `main` DEBE disparar distribución externa automática.
Los workflows de distribución DEBEN tener un gate explícito que verifique
aprobación y revisión exacta antes de cualquier envío. Aprobar integración no
aprueba publicación ni autoriza promover/fusionar un PR automáticamente. Se
conservan abiertos los Issues y criterios restantes hasta cumplir su alcance
completo, incluidos los requisitos de publicación.

#### Excepción autorizada: beta 1.0.1 (build 4)

Por decisión explícita de la persona del **2026-10-29**, se permite una beta
excepcional **1.0.1 (build 4)** para **Android mediante Firebase App
Distribution** e **iOS mediante TestFlight**, preparada en el
[PR #47](https://github.com/Juanpvivas/demons/pull/47) y seguida en el
[Issue #46](https://github.com/Juanpvivas/demons/issues/46). La autorización
incluye fusionar ese PR y ejecutar manualmente ambos envíos de la beta.
La preparación puede completarse con su PR correctivo de filtros de
exportación nativos, identificado en el mismo Issue, exclusivamente para
reutilizar las exclusiones Web de pruebas, addons de pruebas y archivos de
desarrollo/documentación, sin modificar gameplay, renderer, versión o canales.
La revisión exacta de `main` que incorpora esa preparación debe identificarse
en cada veredicto de QA y ejecución de
distribución. El veredicto anterior no se extiende automáticamente al PR
correctivo: requiere nueva revisión independiente, CI y verificadores previos
al upload equivalentes a los de la preparación inicial.

Exclusivamente para esa beta, se **difieren** las verificaciones físicas
completas de instalación y smoke de partida de II/V, y las mediciones de
rendimiento/60 FPS y referencia aplicable de IV/005. No se dan por aprobadas:
**004/T039 y 005/T071 conservan sus pendientes**, y la excepción provisional
del Xiaomi para 004 no se extiende a 005 ni a otros dispositivos. Se mantienen
las limitaciones y anomalías observadas, sin certificar hardware desde CI,
emulación, simuladores o un arranque parcial.

Siguen siendo obligatorios fuente funcional, pruebas/GREEN y regresión
pertinentes, compilación/CI, configuración y renderer de destino, y
**firma, empaquetado y versión exactos del APK/IPA**. Estos últimos DEBEN
verificarse en el proceso de distribución **antes de cada upload**; un fallo
de verificación bloquea el envío. La excepción no dispensa errores reales de
fuente, build o funcionamiento conocido.

QA independiente puede emitir **APROBADO PARA PUBLICACIÓN — beta excepcional
1.0.1 (build 4)** con ese alcance y sus pendientes explícitos. El veredicto
puede condicionar el envío a las verificaciones de firma/empaquetado/versionado
previas al upload; su incumplimiento invalida la autorización de ese envío.
Esto no equivale a certificar los requisitos físicos diferidos. Se conservan
el despacho manual desde `main`, los guards de versión y las confirmaciones
de QA/humanas; no se permite registrar un veredicto inexistente ni omitir gates.

La excepción se agota con un envío exitoso por destino de esa beta. Un intento
fallido antes del upload no la consume. Permite reintentar mientras no se haya
confirmado la subida de ese destino, sobre la revisión exacta aprobada de la
preparación o de la corrección acotada anterior. No autoriza otras revisiones
fuera de ese alcance, futuros builds, cambios de renderer, itch.io,
publicación en tiendas ni cierre de las features 004/005.
La regla general de II/IV/V sigue vigente para cualquier otro alcance.

#### Excepción autorizada: beta 1.0.2 (build 5)

Por decisión explícita de la persona del **2026-10-30**, se permite una beta
excepcional **1.0.2 (build 5)** para **Android mediante Firebase App
Distribution** e **iOS mediante TestFlight**, preparada en el
[PR #52](https://github.com/Juanpvivas/demons/pull/52) y seguida en el
[Issue #51](https://github.com/Juanpvivas/demons/issues/51). La autorización
incluye integrar esa preparación mediante **Squash and merge** y ejecutar
manualmente un envío exitoso por destino, sobre la revisión exacta de `main`
que QA apruebe. No autoriza otra versión, build, canal o cambio de
gameplay/renderer.

Exclusivamente para esta beta se **difieren** las verificaciones físicas
completas de instalación y smoke de partida de II/V, y las mediciones de
rendimiento/60 FPS y referencia aplicable de IV/005. No se dan por aprobadas:
**004/T039, 005/T071 y SC-007 conservan sus pendientes**, y **006 mantiene su
pausa**. La referencia provisional Xiaomi de 002/004 no se extiende a 005,
a iOS ni a otros dispositivos. Se conservan las anomalías y limitaciones
observadas; ni la prueba humana de una copia QA, ni CI, ni simulación
certifican el artefacto final, hardware o 60 FPS.

Siguen siendo obligatorios fuente funcional, GREEN/regresión pertinentes,
compilación/CI, configuración y renderer de destino, y **firma, empaquetado,
identificadores y versión exactos del APK/IPA**. Para Android se usa la firma
fija nueva autorizada por separado y se verifica el certificado contra la
huella esperada configurada; no se permite una firma alternativa automática
ante un fallo. Las verificaciones del paquete DEBEN ejecutarse **antes de
cada upload** y cualquier fallo bloquea el envío. La excepción no dispensa
errores reales de fuente, build, firmante o funcionamiento conocido, ni
permite reemplazar Mobile por una variante Compatibility de QA.

QA independiente puede emitir **APROBADO PARA PUBLICACIÓN — beta excepcional
1.0.2 (build 5)** con el alcance diferido explícito e identificando la revisión
exacta de `main` y los artefactos. Puede condicionar el envío a las
verificaciones previas de firma/empaquetado/versionado; su incumplimiento
invalida ese envío. Se mantienen el despacho manual desde `main`, los guards
de versión y las confirmaciones de QA/humanas. No se registra un veredicto
inexistente ni se desactiva ningún gate.

La excepción se agota con **un upload exitoso por destino** de esta beta. Un
intento fallido antes del upload no la consume; se puede reintentar sólo
mientras no se haya confirmado la subida de ese destino y sobre la revisión
exacta aprobada. No se reutiliza la excepción consumida de 1.0.1/build 4 ni se
autorizan futuros builds, itch.io, publicación en tiendas o cierre de las
features 004/005. La regla general de II/IV/V permanece vigente fuera de este
alcance. Esta autorización no constituye por sí misma un veredicto de QA ni
afirma que los envíos se hayan ejecutado.

#### Excepción autorizada: beta 1.0.3 (build 6)

Por confirmación explícita de la persona del **2026-10-31**, se autoriza la beta
acotada **1.0.3 (build 6)**, preparada en [PR #62](https://github.com/Juanpvivas/demons/pull/62)
y seguida en [Issue #61](https://github.com/Juanpvivas/demons/issues/61). Incluye
integrar esa preparación tras QA y efectuar manualmente **un upload exitoso por
destino**, sobre el **SHA exacto nuevo de `main` resultante del merge**, con QA
independiente y CI pertinentes a esa revisión. Las aprobaciones/CI de la rama
no certifican automáticamente el SHA resultante ni constituyen por sí solas
`APROBADO PARA PUBLICACIÓN`.

Los destinos se limitan a **Android/Firebase App Distribution, grupo `demons`**,
e **iOS/TestFlight, sólo carga y procesamiento hasta `VALID`**, sin correos,
invitaciones, revisión externa o destinatarios nuevos. Se conservan las
preferencias persistentes del Issue #51. No autoriza itch.io, tiendas, otro
canal, versión/build futuro o cambios de gameplay/renderer.

Exclusivamente para esta beta se **difieren** instalación y smoke físicos
completos de II/V y las mediciones de rendimiento/60 FPS y referencias físicas
aplicables de IV/005. No se aprueban: **004/T039/SC-007, 005/T071/SC-007,
014/T014/SC-007 y 015/T015/SC-008** conservan seguimiento en #61. La introducción
incluida conserva **013/SC-006 y T014/SC-008 en #53**; esta excepción no certifica
sus destinos no acreditados ni sus criterios como completados. **006 sigue
pausada**. La referencia provisional Xiaomi de 002/004 no se amplía a 005, iOS u
otros equipos. CI, simulación y feedback humano de una app QA no acreditan el
artefacto beta final, rendimiento físico o 60 FPS.

Siguen obligatorios fuente funcional, GREEN/regresión pertinente, build/CI,
configuración y renderer de cada destino. **Antes de cada upload** se verifican
firma, empaquetado, identificadores y versión exactos del APK/IPA. Android usa
el mismo certificado fijo de 1.0.2, contrastado con la huella esperada; no hay
fallback a otra firma. iOS se firma con el certificado Distribution y perfil
actuales mediante el runner existente y debe superar el verificador obligatorio
del IPA antes de subir. Exportar un proyecto Xcode no acredita un IPA firmado
y verificado. No se modifica el workflow ni se dispensa un fallo real de
fuente, build, firmante, paquete, versión o funcionamiento conocido, ni se cambia
Mobile por Compatibility de QA. Todo control fallido bloquea ese envío.

QA independiente puede emitir **APROBADO PARA PUBLICACIÓN — beta excepcional
1.0.3 (build 6)** identificando el SHA exacto de `main`, los artefactos y el alcance
físico diferido. Puede condicionar el envío a las comprobaciones previas; su
incumplimiento invalida ese envío. Se conservan despacho manual desde `main`,
guards de versión y confirmaciones QA/humanas; no se inventa un veredicto o
resultado de distribución desde esta autorización.

La excepción se consume con **un upload exitoso por destino**. Un fallo previo
al upload no la consume; sólo se reintenta mientras no exista una subida exitosa
confirmada en ese destino, con la revisión/QA vigentes y comprobaciones previas
aplicables. Procesar la carga de TestFlight hasta `VALID` no autoriza una segunda
subida exitosa ni ampliar su distribución. Las excepciones anteriores de
**1.0.1/build 4 y 1.0.2/build 5 están consumidas**, con los envíos anteriores
seguidos en sus Issues, incluido #51; no se reutilizan ni renuevan. Los cierres
funcionales de #18/#22/#55/#58 no completan publicación: #61 y #53 siguen abiertos.
La política general II/IV/V rige íntegramente fuera de este alcance; autorizar
esta beta no afirma que se haya enviado.

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

**Version**: 4.3.0 | **Ratified**: 2026-08-13 | **Last Amended**: 2026-10-31
