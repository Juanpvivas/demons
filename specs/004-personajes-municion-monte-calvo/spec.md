# Feature Specification: Personajes y munición de Monte Calvo

**Feature ID**: `004-personajes-municion-monte-calvo`

**Execution Branch**: `codex/004-i1-soldado`; una rama por incremento.

**Created**: 2026-10-16

**Status**: I1 inicial aprobado sobre `87a39c6`; corrección de legibilidad y
encuadre aprobada funcionalmente en T036. I2/I3 siguen pendientes; las
[tareas](tasks.md) y el PR delimitan la consolidación y entrega.

**Input**: «Entonces preparemos con Spec Kit la siguiente feature de personajes
y munición de Monte Calvo, siguiendo el flujo que ya tengo definido».

El siguiente acercamiento al [concepto de Monte Calvo](../002-monte-calvo-terreno-trincheras/references/monte-calvo-concept.png)
reemplaza las formas provisionales del soldado colombiano base, del enemigo
base y de la munición recolectable por personajes y cajas con el estilo
pictórico del escenario. Incorpora poses y animaciones visuales básicas para
comunicar las acciones que ya ocurren. No amplía el roster ni cambia las reglas.

**Enmienda T031**: el feedback posterior a I1 pide un soldado más visible sobre
el suelo y márgenes equilibrados en Xiaomi, conservando la composición de iPad.
La corrección tiene aprobación funcional T036; los criterios siguientes
conservan su alcance y las aprobaciones históricas de T001–T013.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reconocer al soldado y su modo de combate (Priority: P1)

Como jugador, quiero ver un soldado colombiano coherente con Monte Calvo y
distinguir cuándo usa el fusil o el machete, para entender su respuesta al
combate sin depender del color de un bloque.

**Why this priority**: El soldado es la unidad que el jugador despliega; su
silueta y cambio de arma comunican el diferenciador del juego.

**Independent Test**: Con el enemigo y la munición todavía provisionales,
observar un soldado inicial y uno desplegado, hacer que disparen y agoten su
munición, provocar un ataque de machete y daño, y comprobar por separado una
recarga mediante la ruta de verificación existente y la derrota del soldado.

**Acceptance Scenarios**:

1. **Given** el nivel actual, **When** aparece el soldado inicial o se despliega
   uno nuevo, **Then** ambos muestran el mismo diseño base colombiano, con
   casco, uniforme oliva y fusil reconocibles; permanecen en su posición real.
2. **Given** un soldado en modo fusil, **When** realiza un disparo real,
   **Then** su pose o animación comunica el disparo sin crear impactos ni
   consumir munición por cuenta de la animación; sin objetivo no simula fuego.
3. **Given** el último disparo de la carga, **When** cambia el modo real a
   machete, **Then** la postura y el arma del soldado pasan a machete; un ataque
   cuerpo a cuerpo real tiene una respuesta visual distinguible del disparo.
4. **Given** un soldado en modo machete, **When** se ejecuta una recarga válida
   por la ruta existente, **Then** recupera la presentación de fusil y conserva
   la moral real; esta feature no incorpora un botón para recargarlo.
5. **Given** un soldado vivo, **When** recibe daño o es derrotado,
   **Then** el daño tiene una respuesta visual breve y la derrota es reconocible;
   la liberación de su celda y la desaparición de su presencia jugable conservan
   el momento actual, sin esperar al final de una animación.

---

### User Story 2 - Leer el avance y la derrota del enemigo (Priority: P1)

Como jugador, quiero reconocer a la infantería enemiga y ver su avance, los
impactos recibidos y su derrota, para seguir el peligro que se acerca a la
posición defendida.

**Why this priority**: Sustituir el enemigo provisional completa la lectura de
los dos bandos y permite entender el combate sobre el terreno ya ilustrado.

**Independent Test**: Con el soldado todavía provisional si hace falta,
observar un enemigo que avanza, se detiene contra un soldado, recibe daño no
letal, muere y vuelve a aparecer reutilizado en una oleada posterior.

**Acceptance Scenarios**:

