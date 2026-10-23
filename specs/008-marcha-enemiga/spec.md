# Feature Specification: Marcha enemiga

**Feature ID**: `008-marcha-enemiga`
**Planned Branch**: `codex/008-marcha-enemiga`, desde `main` `90cc824` (PR #35).
**Created**: 2026-10-23
**Status**: US1 implementada y corrección de continuidad validada funcional y visualmente en T013. La aprobación de `f05d9e6`/T001–T009 se conserva como histórica; el cierre de integración y la CI de la revisión actual se registran en [tareas](tasks.md), el mismo [PR #37 en borrador](https://github.com/Juanpvivas/demons/pull/37) e Issue [#36](https://github.com/Juanpvivas/demons/issues/36). Publicación pendiente.
**Input**: La persona da por terminado por ahora el trabajo de rendimiento y pide mejorar la animación de los enemigos al acercarse a las trincheras, usando el GIF de un soldado de Metal Slug como ejemplo de movimiento.

## User Scenarios & Testing

### User Story 1 — Leer un avance con pasos convincentes (Priority: P1)

Como jugador, quiero ver al enemigo alternar sus pasos y acompañarlos con el cuerpo y el equipo al acercarse a las trincheras, conservando el personaje pictórico de Monte Calvo.

**Why this priority**: La marcha actual repite una zancada muy similar y transmite poco movimiento de piernas.
**Independent Test**: Observar un ciclo completo ampliado y en el tablero, y seguir a un enemigo hasta detenerse, recibir impacto, caer y reaparecer en otro uso.

**Acceptance Scenarios**:

1. **Given** un enemigo que avanza hacia las trincheras, **When** recorre su fila, **Then** se distinguen apoyo, paso intermedio y apoyo opuesto, con balanceo coherente de torso, brazos, rifle y equipo.
2. **Given** varias vueltas de la marcha, **When** el ciclo enlaza su final con su inicio, **Then** conserva identidad, orientación y anclaje, sin saltos de posición, recortes ni poses duplicadas que sustituyan la alternancia.
3. **Given** un enemigo bloqueado o en contacto, **When** deja de desplazarse, **Then** conserva su postura de contacto vigente; la marcha no implica movimiento inexistente ni añade un ataque.
4. **Given** impactos, baja, reutilización o un nuevo intento, **When** cambian esos estados, **Then** mantienen sus transiciones y consecuencias actuales, sin arrastrar la marcha ni el aspecto de un uso anterior.

### Edge Cases

- Último paso → primero y apoyo de cada pie: sin salto lateral/vertical involuntario ni partes del equipo que aparezcan o desaparezcan.
- Enemigos simultáneos o de distintas filas: misma identidad y escala, con animación independiente por actor.
- Bloqueo, impacto durante la marcha, caída y reutilización rápida: conservar los estados vigentes y limpiar transitorios.
- Tamaño del juego y vista ampliada: piernas legibles, rifle completo y transparencia sin halos, fondo o figuras vecinas.

## Requirements

### Functional Requirements

- **FR-001**: El avance DEBE mostrar alternancia real de piernas, con apoyos opuestos y fases intermedias reconocibles, acompañados por un movimiento coherente del cuerpo, brazos y equipo.
- **FR-002**: El ciclo DEBE repetirse sin salto involuntario en su unión y conservar el apoyo del personaje sobre el suelo y su encaje actual en la fila.
- **FR-003**: La presentación DEBE conservar el estilo pictórico, la infantería gris/marrón con gorra y la orientación hacia las trincheras. El GIF sirve de referencia de movimiento; no sustituye al personaje ni define el estilo gráfico.
- **FR-004**: Sólo se DEBE sustituir la marcha; contacto, impacto, caída y reinicio visual mantienen su lectura y reglas vigentes.
- **FR-005**: La animación DEBE seguir al desplazamiento real sin modificar velocidad, trayectoria, cuerpo, colisiones, alcance, salud, daño, oleadas, economía o reutilización.
- **FR-006**: Web en computador y apps Android/iOS DEBEN consumir el mismo arte; cada validación identifica su destino y no acredita otro.
- **FR-007**: La entrega DEBE respetar la decisión de no continuar por ahora las pruebas o validaciones de rendimiento de 006. No incluye benchmarks, probes u optimizaciones y no declara resueltos sus pendientes.
- **FR-008**: La entrega DEBE conservar publicación pendiente y los requisitos históricos no verificados; integrar la mejora no distribuye el juego.

### Key Entities

- **Ciclo de marcha**: poses consecutivas que describen un paso de cada pierna y su transición continua.
- **Enemigo existente**: mismo actor y estado jugable; sólo cambia la presentación de su avance.

## Success Criteria

### Measurable Outcomes

- **SC-001**: La revisión visual distingue ambos apoyos y sus pasos intermedios en ciclos consecutivos, ampliados y a tamaño de juego, sin repetir siempre la misma zancada.
- **SC-002**: El ciclo completo conserva personaje, escala, orientación, equipo y suelo, sin recortes, contaminación entre poses o salto involuntario en la unión.
- **SC-003**: La revisión funcional confirma marcha → contacto, impacto, baja, reutilización y nuevo intento sin alterar las consecuencias existentes; la regresión pertinente y la CI pasan.
- **SC-004**: Importación/carga y exportación aplicables funcionan; QA declara los destinos funcionales/visuales comprobados y sus límites.
- **SC-005**: Documentación, procedencia y PR en borrador reflejan el alcance aprobado, la pausa de rendimiento y la publicación pendiente, sin nuevos registros de validación en Git.

## Assumptions

- Se conserva la dirección pictórica ya aceptada; la referencia adjunta orienta la cinemática del avance.
- El cambio de prioridad está autorizado por la petición de la persona; los pendientes de 006 se conservan como historia y trabajo pausado.
- No hay API, persistencia, interfaz, personajes, audio ni mecánicas nuevas. Las verificaciones son visuales y funcionales; una eventual modificación de comportamiento necesita su propio TDD antes de implementarse.
