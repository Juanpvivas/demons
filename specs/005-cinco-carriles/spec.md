# Feature Specification: Cinco carriles horizontales y salida de trincheras

**Feature ID**: `005-cinco-carriles`
**Planned Branch**: `codex/005-cinco-carriles-preparacion`
**Created**: 2026-10-19
**Status**: Aclaraciones principales resueltas; precisiones pendientes para plan.

**Input**: Cinco filas horizontales, con cinco trincheras a la izquierda,
soldados colombianos disparando hacia la derecha desde ellas y enemigos de
derecha a izquierda. Al agotar la munición, el soldado sale hacia el enemigo
con machete y combate de frente. La persona aprobó la imagen como referencia
y pidió conservar I2, abrir rama y preparar la especificación antes de desarrollar.

005 pasa a ser la prioridad por petición expresa. Parte de I2/004 conservado
en `f90e888`, sin aprobar su cierre ni modificar sus tareas. Este documento
especifica el comportamiento futuro; no afirma que esté implementado.

## Clarifications

### Session 2026-10-19

- Q: ¿Cuántas plazas hay y quién ocupa una trinchera durante la salida? → A:
  Cinco plazas únicas, una por fila, reservadas por su soldado vivo aunque
  salga; solo se reemplaza al soldado después de su muerte.
- Q: ¿Cómo sale, espera y vuelve el soldado sin munición? → A: Sale únicamente
  hacia enemigos delante en su misma fila y combate frontalmente sin cambiar
  de fila; si no hay ninguno delante espera donde está. Recargar conserva
  salud/moral, provoca regreso físico a su trinchera y permite disparar al llegar.
- Q: ¿Cómo se ordena recargar a un soldado que puede estar fuera? → A:
  Seleccionar su trinchera y pulsar «Recargar», mostrando la munición y moral
  individuales de ese soldado, aunque esté combatiendo fuera.
- Q: ¿Cómo empiezan las defensas y se reparten las oleadas? → A: Cinco soldados
  cargados desde el inicio, uno por trinchera, y reserva global cero. Conservar
  cantidades y tiempos actuales de oleadas, con reparto prefijado entre filas.

### Precisiones pendientes para plan

- **C4 — Velocidad de salida/regreso**: [NEEDS CLARIFICATION: ¿Qué velocidad
  propia tendrá el soldado al salir y regresar: 40/40, 60/60 o 40/60 unidades
  de mundo por segundo, respectivamente? No se ha elegido ninguna opción.]
- **C5 — Elegibilidad de recarga**: [NEEDS CLARIFICATION: ¿«Recargar» se permite
  solo con carga cero o también con una carga parcialmente gastada? Ambas
  opciones bloquean nuevas recargas durante el regreso; falta elegir la
  condición que habilita la orden y su cobro.]
- **C6 — Secuencia de filas**: [NEEDS CLARIFICATION: ¿El reparto prefijado
  recorre 1→2→3→4→5 de forma continua entre oleadas o vuelve a empezar en la
  fila 1 al comenzar cada oleada? No se ha elegido ninguna secuencia.]

El botón de recarga introduce una orden con costo observable, no solo una
presentación de la operación existente. Su habilitación, rechazo y cobro por
orden necesitan la decisión C5 antes de planificar el comportamiento; no se
consideran resueltos por conservar el costo unitario equivalente al despliegue.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Defender cinco filas desde las trincheras (Priority: P1)

Como jugador, quiero reconocer las cinco defensas izquierdas y la aproximación
enemiga desde la derecha para decidir dónde sostener Monte Calvo.

**Why this priority**: El tablero y la orientación definen el juego horizontal.
**Independent Test**: Iniciar con cinco soldados cargados y reserva global
cero; comprobar las cinco filas, el disparo estacionario y un avance enemigo
hasta la posición defendida.

**Acceptance Scenarios**:

1. **Given** una partida nueva, **When** carga Monte Calvo, **Then** aparecen
   exactamente cinco filas y cinco trincheras izquierdas, cada una con su
   soldado cargado, y la reserva global de munición es cero.
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
machete; retirar los enemigos frontales para comprobar espera y recargar desde
su trinchera para comprobar regreso físico antes de reanudar el fusil.

**Acceptance Scenarios**:

1. **Given** un soldado con una bala y objetivo, **When** efectúa el último
   disparo válido, **Then** cambia a machete; avanza hacia enemigos delante
   en su fila, o espera donde está si ya no hay ninguno, sin crear otro actor
   ni disparar otra vez con carga cero.
2. **Given** el soldado saliendo hacia un enemigo elegible, **When** entra en
   alcance frontal de machete, **Then** se detiene para combatir sin atravesarlo;
   ambos pueden recibir daño y morir con sus reglas vigentes.
3. **Given** el objetivo derrotado o retirado durante el acercamiento,
   **When** se elige la continuación, **Then** busca otro enemigo delante
   en esa fila o espera donde está si no hay ninguno; no ataca una baja
   anterior ni duplica recompensas o cambia de fila.
