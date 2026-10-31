# Feature Specification: Combate a distancia y recompensas de machete

**Feature ID**: `015-combate-a-distancia-y-recompensas`
**Branch**: `codex/015-combate-a-distancia-y-recompensas`
**Created**: 2026-10-30
**Status**: 015-I1 e I2 integrados en `main` por [PR #59](https://github.com/Juanpvivas/demons/pull/59), `73c2dff`. Publicación T015/SC-008 pendiente
**Revisión vigente**: 015-I2 integrado: dos asaltantes por fusilero, con aprobación QA/CI previa sobre `d8826e2`. I1 conserva su aprobación e historial; las reglas de composición siguientes sustituyen sólo la uniformidad de fusileros de I1.
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

## Enmienda 015-I2 — Dos asaltantes por fusilero

### User Story 4 - Alternar avance y fuego (Priority: P1)

Como jugador quiero dos asaltantes que avancen por cada fusilero, conservando
la progresión de los fusileros y los ritmos de aparición aprobados.

**Acceptance Scenarios**:

1. Los 99 enemigos WAVE forman una secuencia global A,A,R repetida33 veces,
   continua entre oleadas; el inicial es R de perfil1 y no consume tipo ni carril WAVE.
2. Un A sin fusil avanza aun con colombiano frontal vivo válido; R conserva el
   tiro/parada de I1 y vuelve a avanzar sin blanco. Contacto y colisiones vigentes
   permanecen, incluso al aparecer detrás de un R detenido.
3. Al reutilizar el mismo actor R→A→R no quedan blancos, relojes, presentación
   o callbacks de otra activación. La mezcla no cambia otros stats ni recursos compartidos.

- **FR-011**: Autorizar exactamente66 A y33 R WAVE, en orden global A,A,R sin reinicio por oleada; inicial independiente R/perfil1.
- **FR-012**: A tiene fusil desactivado y HP15/velocidad40/melee5/drop3. R conserva alcance864 y tabla de daño/intervalo I1 según la oleada en que aparece. No nueva IA, arte, UI o mutación de stats.
- **FR-013**: Conservar cantidades, cada intervalo de aparición y cursor continuo de cinco carriles. La intercalación no puede agrupar todos los A y después todos los R.
- **FR-014**: Preservar física/contacto y reset del pool existentes. Validar composición nueva con RED y el resto con regresión proporcional; no inventar fallo de colisiones ni cambiar reglas ya aprobadas sin defecto real.

| Oleada | Total WAVE | A | R | Intervalo de aparición(s) |
|---|---:|---:|---:|---:|
| 1 | 3 | 2 | 1 | 1.5 |
| 2 | 4 | 3 | 1 | 1.4 |
| 3 | 5 | 3 | 2 | 1.3 |
| 4 | 6 | 4 | 2 | 1.2 |
| 5 | 8 | 6 | 2 | 1.1 |
| 6 | 10 | 6 | 4 | 1.0 |
| 7 | 12 | 8 | 4 | 0.9 |
| 8 | 14 | 10 | 4 | 0.8 |
| 9 | 17 | 11 | 6 | 0.7 |
| 10 | 20 | 13 | 7 | 0.6 |

- **SC-009**: Secuencia aplanada exacta de99 WAVE =66 A/33 R; inicial R/perfil1 excluido y composición por oleada igual a tabla, sin cambiar intervalos/carriles.
- **SC-010**: Cuerpos reales mixtos acreditan avance A, parada/tiro y reanudación R, contacto vigente y reset R→A→R sin restos; reglas I1/013/014 conservadas.
- **SC-011**: RED/GREEN, regresión, build/preview y QA/CI exactos sustentan I2 en el mismo PR59 en borrador/Issue58. La entrega personal del APK de prueba autorizada se gestiona por root; no completa publicación T015/SC-008 ni autoriza otros destinos.
