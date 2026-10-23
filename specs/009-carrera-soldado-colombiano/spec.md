# Feature Specification: Carrera del soldado colombiano

**Feature ID**: `009-carrera-soldado-colombiano`
**Planned Branch**: `codex/009-carrera-soldado-colombiano`, desde `main` `a88e7c5` (PR #37 integrado).
**Created**: 2026-10-23
**Status**: Preparación; implementación y QA de integración pendientes. Publicación pendiente.
**Input**: La persona probó y aceptó la marcha enemiga, integró el PR #37 y pide hacer lo mismo para mejorar cómo corre el soldado colombiano.

## User Scenarios & Testing

### User Story 1 — Leer una corrida continua de ida y regreso (Priority: P1)

Como jugador, quiero reconocer los pasos del soldado colombiano cuando sale con machete y cuando regresa con el fusil bajo, conservando su identidad pictórica de Monte Calvo.

**Why this priority**: Aplicar la continuidad ya aceptada en el enemigo a los dos desplazamientos del soldado evita que sus piernas parezcan repetir siempre la misma zancada.
**Independent Test**: Observar varios ciclos de ida y regreso, ampliados y en el tablero, y completar el recorrido salida → contacto → solicitud de recarga aceptada → regreso → hogar.

**Acceptance Scenarios**:

1. **Given** un soldado que sale con machete, **When** avanza por su fila, **Then** alterna los apoyos con pasos intermedios y un movimiento coherente de cuerpo, brazos y equipo.
2. **Given** un soldado que vuelve por una orden de recarga aceptada, **When** corre hacia su trinchera, **Then** muestra ambos apoyos y conserva el fusil bajo, la dirección y las reglas actuales del regreso.
3. **Given** varios ciclos consecutivos de cualquiera de los dos recorridos, **When** la última pose enlaza con la primera, **Then** la pierna que alcanza el suelo continúa en su propio apoyo, sin intercambio brusco, salto involuntario ni cambio de identidad.
4. **Given** una detención, contacto, ataque, impacto, baja o nuevo intento, **When** el soldado cambia de estado, **Then** mantiene su lectura y consecuencias vigentes, sin seguir corriendo cuando está quieto.

### Edge Cases

- Ambas transferencias de apoyo y cierre final → inicio: conservar suelo, altura corporal coherente y armas completas.
- Regreso orientado hacia el hogar y parada antes de alcanzarlo: no confundir fusil bajo con apuntar o atacar.
- Varios soldados y filas: igual identidad, escala y encaje, con reproducción independiente.
- Tamaño del juego y vista ampliada: sin recortes, halos, figuras vecinas ni equipo que aparezca o desaparezca.

## Requirements

### Functional Requirements

- **FR-001**: Ambos recorridos DEBEN mostrar apoyo de cada pierna y pasos intermedios reconocibles, con balanceo coherente de torso, brazos, machete, fusil y equipo.
- **FR-002**: Cada ciclo DEBE repetirse sin brinco involuntario, conservando el suelo y la continuidad de la misma pierna entre alcance y apoyo.
- **FR-003**: La presentación DEBE conservar el soldado colombiano actual: uniforme oliva, casco, botas, equipo y acabado pictórico; las referencias orientan sólo el movimiento.
- **FR-004**: Sólo DEBE cambiar la corrida de salida con machete y de regreso con fusil bajo; espera, disparo, ataque, impacto, baja y reinicio mantienen su presentación vigente.
- **FR-005**: La corrida DEBE acompañar el desplazamiento real y conservar cadencia, velocidad, trayectoria, orientación, colisiones, alcance, daño, munición, moral, recarga y condiciones de partida actuales.
- **FR-006**: Web en computador y apps Android/iOS DEBEN consumir el mismo arte, identificando por separado los destinos realmente comprobados y sus límites.
- **FR-007**: La entrega DEBE conservar intacta la marcha enemiga aceptada y la pausa de rendimiento de 006, sin nuevas mediciones ni declarar resueltos sus pendientes.
- **FR-008**: La entrega DEBE documentar procedencia y alcance aprobado en un PR en borrador, con publicación pendiente y sin completar requisitos históricos ajenos.

### Key Entities

- **Corrida de salida**: ciclo de ambos apoyos mientras el soldado se desplaza con machete y fusil guardado.
- **Corrida de regreso**: ciclo de ambos apoyos durante el retorno vigente con fusil bajo.

## Success Criteria

### Measurable Outcomes

- **SC-001**: La revisión visual distingue ambos apoyos y pasos intermedios en al menos tres vueltas consecutivas de cada recorrido, ampliadas y a tamaño de juego.
- **SC-002**: Ambos ciclos conservan personaje, escala, orientación, suelo y equipo completo, sin recortes, contaminación ni salto involuntario en su unión.
- **SC-003**: La comprobación funcional conserva salida, detención, contacto/ataque, recarga, regreso, hogar, baja y nuevo intento; la regresión y las comprobaciones automáticas aplicables pasan.
- **SC-004**: El juego carga y muestra el arte integrado en los destinos disponibles; la revisión identifica cada entorno, variante y límite sin extrapolar resultados.
- **SC-005**: Documentación, procedencia y PR en borrador reflejan el alcance aprobado, la pausa de rendimiento y la publicación pendiente, sin nuevos registros de validación en Git.

## Assumptions

- La petición actual autoriza esta mejora visual después de aceptar 008; las tres referencias animadas previas siguen siendo referencias de cinemática.
- Se conserva la arquitectura y las reglas existentes; no hay interfaz, API, persistencia, audio o mecánicas nuevas. Un cambio de comportamiento requeriría TDD antes de implementarse.
