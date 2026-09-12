# Feature Specification: Soldado Defensor con Munición y Moral

**Feature Branch**: `001-soldado-defensor-oleadas`

**Created**: 2026-08-13

**Status**: Draft

**Input**: User description: "Un jugador defiende una posición colocando un soldado colombiano inspirado en el Batallón Colombia (Guerra de Corea, apodados "demonios de las trincheras"). El soldado dispara automáticamente con fusil a los enemigos que se acercan por su carril frontal y diagonales adyacentes, con munición limitada. Al quedarse sin munición, pasa automáticamente a combate cuerpo a cuerpo con machete, cuyo daño depende de la moral que acumuló mientras disparaba y eliminaba enemigos. Los enemigos derrotados sueltan munición que el jugador recolecta y puede usar para recargar al soldado en el tablero o desplegar uno nuevo. El objetivo es resistir oleadas crecientes de enemigos sin que lleguen a la posición defendida."

## Clarifications

### Session 2026-08-13

- Q: Cuando hay enemigos simultáneamente en el carril frontal y en una o ambas diagonales adyacentes, ¿el soldado dispara a un solo objetivo a la vez, o puede disparar simultáneamente a varios enemigos (uno por línea)? → A: Un solo objetivo a la vez: el soldado elige un enemigo prioritario entre las 3 líneas y le dispara exclusivamente hasta eliminarlo o perderlo de rango.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Defensa automática de un soldado (Priority: P1)

Un jugador coloca un soldado en el tablero. El soldado detecta automáticamente a los enemigos que entran en su carril frontal y en las diagonales adyacentes, y dispara con su fusil contra un único objetivo prioritario a la vez hasta agotar su munición. Al quedarse sin munición, el soldado cambia automáticamente a combate cuerpo a cuerpo con su machete contra los enemigos que lleguen a su alcance melee.

**Why this priority**: Es el núcleo mínimo jugable del sistema de combate: sin esta mecánica no existe el "tower defense" en absoluto. Debe funcionar de forma aislada para validar la sensación de combate antes de sumar economía u oleadas.

**Independent Test**: Se puede probar colocando un único soldado frente a un solo enemigo que avanza, y verificando que dispara automáticamente, agota munición, y transiciona a machete sin intervención del jugador.

**Acceptance Scenarios**:

1. **Given** un soldado recién desplegado con munición completa, **When** un enemigo entra en su carril frontal, **Then** el soldado dispara automáticamente contra ese enemigo sin que el jugador realice ninguna acción adicional.
2. **Given** un soldado con munición, **When** un enemigo entra en una de las diagonales adyacentes al soldado (no en el carril frontal), **Then** el soldado también le dispara automáticamente.
3. **Given** un soldado con munición que ya tiene un enemigo objetivo en su carril frontal, **When** otro enemigo entra simultáneamente en una diagonal adyacente, **Then** el soldado sigue disparando exclusivamente a su objetivo actual y no divide su fuego entre ambos.
4. **Given** un soldado cuya munición llega a cero mientras dispara, **When** se dispara el último proyectil disponible, **Then** el soldado deja de disparar con fusil y pasa a modo de combate cuerpo a cuerpo con machete.
5. **Given** un soldado en modo cuerpo a cuerpo, **When** un enemigo entra en su rango de melee, **Then** el soldado lo ataca con el machete infligiendo daño proporcional a la moral acumulada durante la fase de disparo.

---

### User Story 2 - Recolección de munición y reabastecimiento (Priority: P2)

Cuando el jugador elimina enemigos, estos sueltan munición en el tablero. El jugador recolecta esa munición y puede usarla para recargar a un soldado que se quedó sin balas, o para desplegar un soldado nuevo en otra posición del tablero.

**Why this priority**: Es el bucle de economía que le da profundidad estratégica al juego (dónde recargar vs. dónde expandir), pero depende de que el combate automático (P1) ya exista y genere enemigos derrotados.

**Independent Test**: Se puede probar derrotando un enemigo, verificando que suelta munición recolectable, y confirmando que esa munición puede aplicarse tanto a recargar un soldado existente como a desplegar uno nuevo.

**Acceptance Scenarios**:

