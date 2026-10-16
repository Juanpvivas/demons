# Feature Specification: Monte Calvo — terreno y trincheras, iteración visual 1

**Feature ID**: `002-monte-calvo-terreno-trincheras`

**Branch**: `codex/002-monte-calvo-terreno-trincheras`.

**Created**: 2026-10-15

**Status**: implementación y validación por agentes completadas el 2026-10-16; 22/22 tareas aprobadas por QA según [el registro de ejecución](tasks.md). La integración en main requiere revisión y fusión humanas del PR en borrador.

**Input**: «Usa Spec Kit para preparar la especificación, el plan y las tareas de la primera iteración visual del terreno y las trincheras, siguiendo la imagen y manteniendo las mecánicas actuales».

**Autorización posterior**: el 2026-10-15 la persona autorizó ejecutar esta feature mediante los roles del proyecto. Se conserva el alcance visual y todos los criterios de aceptación de la preparación.

**Referencia visual**: [concepto aprobado y criterios de adaptación](references/visual-reference.md). La imagen es una dirección artística, no una captura del juego ni una definición de sus reglas.

## Adenda de preparación — 2026-10-16

**Estado**: preparación de la adenda aprobada por QA; no aprueba por sí sola T019, la corrección ni las verificaciones nativas. El [registro del orquestador en tasks.md](tasks.md) es la fuente vigente de aprobaciones. Se conservan las aprobaciones históricas. La adenda original se preparó con la constitución 1.1.0; la decisión de referencia provisional posterior se documenta en la enmienda 1.2.0.

- La persona autorizó validar iOS/Android mediante simuladores/emuladores. V4 se realizará en **iOS Simulator**, con gestos sobre la interfaz de la app y registro de coordenadas/estado; su aceptación será de simulador, sin afirmar iOS físico probado. V3 conserva el **Xiaomi físico** disponible para interacción humana y comparación de rendimiento. Ese 11T Pro de 2021 no cumple la referencia nominal de gama media de los últimos ~3 años. Tras identificar esa limitación, la persona lo autorizó como referencia provisional exclusiva de 002 según la enmienda posterior; SC-007 mantiene 60 FPS estables y revisión QA, sin aprobación automática.
- I4 y US2/AC2 ya exigían recoger sin desplegar además un soldado. El diagnóstico nativo actual reproduce el defecto tanto en la copia anterior al arte como en `b670d86`: con reserva 12 y un pickup de 3 en celda libre, un clic puede dejar 5 y crear otro soldado. El script de ambas versiones es idéntico (SHA-256 `2420d7100eb852b6dee0521df56015784a5ac0a0b2af0274b3fa6d2b3fe27e6b`); el arte no lo introdujo.
- Se planifica adelantar **solo la corrección de precedencia pickup→despliegue** validada mediante TDD en 003 (`4a2915c`), como arreglo separado T019–T022. No se atribuye a la persona una autorización explícita de este backport: su fundamento es el defecto ya corregido/validado en 003 y la necesidad de cumplir I4. La preparación está aprobada; su aceptación en 002 exige completar el ciclo nativo y su QA.
- Única excepción a la conservación histórica: corregir ese resultado erróneo en `scenes/levels/nivel_monte_calvo.gd` y añadir las seis pruebas/UID de regresión correspondientes. Se mantienen InputMap, costos, recompensas, balance, datos, geometría, escenas de actores y exportaciones. No se incorpora Web ni configuración de 003. La línea base y las evidencias artísticas originales se conservan; la comparación visual se separa de la corrección según [el contrato](contracts/visual-boundary.md).

**Aclaración de método Android, aprobada por QA (2026-10-16)**: la autorización de emuladores permite añadir una subcobertura controlada de I1–I4/I9 mediante **Android Emulator (AVD)**, con gestos entregados por el sistema operativo a la app, incluida la entrada ADB dirigida exclusivamente al serial verificado del emulador. No sustituye V3: el Xiaomi conserva la comprobación humana de interacción física y las mediciones reales disponibles. Los resultados de ratón PC, toque simulado Android, toque humano Xiaomi y gesto iOS Simulator se registran por separado, con coordenadas y estado previo/posterior. Este método no acredita por anticipado ningún caso ni convierte la emulación en prueba física o medición de SC-007; véase [quickstart](quickstart.md).

## Clarifications

### Session 2026-10-16