1. **Given** un enemigo recién aparecido, **When** avanza hacia la defensa,
   **Then** muestra infantería de silueta y uniforme gris/marrón distinguibles
   del soldado colombiano, con animación de avance alineada con su movimiento.
2. **Given** un enemigo detenido por contacto, **When** deja de desplazarse,
   **Then** abandona la animación de avance y conserva una postura de contacto;
   no se exige crear una acción de ataque nueva ni suponer que ya existe una
   animación o señal de ataque enemiga.
3. **Given** un enemigo que recibe un impacto no letal, **When** baja su salud
   real, **Then** se percibe un feedback de impacto y vuelve a la presentación
   correspondiente, sin modificar su velocidad, bloqueo o capacidad de daño.
4. **Given** un enemigo derrotado, **When** se procesa su muerte real,
   **Then** se comunica visualmente la derrota y aparece la munición según la
   regla actual, sin retrasar el crédito de la baja ni su devolución al pool.
5. **Given** una instancia reutilizada después de recibir daño o morir,
   **When** reaparece, **Then** inicia viva, visible y sin tintes, escalas,
   poses, animaciones o efectos residuales de su uso anterior.

---

### User Story 3 - Identificar y recoger la caja de munición (Priority: P2)

Como jugador, quiero identificar la munición que dejan los enemigos como una
caja de suministros, para reconocer qué puedo recoger sin confundirlo con
decoración del terreno.

**Why this priority**: La munición sostiene la economía actual; su nueva imagen
debe mejorar su lectura y conservar la recolección ya aprobada.

**Independent Test**: Con actores todavía provisionales si hace falta, provocar
una baja, localizar su caja sobre el terreno y recogerla con clic o toque;
repetir con reserva suficiente y una celda libre bajo la caja.

**Acceptance Scenarios**:

1. **Given** la muerte de un enemigo que suelta munición, **When** aparece su
   pickup, **Then** se muestra una caja oliva con motivo de cartuchos, separable
   del terreno y de los actores, en la posición real del drop.
2. **Given** una caja visible, **When** el jugador hace clic o toca su área
   actual de recolección, **Then** se recoge una sola vez, desaparece y suma
   exactamente la cantidad existente.
3. **Given** una caja sobre una celda libre y reserva suficiente para desplegar,
   **When** se recoge, **Then** no se despliega además un soldado ni se cobra
   munición con ese mismo gesto.

### Edge Cases

- El último disparo puede causar una baja y cambiar a machete en el mismo
  momento: la presentación final refleja el modo real y conserva el aumento
  de moral correspondiente, sin repetir el ataque por una transición visual.
- Daño y derrota pueden coincidir: la derrota prevalece y ningún efecto de
  impacto devuelve a un actor muerto a una pose viva.
- Una muerte se puede procesar en el mismo instante en que el enemigo vuelve
  al pool o el soldado desaparece. Su confirmación visual debe ser desacoplada
  de la presencia jugable; no deja un cadáver persistente o un objetivo falso.
- Un enemigo se puede reutilizar antes de terminar un efecto visual anterior:
  ese efecto no puede desplazarse con él ni modificar la nueva aparición.
- Dos instancias del mismo tipo pueden combatir en estados distintos: el
  estado visual de una no se comparte con las demás.
- Un enemigo detenido no debe deslizarse visualmente ni atacar por el simple
  hecho de que una animación se repita; el daño sigue dependiendo del combate.
- Varias cajas pueden solaparse: se conserva la regla existente de recolección
  y sus áreas, sin resolver el solapamiento mediante cambios de economía/input.
- El escalado de pantalla no debe ocultar las armas, confundir los bandos o
  desplazar el apoyo respecto de la posición jugable. Un viewport ancho centra
  el eje del combate sin aumentar el zoom ni dejar vacío el margen izquierdo;
  los recortes ajenos a esta corrección se registran sin rediseñar el tablero.
- Al redimensionar, el origen vertical efectivo del canvas sigue en y=0;
  centrar una cámara no significa fijar su posición y=0. Mostrar mundo x<0 en
  pantallas anchas es necesario; un límite izquierdo en cero no debe impedirlo.
