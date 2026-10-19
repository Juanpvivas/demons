# Demonios de las Trincheras — Spec del juego

> Documento vivo. Actualízalo a medida que el diseño evolucione; sirve como fuente única de verdad del proyecto.

**Nombre del juego (confirmado):** Demonios de las Trincheras

## 1. Resumen

Juego de defensa por carriles (estilo *Plants vs. Zombies*) inspirado en la historia real del Batallón Colombia en la Guerra de Corea, apodado **"los demonios de las trincheras"**. El jugador coloca soldados colombianos en distintas posiciones para detener el avance de oleadas enemigas y proteger una posición estratégica (ej. Monte Calvo / Old Baldy).

## 2. Contexto histórico e inspiración

- Colombia fue el único país latinoamericano que envió tropas a la Guerra de Corea (Batallón Colombia, ~4.300–5.100 soldados).
- El batallón se destacó especialmente en la **batalla de Monte Calvo (Old Baldy)**, donde llegó a perder cerca del 20% de su fuerza desplegada en un solo combate.
- El apodo "demonios de las trincheras" se lo dieron los propios enemigos, como reflejo del miedo y respeto que inspiraba su ferocidad en combate cuerpo a cuerpo.
- Nota de diseño: el juego usa la versión popular de la historia (soldados que se quedan sin munición y recurren al machete) como base narrativa y mecánica, priorizando jugabilidad sobre precisión documental estricta. Tratar el tema con respeto: es un homenaje, no glorificación gratuita de violencia.

## 3. Género y referencias

- **Género:** Tower defense / lane defense, 2D.
- **Referencia principal:** Plants vs. Zombies (colocación de unidades por costo de recurso, oleadas crecientes, carriles).
- **Diferenciador:** economía dual (ver sección 5) atada temáticamente a la historia real.

## 4. Plataformas objetivo

- **Web (prioridad de publicación):** jugable solo desde el navegador en
  computador; primer portal previsto: itch.io.
- **Android e iOS:** aplicaciones nativas instaladas (APK/IPA o `.app` nativa
  de iOS Simulator). Las pruebas en emulador/simulador identifican ese entorno
  y no acreditan hardware físico.

Este alcance rige desde la decisión de la persona del 2026-10-19, recogida en
la constitución 3.0.0. No se continúan pruebas de navegador en Android/iOS;
las verificaciones móviles Web anteriores se conservan como historia.

No se prevén instaladores propios Windows/macOS/Linux. El ratón sigue siendo
una entrada válida en navegador de computador, y la ejecución nativa local
en PC se mantiene como herramienta de desarrollo y pruebas. La entrega 003
cuenta con exportación y validación Web acotada; no modifica las mecánicas ni
implica una publicación en el portal. [Alcance y evidencias](WEB_EXPORT.md).

## 5. Motor y stack técnico

- **Motor:** Godot 4.x
- **Lenguaje:** GDScript compartido entre Web, Android e iOS. No se incorporan
  dependencias C#/.NET al juego exportado que impidan Web. Godot 4 no admite
  actualmente exportar proyectos C# a Web; cualquier cambio futuro requiere
  demostrar compatibilidad y revisar la constitución. [Limitación oficial](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).
- **Licencia del motor:** MIT, sin regalías, sin costos.
- **Portabilidad validada en 003:** Compatibility específico para Web, con
  Godot estándar 4.7.1 y un hilo, manteniendo Mobile para las apps nativas.
  QA aceptó históricamente la entrega en Chrome de escritorio y Xiaomi/Chrome
  horizontal;
  rendimiento sostenido y entornos no probados conservan límites explícitos.
  El paquete está revisado localmente y no publicado en itch.io.

## 6. Mecánicas core

### 6.1 Sistema de economía

