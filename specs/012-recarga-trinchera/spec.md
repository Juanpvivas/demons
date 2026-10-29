# Feature Specification: Recarga directa sobre la trinchera

**Feature ID**: `012-recarga-trinchera` | **Planned Branch**: `codex/012-recarga-trinchera`
**Created**: 2026-10-29 | **Status**: preparación; implementación y QA de entrega pendientes.
**Tracking**: [Issue #49](https://github.com/Juanpvivas/demons/issues/49).
**Input**: mover «Recargar» sobre la trinchera; confirmación «Sí, botón directo en cada trinchera».
**Perfil confirmado**: cada trinchera muestra automáticamente su botón cuando su dueño vivo se queda sin balas, sin selección previa. Sustituye la acción del panel; conserva sus reglas, texto, estilo y tamaño mínimo actuales.

## User Scenarios & Testing

### User Story 1 — Recargar directamente desde el hogar (Priority: P1)

Como jugador, quiero pulsar «Recargar» sobre la trinchera del soldado sin balas para darle la orden en una sola acción, aunque esté combatiendo fuera.

**Why this priority**: evita buscar la orden en el panel y vincula cada recarga con su trinchera.
**Independent Test**: agotar la carga de dos soldados sin seleccionarlos, activar el botón de uno y comprobar que sólo su dueño se recarga/regresa con un único cobro.

**Acceptance Scenarios**:

1. **Given** un dueño vivo con carga, **When** agota sus balas dentro o fuera de su trinchera, **Then** aparece «Recargar» sobre su hogar, sin seleccionar antes al soldado.
2. **Given** un dueño vivo sin balas y fondos suficientes en partida activa, **When** se pulsa su botón una vez, **Then** se cobra una recarga, se repone su carga y se oculta el botón; conserva salud/moral y, si está fuera, regresa físicamente con las reglas actuales.
3. **Given** dos dueños sin balas, **When** se activa el botón de uno sin selección o con otro seleccionado, **Then** sólo se ordena la recarga del dueño de esa trinchera; la selección informativa no determina el destinatario.
4. **Given** un dueño sin balas pero sin fondos, **When** se observa o pulsa el botón, **Then** permanece visible y deshabilitado, sin gasto; vuelve a habilitarse al disponer de fondos si sigue siendo elegible.
5. **Given** pausa, fin de partida, aceptación de una orden o regreso activo, **When** llega una nueva pulsación, **Then** no acepta otra recarga ni otro cobro; al morir el dueño o cerrar el intento no queda una acción utilizable suya.
6. **Given** una intención capturada para un dueño que muere o es reemplazado, **When** se procesa, **Then** no cobra ni recarga a su sucesor, aunque comparta la trinchera.
7. **Given** varios botones, un cambio de tamaño y una nueva partida, **When** se interactúa con ratón o toque, **Then** cada botón sigue sobre su hogar, conserva legibilidad y una acción por gesto; no produce recogida/despliegue debajo ni deja controles del intento anterior.

### Edge Cases

- Pulsaciones repetidas, toque con ratón emulado y callbacks síncronos durante el gasto: un cobro como máximo por orden aceptada.
- Baja/reemplazo entre pulsación y ejecución; órdenes de otro intento o de una celda sin dueño válido: sin efectos.
- Cinco dueños sin munición a la vez; al recargar uno no se ocultan ni redirigen los demás botones, aunque el saldo restante deshabilite alguno.
- Pausa y reanudación, derrota/victoria, regreso al menú y Retry: estado coherente sin acciones obsoletas.
- Pickup sobre el área de un botón: el gesto pertenece a la UI; fuera de botones se conserva la precedencia de recogida sobre selección/despliegue.

## Requirements

### Functional Requirements

- **FR-001**: Cada trinchera DEBE mostrar automáticamente un único botón «Recargar» cuando su dueño esté vivo y tenga carga cero, sin requerir selección; con carga positiva o sin dueño vivo NO DEBE mostrar esa acción.
- **FR-002**: El botón DEBE anclarse sobre la trinchera de origen, incluso mientras el soldado está fuera; DEBE conservar el texto, estilo y tamaño mínimo actuales de 112×48, adaptarse al área visible y evitar tapar barras de vida, HUD u otros botones.
- **FR-003**: Una pulsación válida DEBE ordenar la recarga del dueño actual de esa trinchera, independientemente de la selección informativa y sin exigir un segundo gesto.
- **FR-004**: La recarga DEBE conservar elegibilidad, coste, cobro único, reposición de carga, salud/moral y regreso físico actuales; sin fondos, el botón permanece visible y deshabilitado. Pausa, estado terminal, orden en aceptación o regreso activo NO DEBEN permitir otra orden.
- **FR-005**: Aceptar la recarga DEBE retirar el botón al reponerse la carga, sin demora visual añadida. La muerte, retirada o cierre del intento DEBEN invalidar su acción; ninguna intención antigua DEBE actuar sobre otro dueño o intento.
- **FR-006**: El panel de selección DEBE conservar fila, carga/capacidad, moral y aviso de regreso como información; DEBE eliminar su antiguo botón de recarga, sin duplicar la acción visible.
- **FR-007**: Ratón y toque DEBEN producir la misma orden una sola vez; el área de los botones, incluidos los deshabilitados, DEBE consumir el gesto sin recoger, seleccionar o desplegar debajo. Fuera de ellos se conserva el enrutamiento actual de entrada.
- **FR-008**: La UI DEBE reflejar altas, bajas, cambios de carga/fondos/partida y redimensionamiento; menú/Retry NO DEBEN conservar botones o intenciones de la partida anterior. No cambian combate, economía, oleadas, victoria/derrota ni destinos del producto.

### Key Entities

- **Trinchera de origen**: hogar estable cuyo ocupante vivo determina a quién pertenece la orden.
- **Acción de recarga**: botón individual que refleja la elegibilidad actual y expresa una intención para ese dueño concreto.
- **Selección informativa**: lectura de fila, carga y moral, independiente del destinatario de una recarga directa.

## Success Criteria

### Measurable Outcomes

- **SC-001**: En las cinco trincheras, al llegar la carga a cero aparece una sola acción sobre el hogar correcto; no aparece para dueños cargados, muertos o ausentes.
- **SC-002**: Una pulsación válida realiza exactamente un cobro y una recarga del dueño indicado sin selección previa; los casos no elegibles y las intenciones obsoletas realizan cero cobros/recargas adicionales.
- **SC-003**: En cada entorno probado, los botones permanecen legibles y utilizables tras redimensionar, sin superponerse a los elementos indicados, y el gesto sobre ellos no desencadena ninguna acción del tablero.
- **SC-004**: El panel conserva su información con cero botones antiguos; tras menú/Retry no hay acciones del intento anterior y se conservan resultados de combate, salud/moral, economía y regreso.

## Dependencies & Scope

- Reutiliza la recarga y la selección integradas por 005-I3 y la presentación actual de Monte Calvo; no introduce API remota, persistencia, permisos ni nuevos datos de balance.
- Un único incremento funcional `012-I1`, con preparación Spec Kit y ejecución por roles/TDD/QA. La preparación no acredita implementación ni pruebas ejecutadas.
- Web en navegador de computador y Android/iOS como apps instaladas; no pruebas Web móviles, campaña FPS de 006, cambio de versión ni distribución. La excepción de beta 1.0.1 no se extiende a 012.
