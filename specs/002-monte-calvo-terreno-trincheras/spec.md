# Feature Specification: Monte Calvo — terreno y trincheras, iteración visual 1

**Feature ID**: `002-monte-calvo-terreno-trincheras`

**Branch**: `codex/002-monte-calvo-terreno-trincheras`.

**Created**: 2026-10-15

**Status**: implementación por agentes autorizada el 2026-10-15; en curso, pendiente de las verificaciones y aprobaciones de cada tarea.

**Input**: «Usa Spec Kit para preparar la especificación, el plan y las tareas de la primera iteración visual del terreno y las trincheras, siguiendo la imagen y manteniendo las mecánicas actuales».

**Autorización posterior**: el 2026-10-15 la persona autorizó ejecutar esta feature mediante los roles del proyecto. Se conserva el alcance visual y todos los criterios de aceptación de la preparación.

**Referencia visual**: [concepto aprobado y criterios de adaptación](references/visual-reference.md). La imagen es una dirección artística, no una captura del juego ni una definición de sus reglas.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reconocer un terreno ilustrado de Monte Calvo (Priority: P1)

Como jugador, quiero que el terreno y el fondo transmitan una ladera bélica ilustrada, con tierra ocre, vegetación seca y montañas entre la niebla, mientras distingo claramente la acción.

**Why this priority**: ofrece una primera mejora visible utilizable por sí sola; constituye el MVP visual antes de añadir las trincheras.

**Independent Test**: comparar el nivel antes/después con las mismas posiciones y tamaño de ventana, manteniendo los actores provisionales. Revisar suelo, montañas y claridad del recorrido central sin necesitar las trincheras de US3.

**Acceptance Scenarios**:

1. **Given** la referencia aprobada, **When** se abre Monte Calvo, **Then** el suelo utiliza tierra ocre/oliva con textura pictórica y el horizonte presenta montañas azul grisáceo, sin convertir el juego en una escena tridimensional.
2. **Given** soldados, enemigos y munición en pantalla, **When** atraviesan o permanecen sobre el terreno nuevo, **Then** sus siluetas, estado y objetos recolectables se distinguen del fondo; el centro contiene menos detalle que los bordes.
3. **Given** la entrada y el recorrido enemigos actuales, **When** se observa el campo, **Then** el arte acompaña el único avance central y no dibuja cinco carriles, casillas nuevas o una promesa de zonas restringidas.

---

### User Story 2 - Seguir jugando con las mismas reglas y entradas (Priority: P1)

Como jugador, quiero conservar la colocación, el combate, la munición y las oleadas actuales al recibir la mejora visual.

**Why this priority**: es un requisito de aceptación de toda la iteración, tanto de US1 como de US3; la mejora artística no autoriza cambios de jugabilidad.

**Independent Test**: comparar escenarios equivalentes antes/después, con clic y toque, y ejecutar la regresión existente. La conservación de reglas también puede revisarse por separado de la aprobación artística.

**Acceptance Scenarios**:

1. **Given** una celda libre y munición suficiente, **When** se repite el mismo clic o toque antes/después, **Then** el despliegue ocupa la misma celda, consume el mismo costo y mantiene su posición; una celda ocupada o fondos insuficientes se comportan igual que antes.
2. **Given** una munición recolectable sobre el nuevo fondo, **When** se recoge, **Then** se mantiene el resultado anterior, sin que la decoración absorba la entrada o provoque además un despliegue.
3. **Given** las mismas unidades y secuencia de oleadas, **When** se desarrolla el combate, **Then** se conservan aparición, movimiento, daño, munición, moral y condiciones de victoria/derrota. La recarga existente se verifica por sus pruebas, sin añadirle una interfaz nueva.
4. **Given** las proporciones de pantalla incluidas en la validación, **When** se muestra el escenario, **Then** no aparecen huecos nuevos de fondo ni cambian las coordenadas de las acciones, el recorrido o el área defendida para encajar el arte.

---

### User Story 3 - Entender la posición defendida a través de trincheras decorativas (Priority: P2)

Como jugador, quiero ver tierra excavada, madera y sacos de arena que enmarquen la posición defendida sin obstaculizar las acciones o esconder unidades.

**Why this priority**: completa la identidad del escenario y su relación con el concepto aprobado después de establecer el terreno.

**Independent Test**: revisar las trincheras como una capa identificable, comparando el mismo terreno con/sin esa decoración y comprobando las interacciones en sus bordes. Depende del terreno aprobado de US1 para la integración final.

**Acceptance Scenarios**:

1. **Given** el terreno de US1, **When** se añaden las trincheras, **Then** la excavación, refuerzos de madera y sacos se leen como elementos distintos y coherentes con la imagen.
2. **Given** un actor o una munición junto a esa decoración, **When** se juega, **Then** la decoración permanece detrás de ellos y no tapa su lectura ni intercepta sus acciones.
3. **Given** un punto donde antes podía desplegarse un soldado, **When** coincide visualmente con tierra, sacos o madera, **Then** sigue sujeto exactamente a las reglas anteriores; las trincheras no proporcionan cobertura ni crean obstáculos o prohibiciones.

---

### Edge Cases