- La mejora mate de contraste se conserva en la caída mediante un material de
  estilo compartido e inmutable. Daño/moral no contaminan ese material ni el
  snapshot neutro, y un efecto reciclado no retiene el material de otro uso.
- Si falta un recurso visual o no se puede verificar un entorno, se registra
  como fallo o pendiente; no se acepta un placeholder silencioso como arte final.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: La feature DEBE sustituir las tres representaciones provisionales
  de producción: soldado base, enemigo base y munición recolectable. No añade
  tipos de unidad o enemigo ni variantes con estadísticas diferentes.
- **FR-002**: El arte DEBE seguir la textura pictórica, materiales mates, luz
  difusa y paleta ocre/oliva del entorno aprobado. El soldado usa uniforme oliva,
  casco y armas legibles; el enemigo gris/marrón conserva una silueta distinta;
  la caja es oliva con cartuchos reconocibles. No se introducen pixel art,
  fotorrealismo, render 3D brillante, caricaturas deshumanizantes ni violencia
  gráfica. No se requiere una insignia, arma de modelo histórico preciso o
  nacionalidad enemiga nueva que no esté fijada por el diseño.
- **FR-003**: Las poses DEBEN adaptarse al avance central existente: el soldado
  mira hacia la amenaza y el enemigo hacia la defensa. Su apoyo en el suelo,
  escala y orientación resultan coherentes con el escenario; copiar los cinco
  carriles o la perspectiva del concepto queda fuera.
- **FR-004**: El soldado DEBE comunicar espera en fusil, disparo real, espera
  en machete y golpe real de machete mediante posturas/animaciones distintas.
  Agotar munición y recargar reflejan el modo real, sin depender solo del color.
- **FR-005**: El enemigo DEBE comunicar avance, detención por contacto, daño
  recibido y derrota. La postura de contacto no requiere animar un ataque
  enemigo ni crear una acción nueva.
- **FR-006**: Soldado y enemigo DEBEN ofrecer feedback de daño y derrota
  sincronizado con los hechos del combate. Los ataques, daños, drops, bajas,
  liberación de celdas, devolución de enemigos al pool y resultados de partida
  NO DEBEN esperar a las animaciones ni ser disparados por ellas.
- **FR-007**: El ciclo de reutilización de enemigos y de cualquier efecto
  visual reciclado DEBE reiniciar íntegramente su presentación. Se conserva el
  pooling existente; no se sustituye por destrucción/creación por cada muerte.
- **FR-008**: La caja DEBE distinguirse del decorado con forma, motivo y
  contraste local, permanecer en el drop actual y desaparecer al recogerse.
  No muestra cantidades o costos ilustrativos del concepto como datos reales.
- **FR-009**: La integración DEBE conservar salud, daño, munición, moral
  individual, costos, alcances, cadencias, movimiento, colisiones, zonas de
  detección/recolección, prioridades de objetivo, ocupación y oleadas actuales.
  También conserva la precedencia de recoger sobre desplegar y las condiciones
  de victoria/derrota. La imagen visual no desplaza las posiciones jugables.
- **FR-010**: La presentación DEBE conservar legibilidad y correspondencia con
  la interacción en los tamaños de la matriz de aceptación, en Web de escritorio
  y móvil, Android e iOS nativos. El soldado DEBE ser reconocible sobre el suelo
  sin overlays y también en grises, con luz/contorno mate discreto. El encuadre
  DEBE centrar horizontalmente el combate en pantallas anchas, conservar el origen
  vertical efectivo y la composición de iPad, sin mover las posiciones jugables.
  Cada resultado identifica su entorno real;
  una ejecución nativa local o un simulador no acredita navegador ni hardware
  físico de otra plataforma.
- **FR-011**: Cada recurso artístico nuevo DEBE tener procedencia y permisos
  documentados: autor o herramienta/fuente de creación, recurso original,
  transformaciones relevantes, condiciones de uso y atribución cuando aplique.
  La referencia conceptual no se integra como una imagen de combate con actores
  o interfaz incrustados. Se producen recursos separados sin terreno/HUD pegados.
