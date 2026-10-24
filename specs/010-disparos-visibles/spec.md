# Feature Specification: Disparos visibles

**Feature ID**: `010-disparos-visibles`
**Planned Branch**: `codex/010-disparos-visibles`
**Created**: 2026-10-23
**Status**: Draft
**Tracking**: [Issue #40](https://github.com/Juanpvivas/demons/issues/40)
**Input**: «Implementa el destello y la trazadora desde main, conservando el estilo pictórico y las mecánicas actuales. Sigue el flujo de agentes y QA, actualiza documentación y prepara un PR en borrador, manteniendo la publicación pendiente».

## User Scenarios & Testing

### User Story 1 — Reconocer cada disparo del soldado colombiano (Priority: P1)

Como jugador, quiero ver un destello en la boca del fusil y una trazadora breve hacia el enemigo al que dispara el soldado, para reconocer su acción sobre el terreno de Monte Calvo.

**Why this priority**: la pose actual de ataque no permite seguir claramente el disparo. El feedback visual completa esa lectura sin alterar el combate.

**Independent Test**: jugar una partida con soldados disparando de frente y en las diagonales permitidas; comprobar destello, dirección, desaparición y continuidad de las reglas actuales, incluidos última bala, pausa y otra partida.

**Acceptance Scenarios**:

1. **Given** un soldado con munición y un enemigo elegible, **When** realiza un disparo real, **Then** aparece una sola pareja de destello y trazadora desde el cañón hacia ese blanco, con el daño y consumo de munición inmediatos actuales.
2. **Given** un disparo frontal o diagonal permitido, **When** se muestra su efecto, **Then** la dirección corresponde al blanco de ese disparo y el efecto desaparece por completo en un máximo de 0,20 s de juego activo.
3. **Given** la última bala o un blanco que muere y se retira, **When** termina el disparo, **Then** se solicita su efecto una sola vez con la posición original del blanco y se respeta el cambio de arma o fin de partida existente. El tiro que causa victoria puede completar su breve efecto, sin habilitar otro ataque.
4. **Given** un soldado sin blanco válido, sin balas, usando machete o regresando, **When** espera o actúa según su estado, **Then** no aparece un disparo de fusil ficticio.
5. **Given** efectos activos, **When** se pausa, se alcanza victoria/derrota o se sale de ese intento, **Then** la pausa congela y reanuda su progreso; victoria/derrota permiten terminar sólo los efectos ya confirmados; volver al menú o iniciar otra partida elimina los efectos anteriores de inmediato.

### Edge Cases

- Dos o más soldados disparan en el mismo intervalo: cada disparo mantiene su origen, destino y duración, sin compartir estados transitorios.
- Un blanco muere, sale del árbol o su cuerpo se reutiliza durante el disparo: la trazadora conserva la posición capturada y nunca sigue al nuevo uso del cuerpo.
- La última bala cambia al soldado a machete: no elimina el efecto ya confirmado; la pose y corrida vigentes conservan su prioridad.
- Un efecto termina después de que su instancia fue reutilizada: no puede ocultar ni retirar una activación posterior.
- Redimensionar la ventana o cambiar la relación de pantalla conserva la alineación con el mundo y no hace al efecto interceptar entrada.
- Un disparo causa victoria: completa su efecto dentro del mismo máximo de 0,20 s y no permite otro ataque. Salir al menú o reintentar antes cancela esa presentación.

## Requirements

### Functional Requirements

- **FR-001**: Cada disparo de fusil confirmado DEBE solicitar exactamente un destello de cañón y una trazadora breve hacia la posición del blanco al disparar; ambos forman un único efecto cosmético.
- **FR-002**: El efecto DEBE seguir la orientación frontal o diagonal del disparo, partir de la boca del fusil y desaparecer completamente en un máximo de 0,20 s de juego activo, sin parecer un haz continuo.
- **FR-003**: El efecto DEBE conservar la identidad pictórica de Monte Calvo mediante tonos cálidos moderados y bordes suaves, ser legible sobre el terreno y no aclarar, teñir ni iluminar el cuerpo completo del soldado.
- **FR-004**: El daño DEBE continuar siendo instantáneo; munición, cadencia, alcance, selección de blanco, moral, recompensas, movimiento, oleadas y condiciones terminales DEBEN conservar sus reglas y valores actuales.
- **FR-005**: El efecto NO DEBE causar daño, colisión, ocupación, interacción ni sonido nuevo, ni introducir proyectiles físicos, retardo de impacto o rebalance.
- **FR-006**: La última bala y los disparos letales DEBEN conservar su solicitud visual, independiente de los cambios de arma y retiro o reutilización de actores; no DEBEN producirse efectos sin un disparo real.
- **FR-007**: Cada efecto DEBE ser independiente de los actores después del disparo; activaciones simultáneas o reutilizadas no DEBEN modificar ni retirar otras activaciones.
- **FR-008**: Pausar DEBE congelar el efecto hasta reanudar; victoria/derrota DEBEN rechazar nuevos efectos y permitir completar sólo los ya confirmados dentro de su duración. Cerrar el intento, volver al menú o iniciar otra partida DEBE limpiar inmediatamente los efectos e impedir que solicitudes anteriores reaparezcan.
- **FR-009**: La presentación DEBE conservar la corrida y el color del colombiano aprobados en 009, la animación enemiga de 008, la lectura del HUD y la entrada existente, también al redimensionar.

### Key Entities

- **Disparo confirmado**: hecho de combate con origen y destino capturados antes de las consecuencias del daño; no representa un proyectil con autoridad jugable.
- **Efecto de disparo**: presentación efímera de un destello y una trazadora, con progreso propio y sin dependencia posterior de los actores.

## Success Criteria

### Measurable Outcomes

- **SC-001**: En todos los escenarios de disparo frontal, diagonal, simultáneo, última bala y baja del blanco, la comprobación funcional confirma una solicitud visual por cada disparo real y ninguna en los estados sin disparo descritos.
- **SC-002**: La revisión visual distingue el cañón y la dirección hacia el blanco sobre Monte Calvo, confirma la desaparición completa antes de 0,20 s de juego activo y no observa haces sostenidos, tintes del soldado ni cambios de su corrida.
- **SC-003**: Las comprobaciones de daño inmediato, cadencia, munición, blancos, moral, movimiento y ciclo de partida conservan los resultados actuales con efectos presentes o ausentes.
- **SC-004**: En pausa/reanudación y retirada/reutilización del blanco los efectos conservan su progreso y contexto; en victoria/derrota sólo terminan los ya confirmados antes de 0,20 s activo. Menú, cierre y otra partida dejan cero efectos anteriores, sin reaparición ni interferencia entre activaciones.
- **SC-005**: La entrega incluye QA independiente para integración, documentación actualizada y un PR en borrador vinculado a su Issue; los resultados identifican su entorno y mantienen la publicación pendiente.

## Assumptions

- Se reutilizan el nivel, soldados, combate y flujo de menú actuales; no se añaden controles ni opciones para esta feature.
- La trazadora es una indicación breve del tiro ya resuelto; no pretende simular tiempo de vuelo ni modificar las posiciones de armas o actores.
- La validación visual contempla Web en computador y apps nativas Android/iOS cuando estén disponibles. Cada resultado acredita sólo el entorno ejecutado; hardware, renderer y paquete final pendientes pertenecen al gate de publicación.
- El diagnóstico de rendimiento de Issue #30 permanece pausado por decisión del usuario. Esta feature no reabre mediciones de FPS ni campañas de rendimiento, ni acredita requisitos de publicación con una prueba funcional.
