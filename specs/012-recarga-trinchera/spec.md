# Feature Specification: Recarga directa sobre la trinchera

**Feature ID**: `012-recarga-trinchera` | **Planned Branch**: `codex/012-recarga-trinchera`
**Created**: 2026-10-29 | **Status**: revisión visual de `012-I1` aprobada funcionalmente en T018 sobre `87eedb3`; seguimiento de integración en [tasks.md](tasks.md) y [PR #50](https://github.com/Juanpvivas/demons/pull/50).
**Tracking**: [Issue #49](https://github.com/Juanpvivas/demons/issues/49).
**Input vigente**: sustituir «Recargar» por brillo rojo en la trinchera y tocarla para recargar. Confirmación: «Rojo tenue sin titilar; el pulso aparece cuando ya puedes recargar».

## Decisiones e historia conservada

La entrega anterior trasladó «Recargar» del panel a un botón sobre cada hogar. T001–T012 y sus aprobaciones describen esa revisión hasta `994b176`; no se reconstruye su TDD ni se cambian sus casillas. La persona probó aquella copia en el Xiaomi y confirmó que funciona, pero solicitó reemplazar su presentación. Esa observación no certifica el efecto nuevo, FPS ni publicación. T013 en adelante mantiene la acción directa y sustituye texto, decoración de botón y área flotante por la señal roja y el toque sobre la propia trinchera.

## User Scenarios & Testing

### User Story 1 — Reconocer y recargar desde la propia trinchera (Priority: P1)

Como jugador, quiero que la trinchera de un soldado sin balas llame mi atención mediante brillo rojo y poder tocarla para recargarlo en una sola acción, incluso si está fuera, sin rótulos que alteren el estilo del juego.

**Why this priority**: vincula la orden con el hogar y conserva el arte como parte de la interacción.
**Independent Test**: agotar la carga de dos dueños sin seleccionarlos; con fondos, observar el pulso y tocar una trinchera. Sólo su dueño se recarga/regresa con un cobro y su trinchera vuelve inmediatamente al aspecto normal.

**Acceptance Scenarios**:

1. **Given** un dueño vivo con carga, **When** agota sus balas y puede recargar, **Then** su propia trinchera pulsa con brillo rojo sin selección previa, texto, cartel ni botón visible, aunque el soldado esté fuera.
2. **Given** un dueño vivo vacío y fondos suficientes en partida activa, **When** se toca su trinchera una vez, **Then** se cobra una recarga, se repone su carga y cesa la señal roja sin espera añadida; conserva salud/moral y regreso físico actuales.
3. **Given** dos dueños vacíos, **When** se toca la trinchera de uno sin selección o con otro seleccionado, **Then** sólo se ordena la recarga del dueño de esa trinchera.
4. **Given** un dueño vivo vacío sin fondos, **When** se observa o toca su trinchera, **Then** aparece rojo tenue estático, sin pulso ni gasto; al disponer de fondos pulsa sólo si es elegible.
5. **Given** pausa, terminal, aceptación de orden o regreso activo, **When** llega otra pulsación, **Then** no acepta otra orden/cobro y no mantiene un pulso de disponibilidad. Muerte, retirada o cierre normalizan la trinchera y retiran su acción.
6. **Given** una intención capturada para un dueño que muere o es reemplazado, **When** se procesa, **Then** no cobra ni recarga a su sucesor; su presentación refleja únicamente el estado nuevo.
7. **Given** varias trincheras señaladas, resize y una nueva partida, **When** se interactúa con ratón/toque, **Then** cada zona activa sigue sobre su trinchera sin seguir al actor, invadir vecinos, activar tablero debajo o conservar controles/animaciones antiguos.

### Edge Cases

- Pulsaciones repetidas, toque con ratón emulado y callbacks síncronos del gasto: un cobro como máximo por orden aceptada.
- Baja/reemplazo entre press y release; otro intento o celda sin dueño válido: sin efectos económicos ni visuales sobre el sucesor.
- Cinco dueños vacíos: recargar uno normaliza sólo su trinchera; el saldo compartido puede pasar las demás de pulso a tenue.
- Pausa sin retirar escena: detener explícitamente el pulso por estado de partida; reanudar sólo si sigue elegible. Victoria/derrota, menú/Retry no dejan efectos antiguos.
- La zona de una trinchera vacía, incluso deshabilitada, consume el gesto. Fuera se conserva pickup→selección/despliegue. Un hogar cargado no mantiene zona de recarga activa.

## Requirements

### Functional Requirements

- **FR-001**: Cada hogar DEBE señalar automáticamente a su dueño vivo con carga cero, sin selección, incluso fuera. Carga positiva, ausencia/muerte o cierre DEBEN dejar aspecto normal y ninguna acción de recarga activa.
- **FR-002**: La señal DEBE ser brillo rojo sobre el arte de la propia trinchera, sin texto/cartel/decoración de botón. DEBE preservar textura, tamaño, posición y orden visual; no teñir actor, barra de vida, HUD o vecinos. Su zona táctil DEBE corresponder a esa trinchera tras resize y no seguir al actor.
- **FR-003**: Un clic/toque válido sobre la propia trinchera DEBE recargar a su dueño actual en un gesto, independiente de selección y sin área flotante que deba pulsarse encima del hogar.
- **FR-004**: Sin fondos, la trinchera vacía DEBE mostrarse roja tenue y estática, sin aceptar gasto. El pulso rojo DEBE existir sólo mientras el dueño pueda recargar en partida activa; pausa, terminal, aceptación o regreso DEBEN impedir otra orden y detener el pulso. Se conservan coste, cobro único, carga, salud/moral y regreso actuales.
- **FR-005**: Al reponer la carga, el rojo DEBE desaparecer sin demora añadida. Muerte, retirada, reemplazo/cierre DEBEN invalidar la acción previa y restaurar la presentación; ninguna intención o animación antigua DEBE afectar al sucesor ni a otro hogar.
- **FR-006**: El panel DEBE conservar fila, carga/capacidad, moral y regreso como información, sin botón ni segunda acción visible de recarga.
- **FR-007**: Ratón y toque DEBEN realizar la misma orden una sola vez. La zona, incluso deshabilitada, DEBE consumir el gesto sin recoger, seleccionar o desplegar debajo; fuera se conserva el enrutamiento actual. Los hogares cargados conservan entrada/selección normales.
- **FR-008**: Acción y efecto DEBEN reflejar altas/bajas, carga/fondos/partida y resize; menú/Retry NO DEBEN conservar controles, conexiones o animaciones útiles del intento previo. No cambian combate, economía, oleadas, terminales, cámara ni destinos.
- **FR-009**: Los cinco hogares DEBEN tener estado visual independiente. Repetir un estado no duplica pulsos; detener uno no modifica otros salvo por fondos/partida compartidos. El pulso no oculta la trinchera completa ni produce saltos de posición/tamaño.

### Key Entities

- **Trinchera de origen**: hogar estable cuyo dueño vivo determina el destinatario.
- **Señal de recarga**: normal, rojo tenue estático o rojo pulsante según carga/elegibilidad actuales.
- **Zona de recarga**: área sin decoración sobre la trinchera que acepta el gesto para ese dueño concreto.
- **Selección informativa**: fila, carga y moral independientes del destinatario de la recarga.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Los cinco hogares vacíos muestran la señal correcta; cero textos/carteles «Recargar». Dueños cargados, muertos/ausentes y cierre dejan cero efectos rojos o acciones antiguas.
- **SC-002**: Un gesto válido sobre la trinchera realiza exactamente un cobro/recarga del dueño indicado sin selección; estados no elegibles e intenciones obsoletas realizan cero efectos económicos adicionales.
- **SC-003**: En cada entorno observado, la zona coincide con la trinchera tras resize, es utilizable y no invade vecinos; el rojo preserva lectura de actores/barras/HUD y el gesto no activa el tablero debajo.
- **SC-004**: El panel conserva su información y cero botones antiguos; menú/Retry deja cero controles, conexiones o animaciones útiles del intento anterior; combate, salud/moral, economía y regreso se conservan.
- **SC-005**: Sin fondos o en pausa/terminal hay cero pulsos de disponibilidad. Añadir fondos/reanudar inicia un único pulso sólo donde sea elegible; modificar un hogar no altera los restantes salvo por fondos/partida compartidos.

## Dependencies & Scope

- Reutiliza recarga/selección de 005-I3 y autoridad por hogar/identidad de 012; no API remota, persistencia, permisos o balance nuevos.
- Revisión visual del mismo `012-I1`, Issue #49 y PR #50 en borrador. TDD para estado/entrada y revisión visual para el acabado; no hereda aprobación del botón anterior.
- Web en computador y Android/iOS como apps instaladas; sin Web móvil, campaña FPS de 006, nueva versión ni distribución. La excepción de beta 1.0.1 no se extiende a 012.

## Alcance de la aprobación funcional

T008 y la observación humana del Xiaomi corresponden al botón anterior; no certifican el brillo. T018 aprueba la revisión roja de `87eedb3` con fuente `6e7b65b`, según el alcance observado; seguimiento final en [tareas](tasks.md) y [PR #50](https://github.com/Juanpvivas/demons/pull/50). Chrome comprobó aspecto/acción con un fixture declarado; sus dimensiones DOM/canvas960 y DPR1 no equivalen al viewport lógico probado por GUT. El APK normal de QA Mobile fue verificado, sin instalación: la confirmación USB Android rechazó el preview (`USER_RESTRICTED`), por lo que el gesto nativo nuevo no quedó observado. iOS usó bootstrap anterior Compatibility y fixture de autoarranque: aspecto de dos hogares pulsantes/tres tenues, sin certificar período, gestos, IPA final, hardware o FPS; su franja gris superior tiene antecedente en 010 y no se atribuye al efecto. Se conservan el cruce previo aviso de oleada/primera barra de vida y avisos transitorios de `queue_free` examinados en casos acotados, sin concluir ausencia general de fugas. La publicación y certificación física conservan su gate separado.
