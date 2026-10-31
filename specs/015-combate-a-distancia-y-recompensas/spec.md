# Feature Specification: Combate a distancia y recompensas de machete

**Feature ID**: `015-combate-a-distancia-y-recompensas`
**Branch**: `codex/015-combate-a-distancia-y-recompensas`
**Created**: 2026-10-30
**Status**: 015-I1 APROBADO PARA INTEGRACIÓN por QA con CI de `2351798`; [PR #59 en borrador](https://github.com/Juanpvivas/demons/pull/59) en su rama, sin fusionar. Publicación T015/SC-008 pendiente
**Tracking**: [Issue #58](https://github.com/Juanpvivas/demons/issues/58)
**Input**: Tres cambios autorizados: fusil colombiano hasta la entrada, enemigos con fusil de daño/frecuencia crecientes que se detienen para disparar y baja letal de machete del dueño que otorga +2 moral/+3 vida. Las reglas y la progresión siguientes fueron resueltas por la persona.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Defender desde la entrada (Priority: P1)

Como jugador quiero que el colombiano con fusil cubra su carril desde su hogar hasta la aparición enemiga.
**Why this priority**: Amplía la defensa a toda la longitud autorizada, sin abrir diagonales nuevas.
**Independent Test**: Con cuerpos reales en hogar x144 y entrada x1008, verificar adquisición/daño, no sólo invocar el callback de ataque.

**Acceptance Scenarios**:

1. **Given** soldado en hogar con munición y enemigo vivo en entrada del mismo carril, **When** corre combate físico real, **Then** puede disparar/aplicar daño desde distancia864.
2. **Given** blanco detrás, fuera del alcance físico o en diagonal profunda, **When** se buscan objetivos, **Then** no es elegible. Las dos diagonales inmediatamente contiguas conservan sus reglas previas y el machete no cambia alcance.

### User Story 2 - Enemigos que disparan con progresión (Priority: P1)

Como jugador quiero enemigos que disparen desde su carril con dificultad autorada por oleada.
**Why this priority**: Introduce amenaza a distancia con comportamiento legible.
**Independent Test**: Enemigo real en entrada, colombiano vivo enfrente/mismo carril: enemigo se detiene y dispara inmediatamente al adquirir, luego por intervalo; sin blanco vuelve a avanzar.

**Acceptance Scenarios**:

1. **Given** blanco vivo válido delante en su carril y alcance, **When** lo adquiere, **Then** se detiene y dispara primero de inmediato, después según su intervalo. No tiene sistema nuevo de munición.
2. **Given** blanco muerto, detrás, de otro carril o fuera de alcance, **When** revalida, **Then** no dispara a ese blanco y avanza si no hay otro válido.
3. **Given** contacto cuerpo a cuerpo, **When** ataca, **Then** sólo opera el contacto vigente, sin sumar fusil y melee.
4. **Given** oleada1,5 o10, **When** aparece su enemigo, **Then** usa respectivamente daño1/intervalo4s, daño2/3s y daño3/2s. Los intermedios siguen la tabla; el inicial usa perfil1.
5. **Given** tiro enemigo confirmado, **When** se presenta, **Then** destello/trazadora/sonido corresponden una vez al tiro, sin otro daño por efecto; eventos viejos tras reciclado no afectan la nueva activación.

### User Story 3 - Recompensar la baja de machete (Priority: P1)

Como jugador quiero que una baja letal a machete refuerce al soldado que la consiguió.
**Why this priority**: Atribuye recompensa a una acción confirmada del dueño.
**Independent Test**: Soldado herido vivo mata con machete: +2 moral/+3 vida hasta su máximo; daño no letal y baja de fusil no reciben esa combinación.

**Acceptance Scenarios**:

1. **Given** baja letal de machete confirmada, **When** el dueño sigue vivo, **Then** recibe una vez +2 moral y +3 vida, sin superar max_health actual30.
2. **Given** vida completa, **When** mata a machete, **Then** suma2 moral sin sobrecuración; si el dueño murió durante callbacks no se cura ni resucita.
3. **Given** callback repetido o enemigo reciclado durante la transacción, **When** retorna daño, **Then** no duplica crédito ni lo atribuye a la activación nueva.
4. **Given** baja de fusil, **When** confirma, **Then** conserva +1 moral sin curación. La última baja que lleva a victoria conserva recompensa de machete del dueño vivo.

### Edge Cases

- Límite físico inclusivo por solape real de cuerpos, no sólo distancia al centro.
- Enemigo pierde/reemplaza blanco, pausa/terminal, cleanup vivo y reactivación del pool.
- No acumular ráfagas al pausar ni heredar objetivo/cooldown de otra activación.
- Contacto mutuo y daño enemigo no aplican dos ataques del mismo enemigo en una fase.
- Reentrada durante take_damage, muerte del dueño y baja final/resultado síncronos.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Ampliar el alcance frontal del fusil colombiano a864 desde hogar hasta entrada, con detección física real. Conservar prioridad de blancos, disparo hacia delante, diagonales inmediatas y alcance de machete.
- **FR-002**: Enemigo busca sólo colombiano vivo delante/mismo carril y dentro de alcance equivalente864, se detiene para disparar, dispara al adquirir y respeta intervalos posteriores; si no hay objetivo válido avanza.
- **FR-003**: Contacto melee y fusil enemigo son excluyentes; en contacto se conserva melee vigente. No nuevo sistema de munición ni daño adicional por animación/proyectil.
- **FR-004**: Autoría de daño/intervalo por oleada según tabla; perfiles inmutables, inicial igual a1, sin modificar HP15/speed40/melee5/drop3 o conteos/intervalos de spawn existentes.
- **FR-005**: Baja letal de machete concede al dueño vivo +2 moral/+3 vida limitada por su max_health; no concede por impacto no letal, fusil, callback repetido o cleanup ni resucita.
- **FR-006**: Fusil colombiano conserva +1 moral por baja, daño5/cadencia1.5, ammo10/HP30 y demás reglas; el machete sigue base3+moral×1 y su nueva moral afecta ataques posteriores.
- **FR-007**: Separar estado por activación del enemigo y validar identidad/generación antes de daño/presentación; pausa/terminal/cierre/pool no heredan targets/relojes o disparos atrasados.
- **FR-008**: Tiros enemigos usan presentación y audio de fusil existentes una vez por confirmación, con snapshots de datos sin dueño Node y generación validada. Preservar013 y mezcla Stream/GameplaySFX de014.
- **FR-009**: Recompensa actualiza barras/estado observador existentes sin UI/persistencia/red nuevas. Datos de balance en perfiles autorados, sin mutación compartida o RNG jugable nuevo.
- **FR-010**: Validar tres cambios con TDD, regresión y playtesting de balance; separar integración de publicación/hardware y conservar pausa006/pendientes anteriores.

### Progresión autorizada

| Oleada | Daño por disparo | Intervalo(s) |
|---|---:|---:|
| 1 | 1 | 4.0 |
| 2 | 1 | 3.75 |
| 3 | 1 | 3.5 |
| 4 | 1 | 3.25 |
| 5 | 2 | 3.0 |
| 6 | 2 | 2.8 |
| 7 | 2 | 2.6 |
| 8 | 2 | 2.4 |
| 9 | 2 | 2.2 |
| 10 | 3 | 2.0 |

Intervalo entre tiros, no tasa; tasa=1/intervalo. El inicial usa perfil1. Cantidades y spawn_interval de cada oleada permanecen idénticos (incluidos1:3/1.5s y10:20/0.6s).

### Key Entities

Perfil de enemigo por oleada, activación con blanco/reloj propio, transacción de daño letal y recompensa del dueño, snapshot cosmético inmutable.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Cuerpos reales hogar144→entrada1008 producen tiro colombiano válido desde864; controles negativos de detrás/fuera/diagonal profunda no disparan y diagonales inmediatas conservan reglas.
- **SC-002**: Enemigo se detiene y realiza tiro inmediato/intervalado al colombiano vivo frontal de su carril, reanuda avance sin blanco y no acumula daño de fusil+contacto.
- **SC-003**: Los diez perfiles cumplen exactamente la tabla y el inicial perfil1; HP/speed/melee/drop, cantidades/spawn y recursos compartidos no se alteran en runtime.
- **SC-004**: Cada baja letal a machete aporta una sola recompensa +2/+3 con tope30/vida máxima y sin resurrección, incluso con reentrada/reciclado/baja final; fusil sólo conserva +1.
- **SC-005**: Cada tiro enemigo aplica daño una vez y emite presentación/sonido una vez; eventos/targets/generaciones viejas no dañan o presentan otro uso del pool.
- **SC-006**: Pausa/terminal/cierre/retry conservan relojes/aislamiento correctos y regresión013/014, sin ráfagas atrasadas, UI/persistencia/red nuevas o modificaciones de mezcla.
- **SC-007**: RED/GREEN válido, regresión completa, build/export/CI, playtesting de balance y QA independiente sustentan integración de los tres cambios con límites explícitos.
- **SC-008**: Publicación exige artefacto/renderer/firma/versión, smoke/instalación y rendimiento físico requeridos, QA de publicación y autorización explícita; integración no acredita este criterio.

## Assumptions

Las reglas materiales están resueltas por la persona; las decisiones técnicas concretas constan en plan/contrato. Un incremento entrega los tres cambios. Sin recursos artísticos nuevos imprescindibles; se reutilizan fusil/audio/efectos existentes. No cambia publicación, versiones o pendientes004/005/013/014 y006.
