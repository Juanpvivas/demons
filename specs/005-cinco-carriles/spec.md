# Feature Specification: Cinco carriles horizontales y salida de trincheras

**Feature ID**: `005-cinco-carriles`
**Planned Branch**: `codex/005-cinco-carriles-preparacion`
**Created**: 2026-10-19
**Status**: Draft — pendiente de aclaraciones humanas y revisión independiente.

**Input**: Cinco filas horizontales, con cinco trincheras a la izquierda,
soldados colombianos disparando hacia la derecha desde ellas y enemigos de
derecha a izquierda. Al agotar la munición, el soldado sale hacia el enemigo
con machete y combate de frente. La persona aprobó la imagen como referencia
y pidió conservar I2, abrir rama y preparar la especificación antes de desarrollar.

005 pasa a ser la prioridad por petición expresa. Parte de I2/004 conservado
en `f90e888`, sin aprobar su cierre ni modificar sus tareas. Este documento
especifica el comportamiento futuro; no afirma que esté implementado.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Defender cinco filas desde las trincheras (Priority: P1)

Como jugador, quiero reconocer las cinco defensas izquierdas y la aproximación
enemiga desde la derecha para decidir dónde sostener Monte Calvo.

**Why this priority**: El tablero y la orientación definen el juego horizontal.
**Independent Test**: Con la dotación acordada en C3, comprobar las cinco filas,
el disparo estacionario y un avance enemigo hasta la posición defendida.

**Acceptance Scenarios**:

1. **Given** una partida nueva, **When** carga Monte Calvo, **Then** aparecen
   exactamente cinco filas horizontales y una trinchera izquierda por fila.
2. **Given** un enemigo en cualquier fila, **When** avanza sin oposición,
   **Then** recorre esa fila de derecha a izquierda sin cambiar de carril.
3. **Given** un soldado con balas y objetivo elegible a su derecha, **When**
   dispara, **Then** permanece dentro de su trinchera, orientado hacia el
   frente, y consume su carga individual conforme al combate vigente.
4. **Given** un enemigo bloqueado por un soldado, **When** avanzan enemigos
   en otras filas, **Then** ese contacto no bloquea sus rutas independientes.
5. **Given** un enemigo que alcanza el límite defendido por cualquiera de las
   filas, **When** cruza por la izquierda, **Then** ocurre una sola derrota.

### User Story 2 - Salir con machete al agotar la carga (Priority: P1)

Como jugador, quiero que el soldado sin balas abandone la trinchera y alcance
al enemigo de frente para continuar la defensa con machete.

**Why this priority**: Es la nueva mecánica pedida y expresa el valor de la moral.
**Independent Test**: En una fila, observar última bala, salida, contacto y
machete; después comprobar ausencia de objetivo y recarga según C2.

**Acceptance Scenarios**:

1. **Given** un soldado con una bala y objetivo, **When** efectúa el último
   disparo válido, **Then** cambia a machete y aplica C2 sin crear otro actor
   ni disparar otra vez con carga cero.
2. **Given** el soldado saliendo hacia un enemigo elegible, **When** entra en
   alcance frontal de machete, **Then** se detiene para combatir sin atravesarlo;
   ambos pueden recibir daño y morir con sus reglas vigentes.
3. **Given** el objetivo derrotado o retirado durante el acercamiento,
   **When** se continúa la salida, **Then** se aplica C2 sin atacar una baja
   anterior, duplicar recompensas ni cambiar de fila sin autorización.
4. **Given** una recarga permitida por C2 y fondos suficientes, **When** se
   solicita mediante la acción allí acordada, **Then** se cobra una vez y se
   conserva salud y moral, con la continuación acordada y sin teletransporte.
5. **Given** el soldado derrotado fuera de su trinchera, **When** muere,
   **Then** deja de combatir, pierde su moral y libera la plaza conforme a C1,
   sin esperar a que termine la caída visual.

### User Story 3 - Administrar plazas y munición (Priority: P2)

Como jugador, quiero desplegar y recargar donde corresponda y recoger cajas
sin órdenes accidentales, tanto con ratón como con toque en la app.

**Why this priority**: La salida cambia la ocupación y debe preservar la economía.
**Independent Test**: Comparar reserva, soldados y plazas antes/después de
cada gesto válido o rechazado, incluida la salida y derrota del dueño de una plaza.

**Acceptance Scenarios**:

1. **Given** plaza válida libre según C1 y fondos, **When** se despliega sin
   tocar una caja, **Then** aparece un soldado cargado y se cobra una vez.
2. **Given** plaza no disponible, punto inválido o fondos insuficientes,
   **When** se intenta desplegar, **Then** no cambian reserva, unidades u ocupación.