**Recurso global: Munición**
- Se obtiene principalmente de enemigos derrotados (dropean munición al morir, el jugador la recoge/recolecta). *(Supuesto — confirmar si además debería acumularse pasiva y automáticamente con el tiempo, estilo sol en PvZ.)*
- **Confirmado** (spec `001-soldado-defensor-oleadas`, T031/T032): la recolección de la munición soltada es una acción **explícita** del jugador — tap/click sobre la pickup (`AmmoPickup`, `Area2D`) que aparece en la posición del enemigo derrotado — nunca automática por proximidad. Misma acción discreta (`collect_pickup` del `InputMap`) en touch y mouse; ver rationale en `research.md` §3 de esa feature. Web en computador y las apps nativas deben conservar esa semántica; 003 documenta su verificación histórica en navegador.
- **Precedencia confirmada** (`002-monte-calvo-terreno-trincheras`, T019–T022): un clic/toque sobre una pickup recoge su munición sin desplegar además un soldado ni gastar el costo de despliegue, aunque la reserva ya sea suficiente y su celda esté libre. El despliegue sigue requiriendo un gesto sobre una celda libre sin pickup y fondos suficientes. La corrección separada pasó [RED/GREEN y regresión nativas](../specs/002-monte-calvo-terreno-trincheras/evidence/t021-green.md); la [matriz de entrada](../specs/002-monte-calvo-terreno-trincheras/evidence/native-validation-matrix.md) distingue ratón, emulación y dispositivos físicos. La [verificación Web de 003/T015–T018](../specs/003-web-itchio/evidence/t017-green.md) conserva su alcance propio en navegador.
- Uso dual, a elección del jugador:
  1. **Recargar** a un soldado ya desplegado en el tablero (le da más disparos antes de quedarse sin balas).
  2. **Desplegar** un soldado nuevo en una casilla libre.
- **Confirmado** (spec `001-soldado-defensor-oleadas`, Assumptions; implementado y validado en T034): el costo en munición recolectada de una recarga completa es el mismo que el de desplegar un soldado nuevo de ese tipo (`UnitStats.deploy_ammo_cost` — no existe un campo separado de "costo de recarga").

**Stat individual: Moral (por soldado, no es un recurso global)**
- Cada soldado acumula su propia moral mientras tiene munición y sigue eliminando enemigos (los impactos que no eliminan al enemigo no otorgan moral).
- Al quedarse sin munición, el soldado pasa automáticamente a combate cuerpo a cuerpo (machete).
- El **daño del machete depende de la moral acumulada por ese soldado en particular** antes de quedarse sin balas: un soldado que resistió más tiempo disparando y sumó más bajas será más letal cuerpo a cuerpo que uno que se quedó sin munición rápido.
- **Confirmado** (spec `001-soldado-defensor-oleadas`): si el soldado es recargado después de haber entrado en modo machete, vuelve a modo fusil conservando la moral acumulada — la moral no decae con el tiempo, y solo se pierde por completo si el soldado es derrotado.

Esta economía recrea la tensión histórica real: cada bala cuenta, y sobrevivir el tiempo suficiente disparando paga dividendos cuando llega el momento de pelear cuerpo a cuerpo.

### 6.2 Sistema de colocación

- **Decisión de la persona del 2026-10-19, en preparación y sin implementar:**
  cinco filas horizontales con cinco trincheras a la izquierda y enemigos de
  derecha a izquierda, tomando *Plants vs. Zombies* como referencia. La
  prioridad pasa a preparar [005-cinco-carriles](../specs/005-cinco-carriles/spec.md)
  en una nueva rama, conservando I2 de 004 guardado con sus validaciones
  pendientes; no se declara terminado ni aprobado por este cambio de diseño.
- **Estado actual:** Monte Calvo conserva un único avance central enemigo;
  el sistema de cinco carriles todavía no está implementado. El combate
  frontal y las diagonales adyacentes, así como los stats vigentes, se
  conservan; §10 recoge los detalles pendientes del nuevo tablero.
- Colocación restringida por casillas (snap a grid).
- Cada unidad ocupa una casilla; algunas pueden tener rango de ataque que cubre varias casillas adelante.

### 6.3 Tipos de unidad (borrador inicial — por refinar)