- **FR-012**: Quedan fuera HUD, retratos, barras de salud/munición/moral,
  selección o casillas nuevas, controles de recarga, pantallas terminales,
  audio, nuevos proyectiles, explosiones, partículas ambientales, carteles,
  banderas y rediseño del terreno. La excepción T031 permite exclusivamente
  ajustar escala/offset y contraste mate del hijo visual del soldado, una cámara
  local sin zoom para equilibrar el encuadre y extender a la izquierda la
  cobertura decorativa de cielo/panorama/suelo con sus texturas existentes.
  Trincheras, actores y grid conservan sus posiciones. No se cambian InputMap,
  semántica de input, tablero, renderer, exportaciones, distribución ni publicación.

### Key Entities

- **Soldado visual**: diseño base colombiano y presentación por instancia de
  su modo, acción, daño y derrota; refleja el estado jugable existente.
- **Enemigo visual**: diseño de infantería base y presentación por instancia
  de avance, contacto, daño y derrota, reiniciable al reutilizarse.
- **Caja de munición**: presentación del pickup existente, con el mismo valor,
  posición y área de recolección; no es una nueva clase de recurso económico.
- **Recurso de arte**: imagen o conjunto de poses/animaciones, con procedencia,
  permisos y uso de producción identificables.
- **Matriz de aceptación**: entorno, tamaño/orientación, entrada, casos visuales
  y jugables, carga/rendimiento medidos y límites de la comprobación.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Las tres representaciones de producción se reemplazan y superan
  la comparación visual con el concepto en cinco aspectos: estilo pictórico,
  paleta/materiales, distinción de bandos, armas/caja reconocibles y apoyo en
  el suelo. No quedan bloques provisionales visibles en esos tres elementos.
- **SC-002**: Se verifican los seis casos del soldado — fusil/disparo,
  machete/golpe, cambio por agotamiento, recarga, daño y derrota — y los cuatro
  del enemigo — avance, contacto, daño y derrota — sin animar acciones ficticias
  ni retrasar sus consecuencias jugables. El cambio de modo es identificable
  también sin usar el tinte como única pista.
- **SC-003**: En diez reutilizaciones consecutivas de un enemigo que recibió
  daño o murió no aparecen poses, visibilidad, tintes, escalas o efectos
  residuales; dos instancias en estados distintos conservan su independencia.
- **SC-004**: Clic y toque conservan los cuatro resultados de la economía:
  recoger una sola vez sin desplegar, desplegar en libre con costo real,
  rechazar celda ocupada y rechazar fondos insuficientes. La regresión pertinente
  confirma cero cambios de datos de balance y de las invariantes de FR-009.
- **SC-005**: En al menos dos tamaños de escritorio y un tamaño móvil
  horizontal de la matriz se distinguen soldado, enemigo, sus armas y la caja;
  al cambiar de tamaño conservan su alineación jugable. Para la corrección I1,
  el soldado neutro tiene altura opaca objetivo aproximada de 72 unidades,
  anclaje en raíz+y24 y pivote estable con error ≤1 unidad; en CSS 794×305 su
  silueta neutra mide al menos 32 CSS px de alto, sin contar transparencia,
  contorno o pulsos. Se reconoce sobre el suelo sin overlay y también en grises.
  El eje mundo x=576 se proyecta al 50 % del ancho del viewport lógico con error
  ≤1 unidad y el origen vertical efectivo del canvas permanece en y=0, sin zoom.
  Se conserva la distribución iPad 1152×864 y se equilibran márgenes en Xiaomi
  1440×648 y Web aproximadamente 1684×648, sin vacíos decorativos a la izquierda.
  Web y apps nativas tienen resultados separados, incluidos pendientes y límites.
- **SC-006**: Una partida manual completa hasta un resultado terminal no
  presenta errores críticos, actores ausentes por reciclado, bloqueos por
  animación ni cambios de reglas. Victoria y derrota se verifican además por
  separado con las rutas de comprobación existentes.