3. **Given** una caja donde sería posible desplegar y fondos suficientes,
   **When** se recoge, **Then** ese gesto solo recoge munición, sin desplegar,
   recargar ni cobrar además otro soldado; conserva también la regla de cajas solapadas.
4. **Given** un soldado vivo fuera de su trinchera, **When** se intenta usar
   su plaza, **Then** rige C1 sin ocupaciones duplicadas ni cobros de un rechazo.
5. **Given** la dotación y oleadas acordadas en C3, **When** se derrotan todos
   los enemigos sin perder la posición, **Then** ocurre una sola victoria.

### Edge Cases

- Primera y quinta fila: no existen filas exteriores ni diagonales hacia ellas.
- Última bala y baja simultáneas: una sola recompensa y moral por eliminación;
  la imagen del disparo no prolonga el modo fusil.
- Objetivo perdido, enemigo detrás o ausencia de enemigos: continuar conforme
  a C2, sin atacar bajas ni buscar otras filas por una decisión implícita.
- Recarga sin fondos, solicitud repetida o muerte durante regreso: sin cobro
  parcial, duplicación, resurrección ni reserva perpetua de una plaza liberada.
- Contactos múltiples y de distintas filas: sin daño duplicado por el mismo
  ataque ni bloqueo entre filas que no comparten contacto.
- Reutilización enemiga en otra fila y reinicio: sin objetivos, posiciones,
  intenciones de contacto, tintes o callbacks heredados de la activación anterior.
- Cajas solapadas o bajo soldados: recoger no desencadena otra acción económica.
- Resize y distintos aspectos: filas extremas, plazas y clic/toque corresponden
  a lo que se ve; tras terminal no se altera la partida con acciones tardías.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Presentar exactamente cinco filas horizontales, una trinchera
  izquierda por fila y entrada enemiga por su derecha.
- **FR-002**: Hacer visibles las plazas válidas y rechazar puntos inválidos
  antes de cobrar o crear unidades. Disponibilidad y pertenencia se fijan en C1.
- **FR-003**: Asignar a cada enemigo una fila de avance derecha→izquierda,
  conservada hasta su retirada. C3 fija el reparto; cinco filas no multiplican
  automáticamente las cantidades de enemigos.
- **FR-004**: El fusil dispara a derecha desde dentro de la trinchera,
  conservando carga, alcance, daño, cadencia y prioridad vigentes: frente y
  celdas diagonalmente contiguas de filas adyacentes, sin ampliar el cono ni
  alcanzar objetivos detrás del soldado.
- **FR-005**: Al agotar la carga, el mismo soldado muestra machete y sale
  físicamente hacia el enemigo de frente conforme a C2; no basta una animación
  decorativa ni una copia o teletransporte.
- **FR-006**: El machete conserva rango frontal, cadencia y daño por moral;
  el contacto permite daño y derrota reales de ambos actores. Las trincheras
  no conceden cobertura, invulnerabilidad ni bonificaciones estadísticas.
- **FR-007**: La recarga conserva salud y moral, cuesta lo mismo que desplegar
  ese tipo y sigue C2; la falta de fondos no cobra ni altera el estado.
- **FR-008**: La ocupación sigue C1 y se libera al morir sin esperar efectos;
  ninguna unidad cuenta dos veces ni produce dos bajas por una derrota.
- **FR-009**: Conservar reserva global, recompensas, moral por eliminación y
  recolección explícita con precedencia sobre despliegue. No añadir generación
  pasiva, moral por impacto ni consecuencias jugables causadas por animaciones.
- **FR-010**: Conservar tipos, cantidades y tiempos de oleadas, y costos
  vigentes, salvo dotación inicial y reparto aprobados en C3. Todas las oleadas
  derrotadas producen victoria; un cruce izquierdo en cualquier fila, derrota.
- **FR-011**: Distinguir fusil dentro, última bala, salida/marcha con machete,
  golpe, daño, recarga/regreso aplicables y derrota por la acción real, sin
  depender solo del color. Seguir la [referencia](references/visual-reference.md)
  en composición, materiales y siluetas, sin adoptar sus cifras de HUD o balance.
- **FR-012**: Mantener cinco filas y plazas visibles y utilizables al variar
  la vista, con igual significado de acción en Web de computador y apps
  Android/iOS. Limpiar transiciones al reiniciar/reutilizar, manteniendo los
  efectos separados de daño, recursos, ocupación y resultado.

### Clarificaciones pendientes