4. **Given** un soldado fuera y fondos suficientes para una recarga válida,
   **When** se selecciona su trinchera y se pulsa «Recargar», **Then** se cobra
   esa recarga una vez, conserva salud/moral y regresa físicamente a su origen;
   no dispara durante el regreso y vuelve al fusil al llegar.
5. **Given** el soldado derrotado fuera de su trinchera, **When** muere,
   **Then** deja de combatir, pierde su moral y libera su plaza de origen,
   sin esperar a que termine la caída visual.
6. **Given** un soldado sin balas que espera y enemigos solo detrás o en otra
   fila, **When** se evalúa su salida, **Then** mantiene la posición; al
   aparecer un enemigo delante en su fila reanuda el avance frontal.

### User Story 3 - Administrar plazas y munición (Priority: P2)

Como jugador, quiero desplegar y recargar donde corresponda y recoger cajas
sin órdenes accidentales, tanto con ratón como con toque en la app.

**Why this priority**: La salida cambia la ocupación y debe preservar la economía.
**Independent Test**: Comparar reserva, soldados y plazas antes/después de
cada gesto válido o rechazado, incluida la salida y derrota del dueño de una plaza.

**Acceptance Scenarios**:

1. **Given** una de las cinco plazas libre tras la muerte de su soldado y
   fondos suficientes, **When** se despliega sin
   tocar una caja, **Then** aparece un soldado cargado y se cobra una vez.
2. **Given** plaza no disponible, punto inválido o fondos insuficientes,
   **When** se intenta desplegar, **Then** no cambian reserva, unidades u ocupación.
3. **Given** una caja donde sería posible desplegar y fondos suficientes,
   **When** se recoge, **Then** ese gesto solo recoge munición, sin desplegar,
   recargar ni cobrar además otro soldado; conserva también la regla de cajas solapadas.
4. **Given** un soldado vivo fuera de su trinchera, **When** se intenta usar
   su plaza para reemplazarlo, **Then** se rechaza el despliegue sin cobrar;
   seleccionarla muestra la carga y moral individuales del dueño para recargarlo.
5. **Given** cinco soldados inicialmente cargados, reserva global cero y
   oleadas actuales repartidas de forma prefijada, **When** se derrotan todos
   los enemigos sin perder la posición, **Then** ocurre una sola victoria.
6. **Given** una trinchera cuyo dueño ha muerto, **When** se solicita recargar
   desde una selección anterior, **Then** no se resucita al muerto ni se cobra
   recarga a otra unidad; la plaza queda disponible para un nuevo despliegue.

### Edge Cases

- Primera y quinta fila: no existen filas exteriores ni diagonales hacia ellas.
- Última bala y baja simultáneas: una sola recompensa y moral por eliminación;
  la imagen del disparo no prolonga el modo fusil.
- Objetivo perdido: avanzar hacia otro enemigo frontal de la misma fila;
  sin enemigos delante, esperar en el punto actual, sin atacar bajas,
  perseguir enemigos detrás ni buscar otra fila.
- Recarga sin fondos, solicitud repetida o muerte durante regreso: sin cobro
  parcial por un rechazo, duplicación de un gesto, resurrección ni reserva
  perpetua de una plaza liberada. La elegibilidad de cargas cero/parciales y
  las órdenes durante el regreso siguen pendientes de la decisión C5.
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
  izquierda por fila y entrada enemiga por su derecha. La partida empieza con
  un soldado cargado por trinchera y reserva global de munición cero.
- **FR-002**: Ofrecer exactamente cinco plazas válidas, una por trinchera,
  visibles y reservadas por su soldado vivo incluso mientras está fuera.
  Reemplazarlo solo después de su muerte y rechazar despliegues en puntos
  inválidos o plazas reservadas antes de cobrar o crear unidades.
- **FR-003**: Asignar a cada enemigo una fila de avance derecha→izquierda,
  conservada hasta su retirada, mediante un reparto prefijado entre las cinco
  filas; C6 cierra su continuidad entre oleadas. No introducir reparto
  aleatorio ni multiplicar cantidades por cinco.
- **FR-004**: El fusil dispara a derecha desde dentro de la trinchera,
  conservando carga, alcance, daño, cadencia y prioridad vigentes: frente y
  celdas diagonalmente contiguas de filas adyacentes, sin ampliar el cono ni
  alcanzar objetivos detrás del soldado.
- **FR-005**: Al agotar la carga, el mismo soldado muestra machete y sale
  físicamente solo hacia enemigos delante en su fila. Avanza y ataca en esa
  fila; al perder o eliminar objetivo busca otro frontal en la misma fila y,
  si no existe, espera en su posición actual hasta que haya uno o se recargue.
  Las velocidades propias de salida/regreso se fijan en C4. No basta
  animación decorativa ni una copia o teletransporte.
- **FR-006**: El machete conserva rango frontal, cadencia y daño por moral;
  el contacto permite daño y derrota reales de ambos actores. Las trincheras
  no conceden cobertura, invulnerabilidad ni bonificaciones estadísticas.