- Decoración dibujada detrás de una unidad o pickup: conservar lectura y entrada incluso cerca de los bordes de las trincheras.
- Colocación fuera del centro representado: el terreno no define nuevos límites; preservar el comportamiento anterior en todo punto que ya recibía la interacción.
- Soldado inicial y soldados nuevos con alineaciones distintas: adaptar el arte a ambos sin recolocar ninguno.
- Pantallas más anchas o altas: cubrir el fondo visible y registrar cualquier recorte preexistente; no resolverlo cambiando la geometría o las reglas del nivel.
- Importación con halos, costuras o pérdida de contraste: corregir los recursos visuales antes de aprobar, manteniendo intacto el comportamiento.
- Fallos preexistentes o funciones sin interfaz en el nivel: registrarlos por separado; no repararlos dentro de esta iteración ni presentarlos como entregados.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El escenario DEBE seguir la paleta, materialidad pictórica y jerarquía visual de la referencia versionada: ocre/oliva en tierra y decoración, azul grisáceo en montañas y atmósfera.
- **FR-002**: El terreno DEBE ofrecer una superficie continua y un centro de combate con menos ruido visual que el marco lateral.
- **FR-003**: Las trincheras DEBEN representar tierra excavada, madera y sacos de arena como decoración reconocible próxima a la posición defendida.
- **FR-004**: Todo el entorno nuevo DEBE quedar detrás de soldados, enemigos, municiones y cualquier indicador existente, sin interceptar entradas.
- **FR-005**: Se DEBEN conservar exactamente las posiciones, escalas, recorridos, tamaños de celda y geometrías de interacción y combate actuales.
- **FR-006**: Se DEBEN conservar colocación, ocupación/liberación, recolección, costos, estadísticas, daño, munición, moral, recarga, oleadas y condiciones de fin de partida.
- **FR-007**: Se DEBEN conservar las mismas entradas de ratón y toque y la misma correspondencia entre punto pulsado y resultado.
- **FR-008**: La decoración NO DEBE introducir cobertura, obstáculos, navegación, carriles, límites de despliegue, nuevas unidades o nuevas acciones.
- **FR-009**: Se DEBEN mantener los personajes provisionales y la interfaz actual tal como están; no rediseñar ni añadir HUD, controles, retratos o efectos de combate del concepto.
- **FR-010**: El arte DEBE funcionar en las proporciones de pantalla de la matriz de validación sin alterar el encuadre o la geometría jugable para hacerlo coincidir con la imagen.
- **FR-011**: El nuevo entorno DEBE ser estático en esta iteración: no añadir humo animado, partículas, iluminación dinámica, parallax o clima.
- **FR-012**: La entrega DEBE incluir comparación antes/después, evidencia de claridad e interacción y regresión, distinguiendo resultados reales de verificaciones pendientes.
- **FR-013**: Se DEBEN conservar los objetivos de rendimiento del proyecto, verificándolos en el dispositivo de referencia y sin atribuir rendimiento a una mera revisión de documentos.

### Key Entities

- **Referencia artística**: concepto aprobado, su procedencia y los elementos que se adaptan o excluyen.
- **Terreno y fondo**: superficie de tierra, horizonte y marco ambiental que contextualizan la partida.
- **Trinchera decorativa**: conjunto visual de tierra, madera y sacos sin efectos sobre las reglas.
- **Línea base jugable**: estado anterior del nivel, sus recursos y sus interacciones, usado para comparar la conservación de mecánicas.
- **Evidencia de aceptación**: capturas, resultados de regresión y registros de dispositivos/tamaños realmente comprobados.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: La revisión comparativa confirma los cinco rasgos de la referencia aplicables: tierra ocre/oliva, montañas azul grisáceo, textura pictórica, madera y sacos de arena; no aparecen los cinco carriles, personajes o HUD del concepto.
- **SC-002**: En todos los estados de la matriz visual, soldados, enemigos y municiones permanecen reconocibles y delante del nuevo entorno; no hay oclusión atribuible a la decoración.
- **SC-003**: Todos los escenarios de colocación y recolección de la matriz de interacción producen el mismo resultado antes/después con las entradas aplicables de ratón y toque.
- **SC-004**: La comparación de la línea base no encuentra cambios de reglas, valores de balance, posiciones, geometrías o entradas; la regresión requerida termina sin fallos nuevos atribuibles a esta iteración.
- **SC-005**: Las cuatro configuraciones de pantalla de la matriz quedan documentadas con evidencia, sin huecos de fondo nuevos ni cambio de correspondencia visual/entrada.
- **SC-006**: Una partida completa de validación conserva el ciclo del nivel; los escenarios separados de victoria y derrota mantienen los resultados anteriores.
- **SC-007**: En el dispositivo Android de referencia documentado se mantienen 60 FPS en gameplay típico, conforme a la constitución; las limitaciones o una línea base que ya incumpla el objetivo se registran y no se declaran aprobadas.

## Assumptions

- La preparación Spec Kit terminó; la autorización del 2026-10-15 permite producir e integrar los recursos y ejecutar las verificaciones mediante los roles del proyecto. Cada tarea conserva sus dependencias y requiere aprobación QA; la autorización no equivale a aceptación de la entrega.
- La imagen original se conserva en `references/monte-calvo-concept.png`. Se usa como dirección visual; el arte final se adapta al nivel existente y no se extrae de ella un fondo con personajes/UI incrustados.
- El alcance termina en terreno, montañas estáticas y trincheras decorativas. Carteles, bandera, personajes, interfaz, efectos, audio y nuevos sistemas se dejan para otras iteraciones.
- El nivel tiene un único avance central enemigo; no se añade una cuadrícula jugable finita que hoy no existe.
- Las carencias de HUD integrado o de acceso interactivo a la recarga pertenecen a la línea base y quedan fuera. Mantenerlas no equivale a afirmar que esas interfaces ya funcionan en una partida.
- El equipo registra dispositivo, ventana y condiciones de la línea base antes de implementar. Si falta un dispositivo o herramienta, esa comprobación queda pendiente, sin sustitución por una afirmación de compatibilidad.
- No se necesita un modelo de datos nuevo, servicio externo o dependencia de pago para esta mejora visual.
