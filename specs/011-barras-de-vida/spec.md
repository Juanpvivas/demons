# Feature Specification: Barras de vida

**Feature ID**: `011-barras-de-vida` | **Planned Branch**: `codex/011-barras-de-vida`
**Created**: 2026-10-24 | **Status**: Preparación aprobada; implementación pendiente
**Tracking**: [Issue #42](https://github.com/Juanpvivas/demons/issues/42).
**Input**: «Vamos a trabajar con una barra de vida tanto para los soldados enemigos como para los colombianos».
**Perfil confirmado**: siempre visibles mientras viven, sin números, sobre la cabeza; borde oscuro y relleno mate oliva (>50 %), ocre (>25–50 %) y rojo apagado (≤25 %). Baja inmediata y retirada al caer.

## User Scenarios & Testing

### User Story 1 — Reconocer la vida de ambos bandos (Priority: P1)

Como jugador, quiero ver cuánta vida conservan los colombianos y enemigos para interpretar el combate y anticipar sus bajas.

**Why this priority**: ambos bandos ya reciben daño; hoy su vida restante no se comunica sobre el campo.
**Independent Test**: iniciar una partida, observar ambos bandos a vida completa, recibir daño hasta caer, recargar, retirar/reutilizar enemigos e iniciar otra partida; comprobar barras y continuidad del juego.

**Acceptance Scenarios**:

1. **Given** un colombiano o enemigo vivo, **When** aparece o avanza, **Then** muestra siempre una barra completa al iniciar con toda su vida, encima del casco y sin números.
2. **Given** un combatiente vivo, **When** recibe daño, **Then** el relleno representa inmediatamente su proporción de vida restante; es oliva por encima del 50 %, ocre por encima del 25 % hasta el 50 % inclusive y rojo apagado al 25 % o menos.
3. **Given** daño letal, **When** el combatiente cae, **Then** su barra desaparece desde la baja y no acompaña la animación de caída.
4. **Given** un colombiano herido, **When** recarga, avanza, regresa o cambia de arma, **Then** conserva la vida y su barra, sin inversión, iluminación ni cambios de la corrida aprobada.
5. **Given** enemigos retirados o una partida anterior, **When** reaparecen enemigos o comienza otra partida, **Then** cada barra refleja sólo la vida de su combatiente actual, sin restos de la activación anterior.

### Edge Cases

- Los límites exactos de 50 % y 25 % pertenecen a ocre y rojo, respectivamente; vida completa siempre usa oliva.
- Varios combatientes heridos conservan rellenos y colores independientes.
- Retirar y reactivar inmediatamente un enemigo no oculta su nueva barra ni conserva el máximo anterior.
- Daño superior a la vida restante no produce relleno negativo; un actor inactivo o sin máximo válido no muestra barra.
- Al pausar, redimensionar o usar entrada táctil/mouse la barra sigue alineada, sin interceptar acciones ni tapar el HUD.

## Requirements

### Functional Requirements

- **FR-001**: Cada colombiano y enemigo vivo y activo DEBE mostrar siempre una barra sobre su cabeza, incluso a vida completa, sin cifras ni porcentajes.
- **FR-002**: El relleno DEBE representar la proporción entre vida actual y máxima de ese combatiente y actualizarse en el mismo cambio de daño, sin retraso animado ni alterar la vida real.
- **FR-003**: El borde DEBE ser oscuro y el relleno mate: oliva si la proporción es >50 %, ocre si es >25 % y ≤50 %, rojo apagado si es ≤25 %; cada barra DEBE mantener su estado independiente.
- **FR-004**: La barra DEBE ocultarse al morir o retirarse el combatiente; cada aparición posterior DEBE restablecer máximo, relleno y color de su activación actual, incluso con retirada/reaparición inmediata.
- **FR-005**: La barra DEBE conservar posición legible sobre el casco durante avance, regreso, orientación, impacto y pausa; NO DEBE heredar parpadeos o iluminación del soldado, alterar animaciones ni capturar entrada.
- **FR-006**: Vida máxima, daño, moral, munición, cadencia, alcance, movimiento, recompensas, oleadas y condiciones de victoria/derrota DEBEN conservar sus valores y reglas; recargar NO DEBE curar.
- **FR-007**: Menú y otra partida DEBEN eliminar el estado visual anterior; la presentación DEBE conservar el estilo pictórico, la lectura del tablero y del HUD en Web de computador y apps Android/iOS.

### Key Entities

- **Combatiente**: colombiano o enemigo con vida actual propia y una capacidad máxima de su tipo.
- **Barra de vida**: indicador visual individual de esa proporción; observa el combate, sin autoridad sobre él.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Ambos bandos muestran una única barra sin números a vida completa; daño parcial refleja la proporción real de cada uno y los límites 50 %/25 % seleccionan los colores definidos.
- **SC-002**: Daño letal y retirada dejan cero barras del combatiente anterior; reaparición con otro máximo y reaparición inmediata muestran su nuevo estado completo. Otra partida no conserva barras antiguas.
- **SC-003**: La revisión visual confirma barra sobre el casco, borde oscuro, tonos mates, ausencia de inversión/parpadeo y continuidad de corrida, HUD y entrada en cada entorno ejecutado.
- **SC-004**: Las comprobaciones de combate, recarga, moral, munición, movimiento, oleadas y fin/reinicio conservan los resultados actuales; recargar un herido no aumenta su vida.

## Assumptions

- Un solo incremento `011-I1` entrega ambos bandos; no incluye números, curación, opciones, nuevos stats, arte generado ni ajustes de balance.
- Se reutiliza el juego de `main` posterior al PR #41. Las pruebas acreditan sólo su navegador/computador o app/dispositivo ejecutados; un pendiente físico pertenece al gate de publicación.
- Se mantienen agentes, TDD y QA independiente para integración, documentación y PR en borrador. La publicación sigue pendiente; Issue #30 permanece pausado, sin nuevas campañas de FPS ni certificación de rendimiento.