**Soldado base (única unidad inicial, dos modos):**
- **Modo fusil** (por defecto al desplegarlo): dispara a enemigos dentro de su cono de detección (carril frontal + diagonales adyacentes), con una cantidad limitada de disparos definida por su munición actual.
- **Modo machete** (automático al quedarse sin munición): combate cuerpo a cuerpo, rango de 1 casilla frontal, daño escalado según la moral acumulada en modo fusil.
- Stats a definir: disparos por carga, daño por disparo, cadencia de disparo, alcance del cono de detección, fórmula de daño machete según moral (ej. daño_base + moral × multiplicador).

**Diseño futuro confirmado para 005, aún sin implementar:** con balas el
soldado dispara hacia la derecha desde dentro de su trinchera; al agotarlas,
sale hacia el enemigo con machete y combate de frente. El soldado actual
permanece inmóvil incluso en modo machete. La
[referencia aprobada por la persona](../specs/005-cinco-carriles/references/visual-reference.md)
orienta la composición; no fija costos, estadísticas ni HUD. Las
[aclaraciones de 005](../specs/005-cinco-carriles/spec.md#clarifications)
confirman cinco plazas reservadas por sus soldados vivos aunque salgan,
reemplazo solo al morir y cinco soldados cargados al inicio con reserva global
cero. Sin balas avanzan y atacan solo a enemigos delante en su fila; sin ellos
esperan donde están. Seleccionar la trinchera muestra la carga/moral del dueño;
pulsar «Recargar» conserva salud/moral y lo hace regresar físicamente para
disparar al llegar. Las oleadas mantienen cantidades y tiempos con
reparto prefijado, conservando además el atacante inicial separado de ellas.
Quedan por precisar velocidad de salida/regreso, elegibilidad de recarga y
continuidad del reparto entre oleadas; el botón y su cobro son conducta
observable pendiente de esa decisión, no solo un cambio visual. Estas reglas
futuras no alteran todavía el juego actual.

**Futuras unidades (post-MVP, no bloquean el prototipo inicial):**
- [ ] Variantes con distinto alcance/cadencia (ej. mortero de área, francotirador de rango largo)
- [ ] (agregar más según playtesting)

### 6.4 Enemigos y oleadas

- Oleadas crecientes en dificultad, representando el avance de tropas chinas/norcoreanas.
- Definición de enemigos vía `Resource` personalizados (stats: vida, velocidad, daño, tipo).
- Sistema de spawn controlado por `Timer` + cola de oleadas.

## 7. Estructura técnica en Godot (borrador)

- **Autoload `EconomyManager`:** controla el contador global de Munición recolectada, expone señal `ammo_pool_changed`.
- **`TileMap`:** define el grid de carriles y posiciones válidas de colocación.
- **Detección multidireccional por soldado:** en vez de un único `Area2D` en línea recta, se evalúan varias celdas/carriles (frontal + diagonal superior + diagonal inferior) dentro del alcance del arma, para elegir el enemigo válido más cercano. Puede implementarse como una `Area2D` con forma de cono/trapecio, o revisando explícitamente las celdas de los carriles adyacentes vía el `TileMap`. **Confirmado** (spec `001-soldado-defensor-oleadas`): las "diagonales adyacentes" son únicamente las celdas diagonalmente contiguas a la posición del soldado (adyacencia directa), no un cono más amplio de varias celdas de profundidad. Cuando hay varios enemigos elegibles a la vez, el objetivo prioritario por defecto es el más avanzado (más cercano a la posición defendida); el soldado no divide su fuego entre objetivos.
- **Stats por instancia de soldado:** cada soldado en escena mantiene su propio estado local (munición actual, moral acumulada, modo activo: fusil/machete) — no vive en el `EconomyManager` global, solo el pool de munición recolectada es global.
- **`AnimatedSprite2D` / `AnimationPlayer`:** animaciones de disparo, cambio a modo machete, ataque cuerpo a cuerpo y muerte.
- **Unidades y enemigos como `Resource` (.tres):** stats base (daño, cadencia, alcance, fórmula de daño machete) desacoplados del código, para poder balancear sin tocar scripts.
- **Señal `enemy_defeated`:** emitida por cada enemigo al morir, con la cantidad de munición que suelta; conectada a `EconomyManager` para sumar al pool global, y al soldado que dio el golpe final para sumar moral individual.

## 8. Arte y estilo visual

**Dirección aprobada para el entorno de Monte Calvo, primera iteración**
(`002-monte-calvo-terreno-trincheras`): ilustración 2D de textura pictórica,
suelo ocre/oliva y montañas azul grisáceo entre la bruma. El centro de combate
mantiene menos detalle que los bordes; tierra excavada, madera y sacos de arena
enmarcan la posición defendida. La [referencia aprobada](../specs/002-monte-calvo-terreno-trincheras/references/visual-reference.md)
orienta los materiales y la jerarquía visual; su composición se adapta al único
avance central existente.

El entorno es estático y sus trincheras son decorativas: no añaden cobertura,
obstáculos, carriles, casillas o límites de despliegue. El primer incremento de
[`004-personajes-municion-monte-calvo`](../specs/004-personajes-municion-monte-calvo/spec.md),
aprobado funcionalmente en T011, sustituye el bloque del soldado inicial y de
los nuevos despliegues por un colombiano de uniforme oliva, casco y armas
legibles. Sus poses distinguen espera/disparo de fusil y espera/golpe de machete
según el modo y los ataques reales. La última bala da prioridad al cambio a
machete; la recarga existente restaura el fusil conservando la moral. Impacto y
moral ganada tienen respuestas breves, y la derrota prevalece sobre ellas.

La corrección de I1, aprobada funcionalmente en T036, aumenta solo el hijo
visual del soldado a una altura opaca neutra aproximada de 72 unidades,
conservando los pies en raíz+y24 y el cuerpo de 48×48. Un material mate aclara
los tonos medios y añade un borde interior discreto para separarlo del suelo,
también en grises. El encuadre local centra el eje de combate al ensanchar la
pantalla, conserva la composición vertical del iPad y cubre el margen izquierdo
con cielo, panorama y suelo existentes. No mueve trincheras, actores ni grid.

La caída del soldado se muestra durante 0,40 s en un efecto independiente,
sin cuerpo, input u ocupación: la celda se libera y el actor jugable se retira
sin esperar la animación. Las imágenes no aplican daño ni cambian recursos,
cadencias o resultados. El enemigo y la munición siguen provisionales, pendientes
de I2 e I3. HUD, controles de recarga, pantallas terminales, audio y resto del
acabado continúan pendientes; esta entrega parcial no completa el MVP.

La [comparación visual](../specs/002-monte-calvo-terreno-trincheras/evidence/us3.md)
y la [matriz nativa](../specs/002-monte-calvo-terreno-trincheras/evidence/native-validation-matrix.md)
recogen PC, Android y iPad Simulator. La validación de iPad usa Compatibility
temporal; no acredita un iPhone/iPad físico ni el renderer Mobile de iOS.
El [rendimiento aprobado](../specs/002-monte-calvo-terreno-trincheras/evidence/performance.md)
se limita a esta feature y al Xiaomi 11T Pro físico como referencia provisional,
según la enmienda 1.2.0, conservada en la constitución 2.1.0. Conserva los picos y la perturbación del observador
documentados; no certifica otros dispositivos ni ausencia de toda caída.

La aceptación histórica de I1 de 004 distingue Chrome de escritorio y Android
Web de la app Android en el Xiaomi físico provisional autorizado exclusivamente para 004
por la constitución 2.2.0. iOS solo acredita el simulador y su renderer software;
no hardware iOS ni el renderer Mobile. Cada entorno conserva sus propios límites,
sin heredar resultados de 002/003 ni certificar estabilidad sostenida más allá
de las muestras revisadas. El seguimiento de los incrementos está en sus
[tareas](../specs/004-personajes-municion-monte-calvo/tasks.md).
Las nuevas verificaciones siguen §4: navegador solo en computador y apps
instaladas en Android/iOS; la reducción del alcance Web no exime los requisitos
de rendimiento físico nativo ni amplía esas aprobaciones históricas.

## 9. Alcance del MVP (primera versión jugable)

- [ ] 1 nivel (ej. defensa de Monte Calvo)
- [ ] 2–3 unidades de munición
- [ ] 1–2 unidades de refuerzo/machete
- [ ] 1 tipo de enemigo base + 1 variante
- [ ] Sistema de oleadas funcional (3–5 oleadas)
- [ ] HUD con ambos contadores de recurso
- [ ] Condición de victoria/derrota

## 10. Preguntas abiertas / decisiones pendientes

- Resolver [C4–C6 de 005](../specs/005-cinco-carriles/spec.md#precisiones-pendientes-para-plan): velocidades propias de salida/regreso, recarga solo vacía o también parcial con bloqueo durante regreso, y secuencia de filas continua o reiniciada por oleada. Plazas, ciclo principal y dotación inicial están confirmados; dimensiones y puntos de aparición se fijarán al planificar, sin deducir balance de la imagen.
- Acabado visual del enemigo y la caja de munición (I2/I3 de 004), interfaz y demás efectos, siguiendo la dirección de Monte Calvo aprobada en §8.
- ¿Habrá progresión entre niveles (más batallas históricas) o es un solo escenario?
- ¿Narrativa/contexto histórico se presenta dentro del juego (cutscenes, texto) o queda solo como inspiración temática?
- Balance de costos exactos de cada unidad (se define con playtesting).
- ¿La munición cae solo de enemigos derrotados, o también se acumula pasivamente con el tiempo? (supuesto actual: solo de enemigos)
- Todas las alternativas del gap crítico de T043 quedaron resueltas o descartadas — ver entrada en "Resueltas" abajo. La ausencia de una convención propia de `collision_layer`/`collision_mask` en el proyecto sigue documentada como tal (no una decisión tomada) en `docs/ARCHITECTURE.md` §5, sin bloquear nada hoy.

### Resueltas (graduadas desde specs de feature)

- ✅ Dirección visual de la primera iteración del terreno y las trincheras de Monte Calvo: entorno pictórico ocre/oliva, montañas azul grisáceo y decoración estática de tierra, madera y sacos, conservando actores provisionales y reglas actuales en aquella entrega. Aprobada en T016 de `002-monte-calvo-terreno-trincheras`; §8 y sus enlaces delimitan el alcance y la evidencia. I1 de 004 avanza después el soldado; enemigo, caja e interfaz continúan pendientes.
- ✅ Soldado pictórico y presentación de sus estados reales, sin alterar el combate ni esperar a la caída para retirarlo: I1 de `004-personajes-municion-monte-calvo`, aprobado en T011. §8 describe su alcance parcial; el patrón compartido de presentación y efecto independiente se gradúa a `ARCHITECTURE.md` §4.7. No resuelve el acabado del enemigo, la caja o la interfaz.
- ✅ Legibilidad del soldado y encuadre horizontal de Monte Calvo: corrección de I1 de 004 aprobada funcionalmente en T036. §8 recoge el mayor tamaño visual, contraste mate y encuadre que conserva la composición iPad; física, posiciones y reglas permanecen intactas. No amplía el alcance a I2/I3 o interfaz.
- ✅ Moral tras recarga: se conserva, no decae con el tiempo, se pierde solo si el soldado es derrotado. (spec `001-soldado-defensor-oleadas`)
- ✅ Alcance de diagonales: celdas diagonalmente contiguas a la posición del soldado, no un cono más amplio. (spec `001-soldado-defensor-oleadas`)
- ✅ Disparador de moral: solo al eliminar enemigos, no por impactos sin eliminación. Se corrigió el FR-006 del spec `001-soldado-defensor-oleadas`, que decía "impacta o elimina", para alinearlo con esta definición. (spec `001-soldado-defensor-oleadas`)
- ✅ Fórmula exacta de daño en modo machete según moral acumulada: `machete_damage = machete_base_damage + current_morale * machete_moral_multiplier` (lineal), con `machete_base_damage` y `machete_moral_multiplier` como campos `@export_range` de `UnitStats` (balanceables sin tocar código). Con moral en cero, `machete_base_damage > 0` garantiza el daño mínimo del Edge Case de `spec.md`. Implementada y validada en `soldado.gd` (T017-T024) y cubierta por `tests/unit/units/test_soldado.gd` (T015); decisión de diseño en `research.md` §2 de esa feature. (spec `001-soldado-defensor-oleadas`)
- ✅ Mecánica de recolección de la munición soltada por enemigos: acción explícita del jugador (tap/click sobre la pickup `AmmoPickup`), no automática por proximidad, por consistencia entre touch y mouse. No resuelve por sí sola si además habrá acumulación pasiva con el tiempo (pregunta todavía abierta arriba). Implementada en `scenes/levels/AmmoPickup.tscn`/`ammo_pickup.gd` y `Enemigo._spawn_ammo_pickup()` (T031/T032); decisión de diseño en `research.md` §3 de esa feature. (spec `001-soldado-defensor-oleadas`)
- ✅ Gap crítico de derrota alcanzable del `Soldado` (identificado en T043, ver historial abajo): cerrado por T050-T054 de `001-soldado-defensor-oleadas`, la alternativa 1 de las esbozadas por `qa-validator` ("agregar una tarea de salud/daño de `Soldado`"), elegida por la persona dueña del proyecto. `UnitStats.max_health` (T050) le da al `Soldado` una salud runtime; `Soldado.take_damage(amount) -> bool` (mismo contrato que `Enemigo.take_damage()`) reduce esa salud y, al llegar a 0, pone la moral acumulada en 0, emite `soldier_defeated(grid_cell)` y hace `queue_free()` (T052) — con cobertura de tests del Edge Case completo (T051). El daño entrante de cada `Enemigo` (`EnemyStats.melee_damage`, antes sin ningún uso) ahora sí se aplica, y con eso el `Soldado` deja de ser estructuralmente indestructible. La forma concreta en la que se detecta ese daño entrante (T053, con una vuelta atrás incluida) dejó un hallazgo de motor de alcance de proyecto, graduado a `docs/ARCHITECTURE.md` §4.2: una `Area2D` hija de un `CharacterBody2D` que se mueve con `move_and_slide()` (como `Enemigo`) no detecta de forma fiable sus overlaps contra un `StaticBody2D` (como `Soldado`) — por eso el daño se dispara desde la `Area2D` "RangoMelee" del propio `Soldado`, no desde una `Area2D` de `Enemigo`. Finalmente, T054 cierra el gap de punta a punta: al recibir `soldier_defeated(grid_cell)`, `nivel_monte_calvo.gd` libera la celda del tablero (`BoardManager.free_cell()`) tanto para el soldado colocado a mano en la escena como para cualquiera desplegado dinámicamente por el jugador, dejando de bloquear permanentemente el carril — con lo que la condición de derrota de FR-013 vuelve a ser alcanzable en la práctica, no solo en la salud interna del `Soldado`. No se tocó `collision_layer`/`collision_mask` (alternativa 2) ni la distribución de `wave_spawn_position` (alternativa 3) — ambas quedaron descartadas para este gap en favor de la alternativa 1. (spec `001-soldado-defensor-oleadas`)
- ✅ Cadena de derrota/victoria alcanzable de punta a punta en juego real: T038 (test) + T044 (implementación) de `001-soldado-defensor-oleadas`, validados por `qa-validator`, cierran el último eslabón que faltaba tras T050-T054. Ya no basta con que un `Enemigo` pueda alcanzar físicamente "PosicionDefendida" (eso lo resolvió el bloque anterior, dejando de ser indestructible el `Soldado`) — ahora `GameStateManager` (autoload real) efectivamente reacciona a ese hecho: `Enemigo.reached_defended_position` → `nivel_monte_calvo.gd` llama a `GameStateManager.report_reached_defended_position()` → transición real `PLAYING → LOST`; simétricamente, `WaveManager.all_waves_completed` (conexión autoload-a-autoload en `_ready()`) → transición real `PLAYING → WON`. Confirmado con un test de integración de punta a punta con instancias reales (`test_nivel_montecalvo.gd`) para el camino de derrota; el simétrico de victoria queda como hueco de cobertura conocido y no bloqueante (`docs/ARCHITECTURE.md` §6). Con esto, la condición de victoria/derrota de FR-012/FR-013 queda cerrada de punta a punta, no solo a nivel de señal contratada. (spec `001-soldado-defensor-oleadas`)

## 11. Historial de cambios

| Fecha | Cambio |
|---|---|
| 2026-08-12 | Versión inicial del spec a partir de la conversación de diseño |
| 2026-08-12 | Refinado el sistema de economía: munición como recurso único de doble uso, moral como stat individual por soldado que escala el daño cuerpo a cuerpo, y detección de disparo multidireccional (frontal + diagonales) |
| 2026-08-13 | Nombre del juego confirmado: "Demonios de las Trincheras" |
| 2026-09-11 | Graduadas tres decisiones desde el spec de feature `001-soldado-defensor-oleadas`: persistencia de moral tras recarga, alcance exacto de las diagonales, y disparador de acumulación de moral (solo eliminaciones, no impactos). Se corrigió el FR-006 de esa feature, que decía "impacta o elimina", para alinearlo. |
| 2026-09-11 | Reparado el archivo: contenía contenido duplicado/entreverado (versión vieja sin resolver + versión nueva, pegadas sin salto de línea entre ellas). Se recuperó la versión correcta sin pérdida de contenido. |
| 2026-09-12 | Graduada la fórmula de daño de machete según moral desde el spec de feature `001-soldado-defensor-oleadas` (T017-T024, validado por `qa-validator`): `machete_base_damage + moral * machete_moral_multiplier`, lineal, con daño mínimo garantizado en moral=0. Se retira de "pendientes" en §10. |
| 2026-09-12 | §6.1 y §10: graduada la decisión de recolección explícita por tap/click (no por proximidad) de la munición soltada por enemigos, implementada en T031/T032 de `001-soldado-defensor-oleadas` |
| 2026-09-12 | §6.1: graduada la nota de que el costo de una recarga completa equivale al de desplegar un soldado nuevo (`UnitStats.deploy_ammo_cost`, sin campo separado) — decisión ya explícita en `spec.md` Assumptions de `001-soldado-defensor-oleadas`, confirmada al implementar `Soldado.reload()` (T034, validado por `qa-validator`) |
| 2026-09-12 | §10: agregado gap crítico de diseño identificado durante T043 de `001-soldado-defensor-oleadas` (confirmado por `godot-tester` y `qa-validator` de forma independiente) — sin `collision_layer`/`collision_mask` explícitos, un `Soldado` vivo bloquea físicamente a todo `Enemigo` de su carril antes de que este pueda alcanzar "PosicionDefendida", y `Soldado` no tiene forma de ser derrotado en ninguna tarea planeada (`soldier_defeated` contratado en `contracts/signals.md` pero nunca emitido; `EnemyStats.melee_damage` definido pero sin uso). Documentado como pendiente de decisión humana, sin resolver ni elegir alternativa — el pipeline de `001-soldado-defensor-oleadas` queda en pausa en T043 hasta que se decida. |
| 2026-09-12 | §10: graduado el cierre del gap crítico de T043 — resuelto por T050-T053 de `001-soldado-defensor-oleadas` (validados por `qa-validator`): `Soldado` gana salud (`UnitStats.max_health`), `take_damage()`/`soldier_defeated` (T050-T052) y recibe daño real de cada `Enemigo` en su "RangoMelee" (T053), con lo cual deja de ser indestructible y la condición de derrota de FR-013 vuelve a ser alcanzable. Se retira el bullet pendiente de §10 y se agrega a "Resueltas". El hallazgo de motor detrás de la implementación final de T053 (`Area2D` sobre `CharacterBody2D` con `move_and_slide()` no detecta overlaps de forma fiable contra un `StaticBody2D`) se gradúa por separado a `docs/ARCHITECTURE.md` §4.2, por ser una convención técnica de alcance de proyecto, no solo de esta feature. |
| 2026-09-12 | §10: actualizada la entrada "Resueltas" del gap de derrota del `Soldado` para incluir T054 (`001-soldado-defensor-oleadas`, validada por `qa-validator`) — antes decía "cerrado por T050-T053" y atribuía la liberación de la celda del tablero a esas tareas, cuando en realidad `Soldado.take_damage()`/`soldier_defeated` (T050-T052) solo dan salud/derrota interna al `Soldado`; quien libera la celda (`BoardManager.free_cell()`, tanto para el soldado colocado a mano como para cualquiera desplegado dinámicamente) es `nivel_monte_calvo.gd` en T054. El gap queda ahora correctamente cerrado de punta a punta como bloque T050-T054. |
| 2026-09-12 | §10: graduada nueva entrada "Resueltas" — T038+T044 de `001-soldado-defensor-oleadas` (validados por `qa-validator`) cierran el último eslabón de la condición de victoria/derrota: `GameStateManager` real reacciona en juego real tanto a `Enemigo.reached_defended_position` (vía método público, no `.connect()` directo) como a `WaveManager.all_waves_completed`, confirmado con test de integración de punta a punta con instancias reales para el camino de derrota. Se deja nota de hueco de cobertura no bloqueante para el simétrico de victoria (ver `docs/ARCHITECTURE.md` §6). |
| 2026-10-15 | §4–5: Web para itch.io pasa a ser prioridad, se conservan Android/iOS nativos y se retiran los instaladores PC del alcance de producto; GDScript compartido protege compatibilidad Web. Configuración y pruebas del port pendientes en 003, sin cerrar 002 ni cambiar mecánicas. |
| 2026-10-16 | §4–5: referencia de portabilidad sincronizada con la entrega 003 aceptada en su alcance Chrome escritorio/Xiaomi horizontal; paquete revisado localmente, sin publicación, soporte universal o certificación de rendimiento sostenido. No se cierra 002. |
| 2026-10-16 | T017 de `002-monte-calvo-terreno-trincheras`, tras QA T016: §8 documenta el entorno pictórico y las trincheras estáticas aprobadas, con placeholders e interfaces pendientes; §10 resuelve solo esa dirección inicial. §6.1 incorpora la precedencia recolección→despliegue validada por el ciclo nativo T019–T022. Se enlazan evidencias y límites de iPad Simulator y Xiaomi provisional, sin completar el MVP ni cambiar plataformas. |
| 2026-10-16 | Integración de main tras PR #16: se conserva 002 aprobada junto con los destinos y la entrega Web de 003; constitución 2.1.0 reúne ambas decisiones. Las entradas anteriores describen sus estados históricos, sin extender la referencia Xiaomi de 002 a Web. |
| 2026-10-16 | T012 de 004, tras aprobación funcional T011: §8/§10 documentan el soldado pictórico, sus estados reales y la derrota cosmética sin retrasar retiro; enemigo/caja e interfaz siguen pendientes. Se distinguen Xiaomi provisional de 004, Web separado e iOS simulador/software, sin ampliar la aceptación a hardware o estabilidad sostenida. |
| 2026-10-17 | T037 de 004, tras QA funcional T036: §8/§10 incorporan la corrección de legibilidad del soldado y encuadre local de Monte Calvo, conservando geometría, reglas y composición iPad. Enemigo, caja e interfaz siguen pendientes. |
| 2026-10-19 | §4–6/§8: Web solo en computador y Android/iOS como apps instaladas por decisión de la persona y constitución 3.0.0; se conservan las verificaciones Web móviles históricas y los requisitos físicos nativos |
| 2026-10-19 | §6.2/§10: decisión de cinco filas horizontales para soldados colombianos, con enemigos de derecha a izquierda, a preparar como siguiente feature conservando I2 de 004; pendiente de especificación e implementación, sin cambiar aún el avance central, el combate ni los stats vigentes |
| 2026-10-19 | §6.2–6.3/§10: la persona prioriza la preparación de 005 en rama nueva conservando I2 pendiente; confirma fusil dentro de cinco trincheras izquierdas y salida frontal con machete al agotar balas. Referencia visual y decisiones abiertas enlazadas, sin afirmar implementación o aceptación QA del juego |
| 2026-10-19 | §6.3/§10: aclaradas cinco plazas reservadas, cinco soldados cargados/reserva cero, salida en misma fila y recarga desde trinchera con regreso antes de disparar; oleadas con cantidades/tiempos vigentes y reparto prefijado. Pendiente de planificación e implementación de 005, sin cerrar I2 |
