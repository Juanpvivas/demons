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

**La carta** ([013](../specs/013-introduccion-la-carta/spec.md)), integrada en
`main` por [PR #54](https://github.com/Juanpvivas/demons/pull/54) (`77be629`),
presenta siete escenas antes de la primera partida.
La carta y sus personajes son ficción inspirada en el Batallón Colombia,
no testimonios ni retratos de veteranos identificados. Incluye subtítulos y
siete narraciones humanas de la toma3 aportada, elegida y autorizada por la
persona autora, un compañero sintético Qwen3-TTS VoiceDesign y ambiente
original. La persona aceptó expresamente el clip del compañero como voz
definitiva; esa aceptación perceptual humana no se atribuye a los agentes.
T026 aprueba la incorporación técnica de la toma elegida; su aceptación
perceptual es humana y no se atribuye audición propia a los agentes.

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
- Cada soldado acumula su propia moral al eliminar enemigos: el fusil concede +1; desde 015, cada baja letal de machete concede +2 moral y cura 3 de vida al dueño aún vivo, sin exceder su máximo actual 30. No hay premio por impacto no letal, cleanup o callback repetido ni resurrección.
- Al quedarse sin munición, el soldado pasa automáticamente a combate cuerpo a cuerpo (machete).
- El **daño del machete depende de la moral acumulada por ese soldado en particular**: base 3 + moral×1. Las bajas de fusil y las nuevas bajas de machete refuerzan sus ataques posteriores.
- **Confirmado** (spec `001-soldado-defensor-oleadas`): si el soldado es recargado después de haber entrado en modo machete, vuelve a modo fusil conservando la moral acumulada — la moral no decae con el tiempo, y solo se pierde por completo si el soldado es derrotado.

Esta economía recrea la tensión histórica real: cada bala cuenta, y sobrevivir el tiempo suficiente disparando paga dividendos cuando llega el momento de pelear cuerpo a cuerpo.

### 6.2 Sistema de colocación

El tablero de [005-I1](../specs/005-cinco-carriles/spec.md) tiene cinco filas
horizontales y cinco plazas de defensa a la izquierda, una por fila. Empieza
con cinco soldados cargados, sin cobrar sus despliegues, y reserva global de
munición cero. Sólo esas cinco casillas admiten un soldado: una plaza ocupada
o un punto exterior se rechazan antes de gastar. La muerte libera la plaza
para un único reemplazo con fondos suficientes. El snap sigue usando el grid.

Los soldados con balas permanecen en su hogar, disparando hacia la derecha;
los enemigos avanzan desde la derecha hacia la defensa izquierda sin cambiar de fila.
El fusil cubre el frente de su fila y sólo las dos celdas diagonalmente
contiguas dentro del alcance físico vigente. No ataca hacia atrás, en
diagonales profundas ni dos filas más allá. Conserva un blanco elegible;
cuando necesita elegir, prioriza al más avanzado hacia la izquierda.

Una recogida de munición bajo un actor o sobre una plaza libre/ocupada conserva
su precedencia: no despliega ni cobra con el mismo gesto. Las cajas solapadas
mantienen la semántica existente. La cámara centra el tablero en ambos ejes;
los gestos se convierten con la transformación inversa del canvas tras resize.
005-I4, integrado mediante [PR #27](https://github.com/Juanpvivas/demons/pull/27),
sustituye los recuadros de plaza por cinco trincheras laterales y conserva
bandas discretas y números de fila.
Ninguna decoración concede cobertura ni cambia las plazas jugables.

### 6.3 Tipos de unidad (borrador inicial — por refinar)

**Soldado base (única unidad inicial, dos modos):**
- **Modo fusil** (por defecto al desplegarlo): dispara hacia +X a enemigos elegibles del frente de su fila o celdas diagonalmente contiguas, dentro del alcance físico del arma, con una cantidad limitada de disparos definida por su munición actual.
- La revisión de 010 amplió el extremo frontal de 264 a 396; 015 lo lleva a 864 mediante `UnitStats.rifle_range`/`.tres`, desde hogar x144 hasta entrada x1008. Conserva límite cercano 24, altura 192 y solape real del cuerpo enemigo; no amplía diagonales contiguas ni machete.
- **Modo machete** (automático al quedarse sin munición): combate cuerpo a cuerpo, rango de 1 casilla frontal, daño escalado según la moral acumulada por sus bajas de fusil o machete.
- Los stats vigentes viven en `UnitStats`/`soldado_base_stats.tres`; el cambio de orientación no altera daño, carga, moral, costo o cadencia.

**005-I2, integrado en `main` mediante [PR #25](https://github.com/Juanpvivas/demons/pull/25):** al agotar
la munición, el mismo soldado pasa a machete y sale hacia un enemigo delante
en su fila, sin cambiar de carril. Avanza a 40 unidades de mundo/s, con velocidad
propia ajustable en `UnitStats`/`.tres`, independiente de los stats enemigos.
Se detiene al entrar en alcance frontal y combate con las reglas vigentes de
daño, cadencia y moral; la colisión entre cuerpos impide atravesarse. Si pierde
o elimina el blanco, busca otro frontal de su fila o espera donde está. Una
última bala que elimina al único enemigo frontal no provoca una salida sin
objetivo. No persigue enemigos detrás ni en otras filas.

La plaza permanece reservada mientras viva, aunque se aleje. Ambos actores
reciben daño real y pueden morir; al morir, el soldado deja de combatir,
pierde su moral y libera su plaza de origen sin esperar la caída visual.

**Vida visible de ambos bandos (011-I1, aprobado funcionalmente en T008):**
colombianos y enemigos vivos muestran siempre una barra sobre el casco, sin
números, con borde oscuro y relleno mate proporcional a su vida restante.
El relleno baja inmediatamente: oliva por encima del 50 %, ocre por encima
del 25 % hasta el 50 % inclusive, y rojo apagado al 25 % o menos. La barra
desaparece al morir o retirarse, sin acompañar la caída; cada nueva aparición
restaura su propio estado. Recargar conserva la vida y no cura. El indicador
mantiene corrida, color del soldado y reglas de combate vigentes. El
[alcance de 011](../specs/011-barras-de-vida/spec.md) conserva la publicación pendiente.

**005-I3, integrado en `main` mediante [PR #26](https://github.com/Juanpvivas/demons/pull/26):** seleccionar
una trinchera muestra fila, carga/capacidad y moral de su dueño vivo, también
cuando está fuera; no despliega otro soldado ni cobra. «Recargar» sólo acepta
carga cero, fondos suficientes y partida PLAYING, sin orden ya aceptada o
retorno activo. Cobra `UnitStats.deploy_ammo_cost` una sola vez, repone la
carga y conserva salud/moral. Una intención dirigida a un dueño muerto o
reemplazado no recarga a su sucesor.

Fuera del hogar, regresa físicamente por su fila a 40 unidades/s, vulnerable
y sin disparar ni golpear hasta llegar; dentro, recupera el fusil sin viaje.
El panel indica «Regresando». Morir libera su origen
y cancela la selección sin reembolso; el fin de partida detiene movimiento,
combate y nuevas órdenes. La recogida conserva precedencia sobre selección y
despliegue; los controles consumen su gesto sin activar el tablero.

**Recarga directa por trinchera (012-I1, revisión funcional aprobada en T018):**
La propia trinchera de cada dueño vivo sin balas señala la recarga, incluso
si está fuera y sin selección previa: rojo tenue estático sin fondos y un
pulso rojo suave sólo cuando puede recargar en PLAYING. No muestra texto,
cartel ni botón visible. Un toque sobre la trinchera ordena la recarga de
ese dueño, conservando coste, salud/moral y regreso, sin doble cobro ni
actuar sobre reemplazos por intenciones antiguas. Reponer la carga, morir,
retirar o cerrar restaura el aspecto normal; pausa y terminal detienen el
pulso y no aceptan órdenes. El brillo conserva el arte y su oclusión, sin
teñir actores, barras de vida, HUD ni hogares vecinos.

El panel sigue informativo con fila, carga/capacidad, moral y regreso, sin
su botón anterior. La zona táctil acompaña el arte fijo del hogar tras
resize, nunca al soldado; consume el gesto incluso deshabilitada. Fuera de
ella conserva prioridad la recogida y los hogares cargados mantienen su
selección normal. El [alcance de 012](../specs/012-recarga-trinchera/spec.md#alcance-de-la-aprobación-funcional)
detalla los límites de entrada nativa, renderer/paquete final y
rendimiento aún sin certificar; la publicación conserva su gate separado.

La [referencia aprobada](../specs/005-cinco-carriles/references/visual-reference.md)
orienta la composición lateral y no fija costos, estadísticas ni HUD final.

**Futuras unidades (post-MVP, no bloquean el prototipo inicial):**
- [ ] Variantes con distinto alcance/cadencia (ej. mortero de área, francotirador de rango largo)
- [ ] (agregar más según playtesting)

### 6.4 Enemigos y oleadas

- Oleadas crecientes en dificultad, representando el avance de tropas chinas/norcoreanas.
- Definición de enemigos vía `Resource` personalizados (stats: vida, velocidad, daño, tipo).
- Comparten la barra de vida descrita en §6.3; cada enemigo conserva su proporción y color independientes, también al reutilizarse.
- Sistema de spawn controlado por `Timer` + cola de oleadas.
- Monte Calvo conserva un atacante inicial inmediato en la fila central 3 y
  99 enemigos autorados en diez oleadas: 100 en total, sin cambiar cantidades
  ni tiempos. Los de oleadas siguen 1→2→3→4→5 continuamente entre oleadas;
  el inicial no consume ni reinicia esa secuencia. Ambos usan el mismo pool.
- Sólo las bajas de los 99 enemigos de oleadas cuentan para victoria; el
  atacante inicial conserva combate, munición y moral vigentes. El cruce real
  de cualquier enemigo por la defensa izquierda produce una única derrota.
  Los estados terminales bloquean nuevas acciones y otra partida reinicia
  estado, reserva y cursor.

**Fusil enemigo y recompensa (015-I1, integrado por PR #59, `73c2dff`):**
el fusilero vivo dispara hacia −X sólo a un colombiano vivo de su carril, con
alcance 864; se detiene, dispara al adquirir y después respeta su intervalo.
Sin blanco vuelve a marchar; contacto y fusil son excluyentes y no hay munición
enemiga nueva. Los diez perfiles siguen la [tabla autorizada](../specs/015-combate-a-distancia-y-recompensas/spec.md#progresión-autorizada):
daño/intervalo de 1/4 s en ola 1, 2/3 s en ola 5 y 3/2 s en ola 10; el inicial usa
perfil 1. HP15, velocidad40, melee5, drop3 y cantidades/ritmos de spawn permanecen.
La baja letal de machete premia una vez al dueño vivo incluso si activa victoria;
la derrota sigue dependiendo del cruce de PosicionDefendida, no del último soldado.
El avance a machete está expuesto al fusil enemigo y se observaron derrotas tempranas;
esto es un riesgo táctico, sin conclusión de imposibilidad de victoria ni nuevo
balance autorizado. [Verificación y límites](../specs/015-combate-a-distancia-y-recompensas/research.md#alcance-funcional-aprobado-y-límites):
I1 conserva CI/QA de integración de `2351798`; I2 cuenta con CI y QA de
integración aprobados en `d8826e2`. Ambos incrementos están integrados en `main`
por [PR #59](https://github.com/Juanpvivas/demons/pull/59), `73c2dff`;
publicación T015 sigue pendiente.

**Composición mixta (015-I2, aprobación funcional T021):** los 99 enemigos WAVE
siguen A,A,R de forma continua entre oleadas: 66 asaltantes sin fusil y 33
fusileros. El inicial es otro fusilero de perfil1 y no consume la secuencia ni
el cursor de carriles WAVE. Ambos mantienen HP15/velocidad40/melee5/drop3;
los fusileros conservan la tabla anterior y los asaltantes avanzan con el
comportamiento previo sin fusil. Cantidades, intervalos y reparto 1→5 no cambian;
la [tabla de composición](../specs/015-combate-a-distancia-y-recompensas/spec.md#enmienda-015-i2--dos-asaltantes-por-fusilero)
fija los totales por oleada. No hay nueva IA ni cambios de colisión.

## 7. Estructura técnica en Godot (borrador)

**Sonidos de combate (014-I1, integrado en `main` por [PR #56](https://github.com/Juanpvivas/demons/pull/56), `45cd83a`):** cinco eventos
confirmados —fusil, baja enemiga, baja colombiana, victoria y derrota— usan
nueve variantes locales. Las bajas incorporan exclamación breve masculina
ficticia y caída/equipo, sin imitar las voces de La carta. La última bala letal,
la baja y la victoria pueden sonar sin que el resultado corte lo ya admitido.
Daño no letal, cleanup/despawn, menú y retry no inventan bajas o resultados.
La mezcla finita, variación cosmética y control de saturación son presentación,
sin cambiar stats, RNG jugable o reglas. Pausa/foco silencian, sin cola atrasada;
menú/retry cierran las voces propias. Audio definitivo de013 y Master intactos.
[Procedencia y límites](../specs/014-sonidos-combate/research.md): audición,
latencia/techo Web y hardware no certificados. Gate de integración T012/CI
aprobado; publicación T014 sigue pendiente, con pausa006 y pendientes004/005/013 conservados.

- **Autoload `EconomyManager`:** controla el contador global de Munición recolectada, expone señal `ammo_pool_changed`.
- **Tablero:** `TileMap` convierte mundo↔celda; `LaneBoardConfig` define cinco plazas/entradas y zona defendida. El nivel valida esas plazas antes de cobrar y `BoardManager` mantiene su ocupación.
- **Movimiento y detección por soldado:** ambos actores usan `CharacterBody2D`; el soldado avanza con `move_and_slide()` en el tick físico. Consultas físicas de ese tick reúnen candidatos y los filtros conservan frente, fila, alcance y diagonales directas del fusil. El machete busca un frontal de su fila incluso lejos, pero sólo daña dentro de su alcance. No depende de overlaps almacenados de áreas móviles ni mueve sólo el sprite.
- **Validez de blancos:** se comprueba la instancia antes de operaciones tipadas; después, presencia activa, elegibilidad y generación de activación. Se conserva el blanco elegible; al perderlo se prioriza el más avanzado hacia la defensa izquierda, sin dividir fuego ni atacar a un uso anterior del mismo cuerpo reciclado.
- **Stats por instancia de soldado:** cada soldado en escena mantiene su propio estado local (munición actual, moral acumulada, modo activo: fusil/machete) — no vive en el `EconomyManager` global, solo el pool de munición recolectada es global.
- **`AnimatedSprite2D` / `AnimationPlayer`:** animaciones de disparo, cambio a modo machete, ataque cuerpo a cuerpo y muerte.
- **Unidades y enemigos como `Resource` (.tres):** stats base (daño, cadencia, alcance, fórmula de daño machete) desacoplados del código, para poder balancear sin tocar scripts.
- **Baja y recolección:** `enemy_defeated` permite al spawner contar sólo bajas de oleada y reciclar al enemigo. El actor genera una pickup en su posición de muerte y notifica su aparición; la reserva global sólo aumenta al recogerla. El soldado confirma la baja para sumar moral únicamente si fue con fusil. El contexto de baja se conserva aunque el pool reutilice el cuerpo síncronamente.

## 8. Arte y estilo visual

**Introducción La carta (013-I1-R3):** siete cuadros del storyboard aceptado,
con fundidos y encuadres suaves, conservan soldado, carta, uniforme y paleta.
El primer «Jugar» abre la secuencia; terminarla u omitirla deja «Comenzar»
esperando un gesto nuevo, sin combate activo. El recuerdo local por versión
permite iniciar directamente las partidas posteriores. «Ver introducción»
la repite desde el menú y también termina/omite en Comenzar; nunca vuelve al
menú ni inicia combate automáticamente. «Volver a jugar» sigue siendo directo.
«Pausar»/«Continuar» controlan voz, ambiente y avance; perder actividad pausa hasta
continuación explícita. Un fallo al guardar no impide jugar.
En final u omisión sólo aparece Comenzar centrado abajo en la franja segura de
controles, con alto mínimo de 52 px y sin panel/banda, títulos, ficción,
subtítulos u otros controles. La imagen visible conserva opacidad/encuadre al
redimensionar mientras se espera; voz y ambiente ya están detenidos.
Las siete imágenes sólo muestran subtítulos de voz y controles, sin contador,
caption ni aviso superior. Un ambiente original de viento/rumor grave suena
en canal separado y cesa con la reproducción. «Menú principal», visible en la
franja superior durante partida activa/pausada, cierra el intento sin modal ni
guardado; su zona no se superpone a las trincheras/recarga.
El arte y las voces humana/sintética tienen [procedencia documentada](../specs/013-introduccion-la-carta/research.md).
T032 aprobó función R3 y T026/SC-009 en el alcance de narrador toma3 elegido y
compañero provisional divulgado en aquel momento. R4 conserva sus aprobaciones
técnicas y la persona ha elegido ese mismo clip como voz definitiva del
compañero; no cambia narrador, montaje o controles ni implica audición del agente.
Publicación T014 sigue separada. No se acredita toque iOS, hardware, 60 FPS o paquete final;
el riesgo de carga/memoria de precarga se conserva con [límites explícitos](../specs/013-introduccion-la-carta/research.md#alcance-funcional-r3-y-límites).

**Dirección aprobada para el entorno de Monte Calvo, primera iteración**
(`002-monte-calvo-terreno-trincheras`): ilustración 2D de textura pictórica,
suelo ocre/oliva y montañas azul grisáceo entre la bruma. El centro de combate
mantiene menos detalle que los bordes; tierra excavada, madera y sacos de arena
enmarcan la posición defendida. La [referencia aprobada](../specs/002-monte-calvo-terreno-trincheras/references/visual-reference.md)
orienta los materiales y la jerarquía visual. La composición original de un
avance central se conserva como antecedente; 005-I1 la acompaña de cinco bandas
y plazas provisionales y oculta las antiguas trincheras inferiores en el nivel.
005-I4, integrado en `main` mediante PR #27, añade cinco
puestos laterales: interior de tierra/madera detrás del actor y parapeto de
sacos delante de sus piernas. El fusil y el torso permanecen legibles; la
decoración deja recoger las cajas sobre el hogar o bajo los actores.

El entorno es estático y sus trincheras son decorativas: no añaden cobertura,
obstáculos, carriles, casillas o límites de despliegue. El primer incremento de
[`004-personajes-municion-monte-calvo`](../specs/004-personajes-municion-monte-calvo/spec.md),
aprobado funcionalmente en T011, sustituye el bloque del soldado inicial y de
los nuevos despliegues por un colombiano de uniforme oliva, casco y armas
legibles. Sus poses distinguen espera/disparo de fusil y espera/golpe de machete
según el modo y los ataques reales. La última bala da prioridad al cambio de
pose a machete; la recarga existente restaura el fusil conservando la moral.
Impacto y moral ganada tienen respuestas breves, y la derrota prevalece sobre ellas.

La corrección de I1, aprobada funcionalmente en T036, aumenta solo el hijo
visual del soldado a una altura opaca neutra aproximada de 72 unidades,
conservando los pies en raíz+y24 y el cuerpo de 48×48. Un material mate aclara
los tonos medios y añade un borde interior discreto para separarlo del suelo,
también en grises. El encuadre local centra el eje de combate al ensanchar la
pantalla, conserva la composición vertical del iPad y cubre el margen izquierdo
con cielo, panorama y suelo existentes. Esa corrección no movió trincheras,
actores ni grid. Después, 005-I1 centra el rectángulo completo del tablero en
ambos ejes sin desplazar la geometría jugable al redimensionar.

La caída del soldado se muestra durante 0,40 s en un efecto independiente,
sin cuerpo, input u ocupación: la celda se libera y el actor jugable se retira
sin esperar la animación. Las imágenes no aplican daño ni cambian recursos,
cadencias o resultados.

004-I2 incorpora la infantería enemiga pictórica y su presentación observadora:
el avance se representa sólo si hubo desplazamiento físico real, el bloqueo
muestra contacto y el impacto responde a daño confirmado. La baja captura su
apariencia neutra antes del reciclado y usa la misma caída independiente. El
reset por activación limpia poses, tintes, tweens y callbacks anteriores; la
animación no gobierna daño, recompensas ni retiro. La procedencia está en
[el catálogo del enemigo](../assets/sprites/enemies/monte_calvo/SOURCES.md).
005-I4 sustituye los frames de producción por poses laterales: colombiano
hacia la derecha y enemigo gris/marrón hacia la izquierda. La marcha con
machete sólo se muestra tras desplazamiento real; sin movimiento hay espera
o golpe confirmado. El regreso muestra fusil bajo hacia la izquierda, con
pose quieta si está bloqueado. La última bala cancela la pose de disparo
incompatible; volver al hogar restaura el fusil. La caída conserva la orientación real,
incluido el retorno, sin seguir al cuerpo retirado. Estos cambios no otorgan
protección ni alteran combate, economía o velocidades.

[008-I1](../specs/008-marcha-enemiga/spec.md) renueva sólo la marcha enemiga
con ocho poses de apoyos alternados en un ciclo de 0,60 s, conservando el acabado
pictórico gris/marrón, la escala y el apoyo sobre el suelo. La referencia de
Metal Slug orienta el movimiento; no se incorpora su personaje o pixel art.
Contacto y caída siguen usando el atlas anterior; la animación observa el mismo
desplazamiento real y no altera velocidad, colisiones, daño o reutilización.
La validación local funcional/visual de T004 tiene [límites por destino](../specs/008-marcha-enemiga/research.md#alcance-funcional-y-visual-de-i1):
Chrome incluye contacto/derrota natural/Retry; Android e iPad acreditan sus
recorridos propios, con variantes internas de QA. No certifica el paquete
original nativo, Mobile, hardware o victoria manual de producción completa.
El cierre de integración y CI exacta se registra en el seguimiento/PR; 006
permanece pausado por decisión de la persona y la publicación sigue pendiente.

[009-I1](../specs/009-carrera-soldado-colombiano/spec.md) renueva sólo las
corridas colombianas de salida con machete y regreso con fusil bajo: ocho
fases de apoyos alternados por clip, sin salto involuntario al cerrar el ciclo
de 0,60 s. Conserva el personaje pictórico, encaje, velocidad y reglas; las
seis animaciones restantes siguen usando sus poses anteriores. El alcance local
está aprobado en T004 y sus [límites por destino](../specs/009-carrera-soldado-colombiano/research.md#alcance-funcional-y-visual-de-i1)
distinguen regreso/HOME observados en Chrome, regreso sin HOME en iPad y salida
sin regreso/HOME manuales en Android. La regresión común no sustituye esos
recorridos manuales; las variantes internas no certifican Mobile, hardware,
IPA final ni victoria manual de producción completa. Seguimiento y PR conservan
el cierre exacto de integración, con 006 pausado y publicación pendiente.

[010-I1](../specs/010-disparos-visibles/spec.md) añade a cada disparo real un
destello cálido mate y una trazadora hacia la posición capturada del blanco
frontal o diagonal. La revisión autorizada, aprobada funcionalmente en T018,
duplica el tamaño: destello de silueta 26×12 durante 0,14 s y trazo de hasta
92 unidades. Su cabeza avanza desde el cañón al destino durante 0,30 s con
intensidad conservada y se desvanece durante otros 0,10 s. No ilumina al
colombiano ni cambia sus corridas, daño inmediato, munición o cadencia; el
alcance frontal ampliado es el único cambio de balance. La última bala
puede completar este efecto independiente aunque la pose ya cambie a machete.
Pausa congela su progreso; victoria/derrota dejan terminar sólo los tiros ya
confirmados, y menú/cierre/otra partida los retiran de inmediato.
Chrome de computador acredita el recorrido completo y la sesión de balance;
Android Emulator acredita destello, combate, derrota y repetición, sin aislar
el recorrido completo. iPad Simulator acredita inicio por teclado, combate y
machete; no acredita el efecto, repetición, recogida o retorno manuales, y
conserva una franja gris observada sin causa atribuida. Diagonales, simultáneos
y demás casos de ciclo tienen cobertura automatizada, sin atribuirles
recorridos manuales no ejecutados. Las variantes nativas Compatibility/software
no certifican Mobile, hardware, IPA final ni 60 FPS. El seguimiento del cierre
de integración y de la CI de cada revisión queda en el [PR #41 en borrador](https://github.com/Juanpvivas/demons/pull/41);
publicación pendiente y diagnóstico 006 pausado.

La [procedencia del soldado](../assets/sprites/units/monte_calvo/SOURCES.md)
y [del entorno](../assets/sprites/levels/monte_calvo/SOURCES.md) documentan los
nuevos atlas y conservan los anteriores. 004-I3, aprobado funcionalmente para
integración en T027, reemplaza la caja amarilla por una caja oliva mate con
cartuchos de latón. T040–T043 aumenta el sprite un 25 % y añade brillo;
la ampliación T047–T049 lo aumenta otro 50 % respecto a esa versión.
Conserva el pulso lento de 1,4 s, sin desaparición ni cambio de alfa
de modulación. La textura importada sigue siendo 256×256 y el arte permanece
dentro de la envolvente visual de 60×60; conserva radio de recolección 20,
posición del drop, valor y recogida explícita con precedencia. Puede quedar
parcialmente oculta bajo actores o parapetos. Los extremos visibles fuera del
círculo de radio 20 no amplían su área interactiva; se recoge desde el centro. La
[procedencia de la caja](../assets/sprites/pickups/monte_calvo/SOURCES.md)
documenta el original y su encaje.

005-I3 incorpora HUD mínimo de selección/recarga, avisos y pantalla terminal;
I4 conserva sus controles y adaptación. El acabado adicional de interfaz y
audio futuro fuera de013/014 sigue pendiente; la introducción y los cinco cues
de combate ya están integrados. I5 consolida el alcance funcional integrado mediante
[PR #28](https://github.com/Juanpvivas/demons/pull/28); las
[tareas de 005](../specs/005-cinco-carriles/tasks.md) mantienen el estado de
entrega y PR. La publicación, las features 004/005 y el MVP siguen abiertos.

[007 — Menú de inicio y nueva partida](../specs/007-menu-inicio-reinicio/spec.md),
integrado mediante el [PR #34](https://github.com/Juanpvivas/demons/pull/34),
implementa US1–US3: la entrada muestra el menú con arte
estático de Monte Calvo, sin un nivel activo detrás. «Jugar» inicia una única
partida con las condiciones vigentes, sin propagar el gesto al tablero.
US2 añade «Volver a jugar» desde victoria o derrota: retira el intento anterior
y restablece soldados, recursos, plazas, selección y oleadas sin refrescar ni
reabrir. Eventos del intento retirado no alteran el siguiente.
US3 añade «Menú principal» desde ambos resultados: retira la partida y deja
el menú inerte con «Jugar» disponible y enfocado; sólo esa acción inicia otro
intento limpio. Repetición y regreso comparten el mismo cierre protegido.
El ciclo lógico está aprobado funcionalmente con una oleada autorada de un enemigo;
la derrota usa además un enemigo de cruce controlado. Este escenario reducido
no acredita una victoria manual con los 100 enemigos de producción, cuyo reparto
de 1 inicial + 99 se conserva.

Menú y resultado comparten el acabado oliva/crema/ocre y foco dorado del recurso
`resources/ui/monte_calvo_theme.tres`. El flujo, las esperas activas de menú y la
legibilidad fueron verificados en Chrome de computador, Android AVD Compatibility
e iPad Simulator Compatibility/Apple Software Renderer. El smoke separado de
producción alcanzó derrota natural y un nuevo inicio limpio; no certifica
victoria manual contra 100 enemigos ni rendimiento físico.

Los paquetes nativos internos conservan assets GUT/fixtures inactivos; sus
variantes de QA y el empaquetado original no equivalen a un artefacto final
aprobado. El error del loader GUT al exportar Android original también se
reprodujo en la base; el paquete original no se considera limpio ni aprobado.

Las mediciones Web son descriptivas: no aíslan una mejora
causal ni certifican 60 FPS estables. El monitor de memoria de render del motor
subió unos 11–13 MiB en la candidata; no es RSS ni VRAM y no demuestra causa o fuga.
En Android AVD/SwiftShader, la mediana de combate pasó de unos 41,3 a 39,9 FPS
(−3,5 % observado); el menú sin actores rondó 32 FPS. En iPad Simulator/Apple
Software Renderer, ambas revisiones rondaron 6,66 FPS durante combate y el menú
sin actores rondó 4,27 FPS. Los monitores de memoria de render nativos aumentaron
unos 4,5 MiB. Son observaciones
en software, con cohortes dinámicas; no atribuyen causa o fuga ni se extrapolan
a dispositivos físicos. Las pausas previas al calentamiento continuo se conservan
separadas de las ventanas medidas válidas. El veredicto y CI de la revisión exacta
se registran en el PR y en las [tareas de 007](../specs/007-menu-inicio-reinicio/tasks.md).
Este avance no cierra 004/T039, 005/T071, 006 ni publicación.

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

La constitución 4.0.0 distingue integración funcional de publicación. La
integración conjunta 004-I2/005-I1, realizada en `main` mediante el
[PR #24](https://github.com/Juanpvivas/demons/pull/24), y la integración de
005-I2/005-I3 mediante los [PR #25](https://github.com/Juanpvivas/demons/pull/25)
y [#26](https://github.com/Juanpvivas/demons/pull/26), la de I4 mediante
[#27](https://github.com/Juanpvivas/demons/pull/27) y la consolidación funcional
I5 no certifican 60 FPS físicos, Mobile, GPU,
renderer o empaquetado final; esos gates y SC-007 permanecen pendientes de
publicación en las tareas de cada feature. Las comprobaciones de emulador,
simulador y Compatibility/software conservan sólo su propio alcance.

La aprobación funcional de I3 cubre Chrome de computador y apps instaladas en
Android Emulator/iOS Simulator con Compatibility y renderizado software.
Se observaron caídas importantes (aprox. 39 FPS en Android y 6,67 FPS en iOS);
no certifican 60 FPS físicos, Mobile ni costo del retorno: las muestras tenían
cinco soldados en HOME y ninguno fuera. El smoke de producción llegó a LOST;
los casos difíciles se verificaron en fixtures separados, sin acreditar una
victoria manual de producción. El paquete/renderer final original y hardware
permanecen pendientes en T071.

La aprobación funcional de I4 cubre Web de computador y variantes de apps
instaladas en Android Emulator/iOS Simulator. Web y Android incluyen entrada
tras cambiar la vista; iOS acredita sólo la vista disponible del iPad Simulator.
Los estados difíciles y la victoria determinista usan fixtures separados de
las partidas de producción; no acreditan victoria con los 100 enemigos.
El renderer software y las variantes temporales conservan sus límites de
publicación, sin certificar el paquete final ni SC-007.
La comparación I4 en Android software bajó de unos 49,6 a 41,7 FPS, con
empeoramiento de los tiempos de frame; el fixture dinámico usa cohortes
distintas y no descarta esa regresión. iOS se mantuvo cerca de 150 ms por frame
(6,67 FPS), con stdout parcial y sin aislamiento acreditado respecto de la
antigua app I2. Son muestras descriptivas de esos entornos, sin atribuir
causalidad ni certificar hardware.

I5 conserva esos límites al revalidar la suite y la carga del nivel original.
El conteo de 100 enemigos y la victoria por 99 bajas de oleada tienen
cobertura automatizada; el recorrido de producción hasta LOST y la victoria
determinista separada conservan el alcance aprobado de I4. Esto no acredita
una victoria manual con los 100 enemigos ni una revisión visual nueva.

La aceptación funcional de 004-I3 distingue Web en computador y apps instaladas
en Android Emulator/iPad Simulator, con variantes Compatibility de QA. Conserva
la regresión Android observada en I4: muestras posteriores a otra resolución
no la descartan. iOS mantiene rendimiento software muy limitado y picos,
con stdout parcial y sólo la vista disponible. Las comparaciones no prueban
causalidad ni carga fría, memoria exclusiva o rendimiento físico. Producción
llegó a LOST; la victoria y los casos difíciles de economía/recarga se verifican
por separado. T039 de 004 y T071 de 005 siguen pendientes de publicación.
La corrección de brillo tiene aprobación funcional T043 con smoke de varias
cajas animadas; añade trabajo por instancia cuyo coste no se ha cuantificado.
Las muestras anteriores conservan su alcance y no certifican ese coste ni el
de la cobertura visual mayor aprobada en T049.

El diagnóstico limitado de [006-I1](../specs/006-diagnostico-rendimiento/spec.md),
aprobado para integración en T009, añade un instrumento optativo sin cambiar
el juego. En Chrome/macOS, las comparaciones del fixture constante con
observador mínimo y sin material del soldado no distinguen una ganancia de
la dispersión y la cadencia observadas. En Android Emulator/Compatibility,
la deriva entre repeticiones y las lecturas de foco/vsync que devuelven
valores fijos impiden una conclusión causal; producción rondó 49,3–49,5 FPS,
sólo como descripción. Tras resolver el bloqueo inicial del Mac, tres ventanas
descriptivas de iPad Simulator con Apple Software Renderer registraron medias
de 150,12–150,92 ms por frame (unos 6,6 FPS). El collector conserva intervalos
independientes; el probe permanece inválido intencionalmente, con condiciones
esperadas vacías al no acreditar foco/vsync efectivos. Estas lecturas no completan una base
comparable ni atribuyen el coste a GPU, shader o entorno.
No se autoriza un parche del shader ni se dan por resueltas las caídas
históricas. Las bases nativas de T008/SC-001, US2 y T039/T071 siguen pendientes;
el [protocolo](../specs/006-diagnostico-rendimiento/contracts/profiling-protocol.md)
delimita las próximas mediciones, sin acreditar hardware o paquete final.

I2, sobre `2272aa2`, añade perfilado de componente GPU Web separado del probe
global. T009-I2 aprueba diagnóstico sin parche: la señal favorable de cola no
demuestra ahorro medio general ni ganancia de FPS. Observador, colas wall y
variación de memoria conservan sus límites en la [decisión](../specs/006-diagnostico-rendimiento/research.md#decisión-de-t009-i2-diagnóstico-gpu-limitado-sin-t010).
Producto y pendientes nativos/US2/T039/T071 permanecen intactos, sin publicación.

## 9. Alcance del MVP (primera versión jugable)

- [ ] 1 nivel (ej. defensa de Monte Calvo)
- [ ] 2–3 unidades de munición
- [ ] 1–2 unidades de refuerzo/machete
- [ ] 1 tipo de enemigo base + 1 variante
- [ ] Sistema de oleadas funcional (3–5 oleadas)
- [ ] HUD con ambos contadores de recurso
- [ ] Condición de victoria/derrota

## 10. Preguntas abiertas / decisiones pendientes

- Publicación de [005](../specs/005-cinco-carriles/tasks.md), T071/SC-007: rendimiento físico, renderer y artefacto final, firma/instalación/versionado y matriz de destino. I1–I4 están integrados en `main` mediante los PR #24–#27 e I5 consolida el alcance funcional aprobado; las tareas mantienen el estado de entrega. No deducir balance de la imagen.
- Acabado adicional de interfaz, audio futuro fuera de013/014 y demás alcance del MVP, siguiendo §8; HUD/recarga/resultados de005, introducción013 y cinco cues014 ya están integrados. Esto no completa el MVP ni SC-007/certificaciones de publicación.
- ¿Habrá progresión entre niveles (más batallas históricas) o es un solo escenario?
- Balance de costos exactos de cada unidad (se define con playtesting).
- ¿La munición cae solo de enemigos derrotados, o también se acumula pasivamente con el tiempo? (supuesto actual: solo de enemigos)
- Todas las alternativas del gap crítico de T043 quedaron resueltas o descartadas — ver entrada en "Resueltas" abajo. La ausencia de una convención propia de `collision_layer`/`collision_mask` en el proyecto sigue documentada como tal (no una decisión tomada) en `docs/ARCHITECTURE.md` §5, sin bloquear nada hoy.

### Resueltas (graduadas desde specs de feature)

- ✅ Alcance colombiano 864, fusil enemigo estacionario por carril con progresión autorada y baja de machete +2 moral/+3 vida limitada al máximo del dueño vivo: 015/T008–T010, aprobado funcionalmente. Se conservan diagonales inmediatas, contacto excluyente, reglas de derrota y resto de stats; integrados en `main` por PR #59 (`73c2dff`), con publicación pendiente.

- ✅ Narrativa dentro del juego mediante La carta: 013-I1 integrado por PR #54 (`77be629`), con siete escenas, narrador humano toma3 y compañero sintético definitivo aceptados por la persona, subtítulos y recuerdo local. Tras Jugar o Ver introducción espera Comenzar antes del combate. Es ficción inspirada en el contexto histórico; publicación T014 sigue pendiente.

- ✅ Selección por dueño de trinchera, recarga única sólo con carga cero y regreso físico vulnerable sin ofensiva: 005-I3/T037–T042, integrado mediante PR #26 (`8c4cab4`). La publicación T071 sigue pendiente.
- ✅ Composición lateral y estados observadores de marcha/espera, regreso con fusil bajo y caída orientada: 005-I4/T050–T057, integrado mediante PR #27 (`cffb2ec`). El estado de entrega y PR se mantiene en las tareas de 005. No cambia reglas, geometría ni concede cobertura.
- ✅ Caja oliva pictórica con cartuchos: 004-I3/T023–T027, corrección T040–T043 y ampliación T047–T049, aprobados para integración. La envolvente visual actual es 60×60 y tiene pulso suave; radio 20, lógica, valor y precedencia intactos. Completa el acabado funcional de soldado/enemigo/munición; T039 conserva la publicación pendiente.

- ✅ Tablero horizontal de cinco filas/plazas y fusil hacia +X, enemigos hacia −X, cinco cargas gratuitas/reserva cero y reparto continuo de oleadas sin alterar los 100 enemigos: 005-I1, integrado con 004-I2 mediante PR #24 (`658dd7e`).
- ✅ Salida/espera/contacto real de machete en la misma fila, velocidad propia 40, hogar reservado y liberación al morir fuera: 005-I2/T023–T028, integrado en `main` mediante PR #25 (`c1f43d2`). §6.3 describe además la recarga y el regreso de I3 integrados por PR #26; publicación sigue pendiente.
- ✅ Presentación observadora del enemigo, contacto basado en movimiento real, snapshot anterior al reciclado y reset por activación: 004-I2, extendiendo el patrón común sin dar autoridad jugable a la animación.
- ✅ Dirección visual de la primera iteración del terreno y las trincheras de Monte Calvo: entorno pictórico ocre/oliva, montañas azul grisáceo y decoración estática de tierra, madera y sacos, conservando actores provisionales y reglas de aquella entrega. Aprobada en T016 de `002-monte-calvo-terreno-trincheras`; §8 recoge la evolución posterior de actores, caja e interfaz mediante 004/005.
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
| 2026-10-19 | §6.3/§10: confirmadas velocidades propias 40/40, recarga solo con carga cero y una orden por retorno, sin ataques durante el regreso vulnerable, y secuencia de filas 1→5 continua entre oleadas; se conservan 1 atacante inicial + 99 autorados. Pendiente QA de especificación completa de 005, sin implementación o cierre I2 |
| 2026-10-19 | 005/T015 y 004/T021: consolidación de integración funcional del tablero de cinco filas y presentación del enemigo; se distinguen machete móvil, recarga UI, arte lateral, caja y publicación aún pendientes |
| 2026-10-20 | 005/T029 tras QA T028: salida, espera y contacto móvil con machete en su carril, velocidad propia y hogar reservado; recarga heredada limitada a la posición del hogar. Se actualiza el estado integrado de PR #24 y se conservan I3, arte lateral y publicación pendientes. |
| 2026-10-20 | 005/T043 tras QA T042: selección del dueño por trinchera, recarga única con carga cero y regreso físico vulnerable sin ofensiva; HUD mínimo y precedencia de entrada. I3 aprobado para integración en su rama; arte lateral, consolidación y publicación pendientes. |
| 2026-10-20 | 005/T056 tras QA T055: composición lateral de cinco trincheras, marcha/espera y regreso observados, caída con orientación real y procedencia. I3 integrado por PR #26; I4 aprobado en su rama, I5 y publicación pendientes. |
| 2026-10-21 | 005/T063 tras QA T062: consolidación funcional de I1–I4 integrados, con límites de producción/fixtures y rendimiento software explícitos; publicación T071, 004-I3 y acabado del MVP pendientes. |
| 2026-10-21 | 004/T028 tras QA T027: caja oliva y cartuchos con huella/picking/economía conservados; tres representaciones aprobadas funcionalmente y evolución 005 vigente, con publicación T039/T071 pendiente. |
| 2026-10-21 | 004/T044 tras QA T043: caja un 25 % mayor y pulso de brillo suave, con radio/valor/input conservados; coste del pulso sin cuantificar y publicación T039/T071 pendiente. |
| 2026-10-21 | 004/T050 tras QA T049: otro 50 % de tamaño sobre la versión con brillo, envolvente visual 60×60 y recogida radio 20 conservada; publicación pendiente. |
| 2026-10-21 | 006/T013 tras QA T009: instrumento optativo y diagnóstico limitado aprobados para integración, sin mejora causal ni parche; bases nativas, estabilización y publicación pendientes. |
| 2026-10-21 | 006/T013: ampliación del diagnóstico con tres ventanas descriptivas de iPad Simulator/software, conservando límites de observación y bases nativas pendientes. |
| 2026-10-21 | Preparación de 007: dirección pictórica y flujo de menú, inicio y repetición confirmados; implementación, pendientes de 006 y publicación conservados. |
| 2026-10-21 | 007/T010 tras QA T009: menú inerte e inicio explícito de US1 aprobados funcionalmente en rama; repetición, regreso al menú, validación visual/matriz final y publicación pendientes. |
| 2026-10-21 | 007/T016 tras QA T015: repetición desde victoria/derrota, cierre y reinicio aprobados funcionalmente con fixture reducido; producción 1+99 intacta, regreso al menú, matriz final y publicación pendientes. |
| 2026-10-21 | 007/T022 tras QA T021: regreso al menú y nuevo inicio completan el ciclo lógico aprobado; guía de usuario actualizada, con verificación final por plataforma y publicación pendientes. |
| 2026-10-22 | 007/T027 tras QA T026: ciclo completo, Theme y matriz local aprobados; mediciones descriptivas conservan límites de software/paquete, con revisión exacta en PR y publicación pendiente. |
| 2026-10-22 | 006/T013-I2 tras QA T009-I2: diagnóstico de componente GPU sin ahorro medio general ni parche autorizado; bases nativas, estabilización y publicación pendientes. |
| 2026-10-23 | 008/T005 tras QA T004: marcha enemiga de ocho poses con identidad pictórica, contacto/caída y reglas conservados; alcance local por destino y variantes nativas acotados, sin nueva campaña de rendimiento ni publicación. Se actualiza la referencia de 007 integrado por PR #34 en la guía de usuario. |
| 2026-10-23 | 009/T005 tras QA local T004: corridas colombianas de ocho fases para salida y regreso, cuatro atlas con identidad/encaje y reglas conservados; límites de regreso/HOME por destino, sin campaña de rendimiento ni publicación. Sin patrón arquitectónico nuevo. |
| 2026-10-23 | 010/T009 tras QA funcional T008: destello y trazadora pictóricos independientes, última bala distinguida de su pose y ciclo de pausa/terminal/cierre conservando las mecánicas; alcance aprobado en rama con límites visuales por destino, publicación pendiente y 006 pausado. |
| 2026-10-24 | 010/T019 tras QA funcional T018: tamaño doble y recorrido cosmético de 0,40 s; alcance frontal 396 desde stats como único cambio de balance, con límites visuales por destino y cierre de integración/publicación separados. |
| 2026-10-24 | 011/T009 tras QA funcional T008: §6.3/§6.4 incorporan barras de vida siempre visibles y sin números para ambos bandos, proporción inmediata y tonos mates por umbral; sin cambios de balance, con cierre de integración y publicación pendientes. |
| 2026-10-29 | 012/T009 tras QA funcional T008: §6.3 presenta recarga directa sobre cada hogar sin selección previa, panel informativo y reglas conservadas; límites de input nativo, integración final y publicación explícitos. |
| 2026-10-29 | 012/T019 tras QA funcional T018: §6.3 sustituye el rótulo por rojo tenue/pulsante y toque sobre el arte de la trinchera, conservando autoridad, panel y reglas; alcance de verificación y publicación separados. |
| 2026-10-30 | 013/T010 tras QA funcional T009: La carta incorpora narrativa ilustrada con voz provisional, primera entrada/replay/recuerdo local; se resuelve la pregunta narrativa y se conservan límites de audición, destinos y coste de precarga, con CI/integración final y publicación pendientes. |
| 2026-10-30 | 013/T022 tras QA funcional T021: ambas rutas terminan en Comenzar, imágenes sin cabecera, ambiente separado y Menú principal activo/pausado; Ald sigue como preview, grabación humana T026 y gates de integración/publicación permanecen pendientes. |
| 2026-10-30 | 013/T033 tras QA funcional T032: siete narraciones de toma3 elegida/autorizada, compañero sintético provisional y prompt Comenzar inferior limpio, estable ante resize; T026/SC-009 aprobados en su alcance, con CI/gate final T035 y publicación pendientes. |
| 2026-10-30 | 013/T041 tras QA técnica T040: sólo compañero sustituido por candidata Qwen3-TTS VoiceDesign; narrador humano y comportamiento intactos, naturalidad humana y gate final T043/publicación pendientes. |
| 2026-10-30 | Corrección documental 013: la persona acepta expresamente el mismo clip Qwen3-TTS VoiceDesign como voz definitiva del compañero; se resuelve su aceptación perceptual humana sin modificar audio, comportamiento o gates de publicación. |
| 2026-10-30 | 014/T010 tras QA funcional T009: cinco cues offline de hechos confirmados, bajas con exclamación breve/caída y mezcla acotada aislada de013; integración final/CI y publicación conservan sus gates y límites. |
| 2026-10-30 | Actualización documental: 013 integrado por PR #54 (`77be629`) y 014 por PR #56 (`45cd83a`); integración/CI aprobados, publicación y requisitos físicos pendientes conservados. |
| 2026-10-30 | 015/T011 tras QA funcional T010: alcance864, fusil enemigo por carril/perfiles y recompensa machete +2/+3; riesgo táctico y límites por destino explícitos, CI/integración final y publicación pendientes. |
| 2026-10-30 | 015/T022 tras QA funcional T021: mezcla continua de 66 asaltantes/33 fusileros WAVE por datos, inicial R1 independiente y tiempos/carriles conservados; CI/integración final I2 y publicación pendientes. |
| 2026-10-30 | Actualización documental: I1/I2 de 015 integrados en `main` por PR #59 (`73c2dff`); conserva CI/QA de sus revisiones previas y pendientes de publicación/hardware, sin distribución nueva. |