1. **Given** un enemigo es derrotado (por disparo o por machete), **When** el enemigo muere, **Then** suelta una cantidad de munición visible y recolectable en el tablero.
2. **Given** el jugador tiene munición recolectada disponible, **When** selecciona un soldado en el tablero que está sin munición (en modo machete), **Then** puede recargarlo y el soldado vuelve a disparar con fusil.
3. **Given** el jugador tiene munición recolectada suficiente, **When** elige desplegar un nuevo soldado en una posición vacía del tablero, **Then** se consume la munición correspondiente y aparece un nuevo soldado con munición inicial completa.
4. **Given** el jugador no tiene munición recolectada suficiente, **When** intenta recargar o desplegar, **Then** el sistema le impide la acción y le indica que no tiene recursos suficientes.

---

### User Story 3 - Resistir oleadas crecientes (Priority: P3)

El jugador se enfrenta a oleadas sucesivas de enemigos que aumentan en dificultad (cantidad y/o fuerza). El objetivo es evitar que cualquier enemigo alcance la posición defendida, sosteniendo la defensa a lo largo de múltiples oleadas.

**Why this priority**: Da propósito y progresión a las mecánicas de combate y economía (P1 y P2), pero el sistema de oleadas solo tiene sentido una vez que la defensa individual y el reabastecimiento ya funcionan.

**Independent Test**: Se puede probar iniciando una partida completa y verificando que las oleadas subsiguientes son perceptiblemente más difíciles que las anteriores, y que la partida termina cuando un enemigo alcanza la posición defendida.

**Acceptance Scenarios**:

1. **Given** el jugador completa una oleada de enemigos, **When** comienza la siguiente oleada, **Then** esta contiene más enemigos y/o enemigos más fuertes que la oleada anterior.
2. **Given** una partida en curso, **When** todos los enemigos de todas las oleadas programadas son derrotados, **Then** el jugador recibe una condición de victoria.
3. **Given** una partida en curso, **When** un enemigo alcanza la posición defendida, **Then** la partida termina en derrota para el jugador.

---

### Edge Cases

- ¿Qué ocurre si varios enemigos ocupan simultáneamente el carril frontal y ambas diagonales de un soldado con munición? El soldado dispara únicamente contra un objetivo prioritario a la vez (no divide su fuego), y solo pasa a atacar a otro enemigo cuando el actual es eliminado o sale de rango.
- ¿Qué ocurre si un soldado se queda sin munición justo cuando varios enemigos ocupan simultáneamente su carril frontal y ambas diagonales? El soldado debe transicionar a machete y priorizar un único objetivo dentro de su rango melee.
- ¿Qué ocurre si un soldado nunca acumuló moral (por ejemplo, se queda sin munición sin haber impactado a ningún enemigo) y debe pasar a combate cuerpo a cuerpo? El machete debe seguir infligiendo un daño base mínimo, aunque reducido.
- ¿Qué ocurre si el jugador intenta desplegar un soldado nuevo en una posición del tablero ya ocupada? El sistema debe impedir el despliegue y señalar que la posición no está disponible.
- ¿Qué ocurre si un soldado en modo cuerpo a cuerpo es derrotado por los enemigos antes de que el jugador pueda recargarlo? El soldado y su moral acumulada se pierden, liberando esa posición del tablero.
- ¿Qué ocurre si la munición soltada por un enemigo no es recolectada por el jugador durante un tiempo prolongado? Debe permanecer disponible en el tablero para recolección posterior dentro de la partida en curso.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE permitir al jugador desplegar un soldado en una posición válida y desocupada del tablero.
- **FR-002**: Un soldado desplegado con munición disponible DEBE disparar automáticamente, sin input directo del jugador por disparo, contra un único enemigo objetivo elegido entre los presentes en su carril frontal o en sus dos diagonales adyacentes; el soldado NO DEBE dividir su fuego entre varios enemigos simultáneamente, y solo elige un nuevo objetivo cuando el actual es eliminado o sale de su rango de detección.
- **FR-003**: Cada soldado DEBE tener una cantidad limitada de munición que se reduce con cada disparo realizado.
- **FR-004**: Cuando la munición de un soldado llega a cero, el sistema DEBE hacer que ese soldado transicione automáticamente a combate cuerpo a cuerpo con machete contra enemigos dentro de su rango de melee.
- **FR-005**: El daño del ataque cuerpo a cuerpo con machete DEBE calcularse en función de la moral acumulada por ese soldado durante su fase de combate a distancia.
- **FR-006**: El sistema DEBE incrementar la moral acumulada de un soldado cada vez que elimina a un enemigo mientras dispara con munición (no por impactos que no resulten en eliminación).
- **FR-007**: Todo enemigo derrotado (por disparo o por machete) DEBE soltar una cantidad de munición recolectable en el tablero.
- **FR-008**: El jugador DEBE poder recolectar la munición soltada por enemigos derrotados y acumularla como recurso disponible.
- **FR-009**: El jugador DEBE poder usar munición recolectada para recargar a un soldado en el tablero que se encuentre sin munición (en modo machete).
- **FR-010**: El jugador DEBE poder usar munición recolectada para desplegar un nuevo soldado en una posición vacía del tablero.
- **FR-011**: El sistema DEBE impedir recargar o desplegar soldados cuando la munición recolectada disponible es insuficiente, e informar al jugador de esta restricción.
- **FR-012**: El sistema DEBE generar oleadas sucesivas de enemigos cuya dificultad (cantidad y/o fuerza) aumenta de forma perceptible respecto a la oleada anterior.
- **FR-013**: El sistema DEBE finalizar la partida en derrota cuando un enemigo alcanza la posición defendida.
- **FR-014**: El sistema DEBE mostrar al jugador, en todo momento, el estado de munición y moral de cada soldado desplegado en el tablero.
- **FR-015**: El sistema DEBE mostrar al jugador la cantidad de munición recolectada disponible para recargar o desplegar soldados.

