# Feature Specification: Monte Calvo jugable en web para itch.io

**Feature ID**: `003-web-itchio`

**Planned Branch**: `codex/003-web-itchio` (preparada por el orquestador)

**Created**: 2026-10-15

**Status**: Preparación; implementación y aceptación pendientes

**Input**: «Sí, creo que tenemos que hacer que funcione en web para poder subir el juego al portal itch.io».

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Abrir Monte Calvo sin instalar el juego (Priority: P1)

Como jugador, quiero abrir una versión web de Monte Calvo y ver el nivel actual,
para probar el juego directamente desde un navegador de computador.

**Why this priority**: Es el primer incremento que permite compartir una demo
accesible mediante un enlace, conservando lo construido.

**Independent Test**: Servir el paquete web en un entorno de prueba y abrirlo
con una sesión nueva del navegador; Monte Calvo carga con su terreno y sus
trincheras, y comienza el combate sin instalar una aplicación.

**Acceptance Scenarios**:

1. **Given** una sesión nueva con conexión y un navegador incluido en la matriz
   validada, **When** el jugador abre la demo y activa el inicio si se le pide,
   **Then** ve Monte Calvo con su arte actual y comienza la partida.
2. **Given** el nivel cargado, **When** comienza el combate,
   **Then** el soldado dispara automáticamente y las oleadas avanzan como en la
   versión actual, sin errores que detengan la partida.
3. **Given** una partida en curso, **When** el jugador recarga la página,
   **Then** comienza una nueva sesión, sin promesa de recuperar la partida.

---

### User Story 2 - Jugar con clic y con toque en el navegador (Priority: P1)

Como jugador de computador o teléfono, quiero recoger munición y desplegar
soldados con las reglas actuales, para jugar Monte Calvo desde ambos tamaños
de pantalla.

**Why this priority**: Una pantalla que solo reproduce el combate no basta como
demo del juego; las decisiones de recolección y despliegue deben funcionar.

**Independent Test**: En navegador de escritorio y en Chrome de un Android
físico, recoger munición, desplegar en posición libre e intentar de nuevo en
una ocupada y sin fondos; comparar los resultados con las reglas existentes.

**Acceptance Scenarios**:

1. **Given** munición amarilla visible, **When** el jugador hace clic o tap sobre
   ella, **Then** se recoge una sola vez y la acción no crea un soldado adicional.
2. **Given** reserva suficiente y una celda libre, **When** el jugador hace clic
   o tap allí, **Then** aparece exactamente un soldado y se descuenta el costo
   actual; repetir en una celda ocupada no crea duplicados ni gasta reserva.
3. **Given** reserva insuficiente, **When** el jugador intenta desplegar,
   **Then** no aparece otro soldado ni se altera la reserva.
4. **Given** una partida en los tamaños de pantalla validados,
   **When** el jugador redimensiona la ventana o juega en horizontal en el
   teléfono, **Then** conserva acceso visual y táctil al área de combate sin
   que las acciones se desplacen respecto de lo mostrado.
5. **Given** la partida iniciada, **When** se juega hasta un resultado terminal,
   **Then** el combate conserva las condiciones existentes de victoria/derrota;
   se verifica además cada resultado por separado con los recursos de prueba.

---

### User Story 3 - Disponer de una entrega lista para cargar en itch.io (Priority: P2)

Como responsable del juego, quiero recibir el paquete web y las instrucciones
de carga, para poder subirlo a itch.io cuando decida compartir la demo.

**Why this priority**: Hace repetible la entrega y evita depender de una
preparación manual distinta en cada versión.

**Independent Test**: Generar el paquete desde un checkout limpio siguiendo la
guía, descomprimirlo y servirlo sin mover sus archivos; comprobar el inicio y
la lista exacta de navegadores/dispositivos probados.

**Acceptance Scenarios**:

1. **Given** el repositorio y las herramientas documentadas,
   **When** el responsable sigue la guía de exportación,
   **Then** obtiene un único paquete web con el archivo de inicio y todos los
   archivos que este necesita, listo para seleccionar al cargar un juego web.
2. **Given** el paquete final, **When** se revisa su contenido,
   **Then** contiene el juego y sus licencias necesarias, sin pruebas,
   herramientas de desarrollo, documentación interna ni credenciales.
3. **Given** una nueva revisión del proyecto, **When** se solicita su generación
   automática, **Then** se obtiene un artefacto descargable identificable por
   versión y revisión, sin publicar el juego ni operar la cuenta de itch.io.

### Edge Cases

- Navegador sin los requisitos gráficos: no se promete compatibilidad; la guía
  identifica los requisitos y conserva el mensaje de fallo del exportador.
- Carga interrumpida o archivo ausente: se registra el fallo y se impide aceptar
  un paquete incompleto como listo para subir.
- Pantalla vertical muy estrecha: la primera demo se valida en horizontal;
  la guía pide girar el teléfono. No se rediseña el tablero para vertical.
- Toque que produce también un clic: una interacción no debe cobrar o
  desplegar dos veces, ni recoger y desplegar en el mismo gesto.
- Cambio de pestaña, pérdida de foco o suspensión del navegador: se comprueba
  el regreso sin cierre o error crítico y se documenta la suspensión observada;
  no se añade avance fuera de línea ni persistencia.
- Bloqueo de audio automático: si existen sonidos en el juego exportado,
  comienzan tras una interacción admitida; no se introduce música nueva.
- Un navegador o dispositivo no disponible se declara «no probado», sin usar
  una prueba de escritorio como sustituto de toque físico o de otro navegador.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: La demo DEBE poder abrir Monte Calvo en un navegador compatible
  sin instalar el juego, con el terreno y las trincheras actuales visibles.
