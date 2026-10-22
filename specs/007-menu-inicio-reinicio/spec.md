# Feature Specification: Menú de inicio y nueva partida

**Feature ID**: `007-menu-inicio-reinicio`
**Branch**: `codex/007-i1-menu`, desde `main` `a97affd`; preparación original en `codex/007-preparacion`.
**Created**: 2026-10-21
**Status**: US1–US3 implementadas; alcance local técnico/funcional/visual aprobado por QA. Mediciones descriptivas sin certificación física; veredicto y CI de la revisión exacta en el PR y seguimiento. Issue #32 abierto y publicación pendiente.
**Input**: «Conservemos el estilo pictórico de Monte Calvo. Prepara la feature 007 con el alcance propuesto, siguiendo el flujo de agentes y QA del proyecto y manteniendo la publicación pendiente».

## Contexto y alcance

La persona probó `main` (`d86543f`, PR #31): la partida comienza al cargar y, al terminar, necesita refrescar la página para volver a jugar. Esta feature permite decidir cuándo empezar y repetir Monte Calvo dentro de la misma sesión.

Flujo acordado: **Menú principal → Jugar → Partida → Victoria/derrota → Volver a jugar o Menú principal**. El menú muestra el título «Demonios de las Trincheras» y «Jugar»; ambos resultados ofrecen «Volver a jugar» y «Menú principal». Se conserva el estilo pictórico vigente y se prepara un único incremento funcional para el ciclo completo.

Fuera de alcance: pausa o salida durante el combate, ajustes, tutorial, guardado/progreso, selección de niveles, audio nuevo, cambios de balance/mecánicas y optimizaciones de 006. Los pendientes anteriores de rendimiento y publicación se conservan.

## User Scenarios & Testing

### User Story 1 — Decidir cuándo comenzar (Priority: P1)

Como jugador, quiero encontrar un menú al abrir el juego para iniciar Monte Calvo cuando esté preparado.

**Why this priority**: Evita que el combate avance antes de que la persona pueda interactuar.
**Independent Test**: Abrir, esperar en el menú y activar «Jugar»; sólo entonces debe comenzar una partida.

**Acceptance Scenarios**:

1. **Given** una apertura nueva, **When** termina la carga, **Then** se ve el menú pictórico con título y «Jugar», sin una partida activa detrás.
2. **Given** el menú, **When** la persona espera o pulsa su fondo, **Then** no aparecen enemigos, no avanzan oleadas y no ocurren acciones de combate, selección, despliegue, recarga o recolección.
3. **Given** el menú, **When** se activa «Jugar», **Then** comienza una única partida con los cinco soldados cargados, reserva cero, atacante inicial y oleadas vigentes.
4. **Given** un inicio ya aceptado, **When** se repite rápidamente la activación, **Then** no se crea otra partida ni el gesto del botón ejecuta además una acción en el tablero.

### User Story 2 — Volver a jugar después de ganar o perder (Priority: P1)

Como jugador, quiero comenzar otra partida después de cualquiera de los dos resultados sin refrescar la página ni reabrir la aplicación.

**Why this priority**: Completa la sesión y permite varios intentos en el propio juego.
**Independent Test**: Alcanzar por separado victoria y derrota y repetir «Volver a jugar»; cada intento debe empezar igual que el primero.

**Acceptance Scenarios**:

1. **Given** victoria o derrota, **When** aparece el resultado, **Then** se distingue su desenlace y están disponibles «Volver a jugar» y «Menú principal»; las acciones de tablero permanecen bloqueadas.
2. **Given** un intento terminado con recursos gastados, soldados dañados/derrotados, cajas, efectos y oleadas avanzadas, **When** se activa «Volver a jugar», **Then** comienza directamente una nueva partida con sus condiciones iniciales vigentes.
3. **Given** una nueva partida, **When** avanza, **Then** no hereda enemigos, cajas, selección, órdenes, resultados, efectos o recompensas anteriores; oleadas y reparto por filas vuelven a su inicio vigente.
4. **Given** un resultado visible, **When** se activan rápida o alternativamente los dos botones, **Then** se acepta como máximo una transición y no se superponen menú y partida activa.

### User Story 3 — Regresar al menú antes de otro intento (Priority: P2)

Como jugador, quiero regresar al menú después de terminar para decidir cuándo iniciar mi siguiente intento.

**Why this priority**: Permite esperar dentro del juego sin que otra partida empiece automáticamente.
**Independent Test**: Desde cada resultado volver al menú, esperar y activar «Jugar»; el menú debe estar inerte y el siguiente intento comenzar limpio.

**Acceptance Scenarios**:

1. **Given** victoria o derrota, **When** se activa «Menú principal», **Then** se retira la partida terminada y vuelve el mismo menú inicial, sin empezar otra partida.
2. **Given** el menú tras un resultado, **When** se espera o pulsa su fondo, **Then** no continúa el combate ni aparecen enemigos, cajas, cambios de recursos o resultados.
3. **Given** ese menú, **When** se activa «Jugar», **Then** comienza una partida con las mismas condiciones iniciales que en la apertura.
4. **Given** los tamaños/aspectos admitidos por el juego, **When** se muestra menú o resultado, **Then** textos y botones son visibles, legibles y operables por ratón/teclado en computador y toque en las apps, con el mismo significado.

### Edge Cases

- Doble clic, toques rápidos o tecla repetida durante una transición: un solo destino y ningún gesto atraviesa al tablero.
- Los dos botones de resultado activados casi a la vez: sólo la primera transición aceptada tiene efecto.
- Baja, oleada, recompensa o resultado tardíos del intento retirado: no alteran menú ni nueva partida.
- Final con selección, recarga/regreso, soldados fuera de su hogar, cajas o efectos visibles: ningún estado se hereda.
- Avisos terminales coincidentes: se conserva la resolución vigente y se ofrece un solo conjunto de acciones.
- Redimensionar menú o resultado: no inicia una partida ni activa botones y las acciones siguen visibles.
- Repetir partidas: no se acumulan enemigos, acciones duplicadas o actividad de intentos retirados.

## Requirements

### Functional Requirements

- **FR-001**: La apertura DEBE mostrar primero el menú con el título «Demonios de las Trincheras» y «Jugar», sin iniciar la partida hasta su activación explícita.
- **FR-002**: Mientras el menú está visible no DEBE existir una partida activa ni avance de enemigos, oleadas, combate, economía o acciones sobre un tablero oculto, también al regresar de un resultado.
- **FR-003**: «Jugar» DEBE iniciar exactamente una partida de Monte Calvo con sus condiciones iniciales vigentes; conserva cantidades, cadencias, geometría, economía, moral, combate y condiciones terminales.
- **FR-004**: Victoria y derrota DEBEN comunicar el desenlace y ofrecer «Volver a jugar» y «Menú principal», manteniendo bloqueadas las acciones sobre el tablero.
- **FR-005**: «Volver a jugar» DEBE iniciar directamente una partida nueva sin refrescar ni reabrir; «Menú principal» vuelve al menú sin iniciar otra y «Jugar» desde éste empieza un intento nuevo.
- **FR-006**: Cada intento nuevo DEBE restablecer estado general, reserva cero, cinco soldados cargados con salud/moral iniciales vigentes, plazas, selección, progreso/reparto de oleadas y atacante inicial. No hereda órdenes, blancos, actores, cajas, efectos, temporizadores o resultado anterior.
- **FR-007**: Retirar una partida DEBE detener su actividad e impedir que eventos, recompensas, interacciones o resultados tardíos afecten al menú o al siguiente intento.
- **FR-008**: Activaciones repetidas o simultáneas DEBEN aceptar como máximo una transición en curso; el gesto de un botón no ejecuta además una acción en el tablero de destino.
- **FR-009**: Menú y acciones de resultado DEBEN conservar la dirección pictórica de Monte Calvo: tierra ocre/oliva, montañas azul grisáceo, texto contrastado y tratamiento coherente con el arte vigente; el fondo del menú no contiene combate activo.
- **FR-010**: Título, resultado y botones DEBEN quedar visibles, legibles y accionables en los tamaños/aspectos admitidos. Ratón y navegación/activación por teclado en computador, y toque en apps nativas, conservan sus consecuencias.
- **FR-011**: El ciclo completo DEBE repetirse en la misma sesión después de cualquiera de los resultados, por ambas acciones de salida, sin actividad acumulada ni acciones duplicadas.
- **FR-012**: Se DEBE conservar Web sólo en computador y Android/iOS como apps instaladas; una verificación de un destino no acredita otro.
- **FR-013**: La entrega DEBE mantener pendientes publicación, certificaciones físicas y trabajos restantes de 006 y otras features; preparar o integrar 007 no distribuye el juego.

### Key Entities

- **Menú principal**: presentación inicial y posterior al resultado con una única acción de inicio.
- **Intento de partida**: sesión independiente de Monte Calvo desde sus condiciones iniciales hasta un resultado; su estado no sobrevive al próximo intento.
- **Resultado**: victoria/derrota vigentes y las dos acciones acordadas.
- **Transición**: aceptación exclusiva de una acción que cambia entre menú, partida y resultado.

## Success Criteria

### Measurable Outcomes

- **SC-001**: En la apertura y tras volver desde cada resultado, esperar 60 segundos en el menú no genera enemigos, oleadas, combate, cambios de recursos o resultado; cada «Jugar» aceptado inicia una sola partida.
- **SC-002**: Victoria y derrota muestran los dos botones y su resultado correcto; los cuatro recorridos resultado × acción llevan al destino indicado sin refrescar ni reabrir.
- **SC-003**: Se completan al menos tres ciclos consecutivos desde cada resultado y por cada acción de salida en la misma sesión, con condiciones iniciales vigentes y sin estado o actividad heredados.
- **SC-004**: Activaciones repetidas y alternadas durante cada transición producen como máximo un destino/partida, sin acciones extra sobre el tablero; avisos tardíos no cambian menú ni nuevo intento.
- **SC-005**: La revisión visual confirma el estilo acordado y ningún título, resultado o botón recortado, superpuesto o fuera del área utilizable en la matriz disponible; ratón/teclado y toque completan el mismo flujo según destino.
- **SC-006**: Los nuevos intentos conservan cinco soldados iniciales, reserva cero, un atacante inicial y 99 enemigos de oleadas, reparto y condiciones terminales vigentes, sin recursos o unidades heredados.
- **SC-007**: Se distingue preparación, implementación y comprobaciones realmente aprobadas; sólo el alcance revisado independientemente se presenta como aprobado para integración, sin atribuir resultados físicos a entornos emulados o de computador.
- **SC-008**: No se distribuye ni se completan por 007 los pendientes de publicación de 004/005 o de rendimiento de 006; la publicación permanece pendiente.

## Assumptions

- La persona confirmó el flujo propuesto, sus tres botones y el estilo pictórico. No quedan decisiones de producto abiertas para esta preparación.
- Monte Calvo es el único escenario del incremento, con el comportamiento integrado de 004/005. El estado de cada intento es temporal; no se añaden almacenamiento ni servicios externos.
- La adaptación parte de la presentación horizontal y tamaños/aspectos vigentes, sin plataformas o modalidades de entrada nuevas.
- La matriz de integración usa Web de computador y apps Android/iOS disponibles con límites explícitos; la certificación física para publicar sigue pendiente sin heredar excepciones de otras features.
- Esta especificación define aceptación; su estado no sustituye el dictamen sobre cada entorno y artefacto. La ejecución sigue el [flujo de agentes y TDD](../../docs/DEVELOPMENT_WORKFLOW.md); se conservan los pendientes de [006](../006-diagnostico-rendimiento/tasks.md).
