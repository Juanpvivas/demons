# Feature Specification: Comandante con memoria — elección de carriles V1

**Feature ID**: `017-comandante-memoria`

**Planned Branch**: I1 `codex/017-i1-comandante-memoria` desde `main` / `e8407ec`; [Issue #65](https://github.com/Juanpvivas/demons/issues/65).

**Created**: 2026-10-31

**Status**: Especificación preparada para planificación; decisiones de producto confirmadas, preparación aprobada independientemente; implementación pendiente.

**Input**: «Preparemos la especificación de esa primera versión del comandante con memoria, conservando los tipos, cantidades y tiempos actuales y variando solo los carriles».

**Aclaraciones confirmadas por la persona (2026-10-31)**:

- **Q1**: un enemigo por carril en cada bloque de cinco, variando el orden.
- **Q2**: memoria local por instalación, con opción de borrado, y aprendizaje
  únicamente de partidas terminadas en victoria o derrota.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ataques variados con las mismas oleadas (Priority: P1)

Como jugador quiero que los enemigos puedan aparecer en distintos carriles entre
partidas, conservando el contenido y el ritmo que ya tiene Monte Calvo.

**Why this priority**: establece la única libertad del comandante y evita que
la variedad encubra más enemigos, mejores estadísticas o ataques adelantados.

**Independent Test**: con memoria neutral, recorrer el calendario completo de
apariciones y contrastarlo con el vigente: sólo puede diferir el carril WAVE.
La comprobación del calendario se separa de una partida real que pueda terminar
antes de emitir las diez oleadas.

**Acceptance Scenarios**:

1. **Given** dos partidas con el mismo contenido autorado y distintas semillas,
   **When** se comparan sus apariciones previstas, **Then** coinciden cantidades,
   orden de tipos, perfiles y tiempos; existen repartos distintos de carriles.
2. **Given** una semilla, memoria y secuencia de observaciones iguales,
   **When** se repite la selección, **Then** se obtiene el mismo reparto.
3. **Given** el fusilero inicial, **When** comienza la partida, **Then** conserva
   su aparición inmediata en la fila central 3 y perfil 1, fuera de la selección,
   memoria y conteo WAVE. Su efecto en el combate sigue siendo el vigente.
4. **Given** WON, LOST, pausa o salida al menú, **When** se interrumpe el juego,
   **Then** no aparecen enemigos adicionales ni se acumulan decisiones atrasadas.
5. **Given** un bloque global de cinco apariciones WAVE, **When** una
   preferencia aprendida pide un carril ya usado, **Then** prevalece el límite
   y se elige otro carril sin saltar, agregar ni retrasar el enemigo previsto.
6. **Given** un bloque que cruza el final de una oleada, **When** aparece el
   siguiente WAVE, **Then** continúa con los carriles pendientes del mismo bloque;
   sólo empieza otro tras sus cinco apariciones. El bloque final de cuatro
   usa cuatro carriles distintos y no genera un quinto enemigo adicional.

### User Story 2 - Experiencia útil entre partidas (Priority: P1)

Como jugador quiero que el comandante recuerde qué repartos funcionaron ante
situaciones parecidas y ajuste sus preferencias cuando yo cambio de estrategia.

**Why this priority**: distingue el aprendizaje de una simple mezcla aleatoria.
Depende del selector de US1, pero el efecto de la memoria se comprueba de forma
separada manteniendo iguales todas las demás entradas.

**Independent Test**: comparar memoria neutral y memoria expuesta a resultados
controlados, ante el mismo contexto y opciones; verificar el cambio de
preferencias y su persistencia entre sesiones tras una victoria o derrota.

**Acceptance Scenarios**:

1. **Given** experiencias repetidas donde un reparto permite más avance enemigo
   en un contexto, **When** se evalúan futuras opciones legales equivalentes,
   **Then** aumenta su preferencia respecto de la memoria neutral, sin hacerlo
   obligatorio ni vulnerar límites de concentración.
2. **Given** una preferencia aprendida, **When** cambia la defensa y los nuevos
   resultados contradicen esa experiencia, **Then** la preferencia puede cambiar;
   un recuerdo antiguo no domina indefinidamente.
3. **Given** una sola experiencia excepcional, **When** se aprende de ella,
   **Then** no desaparecen las alternativas ni se convierte una preferencia en
   una orden permanente; el ajuste por experiencia está acotado.
4. **Given** una victoria o derrota consolidada y guardada, **When** se cierra y abre
   la app, **Then** se recupera la misma experiencia compatible, sin modificar
   salud, economía, progreso narrativo ni estado de la nueva partida.
5. **Given** enemigos reciclados o eliminados al cerrar el nivel, **When** se
   consolidan resultados, **Then** no se inventan bajas ni avances y una misma
   activación no aporta experiencia dos veces.
6. **Given** experiencias recogidas durante una partida sin resultado terminal,
   **When** se abandona al menú o se cierra la app, **Then** se descartan sin
   cambiar la memoria anterior; no cuentan como victoria, derrota o aprendizaje.
7. **Given** una partida que ya consolidó WON/LOST, **When** se pulsa Retry o se
   vuelve al menú, **Then** no se vuelve a contabilizar ese resultado.

### User Story 3 - Desafío limitado y memoria controlable (Priority: P1)

Como jugador quiero poder responder a los ataques y empezar sin experiencia
acumulada si así lo decido, sin que ganar partidas active un aumento permanente
de dificultad.

**Why this priority**: la memoria debe variar la oposición dentro del nivel,
sin convertir el número de partidas jugadas en una penalización acumulativa.

**Independent Test**: exponer el selector a preferencias extremas; comprobar
límites, alternativas, recuperación de memoria inválida y comportamiento de
borrado. El equilibrio requiere además juego manual.

**Acceptance Scenarios**:

1. **Given** una memoria muy favorable a una táctica, **When** empieza otra
   partida, **Then** conserva exactamente los mismos tipos, estadísticas,
   cantidades, tiempos, economía y condiciones de victoria/derrota.
2. **Given** órdenes futuras del jugador o datos no observables, **When** se
   decide el carril, **Then** no se usan para anticipar su respuesta.
3. **Given** un enemigo ya aparecido, **When** cambia la defensa, **Then** el
   comandante no le cambia carril ni destino para contrarrestarla.
4. **Given** memoria ausente, corrupta o incompatible, **When** empieza el nivel,
   **Then** se usa experiencia neutral válida y se puede jugar sin bloquearse.
5. **Given** error al guardar, **When** termina la sesión, **Then** sigue siendo
   posible volver al menú y reintentar, sin afirmar que el aprendizaje persistió.
6. **Given** memoria guardada, **When** el jugador usa la opción de borrado y
   éste tiene éxito, **Then** la próxima partida usa memoria neutral, también
   tras reiniciar la app, sin borrar progreso narrativo ni otras preferencias.

### Edge Cases

- Primer inicio, ausencia de memoria o pérdida del almacenamiento del navegador.
- Cierre de app o abandono antes de WON/LOST: descartar experiencias pendientes.
  Pausar no consolida; Retry tras un terminal no duplica su consolidación.
- Derrota temprana: enemigos no aparecidos o sin resultado no son éxitos ni fracasos.
- Victoria, derrota o retorno al menú durante evaluación: no genera nuevas acciones.
- Memoria dañada, versión futura o parámetros fuera del rango válido.
- Cambio de balance: no reutilizar experiencia incompatible sin una regla explícita.
- Todas las defensas iguales, ausencia de defensores o ningún contexto conocido:
  existen opciones válidas sin consulta de información futura.
- Límite de concentración que elimina la primera preferencia: elegir entre las
  restantes sin consumir ni alterar el calendario de apariciones.
- Los bloques siguen la secuencia global WAVE, no las fronteras de oleada.
  Hay 19 bloques completos y un bloque final de cuatro carriles distintos.
  Una partida nueva empieza un bloque nuevo; el inicial nunca ocupa una plaza.
- Entre dos bloques puede repetirse el último carril como primero del siguiente:
  la regla confirmada limita cada bloque, no toda ventana móvil de cinco.
  Como consecuencia, permite hasta dos apariciones consecutivas en un mismo
  carril en esa frontera. Su efecto requiere playtesting; no acredita un límite
  de enemigos vivos simultáneos por carril.
- Reutilización del cuerpo de un enemigo: distinguir cada activación observada.
- Error de escritura o fallo durante borrado: no comunicar éxito inexistente.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001 — Única salida**: el comandante sólo decide el carril de cada enemigo
  WAVE pendiente entre los cinco existentes. No decide si aparece, su tipo,
  estadísticas, posición longitudinal ni instante de aparición. El inicial
  conserva fila 3 inmediata y no participa del aprendizaje.
- **FR-002 — Contenido invariable**: conservar la tabla siguiente y el orden
  global continuo A,A,R de los 99 WAVE, sin reinicio por oleada. A es asaltante
  sin fusil y R fusilero; se mantienen los perfiles de combate vigentes y otro
  R inicial, para un máximo previsto de 100 apariciones en el recorrido completo.
- **FR-003 — Tiempo invariable**: conservar los intervalos, primera aparición,
  transiciones y disparadores de inicio/fin de oleada vigentes. El comandante no
  añade esperas, pausas tácticas, refuerzos ni compensaciones. El tiempo de reloj
  de una partida puede variar por combate, pausa o derrota: no se promete una
  cronología absoluta idéntica cuando el avance de oleada depende de sus bajas.
- **FR-004 — Límites independientes**: validar toda elección antes de aplicarla.
  El aprendizaje nunca puede modificar sus límites ni evitar la aparición
  prevista. Cada bloque global de cinco WAVE usa los cinco carriles exactamente
  una vez, en orden variable; mientras esté incompleto sólo se elige entre los
  carriles aún no usados. Los bloques son consecutivos desde el primer WAVE y
  no se reinician entre oleadas. Las apariciones 96–99 forman un bloque final
  de cuatro carriles distintos, sin rellenarlo ni alterar cantidades. Un mismo
  carril puede cerrar un bloque y abrir el siguiente; no es una restricción de
  ventana móvil ni de ocupación simultánea. Una nueva partida reinicia el bloque.
- **FR-005 — Información permitida**: usar únicamente defensa observable actual
  por carril, cargas enemigas observadas, fase de la partida, tipo del próximo
  enemigo y experiencia anterior compatible. Excluir próximas órdenes, RNG
  futuro del jugador y datos de evaluación que revelen respuestas esperadas.
- **FR-006 — Decisiones firmes**: las decisiones afectan sólo apariciones
  futuras; no recolocan enemigos existentes ni recalculan ataques retroactivamente.
- **FR-007 — Variedad reproducible**: escoger entre alternativas válidas con
  una semilla propia de partida, independiente de audio/efectos cosméticos.
  Mismas entradas producen las mismas elecciones; distintas semillas permiten
  variantes sin prometer unicidad absoluta de todas las partidas.
- **FR-008 — Memoria contextual**: conservar experiencia de elección de carril
  ligada a la defensa observada, tipo y fase; separar experiencia de contenidos
  incompatibles. No reducirla a «este carril siempre gana» ni a número de victorias.
- **FR-009 — Aprendizaje verificable**: dar crédito sólo a elecciones ejecutadas
  con resultados observados atribuibles, favoreciendo el avance enemigo logrado
  antes de su baja o del cierre válido de la observación. No premiar cleanup,
  pausas, enemigos no emitidos ni adjudicar una partida entera al último ataque.
  El plan definirá una medida normalizada de avance y el tratamiento explícito
  de observaciones incompletas, antes de las pruebas RED.
- **FR-010 — Experiencia limitada**: acotar el ajuste por experiencia, conservar
  oportunidades de alternativas legales y disminuir el peso de recuerdos viejos.
  La memoria aprende preferencias, sin multiplicador acumulativo de dificultad.
  Tasas, rangos y pesos deberán ser datos de balance revisables y quedar cerrados
  en el plan/contrato antes de implementar, sin constantes arbitrarias en lógica.
- **FR-011 — Ciclo de memoria**: persistir entre partidas sin servicios externos
  ni modelo de lenguaje, localmente por instalación/origen y contenido compatible.
  Recoger observaciones provisionales durante la partida y consolidar aprendizaje
  una sola vez al llegar a WON/LOST, capturando resultados antes del cleanup.
  Salir al menú o cerrar la app antes del terminal descarta las observaciones
  pendientes; pausar no consolida. Ofrecer al jugador una opción de borrado de
  memoria desde el menú, fuera de combate; un borrado exitoso deja experiencia
  neutral para la próxima partida y posteriores sesiones, sin afectar progreso
  narrativo ni otras preferencias. Comunicar éxito o fallo real del borrado;
  ubicación y textos concretos se documentarán en el diseño del plan.
- **FR-012 — Integridad**: un resultado cuenta como máximo una vez. La
  experiencia compatible ya guardada no se corrompe por cierres incompletos.
  Memoria ausente/inválida permite inicio neutral; fallos no acreditan guardado
  o borrado exitoso ni bloquean menú y Retry.
- **FR-013 — Estados**: conservar victoria por 99 bajas WAVE, derrota por cruce
  de cualquier enemigo, pausa y cierre vigentes. Ni aprendizaje ni variedad
  alteran economía, munición, moral, recarga, colisiones o IA individual.
- **FR-014 — Equilibrio**: contrastar sin memoria y con experiencia acumulada,
  incluyendo preferencias extremas y defensas de distintos estilos. La misma
  cantidad de enemigos no demuestra igual dificultad: evaluar orden de fusileros,
  cargas por carril y derrotas tempranas. Un reparto que no permita respuestas
  razonables exige revisar límites dentro del alcance, sin cambiar stats/tiempos.
- **FR-015 — Plataformas**: mismo significado en Web de computador y apps nativas
  Android/iOS, sin red obligatoria. El almacenamiento de cada instalación/origen
  puede perderse; no se promete sincronización entre dispositivos ni persistencia
  tras borrar datos o reinstalar.
- **FR-016 — Alcance de preparación**: esta especificación no modifica gameplay,
  no acredita aprendizaje en producto y no inicia implementación, exportación o
  distribución. Para ejecutar requiere plan, contratos, tareas revisadas,
  GodotPrompter aplicable, TDD y QA independiente según el flujo del proyecto.

### Base de contenido que debe conservarse

Referencia: [015, composición integrada](../015-combate-a-distancia-y-recompensas/spec.md#enmienda-015-i2--dos-asaltantes-por-fusilero)
y los diez Resources actuales de `resources/waves/`, contrastados al preparar
este documento sobre `c227982`. Los tiempos son intervalos de aparición,
no intervalos de disparo; los perfiles de fusil permanecen propios de cada oleada.

| Oleada | Total WAVE | A | R | Intervalo de aparición (s) |
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
| **Total** | **99** | **66** | **33** | **Sin cambios** |

### Key Entities

- **Aparición prevista**: posición en la secuencia WAVE, oleada, tipo, perfil y
  reglas temporales existentes; sólo el carril admite decisión nueva.
- **Contexto observable**: resumen de defensa, carga por carril y fase disponible
  al decidir, separado de resultados futuros y criterios de evaluación.
- **Elección de carril**: alternativa seleccionada y contexto que la motivó,
  vinculados a la aparición efectiva y a una activación única.
- **Experiencia del comandante**: intentos y resultados agregados por contexto,
  con versión compatible, confianza limitada y menor peso de recuerdos antiguos.
- **Estado de partida del comandante**: semilla, elecciones recientes y
  resultados pendientes; independiente de memoria persistida y actores reciclados.
- **Política de límites**: restricciones autoradas que siempre prevalecen sobre
  preferencias aprendidas, sin autoridad para cambiar el calendario.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: en el recorrido completo previsto, coinciden las 99 apariciones
  WAVE, sus 66 A/33 R en orden A,A,R, los diez totales y todos los intervalos
  con la base; el R inicial conserva su aparición central y perfil. Cero cambios
  ajenos al carril atribuibles al comandante. Cubre FR-001–003/013.
- **SC-002**: los 19 bloques globales completos son permutaciones de los cinco
  carriles y el último contiene cuatro distintos, incluso con memoria extrema
  y cruces entre oleadas. Cero elecciones fuera de los cinco carriles; ningún
  rechazo agrega, omite o retrasa una aparición. Cubre FR-004/006/010.
- **SC-003**: en un conjunto reproducible de semillas y entradas revisado antes
  de ejecutar, hay más de un reparto completo legal; entradas idénticas reproducen
  el mismo reparto y las variantes cosméticas no lo alteran. Cubre FR-005/007.
- **SC-004**: manteniendo contexto y alternativas, resultados controlados cambian
  las preferencias en la dirección prevista respecto a memoria neutral; resultados
  posteriores opuestos permiten revertir la tendencia y las opciones legales no
  desaparecen por experiencia acumulada. Cubre FR-008–010.
- **SC-005**: las experiencias guardadas de WON/LOST sobreviven al cierre/apertura;
  cada terminal cuenta una sola vez y abandonar/cerrar antes del terminal no
  modifica la memoria guardada. El borrado exitoso vuelve a neutral también
  después de reiniciar, sin alterar datos ajenos. Corrupción, incompatibilidad y
  fallo de escritura tienen resultados verificables sin bloquear una nueva
  partida ni simular éxito. Cubre FR-011/012/015.
- **SC-006**: sesiones manuales completas comparan memoria neutral y acumulada
  con distintos estilos defensivos; se acredita victoria y oportunidad de
  respuesta en cada condición evaluada y se revisan derrotas tempranas. Registrar
  semillas, nivel de experiencia, límites y anomalías. No garantiza que toda
  estrategia gane. El protocolo y umbrales de aceptación de balance deben estar
  acordados antes del playtesting, sin inventar una tasa de victoria. Cubre FR-014.
- **SC-007**: la validación funcional distingue Web por navegador de computador,
  Android por app/dispositivo o emulador e iOS por app/dispositivo o simulador;
  ninguna prueba acredita otro destino. Mantener 60 FPS físicos y aceptación
  del artefacto final como requisitos de publicación constitucionales, sin
  declararlos medidos por esta especificación. Cubre FR-015/016.

## Assumptions

### Alcance confirmado y dependencias

- La petición autoriza preparación documental de 017, no cambiar prioridades de
  ejecución ni dar por terminada 016. Sus T009–T011 y Issue #63 conservan estado.
  La selección de documentación activa puede apuntar a 017 sin cambiar la rama.
- Se conserva el juego Godot compartido para Web de computador y Android/iOS
  nativos; PC nativo sigue reservado a desarrollo/pruebas.
- La propuesta aceptada conserva memoria contextual, variedad, aprendizaje gradual
  y límites externos a éste. Q1/Q2 están resueltas por la respuesta de la persona
  registrada al inicio de esta especificación.
- La conservación de tiempos excluye el alivio mediante demoras o pausas tácticas
  sugerido para versiones más amplias. En V1 sólo se modifica el reparto lateral.
- No se añaden tipos, enemigos, estadísticas, tácticas con retrasos, niveles,
  dificultades, perfiles de usuario, modelos descargables, cloud, telemetría
  externa, sincronización, avisos tácticos o pantallas nuevas aparte del control
  de borrado de memoria confirmado. No se introduce modo de selección adicional.
- No se traslada el catálogo de siete planes de 016: era sintético y varios
  planes incluían pausas/delays incompatibles con esta V1. El resultado de aquel
  experimento no acredita diversión, aprendizaje, equilibrio o viabilidad móvil.
- Cambiar carriles altera combates y puede alterar duración efectiva y ganabilidad;
  conservar recursos no sustituye playtesting ni garantiza dificultad constante.
- Antes de implementar se cerrarán en plan/contratos la medida de resultado,
  observaciones incompletas, granularidad de contextos, exploración, olvido,
  parámetros y límites, compatibilidad de memoria y protocolo de equilibrio.
  No son decisiones aprobadas ni se dejan para improvisar durante desarrollo.
- Constitución 4.3.0 y flujo del proyecto vigentes: gates de integración y
  publicación separados. #61/#53 y pendientes físicos conservados; 006 sigue
  pausada. Sin nueva distribución ni renovación de excepciones beta.