### Key Entities

- **Soldado**: Unidad defensiva colocable por el jugador. Atributos clave: posición en el tablero, munición actual/máxima, moral acumulada, modo de combate actual (distancia o cuerpo a cuerpo), estado (activo/derrotado).
- **Enemigo**: Unidad hostil que avanza hacia la posición defendida. Atributos clave: posición/carril, salud, velocidad de avance, cantidad de munición que suelta al ser derrotado.
- **Oleada**: Agrupación de enemigos generados en una fase de la partida. Atributos clave: número de secuencia, composición y cantidad de enemigos, nivel de dificultad relativo a oleadas previas.
- **Munición recolectada**: Recurso del jugador (distinto de la munición individual de cada soldado) acumulado a partir de enemigos derrotados, usado para recargar o desplegar soldados.
- **Posición defendida**: Punto o línea del tablero que el jugador debe proteger; alcanzarlo por parte de cualquier enemigo termina la partida.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un jugador nuevo puede completar sus primeras 3 oleadas consecutivas sin perder, usando únicamente el soldado inicial y sin instrucciones adicionales más allá de la interfaz del juego.
- **SC-002**: El 100% de las transiciones de un soldado de combate a distancia a combate cuerpo a cuerpo ocurren automáticamente al agotarse la munición, sin requerir ninguna acción del jugador.
- **SC-003**: Un jugador puede identificar, solo mediante retroalimentación visual y/o sonora (sin leer números de interfaz), si un soldado está disparando con fusil o combatiendo con machete.
- **SC-004**: El ciclo completo de "derrotar enemigo → recolectar munición → recargar o desplegar soldado" puede completarse por un jugador nuevo sin tutorial explícito, en una única sesión de prueba.
- **SC-005**: Cada oleada sucesiva presenta un incremento medible en dificultad (cantidad y/o fuerza de enemigos) respecto a la anterior, perceptible a lo largo de al menos 10 oleadas consecutivas.

## Assumptions

- El tablero se organiza como una cuadrícula de posiciones/celdas; el "carril frontal" de un soldado es la fila de celdas entre su posición y el punto de aparición de enemigos, y las "diagonales adyacentes" son las celdas diagonalmente contiguas a su posición.
- Cuando un soldado con munición tiene varios enemigos elegibles a la vez (carril frontal y/o diagonales), el objetivo prioritario es el enemigo más avanzado (más cercano a la posición defendida); esta es la regla de desempate por defecto para la selección de un único objetivo.
- La munición recolectada por el jugador es un recurso único y compartido (no distinto por tipo de enemigo ni por soldado), usado indistintamente para recargar soldados existentes o desplegar soldados nuevos.
- Cada nuevo despliegue de soldado tiene un costo en munición recolectada equivalente a una recarga completa; no existe un recurso económico separado (como "puntos" u "oro") en el alcance de esta feature.
- La moral de un soldado se acumula de forma incremental por cada eliminación exitosa mientras tiene munición (los impactos que no eliminan al enemigo no otorgan moral), no decae con el tiempo, y se pierde por completo si el soldado es derrotado.
- Cuando cualquier enemigo alcanza la posición defendida, la partida termina inmediatamente en derrota (no existe un sistema de "vidas" o daño acumulado a la posición en el alcance de esta feature).
- El soporte multiplataforma (Android, iOS, PC) y el rendimiento a 60 FPS ya están cubiertos por los principios de la constitución del proyecto y no se repiten como requisitos de esta feature.