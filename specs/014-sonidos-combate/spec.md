# Feature Specification: Sonidos de combate

**Feature ID**: `014-sonidos-combate`
**Planned Branch**: `codex/014-sonidos-combate`
**Created**: 2026-10-30
**Status**: Funcionalidad T007–T009 aprobada en rama; CI/suite completa del head final y gate T012 pendientes, publicación T014/SC-007 separada
**Tracking**: [Issue #55](https://github.com/Juanpvivas/demons/issues/55)
**Input**: Incorporar cinco sonidos offline: disparo de fusil confirmado, muerte enemiga, muerte del soldado colombiano, victoria y derrota. La persona eligió para ambas bajas una exclamación breve acompañada de caída; no voces largas ni narración nueva.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Escuchar hechos del combate (Priority: P1)

Como jugador quiero distinguir los disparos, bajas y resultado por sus sonidos.

**Why this priority**: Da respuesta audible a hechos ya existentes sin cambiar el combate.
**Independent Test**: Provocar cada uno de los cinco eventos con actores/resultado reales y contrastar sonido con su transacción.

**Acceptance Scenarios**:

1. **Given** un soldado con blanco válido y munición, **When** confirma un disparo, **Then** suena un disparo una vez, incluida la última bala. No suena por animación, apuntado, recarga o intento rechazado.
2. **Given** cualquiera de los dos bandos, **When** una transacción causa su muerte, **Then** se pide exactamente una vez su sonido de baja. Daño no letal, cleanup, despawn y salida al menú no lo producen.
3. **Given** una partida activa, **When** ocurre victoria o derrota real, **Then** suena una vez únicamente el resultado correspondiente; Menú/Reintentar no lo inventan.
4. **Given** un tiro letal cuya última baja causa victoria, **When** los tres ocurren en la misma cadena de señales, **Then** se aceptan una vez tiro, baja y victoria, sin suprimir ni duplicar eventos ni cortar los sonidos ya admitidos por priorizar el resultado.

### User Story 2 - Sonido controlado durante la sesión (Priority: P1)

Como jugador quiero mezcla moderada que no se acumule al pausar o cambiar de intento.

**Why this priority**: Evita saturación, sonidos fantasma y cruces entre partidas.
**Independent Test**: Ráfaga de eventos, pausa/pérdida de foco, menú y nueva partida; comprobar límite de voces y ausencia de audio del intento anterior.

**Acceptance Scenarios**:

1. **Given** muchos disparos/bajas simultáneos, **When** se agota la capacidad sonora, **Then** se mantiene un número acotado de voces, sin crear reproductores indefinidamente ni retrasar eventos en una cola ilimitada.
2. **Given** sonidos activos, **When** se pausa o pierde actividad, **Then** se silencian; regresar sólo permite nuevos eventos válidos, sin reproducir eventos atrasados.
3. **Given** sonidos o callbacks de un intento, **When** se vuelve al menú o se reintenta, **Then** cesan y quedan invalidados; el intento nuevo tiene su propio audio limpio.
4. **Given** un enemigo reciclado, **When** muere en otra activación, **Then** suena una baja para esa activación, sin conexiones duplicadas o bloqueo heredado.

### Edge Cases

- Registro doble de actor, múltiples impactos letales, muerte y resultado en el mismo tick.
- Callback de reproductor reutilizado o actor reciclado; cierre idempotente y menú durante combate/resultado.
- Audio no disponible no cambia daño, munición, moral, oleadas o resultado; no bloquea jugar.
- Pausa/foco en pantalla de resultado silencia el cue sin volver a emitirlo al regresar.
- No mezclar estos canales con la introducción ni alterar sus voces definitivas/ambiente.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Reproducir cinco cues distinguibles, asociados sólo a disparo de fusil válido, baja enemiga, baja colombiana, victoria y derrota reales.
- **FR-002**: Disparo se origina en la confirmación de consumo/ataque; bajas sólo al morir una vez por actor/activación y resultado sólo una vez por intento real.
- **FR-003**: Ambas bajas combinan exclamación breve masculina adulta ficticia con caída/equipo; sin frases, agonía prolongada, clonación o reutilización de las voces del narrador/compañero.
- **FR-004**: Usar recursos offline de procedencia/licencia portable. No incorporar modelos, motor de síntesis, llamadas de red o voces del sistema operativo.
- **FR-005**: Acotar voces y mezcla; variación moderada sólo cosmética, sin cambiar stats o consumir RNG de gameplay. No amplificar sin límite el resultado de eventos simultáneos.
- **FR-006**: Pausa/pérdida de actividad silencian voces y descartan eventos que no son reproducibles entonces; menú/cierre/retry desconectan e invalidan toda reproducción del intento anterior.
- **FR-007**: Conservar señales/autoridad de combate y resultado, balance, input/UI y persistencia. La introducción y su audio definitivo permanecen idénticos.
- **FR-008**: Mantener semántica en Web de computador y apps Android/iOS; declarar por separado destinos/audio no verificados, sin extrapolar simulación a hardware.

### Key Entities

- **Cue**: uno de los cinco sonidos, sus niveles y variación de presentación.
- **Perfil sonoro**: archivos y límites autorados, separado del estado de reproducción.
- **Sesión sonora**: voces finitas, conexiones y generación del intento; no es progreso jugable.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Cada uno de los cinco eventos reales tiene exactamente una petición sonora por transacción; eventos rechazados/no letales/cleanup/menu no generan cues falsos.
- **SC-002**: Reciclado, registro doble, baja final+victoria y callbacks viejos no duplican ni pierden la petición correcta de baja/resultado.
- **SC-003**: Una ráfaga arbitraria de peticiones mantiene la capacidad de voces autorada, sin crecimiento de reproductores/colas; la variación sonora no altera el RNG o resultado jugable.
- **SC-004**: Pausa/foco/menu/retry no dejan audio residual o eventos atrasados en la sesión siguiente; las voces de introducción permanecen intactas.
- **SC-005**: Los recursos de los cinco cues cargan/importan offline, las bajas incluyen exclamación breve y caída, y la mezcla/duración se verifican proporcionalmente; audición perceptual o destinos no disponibles se declaran sin fingir escucha.
- **SC-006**: RED previo válido, GREEN/regresión, importación/build/export/CI y QA independiente permiten emitir integración con sus límites, sin nuevas evidencias versionadas.
- **SC-007**: Antes de distribuir se verifican artefacto/renderer/firma/versionado, instalación/smoke y rendimiento físico exigido, con QA de publicación y autorización explícita. Integración no satisface este criterio.

## Assumptions

- Los cinco eventos son el incremento completo; no nuevos controles, ajustes de usuario, backend, persistencia, música, ambiente o mecánicas.
- Root prepara medios originales y exclamaciones sintéticas ficticias con licencias portables; su provisión es dependencia técnica, no permiso pendiente.
- No se reabre 013 ni la pausa006 o pendientes físicos/publicación de004/005. Una verificación proporcional local no certifica paquetes finales o hardware.