- Decisión explícita de la persona: «Usar el Xiaomi como referencia provisional para 002». Se adopta el Xiaomi 11T Pro físico (`2107113SG`, generación 2021) solo para la aceptación de 002, mediante la enmienda 1.2.0 de la [constitución](../../.specify/memory/constitution.md). La persona recibió el límite de generación y de la muestra corta disponible; la decisión conserva 60 FPS estables y revisión QA. No certifica otros teléfonos, 003 o iOS ni declara superado SC-007. Esta sincronización documental se entrega como borrador para QA; los resultados siguen en `evidence/`.

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
2. **Given** una munición recolectable sobre el nuevo fondo, **When** se recoge, **Then** se acredita la munición sin desplegar además un soldado ni gastar su costo; la decoración no absorbe la entrada. El defecto previo que incumple este resultado se trata únicamente mediante la adenda T019–T022.
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
- Fallos preexistentes o funciones sin interfaz en el nivel: registrarlos por separado; no repararlos dentro de las tareas artísticas ni presentarlos como entregados. La única corrección prevista es la de I4 en la adenda T019–T022.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El escenario DEBE seguir la paleta, materialidad pictórica y jerarquía visual de la referencia versionada: ocre/oliva en tierra y decoración, azul grisáceo en montañas y atmósfera.
- **FR-002**: El terreno DEBE ofrecer una superficie continua y un centro de combate con menos ruido visual que el marco lateral.
- **FR-003**: Las trincheras DEBEN representar tierra excavada, madera y sacos de arena como decoración reconocible próxima a la posición defendida.
- **FR-004**: Todo el entorno nuevo DEBE quedar detrás de soldados, enemigos, municiones y cualquier indicador existente, sin interceptar entradas.
- **FR-005**: Se DEBEN conservar exactamente las posiciones, escalas, recorridos, tamaños de celda y geometrías de interacción y combate actuales.
- **FR-006**: Se DEBEN conservar colocación, ocupación/liberación, recolección, costos, estadísticas, daño, munición, moral, recarga, oleadas y condiciones de fin de partida, con la única corrección de precedencia exigida por US2/AC2 e I4 y delimitada en la adenda.
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
- **SC-003**: Todos los escenarios de colocación y recolección de la matriz producen el mismo resultado antes/después del arte con las entradas aplicables de ratón y toque. I4 se compara sobre ambas composiciones con la corrección aprobada, conservando por separado el RED del defecto histórico.
- **SC-004**: La comparación de la línea base no encuentra cambios de reglas, valores de balance, posiciones, geometrías o entradas, salvo el arreglo separado y acotado de I4 de la adenda; la regresión requerida termina sin fallos nuevos atribuibles a esta iteración.
- **SC-005**: Las cuatro configuraciones de pantalla de la matriz quedan documentadas con evidencia, sin huecos de fondo nuevos ni cambio de correspondencia visual/entrada.
- **SC-006**: Una partida completa de validación conserva el ciclo del nivel; los escenarios separados de victoria y derrota mantienen los resultados anteriores.
- **SC-007**: En el Xiaomi 11T Pro físico (`2107113SG`), referencia provisional autorizada exclusivamente para 002 conforme a la constitución 1.2.0, se mantienen 60 FPS estables en gameplay típico; las limitaciones o una línea base que ya incumpla el objetivo se registran y no se declaran aprobadas. La aceptación depende de la evidencia y de QA, sin extrapolar a otros teléfonos, 003 o iOS.

## Assumptions

- La preparación Spec Kit terminó; la autorización del 2026-10-15 permite producir e integrar los recursos y ejecutar las verificaciones mediante los roles del proyecto. Cada tarea conserva sus dependencias y requiere aprobación QA; la autorización no equivale a aceptación de la entrega.
- La imagen original se conserva en `references/monte-calvo-concept.png`. Se usa como dirección visual; el arte final se adapta al nivel existente y no se extrae de ella un fondo con personajes/UI incrustados.
- El alcance termina en terreno, montañas estáticas y trincheras decorativas. Carteles, bandera, personajes, interfaz, efectos, audio y nuevos sistemas se dejan para otras iteraciones.
- El nivel tiene un único avance central enemigo; no se añade una cuadrícula jugable finita que hoy no existe.
- Las carencias de HUD integrado o de acceso interactivo a la recarga pertenecen a la línea base y quedan fuera. Mantenerlas no equivale a afirmar que esas interfaces ya funcionan en una partida.
- El equipo registra dispositivo, ventana y condiciones de la línea base antes de implementar. V3 mantiene cobertura física Xiaomi y admite una subcobertura complementaria AVD para los casos controlados I1–I4/I9; no se extrapola entre ambas. V4 admite el simulador iOS autorizado, identificado como tal; iOS físico queda no probado. Cualquier herramienta o comprobación ausente permanece pendiente, sin afirmación de compatibilidad.
- No se necesita un modelo de datos nuevo, servicio externo o dependencia de pago para esta mejora visual.