- **FR-007**: La recarga conserva salud y moral, cuesta lo mismo que desplegar
  ese tipo y se solicita seleccionando la trinchera y pulsando «Recargar»,
  aunque su soldado esté fuera. La selección muestra la munición y moral
  individuales del dueño. Una recarga válida fuera provoca regreso físico
  por su fila hasta su trinchera, sin disparar antes de llegar; dentro restaura
  el fusil sin desplazamiento. La falta de fondos no cobra ni altera el estado.
  C5 debe cerrar qué cargas permiten ordenar/cobrar y el bloqueo durante el regreso.
- **FR-008**: La plaza de origen continúa reservada durante salida, espera,
  contacto y regreso, y se libera al morir sin esperar efectos. No hay dos
  dueños vivos de una plaza ni bajas duplicadas por una misma derrota.
- **FR-009**: Conservar reserva global, recompensas, moral por eliminación y
  recolección explícita con precedencia sobre despliegue. No añadir generación
  pasiva, moral por impacto ni consecuencias jugables causadas por animaciones.
- **FR-010**: Conservar tipos, cantidades y tiempos de oleadas, y costos
  vigentes, con la nueva dotación de cinco soldados cargados/reserva cero y
  el reparto prefijado entre filas. El atacante inicial de producción, separado
  de las oleadas, no se elimina implícitamente al reorganizar el tablero:
  se conservan un atacante inicial y los 99 autorados en oleadas, 100 en total.
  Todas las oleadas derrotadas producen victoria; un cruce izquierdo en
  cualquier fila, derrota.
- **FR-011**: Distinguir fusil dentro, última bala, salida/marcha con machete,
  golpe, daño, recarga/regreso aplicables y derrota por la acción real, sin
  depender solo del color. Seguir la [referencia](references/visual-reference.md)
  en composición, materiales y siluetas, sin adoptar sus cifras de HUD o balance.
- **FR-012**: Mantener cinco filas y plazas visibles y utilizables al variar
  la vista, con igual significado de acción en Web de computador y apps
  Android/iOS. Limpiar transiciones al reiniciar/reutilizar, manteniendo los
  efectos separados de daño, recursos, ocupación y resultado.

### Key Entities *(include if feature involves data)*

- **Fila**: una de cinco rutas entre entrada derecha y defensa izquierda.
- **Trinchera/plaza**: una por fila, origen reservado por su defensor vivo,
  libre solo al morir y sin protección estadística.
- **Soldado**: carga, salud y moral propias, arma, fila, plaza y situación dentro/fuera.
- **Enemigo/oleada**: atacante con fila, salud y progreso; grupo con cantidad, tiempos y reparto.
- **Munición**: reserva compartida y cajas recogibles, separadas de cada carga individual.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Se reconocen cinco filas y cinco trincheras; no hay plazas
  utilizables adicionales ni pérdida de filas por resize. Hay cinco soldados
  cargados inicialmente y reserva global cero, sin cobrar esos despliegues iniciales.
- **SC-002**: En cada una de las cinco filas, avance, bloqueo independiente y
  cruce izquierdo producen su resultado correcto, con una sola derrota terminal.
- **SC-003**: En cada fila se verifica fusil dentro → última bala → machete →
  salida → contacto/ataque, espera sin enemigos frontales y regreso físico tras
  recarga desde la trinchera; el fusil solo se reanuda al llegar, sin disparos
  vacíos, cambios de fila o soldados duplicados.
- **SC-004**: Cada caso válido/rechazado de despliegue, recarga y recolección
  conserva exactamente saldo, unidades y ocupación esperados; un gesto no
  realiza dos acciones económicas incompatibles.
- **SC-005**: Una partida con cinco soldados cargados, reserva cero y oleadas
  actuales con reparto prefijado se recorre de inicio a terminal sin errores
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
- Dimensiones y distancias se fijarán expresamente al planificar, sin alterar
  los stats vigentes por deducción ni tomar números de la imagen. C4–C6 deben
  resolverse antes de cerrar el plan y sus criterios de comportamiento.
- Se reutilizan soldado/enemigo actuales y economía, sin roster nuevo,
  selección manual de objetivos o movimiento entre filas no autorizado.
- Se incorpora el control mínimo confirmado de selección de trinchera y botón
  «Recargar», con munición/moral del soldado individual. Actualmente solo
  existe la operación de recarga, sin ese control integrado en el nivel;
  la selección no modifica recursos y la imagen no autoriza un HUD completo.
- La dependencia I2 está conservada en `codex/004-i2-enemigo` remoto desde
  `f90e888`; tareas y pendientes de 004 siguen intactos y no quedan aprobados aquí.
- Rigen constitución 3.0.0 y [flujo del proyecto](../../docs/DEVELOPMENT_WORKFLOW.md):
  completar plan/tareas y revisión antes de ejecutar tester RED →
  desarrollo → tester GREEN → QA → documentación. No fabricar RED histórico.
- Web solo en computador; Android/iOS solo apps instaladas. No se cambian
  renderer o exportación al preparar. Android físico no está disponible y no
  se solicitará reconexión; emulador/simulador permiten avanzar funcionalmente,
  conservando los límites constitucionales y sin nueva excepción implícita.