- **SC-007**: Se mantiene el objetivo constitucional de 60 FPS estables en
  gameplay típico sobre el Xiaomi 11T Pro físico `2107113SG` de 2021, referencia
  provisional exclusiva de 004 autorizada el 2026-10-16 y recogida en la
  constitución 2.2.0. Se requieren nuevas mediciones y QA; la autorización no
  aprueba rendimiento ni certifica equipos menos potentes. Se mide carga y
  rendimiento por separado en los navegadores/dispositivos de aceptación Web
  y en nativo, incluso en el mismo Xiaomi; no se heredan resultados de 002/003.
  La autorización no acredita iOS. La carga se registra sin inventar el límite
  aún pendiente de la constitución.
- **SC-008**: El 100 % de los recursos artísticos nuevos tiene procedencia y
  permisos documentados. Cada escenario exigido queda identificado como
  aprobado, fallido o pendiente en la revisión de entrega; los resultados y
  el veredicto independiente de QA se resumen en el PR, sin archivos nuevos
  de evidencias en Git ni afirmaciones de aceptación durante esta preparación.

## Assumptions

- La solicitud inicial autorizó la preparación con Spec Kit; la ejecución de
  I1 se autorizó después y conserva su aprobación histórica sobre `87a39c6`.
  La enmienda T031 para el nuevo feedback pasó QA T032 y su propio ciclo
  RED → desarrollo → GREEN/visual → QA funcional T036. La consolidación y
  entrega se siguen en las tareas; I2/I3 no se inician con esta corrección.
- Se conserva la versión integrada de 001, 002 y 003 como línea base; el
  concepto aporta la dirección artística y los valores reales del juego
  prevalecen sobre números, barras, distribución y botones ilustrados.
- Un diseño por bando y una caja son suficientes para este incremento de
  acabado. No se pide fidelidad documental exacta de uniformes/armas, múltiples
  direcciones, esqueletos complejos o cadáveres persistentes.
- El nivel todavía carece de HUD y controles de recarga integrados. La recarga
  se verifica por la ruta existente, sin presentarla como interacción disponible
  para el jugador ni convertir su acceso en requisito de esta feature.
- Las animaciones nuevas requieren adaptación visual a hechos existentes;
  no se presume que ya haya señales de disparo/ataque, animaciones de muerte o
  una espera antes de reciclar. El plan delimitará esa adaptación y sus pruebas.
- Los efectos breves de daño/derrota que se necesiten para comunicar los hechos
  forman parte de los estados básicos; no abren un sistema de efectos de combate
  completo ni cambian el ciclo de vida de los actores.
- La referencia física provisional exclusiva de 004 sigue siendo el Xiaomi
  11T Pro `2107113SG` de 2021, autorizado el 2026-10-16 por la constitución
  2.2.0. Desde el 2026-10-19 la persona informa que ya no será posible realizar
  nuevas pruebas físicas y autoriza continuar con Android Emulator conforme a
  la matriz de [quickstart](quickstart.md#4-verificación-visual-y-gestos-reales).
  La ejecución emulada acredita solo su entorno; no sustituye las nuevas
  mediciones físicas de SC-007, cuya aceptación permanece pendiente. Se
  conservan las aprobaciones históricas y sus límites, sin heredar resultados
  de 002/003 ni certificar hardware desde el emulador.
- La producción de arte y su revisión visual tienen verificación proporcional.
  Cualquier comportamiento visual nuevo verificable automáticamente sigue
  tester RED → desarrollo → tester GREEN → QA, con regresión jugable pertinente.
  El arte sin lógica nueva no necesita fallos artificiales. Solo el orquestador
  marcará tareas aprobadas después de QA.
- La corrección I1 reutiliza el atlas existente; no exige regenerar el PNG.
  Aumenta solo la representación visual y su contraste, sin cambiar cuerpos
  48×48, grid 96×96, detectores, radio de picking 20 o invariantes de FR-009.