- **C1 — Plazas**: [NEEDS CLARIFICATION: ¿Exactamente cinco plazas, una por
  trinchera, reservadas por su soldado vivo durante salida y hasta su muerte;
  reemplazo mientras está fuera; o varias plazas por fila? Define los límites
  de despliegue y qué plaza se libera o recupera al regresar.]
- **C2 — Ciclo y recarga**: [NEEDS CLARIFICATION: ¿Sale solo con enemigo
  frontal en su fila, espera en su posición si no hay ninguno y, al recargar,
  vuelve a trinchera para disparar al llegar; dispara donde fue recargado;
  o no se recarga fuera? Fijar también qué hace al matar/perder objetivo y
  cómo se ordena recargar: seleccionar trinchera + botón, tocar trinchera
  ocupada, o seleccionar soldado + botón. La imagen no aprueba ese HUD.]
- **C3 — Inicio y oleadas**: [NEEDS CLARIFICATION: ¿Cinco soldados cargados y
  reserva cero; un soldado y fondos para otros cuatro; o un soldado y primeras
  oleadas solo en su fila? Confirmar reparto prefijado entre filas conservando
  cantidades y tiempos actuales, sin asumir azar ni multiplicar la población.]

### Key Entities *(include if feature involves data)*

- **Fila**: una de cinco rutas entre entrada derecha y defensa izquierda.
- **Trinchera/plaza**: origen del defensor y disponibilidad según C1, sin protección estadística.
- **Soldado**: carga, salud y moral propias, arma, fila, plaza y situación dentro/fuera.
- **Enemigo/oleada**: atacante con fila, salud y progreso; grupo con cantidad, tiempos y reparto.
- **Munición**: reserva compartida y cajas recogibles, separadas de cada carga individual.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Se reconocen cinco filas y cinco trincheras; no hay plazas
  utilizables fuera de los límites acordados ni pérdida de filas por resize.
- **SC-002**: En cada una de las cinco filas, avance, bloqueo independiente y
  cruce izquierdo producen su resultado correcto, con una sola derrota terminal.
- **SC-003**: En cada fila se verifica fusil dentro → última bala → machete →
  salida → contacto/ataque y el ciclo C2, sin disparos vacíos o soldados duplicados.
- **SC-004**: Cada caso válido/rechazado de despliegue, recarga y recolección
  conserva exactamente saldo, unidades y ocupación esperados; un gesto no
  realiza dos acciones económicas incompatibles.
- **SC-005**: Una partida con C3 se recorre de inicio a terminal sin errores
  críticos; completar todas las oleadas se verifica además por separado y
  produce una sola victoria, sin balance adicional no autorizado.
- **SC-006**: Los recorridos aplicables se verifican por separado en navegador
  de computador, APK en Android Emulator y app de iOS Simulator; no acreditan
  hardware físico ni otros renderers. La revisión visual distingue FR-011
  en filas superior, central e inferior, también tras cambiar la vista.
- **SC-007**: Gameplay típico a 60 FPS estables en la referencia física de
  constitución IV; sin hardware disponible, la aceptación sigue pendiente,
  sin heredar referencias provisionales de 002/004 ni sustituirla por emulación.
  Web registra carga/rendimiento por navegador y computador; el umbral global
  de carga continúa pendiente conforme a constitución.

## Assumptions

- La [imagen aprobada](references/visual-reference.md) fija dirección visual,
  no costos, HUD final, balance o recursos artísticos terminados.
- Dimensiones, distancias y parámetros nuevos de salida/regreso se resolverán
  expresamente antes del desarrollo que los necesite, sin alterar los stats
  vigentes por deducción ni tomar números de la imagen.
- Se reutilizan soldado/enemigo actuales y economía, sin roster nuevo,
  selección manual de objetivos o movimiento entre filas no autorizado.
- La acción de recarga de C2 requiere un control mínimo comprobable;
  actualmente existe la operación de recarga, no un control integrado en el nivel.
- La dependencia I2 está conservada en `codex/004-i2-enemigo` remoto desde
  `f90e888`; tareas y pendientes de 004 siguen intactos y no quedan aprobados aquí.
- Rigen constitución 3.0.0 y [flujo del proyecto](../../docs/DEVELOPMENT_WORKFLOW.md):
  cerrar aclaraciones, plan/tareas y revisión antes de ejecutar tester RED →
  desarrollo → tester GREEN → QA → documentación. No fabricar RED histórico.
- Web solo en computador; Android/iOS solo apps instaladas. No se cambian
  renderer o exportación al preparar. Android físico no está disponible y no
  se solicitará reconexión; emulador/simulador permiten avanzar funcionalmente,
  conservando los límites constitucionales y sin nueva excepción implícita.