- **FR-002**: La demo DEBE conservar los costos, cantidades de munición, moral,
  salud, daño, cadencias, alcance, ocupación y oleadas de la versión actual.
- **FR-003**: La recolección y el despliegue DEBEN conservar sus reglas con
  ratón y con toque, incluyendo celda ocupada, fondos insuficientes y una sola
  acción efectiva por interacción.
- **FR-004**: En los tamaños de pantalla incluidos en la matriz validada, el
  área necesaria para jugar DEBE permanecer visible y las acciones DEBEN
  corresponder a la posición mostrada, también después de redimensionar.
- **FR-005**: La demo DEBE conservar el combate automático, el cambio a machete
  y los resultados terminales actuales, sin exigir nuevos controles al jugador.
- **FR-006**: La entrega DEBE ser un paquete autocontenido del juego web, que
  funcione al descomprimirlo y servirlo manteniendo su estructura.
- **FR-007**: La generación del paquete DEBE ser repetible localmente y mediante
  el proceso automático del repositorio, con registro de versión, revisión,
  tamaño y resultado de verificación.
- **FR-008**: La entrega DEBE incluir una guía para cargarla como juego de
  navegador en itch.io, con tamaño inicial recomendado, opción móvil y pasos
  de comprobación antes de hacer pública la página.
- **FR-009**: El paquete DEBE excluir pruebas, herramientas y documentación
  internas, credenciales y archivos ajenos a su ejecución; conserva las
  atribuciones y licencias que correspondan.
- **FR-010**: La guía DEBE distinguir navegadores/dispositivos probados, fallos
  conocidos y plataformas no probadas; no anuncia soporte universal.
- **FR-011**: La incorporación web DEBE conservar la configuración y los
  procesos de distribución nativos de Android e iOS, sin subir nuevos builds
  móviles como efecto de esta entrega.
- **FR-012**: La entrega NO DEBE crear cuentas, configurar cobros/donaciones,
  subir archivos a itch.io ni publicar una página automáticamente.

### Key Entities

- **Entrega web**: juego exportado, archivo de inicio, archivos compañeros,
  versión/revisión de origen y tamaño del paquete.
- **Matriz de validación**: navegador, versión, dispositivo, tamaño/orientación,
  interacción usada, casos verificados y limitaciones.
- **Partida existente**: soldados, enemigos, munición, moral, oleadas y estado
  terminal; conserva sus datos y reglas, sin nuevas entidades de gameplay.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El paquete final abre Monte Calvo en 3 de 3 cargas nuevas en el
  navegador de escritorio validado, sin instalación ni fallo crítico.
- **SC-002**: En escritorio y Android físico se completan los cuatro casos de
  interacción — recoger, desplegar, rechazar ocupada y rechazar sin fondos —
  sin duplicación ni cambio de costo, con evidencia por caso.
- **SC-003**: En al menos dos tamaños de escritorio y una sesión Android
  horizontal se ven el combate y sus posiciones de interacción; después de
  redimensionar se conserva la correspondencia entre imagen y acción.
- **SC-004**: Se registra al menos una partida manual hasta un resultado
  terminal, sin cierre/error crítico, y se verifican por separado victoria y
  derrota, conservando las reglas existentes.
- **SC-005**: Una segunda generación desde checkout limpio produce un paquete
  que inicia al servirse sin reorganizar archivos; todas sus dependencias
  están presentes y no incluye los contenidos internos excluidos.
- **SC-006**: La entrega incluye una matriz con el 100 % de los casos exigidos
  identificados como aprobados, fallidos o no probados, y mediciones de carga,
  tamaño y rendimiento de las sesiones disponibles, sin confundirlas con la
  validación sostenida pendiente de Monte Calvo.
- **SC-007**: La revisión de cambios confirma cero alteraciones de reglas,
  balance, arte y datos de la partida, y conserva los procesos nativos de
  Android/iOS; las correcciones de compatibilidad indispensables se justifican
  y validan de forma específica antes de aceptarse.

## Assumptions

- La prioridad cambia a habilitar web para itch.io. La feature 002 mantiene su
  estado histórico y sus validaciones pendientes; esta feature no la cierra.
- El primer objetivo publicable es una demo de Monte Calvo actual, no una
  promesa de juego terminado. El HUD ausente, controles nuevos de recarga,
  tutorial, menú, guardado, nuevas unidades y balance quedan fuera de alcance.
- Web en escritorio y móvil, más Android e iOS nativos, forman el objetivo del
  proyecto; se documenta la enmienda de plataformas antes de implementar. No
  se generan instaladores nativos de Windows/macOS/Linux en esta feature.
- Están disponibles un navegador Chromium de escritorio y un Xiaomi Android
  físico. Firefox, Safari y navegador iOS se comprueban si están disponibles;
  sus ausencias se declaran sin bloquear la preparación de un paquete acotado.
- La primera demo móvil se usa en horizontal. Se requiere conexión para la
  carga inicial; no se promete funcionamiento sin conexión ni sincronización.
- La cuenta, textos comerciales, permisos de publicación y monetización de
  itch.io se resuelven aparte; el resultado de esta feature es el paquete y su
  guía, sin intervenir la cuenta del usuario.
- La calidad y rendimiento constitucionales continúan vigentes. Preparar el
  paquete no autoriza difusión a testers externos hasta el smoke exigido, ni
  acredita pruebas físicas o rendimiento sostenido que no se hayan ejecutado.
