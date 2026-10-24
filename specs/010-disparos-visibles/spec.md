# Feature Specification: Disparos visibles

**Feature ID**: `010-disparos-visibles`
**Planned Branch**: `codex/010-disparos-visibles`
**Created**: 2026-10-23
**Status**: Draft
**Tracking**: [Issue #40](https://github.com/Juanpvivas/demons/issues/40)
**Input**: «Implementa el destello y la trazadora desde main, conservando el estilo pictórico y las mecánicas actuales. Sigue el flujo de agentes y QA, actualiza documentación y prepara un PR en borrador, manteniendo la publicación pendiente».

**Revisión autorizada — 2026-10-24**: tras probar Web, iOS y Android, la persona eligió destello/trazadora al doble de tamaño, alcance frontal un 50 % mayor y recorrido visual de 0,30 s más 0,10 s de desvanecido, conservando diagonales contiguas y daño inmediato. Esta revisión actualiza el mismo [PR #41 en borrador](https://github.com/Juanpvivas/demons/pull/41); su implementación y QA están pendientes. T001–T012 conservan la aprobación del perfil inicial de 0,16 s, máximo 0,20 s y alcance anterior; no acreditan el perfil revisado.

## User Scenarios & Testing

### User Story 1 — Reconocer cada disparo del soldado colombiano (Priority: P1)

Como jugador, quiero distinguir el destello y seguir la trazadora desde la boca del fusil hasta el enemigo, con disparos que comiencen a mayor distancia, para reconocer su acción sobre el terreno de Monte Calvo.

**Why this priority**: el perfil inicial cuesta seguirlo a tamaño de juego. La revisión amplía el efecto y el alcance frontal autorizado, conservando las demás reglas de combate.

**Independent Test**: jugar una partida con soldados disparando de frente desde el nuevo alcance y en las diagonales permitidas; comprobar tamaño, recorrido visible, desaparición, balance y continuidad de las demás reglas, incluidos última bala, pausa y otra partida.

**Acceptance Scenarios**:

1. **Given** un soldado con munición y un enemigo elegible, **When** realiza un disparo real, **Then** aparece una sola pareja de destello y trazadora desde el cañón hacia ese blanco, con el daño y consumo de munición inmediatos actuales.
2. **Given** un disparo frontal o diagonal permitido, **When** se muestra su efecto, **Then** destello y trazadora tienen el doble de tamaño del perfil inicial; la cabeza del trazo recorre desde el cañón hasta el destino capturado en 0,30 s, conserva intensidad durante el avance y se desvanece en los siguientes 0,10 s, desapareciendo por completo a los 0,40 s de juego activo.
3. **Given** la última bala o un blanco que muere y se retira, **When** termina el disparo, **Then** se solicita su efecto una sola vez con la posición original del blanco y se respeta el cambio de arma o fin de partida existente. El tiro que causa victoria puede completar su breve efecto, sin habilitar otro ataque.
4. **Given** un soldado sin blanco válido, sin balas, usando machete o regresando, **When** espera o actúa según su estado, **Then** no aparece un disparo de fusil ficticio.
5. **Given** efectos activos, **When** se pausa, se alcanza victoria/derrota o se sale de ese intento, **Then** la pausa congela y reanuda su progreso; victoria/derrota permiten terminar sólo los efectos ya confirmados; volver al menú o iniciar otra partida elimina los efectos anteriores de inmediato.
6. **Given** un enemigo frontal cuyo cuerpo solapa el tramo de alcance ampliado, **When** el soldado tiene munición y puede disparar, **Then** lo ataca con las reglas vigentes; un cuerpo fuera del nuevo alcance no recibe el disparo y las diagonales siguen limitadas a las celdas contiguas.

### Edge Cases

- Dos o más soldados disparan en el mismo intervalo: cada disparo mantiene su origen, destino y duración, sin compartir estados transitorios.
- Un blanco muere, sale del árbol o su cuerpo se reutiliza durante el disparo: la trazadora conserva la posición capturada y nunca sigue al nuevo uso del cuerpo.
- La última bala cambia al soldado a machete: no elimina el efecto ya confirmado; la pose y corrida vigentes conservan su prioridad.
- Un efecto termina después de que su instancia fue reutilizada: no puede ocultar ni retirar una activación posterior.
- Redimensionar la ventana o cambiar la relación de pantalla conserva la alineación con el mundo y no hace al efecto interceptar entrada.
- Un disparo causa victoria: completa su efecto dentro del mismo máximo de 0,40 s y no permite otro ataque. Salir al menú o reintentar antes cancela esa presentación.
- Un blanco está más cerca que la longitud máxima de la trazadora: el segmento queda recortado entre cañón y destino, sin adelantarse, sobrepasarlo ni convertirse en un haz sostenido.
- Dos soldados usan alcances configurados distintos: la geometría de uno no cambia la del otro ni muta sus datos compartidos.

## Requirements

### Functional Requirements

- **FR-001**: Cada disparo de fusil confirmado DEBE solicitar exactamente un destello de cañón y una trazadora breve hacia la posición del blanco al disparar; ambos forman un único efecto cosmético.
- **FR-002**: El efecto DEBE seguir la orientación frontal o diagonal del disparo. La cabeza de la trazadora DEBE partir de la boca del fusil, alcanzar el destino capturado en 0,30 s conservando intensidad durante ese recorrido y desvanecerse en los siguientes 0,10 s; a los 0,40 s de juego activo no queda presentación, sin parecer un haz continuo. El recorrido es cosmético y no retarda el daño.
- **FR-003**: Destello y trazadora DEBEN duplicar el tamaño del perfil inicial, conservar la identidad pictórica de Monte Calvo mediante tonos cálidos moderados y bordes suaves, ser legibles sobre el terreno y no aclarar, teñir ni iluminar el cuerpo completo del soldado.
- **FR-004**: El daño DEBE continuar siendo instantáneo; munición, cadencia, selección/prioridad de blanco elegible, moral, recompensas, movimiento, oleadas y condiciones terminales DEBEN conservar sus reglas y valores actuales. La única modificación de balance autorizada es el alcance frontal de FR-010.
- **FR-005**: El efecto NO DEBE causar daño, colisión, ocupación, interacción ni sonido nuevo, ni introducir proyectiles físicos, retardo de impacto u otros cambios de balance.
- **FR-006**: La última bala y los disparos letales DEBEN conservar su solicitud visual, independiente de los cambios de arma y retiro o reutilización de actores; no DEBEN producirse efectos sin un disparo real.
- **FR-007**: Cada efecto DEBE ser independiente de los actores después del disparo; activaciones simultáneas o reutilizadas no DEBEN modificar ni retirar otras activaciones.
- **FR-008**: Pausar DEBE congelar el efecto hasta reanudar; victoria/derrota DEBEN rechazar nuevos efectos y permitir completar sólo los ya confirmados dentro de su duración. Cerrar el intento, volver al menú o iniciar otra partida DEBE limpiar inmediatamente los efectos e impedir que solicitudes anteriores reaparezcan.
- **FR-009**: La presentación DEBE conservar la corrida y el color del colombiano aprobados en 009, la animación enemiga de 008, la lectura del HUD y la entrada existente, también al redimensionar.
- **FR-010**: El extremo frontal del alcance del colombiano DEBE pasar de 264 a 396 unidades de mundo (+50 %), con el límite cercano de 24 y altura de 192 actuales. El dato DEBE vivir en un Resource de stats; la detección DEBE conservar el solape corporal real, el frente de la misma fila y sólo las diagonales directamente contiguas. Cada actor DEBE tener su geometría independiente, sin mutar stats o formas compartidas.

### Key Entities

- **Disparo confirmado**: hecho de combate con origen y destino capturados antes de las consecuencias del daño; no representa un proyectil con autoridad jugable.
- **Efecto de disparo**: presentación efímera de un destello y una trazadora, con progreso propio y sin dependencia posterior de los actores.
- **Alcance frontal**: dato base del tipo de unidad que determina el extremo longitudinal de detección; no es una distancia al centro del enemigo ni amplía las diagonales elegibles.

## Success Criteria

### Measurable Outcomes

- **SC-001**: En todos los escenarios de disparo frontal, diagonal, simultáneo, última bala y baja del blanco, la comprobación funcional confirma una solicitud visual por cada disparo real y ninguna en los estados sin disparo descritos.
- **SC-002**: La revisión visual distingue destello y trazadora al doble de tamaño, sigue el avance del cañón al destino durante 0,30 s y el desvanecido final de 0,10 s, confirma desaparición completa a los 0,40 s activos y no observa haces sostenidos, tintes del soldado ni cambios de su corrida.
- **SC-003**: Las comprobaciones de daño inmediato, cadencia, munición, prioridad de blancos elegibles, moral, movimiento y ciclo de partida conservan los resultados actuales con efectos presentes o ausentes, salvo la ampliación de alcance autorizada.
- **SC-004**: En pausa/reanudación y retirada/reutilización del blanco los efectos conservan su progreso y contexto; en victoria/derrota sólo terminan los ya confirmados dentro de 0,40 s activos. Menú, cierre y otra partida dejan cero efectos anteriores, sin reaparición ni interferencia entre activaciones.
- **SC-005**: La entrega incluye QA independiente para integración, documentación actualizada y un PR en borrador vinculado a su Issue; los resultados identifican su entorno y mantienen la publicación pendiente.
- **SC-006**: Las comprobaciones funcionales confirman el tramo frontal [24,396] mediante solape real, exclusión fuera de alcance, diagonales contiguas e independencia entre configuraciones. Una sesión manual de balance comprueba el combate con este alcance sin modificar daño, cadencia, munición u oleadas para compensarlo.

## Assumptions

- Se reutilizan el nivel, soldados, combate y flujo de menú actuales; no se añaden controles ni opciones para esta feature.
- La trazadora representa visualmente el recorrido del tiro ya resuelto; no simula tiempo de vuelo jugable ni modifica las posiciones de armas o actores. Un tiro letal puede avanzar hacia la última posición capturada aunque el enemigo ya se haya retirado.
- La validación visual contempla Web en computador y apps nativas Android/iOS cuando estén disponibles. Cada resultado acredita sólo el entorno ejecutado; hardware, renderer y paquete final pendientes pertenecen al gate de publicación.
- El diagnóstico de rendimiento de Issue #30 permanece pausado por decisión del usuario. Esta feature no reabre mediciones de FPS ni campañas de rendimiento, ni acredita requisitos de publicación con una prueba funcional.
