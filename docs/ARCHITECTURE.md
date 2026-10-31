# Demonios de las Trincheras — Arquitectura del Proyecto (Godot)

> Documento vivo de referencia técnica **transversal a todo el proyecto**, no
> específico de una sola feature. Los planes generados por `/speckit-plan`
> para cada feature (`specs/NNN-nombre/plan.md`) DEBEN seguir estas
> convenciones; si una feature necesita desviarse de algo aquí definido, esa
> desviación debe justificarse explícitamente en su propio plan, siguiendo el
> principio de Governance de `.specify/memory/constitution.md`.

## 1. Propósito

Evitar que cada feature reinvente su propia estructura de carpetas, nombres o
patrones. `.specify/memory/constitution.md` define los principios (el "por qué" y las reglas
no negociables); este documento define el "cómo" concreto y compartido para
implementarlos en Godot.

## 2. Estructura de carpetas

```
res://
├── addons/                  # Plugins de terceros (ej. GUT). No se edita a mano.
├── scenes/
│   ├── game/                 # GameRoot.tscn: entrada y composición de menú/nivel
│   ├── units/                # Soldado.tscn y futuras variantes de unidades
│   ├── enemies/               # EnemigoBase.tscn y variantes
│   ├── levels/                 # Nivel_MonteCalvo.tscn, MonteCalvoVisual.tscn, futuros niveles
│   ├── visuals/                # CombatVisualEffects, DeathVisualEffect y RifleShotVisualEffect sin gameplay
│   └── ui/                     # HUD.tscn, menús, pantallas de victoria/derrota
├── resources/
│   ├── schemas/                # Scripts base de Resource (class_name UnitStats,
│   │                           #   EnemyStats, WaveData) — el "molde", no los datos
│   ├── units/                  # soldado_base_stats.tres, futuras unidades
│   ├── enemies/                # stats de cada tipo de enemigo (.tres)
│   ├── levels/                 # LaneBoardConfig concreto por nivel (.tres)
│   ├── director/               # CommanderConfig autorado; núcleo017-I1 aislado
│   ├── ui/                     # Theme compartido del menú y resultado
│   └── waves/                  # definición de oleadas por nivel (.tres)
├── autoloads/                   # Singletons globales (ver sección 4.1)
├── core/                          # Lógica compartida NO-autoload (ver sección 4.5)
│   ├── object_pool.gd             # ObjectPool genérico para enemigos/proyectiles
│   ├── board_manager.gd           # BoardManager: ocupación de celdas del tablero, por-nivel
│   ├── commander_session.gd       # Selector y aprendizaje017-I1, sin cableado al nivel
│   └── commander_memory_store.gd  # Memoria JSON validada, sin autoridad sobre gameplay
├── assets/
│   ├── sprites/
│   │   ├── units/             # monte_calvo/: atlas, frames y procedencia del soldado
│   │   ├── enemies/
│   │   ├── levels/             # monte_calvo/: PNG, .import y procedencia del entorno
│   │   └── ui/
│   ├── audio/
│   │   ├── sfx/
│   │   └── music/
│   └── fonts/
└── tests/
    └── unit/
        ├── units/                # test_soldado.gd
        ├── enemies/              # test_enemigo.gd
        └── systems/              # test_economy_manager.gd, test_wave_manager.gd
```

Cada escena (`.tscn`) vive junto a su script (`.gd`) en la misma carpeta —
convención estándar de Godot, evita saltar entre carpetas paralelas de
"scripts" y "scenes" para una misma unidad lógica.

> **Nota:** `addons/` se versiona en el repo (necesario para que GUT
> funcione en cualquier clon del proyecto) pero su contenido nunca se edita
> a mano — se reemplaza completo al actualizar la versión del plugin.

## 3. Convenciones de nombres

| Elemento | Convención | Ejemplo |
|---|---|---|
| Archivos de escena | PascalCase | `Soldado.tscn`, `EnemigoBase.tscn` |
| Archivos de script | snake_case | `soldado.gd`, `economy_manager.gd` |
| Clases/nodos raíz | PascalCase | `Soldado`, `EconomyManager` |
| Archivos de Resource (datos) | snake_case descriptivo | `soldado_base_stats.tres`, `enemigo_infanteria_oleada1.tres` |
| Señales | snake_case, tiempo pasado para eventos | `enemy_defeated`, `ammo_depleted`, `soldier_state_changed` |
| Autoloads (nombre global) | PascalCase | `EconomyManager`, `WaveManager` |

## 4. Patrones de arquitectura

### 4.1 Autoloads (singletons)

Uso mínimo y deliberado — solo para estado verdaderamente global, no como
atajo para evitar pasar referencias:

- **`EconomyManager`**: dueño del pool global de munición recolectada.
  Expone `ammo_pool_changed(new_amount)` (cualquier cambio al pool, por
  recolección o gasto) y `deploy_or_reload_rejected(reason)` (al intentar
  gastar más munición de la disponible vía `try_spend_ammo()`). Ningún otro
  nodo debe mantener su propia copia de este número. Ciclo completo
  recolección → gasto (recarga/despliegue) → feedback visual consumido por
  `HUD.tscn` (`scenes/ui/hud.gd`, `001-soldado-defensor-oleadas`/T036),
  cerrando de punta a punta el recurso compartido de esta sección.
- **`WaveManager`**: controla la secuencia de oleadas del nivel activo.
  Consume la secuencia de `WaveData` fijada por `start_waves(waves)` y
  expone `get_current_wave()`. Emite `wave_started(wave_number)`,
  `wave_completed(wave_number)` y `all_waves_completed()` (condición de
  victoria, FR-012/SC-005). El `wave_number` de esas señales es siempre el
  valor literal autorado en el `.tres` de esa oleada, nunca un índice
  recalculado, para que lo que muestra el HUD coincida siempre con lo que
  diseño fijó.
- **`GameStateManager`**: controla condición de victoria/derrota y el
  estado general de la partida (menú / en curso / pausada / terminada).
  Se inicializa en `MENU=4`, añadido sin renumerar `PLAYING/PAUSED/WON/LOST`.
  `enter_menu()` establece el estado no jugable sin emitir un resultado;
  el nivel inicia explícitamente la partida mediante `start_new_match()`.

**Convención: autoloads orquestadores no instancian ni temporizan, un
spawner externo se lo notifica.** Un autoload que decide "cuándo" algo
ocurre a nivel de juego (progreso de oleada, pool de munición) no es quien
instancia las escenas físicas involucradas (`Enemigo`, `AmmoPickup`) ni
quien corre el `Timer`/cola de spawn que las genera — eso vive en el nodo
del nivel dueño de esa escena concreta (`Enemigo._die()`, `WaveSpawner` en
`nivel_monte_calvo.gd`), que llama a un método público `notify_*()` del
autoload para avisarle. Esto mantiene a los autoloads libres de lógica de
instanciación de nodos (consistente con la separación de responsabilidad de
4.5) y evita que el autoload necesite referencias directas a nodos de
escena. Dos ejemplos concretos ya en el repo, mismo patrón:
- `EconomyManager.notify_pickup_spawned(pickup_id, position, amount)`
  (T032): `Enemigo._die()` instancia `AmmoPickup.tscn` y se lo notifica;
  `EconomyManager` sigue siendo el único emisor de `ammo_pickup_spawned`
  sin ser quien instancia la escena.
- `WaveManager.notify_enemy_defeated()` (T039): `WaveManager` no instancia
  enemigos ni corre ningún `Timer`/cola de `spawn_interval` — eso es
  responsabilidad de `WaveSpawner` (T042), que llama a este método una vez
  por cada enemigo derrotado de la oleada activa. `WaveManager` solo
  necesita saber cuántos enemigos totales componen la oleada (suma de
  `count` de sus `WaveSpawnEntry`) y cuántos fueron notificados como
  derrotados.
- `GameStateManager.report_reached_defended_position()` (T044,
  `001-soldado-defensor-oleadas`): mismo patrón exacto aplicado a la
  derrota — `nivel_monte_calvo.gd` detecta que un `Enemigo` entró en la
  `Area2D` "PosicionDefendida" y llama a este método en vez de que
  `GameStateManager` se conecte a la señal de instancia
  `Enemigo.reached_defended_position` (imposible desde `_ready()` de un
  autoload, que corre antes de que exista ningún `Enemigo`). Nota de
  nomenclatura menor, no bloqueante (`qa-validator`, T044): el resto de
  ejemplos de este patrón usa el prefijo `notify_*()`
  (`notify_pickup_spawned`, `notify_enemy_defeated`, y el propio
  `Enemigo.notify_reached_defended_position()` de este mismo flujo); este
  método se llamó `report_*()` en su lugar. El nombre sigue siendo claro y
  la tarea que lo introdujo ya está aprobada, así que no amerita reabrirla
  solo por esto — queda documentado aquí como inconsistencia cosmética de
  nombre para quien busque el patrón `notify_*()` de forma literal, y
  como candidato opcional a una futura tarea de limpieza si el equipo
  decide unificarlo.

Cada `Soldado` y `Enemigo` mantiene su **propio estado local** (munición
actual, moral acumulada, modo activo) — eso vive en variables propias del
script del Node, no en un autoload y **no** escrito de vuelta al `Resource`
de stats (ver regla en 4.3). Solo el recurso compartido (munición
recolectada del jugador) es verdaderamente global.

Los scripts de autoload **no declaran `class_name`**: se acceden en todo el
proyecto por su nombre de singleton (registrado en Project Settings →
Autoload, ej. `EconomyManager`), que Godot ya expone como global sin
necesidad de una clase con nombre. Declarar `class_name` además sería
redundante (dos identificadores globales para lo mismo) y expondría el
script como tipo instanciable en el picker de "New Resource"/"New Script",
lo cual no aplica a un singleton pensado para una única instancia viva
gestionada por el motor.

### 4.2 Comunicación por señales

Los nodos se comunican por señales, no por referencias directas ni por
`get_node("../../...")`. Ejemplo del flujo ya definido en el spec de la
primera feature:

```
Enemigo.gd → emite enemy_defeated(ammo_dropped)
    → EconomyManager escucha y actualiza el pool global
Soldado.gd → emite ammo_depleted()
    → el propio Soldado escucha su señal para transicionar a modo machete
    → el HUD escucha para actualizar el ícono de estado del soldado
```

Reglas complementarias:

- Toda conexión de señal (`.connect(...)`) se hace en `_ready()` (o se
  cablea en el editor) — nunca dentro de `_process()`/`_physics_process()`
  ni en callbacks puntuales.
- **Excepción explícita a la regla anterior, para instancias creadas en
  tiempo de ejecución:** cuando el nodo que emite la señal no existe todavía
  al correr el `_ready()` del nodo que la escucha (una instancia creada
  dinámicamente — un enemigo del pool, un soldado desplegado por el
  jugador), la conexión se hace en el mismo punto del código donde esa
  instancia se crea/registra, no en un `_ready()` genérico posterior que
  itere después sobre todas las instancias existentes. Dos ejemplos
  concretos ya en el repo, mismo patrón: `wave_spawner.gd:189`
  (`enemy.enemy_defeated.connect(_on_enemy_defeated.bind(enemy))`, dentro de
  `_on_enemy_pool_instance_created()`, T042) y `nivel_monte_calvo.gd`
  (`nuevo_soldado.soldier_defeated.connect(_on_soldado_defeated)`, dentro de
  `_try_deploy_soldado()`, T054) — este último conecta también, por
  consistencia, la señal del soldado colocado a mano en el propio `_ready()`
  del nivel, en el mismo punto donde ese soldado en concreto se registra
  como ocupante del tablero.
- Referencias a nodos hijos propios (ej. `Soldado.gd` accediendo a sus
  `Area2D` "DeteccionRango"/"RangoMelee") se cachean una sola vez con
  `@onready var` al inicio del script. `get_node()`/`$Path` **nunca** se
  llama dentro de `_process()`/`_physics_process()` — ni para hijos propios
  ni, con más razón, para nodos externos (eso ya lo cubre la regla anterior
  contra `get_node("../../...")`).

**Intenciones de UI y autoridad de gameplay (005-I3/T037–T042):** los widgets
emiten intención con la identidad del actor observado; el nivel revalida esa
identidad, dueño vivo y ocupación antes de delegar. El actor conserva la
validación y el gasto: un botón deshabilitado no sustituye sus precondiciones.
Cuando una operación puede reentrar desde señales síncronas, instala su guard
antes de cualquier notificación, y revalida vida/partida después de callbacks
antes de aplicar efectos tardíos. El HUD observa señales y estado inicial,
sin polling que decida economía ni copia mutable del saldo. Este patrón
extiende las conexiones y la presentación observadora existentes; no añade un
framework ni otro autoload.

**Hallazgo histórico sobre overlaps almacenados de `Area2D`:** la detectora
se situó en el lado estático de la interacción, en lugar del cuerpo que se
movía con `move_and_slide()`. Hallazgo de motor confirmado de
forma empírica durante T053 de `001-soldado-defensor-oleadas` (`qa-validator`,
usando `PhysicsDirectSpaceState2D.intersect_shape()` para verificar overlap
geométrico real y sostenido, no solo lectura de código): una `Area2D` hija de
un `CharacterBody2D` que llama `move_and_slide()` en cada `_physics_process`
**no actualiza de forma fiable su lista interna de overlaps**
(`get_overlapping_bodies()`) contra un `StaticBody2D` — sus señales
`body_entered`/`body_exited` no llegan a dispararse en juego real contra ese
`StaticBody2D`, aunque la geometría sí se solape de forma sostenida. Regla
práctica para cualquier feature futura: si dos nodos necesitan detectarse
mutuamente por `Area2D` y uno de ellos se mueve con `move_and_slide()`, la
`Area2D` de detección debe vivir en el nodo que NO se mueve así (o, si ambos
se mueven, evaluar una alternativa a `Area2D`/señales para esa detección
puntual). Caso resuelto entonces en el repo con este patrón: el daño cuerpo a
cuerpo que un `Enemigo` (`CharacterBody2D`, se mueve con `move_and_slide()`)
infligía a un `Soldado` (`StaticBody2D`, estático) se detectaba y se disparaba
desde la `Area2D` "RangoMelee" del propio `Soldado` — la misma que ya usaba
de forma fiable para su ataque a machete (T023) — en vez de una `Area2D`
propia de `Enemigo` (implementación original de T053, descartada tras este
hallazgo). Ver cabecera de `scenes/units/soldado.gd`/`scenes/enemies/enemigo.gd`
para el detalle completo y `docs/SPEC.md` §10 para el gap de diseño que esto
resolvió.

**Evolución aprobada en 005-I2:** los dos actores son `CharacterBody2D` y
se mueven físicamente. `Soldado` consulta `intersect_shape()` en el tick
físico, filtra candidatos por frente/fila y contrasta el solape de las formas
reales para fusil y machete. Repite la consulta tras avanzar antes de resolver
el contacto. `DeteccionRango` y `RangoMelee` aportan geometría de alcance,
con monitoring desactivado; desde 010 el extremo del fusil se deriva de stats
en una forma propia (§4.3). Ya no aportan listas almacenadas ni señales de
overlap al combate. El daño entrante sigue bajo autoridad del soldado: cada
enemigo elegible aporta su daño al pulso de 1 s, sin una segunda ruta de ataque
en `Enemigo`. Esta alternativa para dos cuerpos móviles conserva el hallazgo
anterior y no lo convierte en una afirmación sobre todas las áreas del motor.

### 4.3 Datos como Resource, nunca hardcodeados

Ya establecido como principio no negociable en `.specify/memory/constitution.md`. Cada tipo
de soldado, enemigo u oleada se define como un `Resource` personalizado
(`.tres`) con un script base (`class_name UnitStats extends Resource`, etc.)
que declara sus campos tipados. Balancear el juego = editar archivos `.tres`
en el editor de Godot, nunca tocar scripts de lógica.

El script base ("molde") vive en `resources/schemas/` (ej.
`resources/schemas/unit_stats.gd`); las instancias de datos concretas
(`.tres`) viven en la subcarpeta de su dominio (`resources/units/`,
`resources/enemies/`, `resources/waves/`). Separar molde de datos evita que
`resources/units/` termine mezclando el script que define la estructura con
los `.tres` que la instancian.

**Regla de límite dato/estado**: los campos de un `Resource` de stats
(`UnitStats`, `EnemyStats`) son siempre **valores base/máximos, de solo
lectura y compartidos** entre todas las instancias que cargan el mismo
`.tres` — nunca se mutan en tiempo de ejecución. El estado que cambia
mientras se juega (munición actual, moral acumulada, salud actual) vive en
variables propias del script del `Node` (ver 4.1), inicializadas a partir
del `Resource` pero nunca escritas de vuelta a él. Ejemplo:

```gdscript
# soldado.gd — MAL: muta el Resource compartido, afecta a todos los
# soldados que usan el mismo soldado_base_stats.tres
func fire() -> void:
    stats.current_ammo -= 1

# BIEN: el Resource solo aporta el valor base; el estado vivo es propio
# de esta instancia
@export var stats: UnitStats
var _current_ammo: int

func _ready() -> void:
    _current_ammo = stats.max_ammo

func fire() -> void:
    _current_ammo -= 1
```

Si en el futuro un sistema necesita mutar directamente una copia de un
`Resource` (por ejemplo, un stats modificado por un buff), esa copia se
obtiene con `stats.duplicate()` antes de mutarla — nunca sobre el recurso
cargado desde disco.

Los campos numéricos con rango acotado y pensados para que diseño balancee
(munición, daño, umbrales de moral, velocidad) usan `@export_range` en vez
de `@export` simple, para que el Inspector muestre un slider con límites en
vez de un campo numérico libre. `Resource`s con muchos campos se organizan
con `@export_group`/`@export_category` en vez de una lista plana.

`LaneBoardConfig` aplica la misma separación a geometría de nivel: rectángulo
de diseño, tamaño de celda, plazas, entradas y zona defendida son datos
compartidos de sólo lectura en `resources/levels/monte_calvo_board.tres`.
Ocupación, carril, origen `INITIAL`/`WAVE`, generación y contexto de baja son
estado runtime del nivel/actor. No se escriben en `UnitStats`/`EnemyStats` ni
se derivan de la decoración. `BoardManager` sigue siendo un mapa genérico;
el nivel aplica whitelist y reserva de gasto antes de crear un dueño.

`UnitStats.advance_speed` y `return_speed` son velocidades propias del soldado,
ambas 40 en `soldado_base_stats.tres`, independientes de `EnemyStats.move_speed`.
I2 usa `advance_speed`; I3 activa `return_speed` para el regreso físico al
hogar. Hogar, fila, estado de movimiento y blancos siguen siendo estado
por actor, no datos mutables del Resource.

`UnitStats.rifle_range` fija el extremo longitudinal de detección desde la
raíz del soldado. Su default de 264 conserva Resources anteriores;
`soldado_base_stats.tres` pasó a 396 en 010 y a 864 en 015.
`Soldado` duplica la forma de fusil por actor y deriva su ancho/posición desde
ese extremo, manteniendo el borde cercano y la altura autorados. Ni la forma
compartida de la escena ni los stats se mutan; cambiar el alcance de una
configuración no altera otros actores.

015 añade perfiles de fusilero `EnemyStats` por oleada con alcance 864, daño e intervalo
según su [tabla](../specs/015-combate-a-distancia-y-recompensas/spec.md#progresión-autorizada).
La consulta física enemiga valida frente, carril, vida y solape real; marcha,
fusil y contacto se excluyen. `Enemigo` reconoce el grupo `soldiers` y el
contrato consultable del actor sin depender de la clase `Soldado`, evitando
una referencia circular entre scripts. Generación, objetivo y reloj son propios
de cada activación. 015-I1 cuenta con CI y QA de integración aprobados en
`2351798`, previos a su integración en `main` por [PR #59](https://github.com/Juanpvivas/demons/pull/59)
(`73c2dff`), sin cerrar publicación. La recompensa de machete captura identidad/generación antes
del daño y bloquea reentrada: sólo la baja confirmada acredita +2 moral/+3 vida
limitada al máximo del dueño aún vivo, incluso con victoria síncrona.

I2 añade un perfil asaltante con los tres campos de fusil en 0 y demás stats
intactos. Los arrays de `WaveData.spawn_entries` intercalan A,A,R globalmente
(66 A/33 R WAVE), reusando hasta tres `WaveSpawnEntry` inmutables por oleada
(A/count2, R/count1 y parcial A/count1). `WaveSpawner` aplana estos datos sin
cursor de tipo, RNG o IA nuevos; conserva tiempos/carriles y el inicial R1
independiente. El mismo pool restaura R→A→R con sus hooks existentes, sin nuevas
colisiones. I2 cuenta con CI y QA de integración aprobados en `d8826e2`,
y se integra junto con I1 en `main` por PR #59 (`73c2dff`), sin cerrar publicación.

### 4.4 Modo fusil / modo machete como estado simple

Para el alcance actual (MVP, una sola unidad con dos modos), un enum +
`match` dentro de `soldado.gd` es suficiente — no se justifica un nodo de
máquina de estados formal todavía:

```gdscript
enum SoldierMode { RIFLE, MELEE }
```

005-I2 conserva ese enum de arma y añade otro de desplazamiento:
`HOME`, `ADVANCING`, `MELEE_CONTACT`, `WAITING`, `RETURNING` y `DEAD`.
I3 activa `RETURNING`: `move_and_slide()` recorre la misma fila hacia el
hogar, limita el último paso a la distancia restante y sólo pasa a `HOME`
al llegar físicamente (tolerancia ≤0,01). Durante ese estado conserva daño
entrante, cancela blancos y no ejecuta la rama ofensiva de ningún arma.
El fusil sólo opera en la posición del hogar; el machete avanza hacia un frontal
de su fila, se detiene al entrar en alcance o espera si no hay frontal.
Movimiento, arma y presentación mantienen responsabilidades separadas, sin
un framework de FSM ni navegación libre.

Si en el futuro se agregan más unidades con comportamientos más complejos
(múltiples transiciones, sub-estados), se reevalúa migrar a un patrón de
State Machine formal (nodo `StateMachine` + nodos hijos por estado). No se
adopta ese patrón de entrada por complejidad innecesaria en el MVP.

### 4.5 Pooling de objetos

Por el principio de Rendimiento de la constitución: enemigos y proyectiles
se reciclan desde un pool en vez de instanciar/destruir en cada oleada. Un
`ObjectPool` genérico gestiona esto para ambos tipos.

`ObjectPool` **no** es un autoload: no representa estado global del juego,
es una utilidad instanciable. Vive en `core/object_pool.gd` — la carpeta
`core/` es el lugar para este tipo de lógica compartida que no encaja como
autoload ni pertenece a una sola feature. Ese precedente ya se concretó en
`001-soldado-defensor-oleadas`/T012 con `core/board_manager.gd`
(`BoardManager`, estructura de datos de ocupación de celdas del tablero,
tampoco autoload por ser estado por-nivel — ver `research.md` §5 de esa
feature): cualquier utilidad futura en la misma situación (no-global,
reutilizable entre features) sigue este mismo patrón.

API concreta de `ObjectPool` (`core/object_pool.gd`, `extends Node`,
confirmada en el repo desde T011): `setup(scene, initial_size)` fija la
escena a reciclar y pre-instancia el tamaño inicial; `acquire()` entrega
una instancia libre (o instancia una nueva si el pool está vacío) y nunca
retorna `null`; `release(instance)` la devuelve al pool en vez de
destruirla; `available_count()`/`in_use_count()` exponen el tamaño del
pool para depuración/tests; `clear()` libera definitivamente todas las
instancias (ver regla de `queue_free()` más abajo). La escena pooleada
puede implementar opcionalmente `on_pool_acquired()`/`on_pool_released()`
para resetear su propio estado (salud, munición, posición) en cada
transición, sin que `ObjectPool` conozca nada específico de esa escena.

**Nota para quien implemente esos hooks** (relevante para T026/T042,
`Enemigo` y proyectiles): una instancia recién creada por el pool (primera
vez que se necesita, o pre-población en `setup()`) pasa por `_deactivate()`
internamente antes de su primer `acquire()`, lo cual invoca
`on_pool_released()` aunque la instancia nunca estuvo realmente "en uso".
Es intencional (deja la instancia nueva en el mismo estado inactivo que
cualquier instancia reciclada, sin duplicar esa lógica), pero implica que
`on_pool_released()` debe poder ejecutarse de forma segura sobre una
instancia recién instanciada con sus valores por defecto — no debe asumir
que ya pasó por `on_pool_acquired()` antes.

**Resuelto en T042 (`Enemigo`/`WaveSpawner`, `001-soldado-defensor-oleadas`)**:
esta implementación concreta terminó **sin usar** los hooks
`on_pool_acquired()`/`on_pool_released()` para reinicializar al enemigo.
Motivo: `acquire()` no admite argumentos, así que el hook se ejecutaría
antes de que el llamador (`WaveSpawner`) pudiera asignarle el `EnemyStats`
correcto de la `WaveSpawnEntry` que se está por spawnear, dejando a la
instancia con el `stats`/salud de su uso anterior. En su lugar, `Enemigo`
expone un método explícito propio (`prepare_for_spawn(stats, position)`,
sin ningún nombre ni firma especial reconocida por `ObjectPool`) que el
dueño del pool llama manualmente justo después de `acquire()`, ya con los
datos concretos del spawn en mano. Queda como guía para cualquier pool
futuro cuyo `acquire()` necesite variar por-instancia: los hooks
automáticos son la opción por defecto para reseteos sin parámetros; un
método explícito llamado por el dueño después de `acquire()` es la opción
correcta cuando la reinicialización necesita datos que no existen todavía
en el momento en que el hook automático se dispara.

Cuando sí hace falta liberar definitivamente un nodo (por ejemplo, al
descargar el nivel o salir al menú, fuera del ciclo de vida del pool), se
usa siempre `queue_free()` y nunca `free()` — `free()` libera el nodo de
forma inmediata y puede causar use-after-free si algo todavía tiene una
referencia pendiente en el mismo frame.

**Validez antes de operaciones tipadas:** una referencia guardada puede apuntar
a un nodo ya liberado aunque no sea `null`. Comprobar `is_instance_valid()`
antes de pasarla a un método con parámetro de nodo tipado o a operaciones como
`Array[Node2D].has()`, no sólo antes de leer sus propiedades dentro del helper.
Después se valida que siga en el árbol, no esté pendiente de borrado, esté
activo y cumpla la elegibilidad del sistema. En actores reciclados, comprobar
además identidad y generación de activación: una instancia válida puede
representar otro uso del pool. Este orden se gradúa desde los blancos de
fusil/machete de 005-I2 y complementa la captura de contexto anterior a callbacks
síncronos; no sustituye ninguno de esos controles.

### 4.6 Compatibilidad del lenguaje con Web

El juego compartido usa GDScript. La enmienda 2.0.0, conservada en la
constitución 2.1.0, retira la excepción
anterior de introducir C# por rendimiento: Godot 4 no exporta actualmente
proyectos C# a Web. Las convenciones C# previas quedan como historial del
documento y no habilitan un sistema nuevo que excluya un destino. Una futura
excepción exige comprobar compatibilidad y enmendar la constitución.
[Restricción oficial de Godot](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).

La sección `[dotnet]` heredada de `project.godot` no implica una dependencia
C# del gameplay. La exportación Web usa Godot estándar oficial **4.7.1** y
templates de esa misma versión, verificados en la feature 003. La edición
Mono local se conserva para desarrollo/pruebas nativos. La aceptación Web
es acotada a los navegadores y dispositivos de su matriz, no universal.
[Herramientas y evidencia](../specs/003-web-itchio/evidence/toolchain.md).

### 4.7 Presentación observadora y derrota cosmética independiente

Patrón graduado desde I1 de `004-personajes-municion-monte-calvo`, aprobado
funcionalmente en T011: el actor conserva la autoridad jugable y su presentador
solo observa modos y hechos confirmados. `SoldadoVisual`, sobre el hijo
`AnimatedSprite2D`, representa espera, ataques reales, impacto y moral sin
aplicar daño, consumir recursos o cambiar cadencias. El modo actual interrumpe
poses incompatibles, incluida la de fusil al agotar la última bala; la muerte
cancela toda pose viva. `reset_visual(mode)` restaura la presentación desde el estado real y los
valores autorados. Frames de arte compartidos son de solo lectura; progreso,
tinte, escala y callbacks pertenecen a cada instancia.

Antes de las señales que retiran al actor, este captura un snapshot neutro por
valor y emite `defeat_visual_requested(snapshot: Dictionary)` una sola vez.
Incluye posición, frames, animación, escala/offset, flips, z y material, sin
tinte/pulso transitorio, referencia al actor o callbacks jugables. Los valores
mutables se copian; los recursos de arte inmutables pueden compartirse. La
ausencia de listener o de recursos visuales nunca impide la muerte jugable.

La corrección I1 de 004, aprobada en T036, amplía este patrón con
`visual_material`, una referencia `Material` inmutable o `null` dentro del
snapshot. El presentador conserva y restaura el material autorado, incluso
si se consulta antes de `_ready()`. El efecto limpia su material a `null`
en cada reset antes de aplicar el siguiente snapshot. El estilo compartido
no contiene daño, moral ni parámetros mutables por actor: ese feedback sigue
en la presentación de cada instancia. Así la caída conserva el estilo neutro
sin filtrar tintes transitorios ni recursos de una activación anterior.

`CombatVisualEffects` es un servicio del nivel, sin autoload, que registra una
vez cada actor integrado y posee un `ObjectPool` precalentado con diez efectos de baja;
el tamaño inicial no es un límite. `DeathVisualEffect.tscn` contiene solamente
`Node2D` y `AnimatedSprite2D`: reproduce la caída durante 0,40 s en la posición
capturada, sin física, input, ocupación ni objetivos. Su final devuelve esa
activación al pool. La celda y el actor se liberan sin esperar, y el efecto no
sigue a una instancia reutilizada. Cada reset cancela tweens y restaura la
presentación; una generación/activación invalida callbacks obsoletos para que
no restauren poses ni liberen otro uso de la misma instancia.

004-I2 extiende el patrón a `EnemigoVisual`: el actor comunica desplazamiento
real después de `move_and_slide()`, y el presentador elige avance o contacto;
la velocidad deseada por sí sola no implica movimiento. Impacto sólo responde
a daño confirmado. Antes de callbacks de derrota/reciclado síncronos se capturan
snapshot y contexto de recompensa por valor. Cada nueva activación restaura
valores autorados, limpia transitorios e invalida callbacks antiguos mediante
generación, sin que la caída siga al enemigo reutilizado.

`WaveSpawner` registra una vez cada instancia física con el servicio visual,
no una vez por acquire. El mismo cuerpo puede servir a `INITIAL` y `WAVE`:
`prepare_for_spawn()` reasigna stats, salud, posición, fila, origen, generación
y presentación. Un enemigo inactivo no es blanco y su cuerpo se deshabilita;
los objetivos del soldado validan identidad/generación además de geometría.
La recompensa conserva el contexto anterior aunque se reutilice el nodo dentro
de una señal síncrona. `ObjectPool` conserva su API genérica.

005-I4, integrado mediante [PR #27](https://github.com/Juanpvivas/demons/pull/27),
extiende el presentador del soldado con `observe_motion(movement_state, displacement)`.
El actor informa después del movimiento físico: sólo el desplazamiento real
activa `melee_march`; un bloqueo conserva `melee_idle`. `RETURNING` elige
`returning` o `returning_idle`, refleja el sprite hacia −X y cancela ataques
incompatibles. No decide la llegada ni mueve al actor. Repetir una pose ya
activa no reinicia su progreso. El snapshot captura los flips actuales para
que una baja durante el retorno caiga en esa dirección; escala, offset y
material mantienen sus valores autorados neutros. Reset restaura también
rotación y velocidad de reproducción, limpia frame/progreso e invalida
callbacks anteriores. Los atlas/frames laterales sustituyen los de producción
y conservan los originales históricos. 004-I3 completa la caja pictórica sin
añadir un presentador ni lógica nueva.
El [contrato de 004](../specs/004-personajes-municion-monte-calvo/contracts/visual-presentation.md)
delimita los tiempos y la frontera jugable.

010-I1 extiende este patrón con `rifle_shot_visual_requested(snapshot)`:
después de consumir la bala y antes del daño/callbacks síncronos, el soldado
captura y emite una vez `origin_world` y `target_world` por valor. El helper de
`SoldadoVisual` ubica el cañón de la pose autorada respetando centrado, offset,
flips y transformación actual. El efecto no conserva actores ni sigue al
blanco retirado o reutilizado; la última bala puede seguir visible aunque la
pose del soldado ya cambie a machete. El actor conserva la autoridad del daño
y su cadencia, sin depender del listener visual.

015 extiende el tiro observado a `Enemigo`: su snapshot añade
`activation_generation` a las dos coordenadas. Audio/VFX validan emisor,
generación y sesión y admiten el tiro antes del daño con posibles callbacks
síncronos; el efecto conserva sólo coordenadas saneadas. Después de emitir,
el enemigo revalida blanco/identidad/contexto antes del hitscan único.
Tiro, baja y resultado conservan sus voces ya admitidas sin daño cosmético;
la mezcla Stream/GameplaySFX de 014 y el audio definitivo de 013 permanecen intactos.

`CombatVisualEffects` registra también esa señal de forma opcional e idempotente
y posee un segundo pool precalentado con diez `RifleShotVisualEffect`, capaz de
crecer; los conteos históricos siguen describiendo sólo bajas. La escena es un
`Node2D` con dibujo 2D de destello/trazadora y reloj propio de 0,40 s activo,
sin física, input, audio ni daño. La revisión de 010 duplica el tamaño del
destello y el trazo; la cabeza recorre cañón→destino en 0,30 s con intensidad
conservada y el segmento se desvanece en los 0,10 s finales. Cola/origen y
cabeza/destino delimitan el trazo, sin seguir actores ni retardar el daño.
Cada activación copia sus endpoints y limpia
geometría, alpha, transformación y reloj al reset; su identidad evita que un
final obsoleto retire otro uso. Los hooks son seguros antes de `_ready()`.

La pausa de árbol o `PAUSED` congela ese reloj. `WON/LOST` rechazan tiros nuevos
y permiten completar los ya confirmados, incluido el ganador; no prolongan el
combate. `MENU` y `close_match()` cancelan y devuelven de inmediato los tiros
activos, cierran ese servicio de forma idempotente y evitan reabrirlo en otro
intento. El nivel siguiente posee su propio servicio. El
[contrato de 010](../specs/010-disparos-visibles/contracts/rifle-shot-visual.md)
detalla el snapshot y las APIs, sin introducir un proyectil jugable ni cambiar
`ObjectPool`.

011-I1 aplica la misma separación a `WorldHealthBar`, un `ProgressBar`
compartido como hijo directo `HealthBar` del root de `Soldado` y `Enemigo`.
Queda fuera de `AnimatedSprite2D`: sigue al cuerpo sin heredar sus flips,
tintes o pulsos. El actor conserva `_current_health` y obtiene el máximo de
sus stats; llama directamente a `set_health(current, maximum)` al iniciar,
recibir daño o reaparecer. La barra sólo presenta `value`/`max_value`, con
proporción limitada, sin porcentajes, input, foco, polling ni tween.

Los tres `StyleBoxFlat` mates son recursos compartidos inmutables: cada barra
selecciona su override `fill` local sin modificar el estilo de las demás.
`clear()` oculta y pone valor cero; el actor lo aplica antes de callbacks de
baja que puedan reciclar y reactivar síncronamente al enemigo, sin limpiar
después la nueva activación. El prewarm permite `on_pool_released()` antes
de `_ready()` resolviendo el hijo directamente; al entrar al árbol el enemigo
inactivo mantiene su barra oculta. Después de `_ready()`, `prepare_for_spawn()`
restaura valor, máximo y color de su uso actual. El snapshot de caída sigue
conteniendo sólo la presentación del sprite. El
[contrato de 011](../specs/011-barras-de-vida/contracts/world-health-bar.md)
detalla ese ciclo sin introducir otra autoridad de salud ni cambiar el pool.

### 4.8 Entrada común y composición local

`GameRoot.tscn` es la entrada del producto y compone menú, introducción y nivel
sin un autoload adicional. `MainMenu` emite `play_requested` o
`intro_requested`; la raíz decide el destino y protege la reentrada.
013-I1/T007–T009 añade `IntroPlayer`: después del primer Jugar no se monta
nivel hasta terminar/omitir la introducción y aceptar Comenzar mediante otro
gesto. Con recuerdo válido, Jugar conserva el montaje directo diferido.
Ver introducción usa una instancia nueva; R2/T019–T021 hace que ambas entradas
terminen/omitan esperando Comenzar, sin retorno al menú ni inicio automático.
R3/T030–T032 presenta sólo Comenzar centrado abajo en el mismo contenedor de
acciones y con mínimo 52 px, sin panel/banda, cabecera, subtítulo ni botones
de reproducción. La imagen visible conserva su opacidad/pivote/encuadre al
redimensionar durante la espera. GameRoot usa show_start_prompt/señal públicos,
sin conocer nodos privados del layout.
La generación y los callbacks ligados a la instancia aíslan cada apertura;
el cierre detiene voz, ambiente y avance antes de retirar la escena. Retry sigue directo.

`IntroSequence`/`IntroSlide` son Resources compartidos inmutables con imágenes,
textos, clips y encuadres; el índice/tiempo/pausa vive sólo en IntroPlayer.
Los clips pregrabados son recursos locales: no hay sintetizador ni modelo
runtime. IntroSequence autora ambiente original en bucle y volumen −18 dB;
IntroPlayer usa otro AudioStreamPlayer independiente de Voice, no reinicia el
fondo por escena y limpia ambos al salir. El tiempo autorado nunca recorta clips;
pausa o pérdida de actividad detienen ambos canales/avance hasta continuación
explícita. Durante las imágenes no hay cabecera ni rótulos; sólo subtítulos y
controles. R3 incorpora siete WAV humanos de toma3 elegida/autorizada; sólo
el compañero usa el clip sintético Qwen3-TTS VoiceDesign, aceptado después
expresamente como voz definitiva por la persona. El origen y procesamiento se
documentan en el catálogo de audio; la aceptación perceptual es de la persona,
separada de las verificaciones técnicas de los agentes.
`IntroProgress`, dependencia local inyectable, escribe un ConfigFile canónico
dedicado en `user://intro_progress.cfg` y comprueba el Error de guardado.
La lectura exige el registro canónico de la versión narrativa actual;
ausencia/corrupción/otra versión se consideran no visto. Un error de escritura
no bloquea el destino ni simula persistencia. Las pruebas usan rutas temporales
y los fixtures de nivel inyectan recuerdo ya visto para mantener su propósito.
El menú usa `CanvasLayer` para mantener su presentación independiente de la
`Camera2D` del nivel. Menú y resultado reutilizan el `Theme` de
`resources/ui/monte_calvo_theme.tres`; el acabado y el foco se comparten como
presentación, sin dar autoridad jugable al recurso.

US2–US3 de 007 añaden repetición y regreso al menú desde `WON/LOST`: el HUD
emite una intención, propagada por el nivel y aceptada por la raíz sólo para
el intento actual.
R2 añade una intención de menú durante PLAYING/PAUSED desde un botón propio
en la franja superior segura del HUD, separado del panel informativo y de las
zonas HOME/recarga. Nivel/raíz aceptan ese retorno activo; las acciones ocultas
de resultado conservan guards terminales y Retry no se habilita en combate.
La ruta reutiliza el cierre común sin modal ni persistencia de partida.
El cierre bloquea reentrada, invalida la generación anterior, entra en `MENU`
y cancela oleadas sin emitir progreso o victoria. Nivel y spawner detienen
actividad y desconectan consumidores antes de retirar su árbol. El servicio
visual de §4.7 se cierra antes de deshabilitar los hijos del nivel; el siguiente
nivel se monta sólo tras su liberación efectiva y conserva su inicialización
vigente. El destino menú usa el mismo cierre, deja cero niveles y restituye
«Jugar» habilitado y enfocado; sólo un nuevo inicio monta otra partida.
Orígenes o callbacks antiguos no cambian el destino ni el nuevo intento.
Este ciclo lógico está aprobado funcionalmente con una oleada autorada de un WAVE;
la derrota añade un enemigo de cruce controlado. No acredita victoria manual
de producción 1+99. La matriz funcional/visual disponible distingue Chrome de
computador, Android AVD Compatibility e iPad Simulator Compatibility/Apple
Software Renderer. Las variantes nativas internas incluyen assets de prueba
inactivos y una exclusión temporal del loader GUT heredado. iPad Simulator usa
un shell ARM64 reutilizado con el PCK del juego; no certifica empaquetado final,
renderer Mobile o hardware.
Las comparaciones son descriptivas: la memoria de render observada es un monitor
del motor, no RSS/VRAM ni prueba de causa o fuga. La cadencia en renderers nativos
software permanece muy por debajo de 60 FPS; no certifica dispositivos físicos.
La aceptación y CI de cada revisión exacta se registran en el PR del incremento.

### 4.9 Audio de combate local a la sesión

014-I1, integrado en `main` por [PR #56](https://github.com/Juanpvivas/demons/pull/56)
(`45cd83a`) con QA de integración T012/CI aprobados, añade `CombatAudio` como hijo del nivel y
`CombatAudioProfile` inmutable con cinco arrays de cues/nueve variantes. Nivel
y spawner registran actores una sola vez. Observa las señales confirmadas de
disparo/baja existentes, sin depender de animación visible o alterar emisores.
Las bajas se deduplican por identidad/activación; `Enemigo.has_confirmed_defeat()`
es consulta de sólo lectura que distingue muerte letal de desactivación por
cleanup, sin cambiar stats o señales. El resultado tiene guard de sesión;
tiro/baja final ya admitidos terminan aunque llegue victoria.

Ocho reproductores de combate y uno reservado a resultado se precalientan y
reutilizan sin cola ilimitada. RNG propio sólo varía presentación. Todos usan
Stream y GameplaySFX en layout estático, con HardLimiter de techo −3 dB;
Sample Web eludiría los efectos de bus. Master/intro no se modifican. Pausa/foco
detienen one-shots sin reanudarlos atrasados; cierre invalida generaciones,
desconecta actores y para sólo voces propias, sin mutear/borrar bus compartido
o afectar otra sesión/intro. Los getters cuentan combate más resultado.

La captura software de mezcla no certifica techo/latencia Web o hardware.
Stream Web puede añadir latencia, especialmente con un hilo; no hay medición
acreditada en esta entrega. Los [límites de014](../specs/014-sonidos-combate/research.md#alcance-funcional-aprobado-y-límites)
conservan publicación pendiente y las observaciones no certificadas, sin
presentar la integración/CI ya aprobados como pendientes.

### 4.10 Núcleo aislado del comandante con memoria (017-I1)

`CommanderSession` y `CommanderMemoryStore` son servicios `RefCounted`
instanciables en `core/`, sin autoload, Timer o conexiones al nivel. I1 está
implementado y aprobado funcionalmente; su gate final de integración exige
además documentación y CI de la revisión exacta. El juego mantiene el cursor
1→5 vigente: la composición de la raíz, el spawner y el menú corresponde a I2.

`CommanderConfig`, en `resources/schemas/`, sólo define campos; el `.tres` de
`resources/director/` autora los parámetros y no contiene memoria mutable.
La sesión copia configuración y memoria, decide entre los carriles pendientes
del bloque global de cinco y conserva propuestas/confirmación/cancelación con
RNG propio. Cada terminal válido consolida una media por contexto; supervivientes
sin resultado se censuran y abandono no aprende. Los pesos están acotados, sin
pretender que las pruebas aisladas acrediten equilibrio o ganabilidad.

El almacén valida JSON, hash, esquema y compatibilidad antes de publicar memoria;
alterna dos slots y verifica la escritura por relectura. Un borrado exitoso
comprueba la ausencia de ambas copias antes de vaciar RAM; un fallo conserva RAM
y obliga a revalidar el disco. Rutas, backend I/O y fuentes de compatibilidad
son inyectables; `TRANSIENT` mantiene sólo RAM sin I/O de memoria. No carga
Resources desde datos del usuario ni modifica progreso narrativo. El
[modelo017](../specs/017-comandante-memoria/data-model.md) fija campos y formato
canónico; el [contrato](../specs/017-comandante-memoria/contracts/commander.md)
distingue errores observables de `FileAccess`, fallos simulados y durabilidad.
Persistencia Web, aplicaciones nativas, control de borrado en menú y playtesting
conservan verificación propia; 006, #61/#53 y los gates de publicación no cambian.

## 5. Composición de escenas (ejemplo concreto)

- **`Soldado.tscn`**: desde 005-I2, raíz `CharacterBody2D` en modo flotante y
  cuerpo 48×48, con avance horizontal mediante `move_and_slide()` en
  `_physics_process()`. Sus hijos son `AnimatedSprite2D`, `CollisionShape2D`
  y las áreas "DeteccionRango"/"RangoMelee", usadas como geometría de alcance
  por las consultas del tick (§4.2). Script `soldado.gd`; el hijo visual usa
  `soldado_visual.gd` y los frames de `assets/sprites/units/monte_calvo/`, con
  [procedencia e importación](../assets/sprites/units/monte_calvo/SOURCES.md).
- **`EnemigoBase.tscn`**: `CharacterBody2D` raíz, `CollisionShape2D` e hijo
  `AnimatedSprite2D` con `enemigo_visual.gd` y atlas/frames de
  `assets/sprites/enemies/monte_calvo/`. Avanza con `move_and_slide()` hacia −X
  manteniendo la fila; `get_advance_progress()` usa −X para priorizar cercanía
  a defensa. La detección/daño mutuo de contacto se resuelve desde el soldado
  mediante consultas físicas, aunque ambos cuerpos puedan moverse.
- **`Nivel_MonteCalvo.tscn`**: raíz `Node2D`, `Tablero` (`TileMap` 96×96),
  `PosicionDefendida`, `MonteCalvoVisual`, `HorizontalBoardVisual`, `Camera2D`
  y `HUD` (`CanvasLayer`).
  Al iniciar una partida el nivel reinicia GameStateManager y la reserva global,
  crea gratuitamente cinco soldados cargados y prepara el servicio visual y
  spawner; los actores iniciales ya no están colocados a mano en el `.tscn`.
  La whitelist contiene `(1,1)`…`(1,5)`, con centros `(144,144)`…`(144,528)`;
  movimiento no cambia la celda de origen (`_grid_cell`) ni el hogar
  (`_home_position`), de modo que la plaza permanece reservada durante salida,
  espera y contacto. La muerte libera ese origen, también lejos del hogar,
  sin esperar el efecto visual. Se valida plaza libre antes del gasto y
  se protege la creación frente a reentrada síncrona de callbacks económicos.
  La defensa real es `Rect2(48,96,48,480)`; un cruce notifica una única derrota.
- **Spawner de Monte Calvo:** un inicial inmediato en fila 3 y 99 enemigos de
  diez Resources de oleadas usan el mismo pool. El inicial no consume cursor
  ni contador de bajas WAVE; los de oleadas usan 1→5 continuamente entre oleadas
  con sus intervalos originales. Sólo sus bajas notifican `WaveManager` para
  victoria. El contexto de origen se lee antes del release síncrono.
- **`AmmoPickup.tscn` (004-I3):** conserva raíz, posición, script y círculo de
  recolección de radio 20. Su sprite de un fotograma usa la caja oliva con
  cartuchos, textura importada 256×256, escala visual 0,234375 y offset local
  `(0; −5,818182)`, con arte dentro de 60×60 desde T047. La corrección T040 añadió
  un `AnimationPlayer` de escena que pulsa sólo el brillo del sprite, con alfa de modulación 1;
  el [contrato](../specs/004-personajes-municion-monte-calvo/contracts/visual-presentation.md#5-arte-huella-y-procedencia)
  delimita el ciclo. La parte visible fuera del círculo radio 20 no recoge.
  Los cambios visuales no alteran
  valor, picking ni precedencia sobre selección/despliegue. La
  [procedencia](../assets/sprites/pickups/monte_calvo/SOURCES.md) recoge original,
  importación y condiciones de uso.
- **Cámara y entrada:** `monte_calvo_camera.gd` centra el rectángulo de diseño
  1152×648 en `(576,324)` en ambos ejes al iniciar y redimensionar, manteniendo
  `canvas_items/expand`, sin zoom ni mover actores/grid. El nivel convierte
  pantalla→mundo con el canvas inverso antes de resolver celda o pickup.
  La precedencia de pickup (§7) se conserva sobre plazas libres/ocupadas, bajo
  actores y con cajas solapadas. Fuera de PLAYING no se despliega ni recoge.
- **Combate horizontal:** el fusil permanece en el hogar. Su broadphase se
  orienta hacia +X y el filtro exige
  frente, misma fila o celda diagonal directamente contigua, solape real de
  formas y generación activa. El tramo longitudinal es [24,864] para el soldado
  base, con altura 192: su extremo procede de `stats.rifle_range` y la forma
  propia conserva el borde cercano autorado; no es una distancia al centro
  del enemigo. Conserva blanco elegible y, al perderlo,
  elige el más avanzado hacia −X. Con carga cero, el mismo actor busca un
  frontal de su fila, avanza a `stats.advance_speed` y se detiene en alcance
  para golpear; sin frontal espera en su posición, sin perseguir detrás o en
  otra fila. La colisión real conserva separación y cada actor puede morir.
  Terminal y muerte cancelan blancos e intención de movimiento.
- **Selección y recarga de 005-I3/012-I1:** el nivel conserva referencia y
  hogar seleccionados para información; el panel muestra fila, carga/capacidad,
  moral y retorno, sin botón de recarga. La orden directa llega como
  `HUD.trench_reload_requested(home_cell, instance_id)` y
  `request_trench_reload()` revalida celda configurada, ocupante vivo de
  `BoardManager`, hogar e identidad antes de delegar a `Soldado.request_reload()`.
  No depende de la selección. La baja limpia selección/vínculo; retirar el
  control anterior impide que un gesto antiguo recargue al reemplazo.
- **Presentación de recarga por hogar (012):** `HUD.tscn`, como CanvasLayer,
  aloja hasta cinco `TrenchReloadControl` sin texto ni decoración de botón,
  vinculados a dueño/ID. Observa `reload_state_changed`, economía y partida,
  sin polling: `NORMAL` oculta la zona y retira rojo; `DIM` deja rojo tenue
  estático/deshabilitado con dueño vacío no elegible; `PULSING` sólo permite
  recargar mientras `can_reload()` y PLAYING. La pausa detiene el pulso por
  señal aunque no se pause SceneTree. El panel queda informativo.
  El nivel proporciona las piezas `PosteriorN`/`ParapetoN` del hogar; el
  control añade dos copias locales de su textura con material aditivo sin
  iluminación y expansión leve, conservando originales, z efectivo −4/+1 y
  oclusión del actor. La fuerza real pinta ambas copias mediante un único
  Tween suave por hogar, sin shader, `TIME` ni creación de nodos o Tweens por frame/ciclo.
  Repetir estado no reinicia ni acumula animaciones; cargar/baja, desregistro,
  reemplazo, salida del árbol y cierre normalizan y retiran efectos locales.
  La unión mundial del arte se proyecta a la zona GUI sobre la trinchera,
  con mínimo táctil 112×48 y área segura, sin mover arte o cámara.
  `Camera2D.framing_changed`, tras `force_update_scroll()`, actualiza resize;
  el control no sigue al soldado y el pulso no mueve su zona. Las seis
  variantes de estilo, incluido `hover_pressed`, quedan vacías.
  `MOUSE_FILTER_STOP` consume ratón/toque incluso deshabilitado; fuera de
  la zona se conserva pickup→selección/despliegue. El [contrato de 012](../specs/012-recarga-trinchera/contracts/trench-reload.md)
  detalla geometría, ciclo e identidad; el [alcance observado](../specs/012-recarga-trinchera/spec.md#alcance-de-la-aprobación-funcional)
  no acredita entrada nativa o renderer/paquete final de publicación.
- **Autoridad del actor:** `can_reload()`/`request_reload()` exigen vivo,
  PLAYING, carga cero, fondos y ausencia de aceptación/retorno activo. El guard
  se instala antes de emitir señales o gastar, pues sus callbacks son síncronos.
  Cobra `stats.deploy_ammo_cost` una vez y repone `stats.max_ammo`, conservando
  salud/moral; `reload()` delega a la misma operación. Tras el gasto vuelve a
  comprobar vida/partida, evitando reanimar o iniciar un retorno tardío si un
  callback mató al actor o terminó el juego. Desde fuera entra en `RETURNING`;
  desde el hogar pasa a `HOME`/fusil sin viaje. Muerte y terminal detienen
  ofensiva/movimiento y nuevas órdenes; la muerte libera el hogar de inmediato.
  I4 añade poses laterales observadoras; conserva cámara, HUD y mapping
  existentes. El acabado general de interfaz sigue pendiente.

### 5.1 Entorno decorativo separado del nivel

La presentación ambiental se compone en una subescena propia para poder
modificarla sin alterar la geometría, el input o la lógica del nivel.
`MonteCalvoVisual.tscn`, aprobada en `002-monte-calvo-terreno-trincheras`,
concreta este patrón con una raíz `Node2D` de transformación identidad y
`z_index=-10`. Sus grupos `Suelo`, `FondoMontanas`, `Bordes` y `Trincheras`
usan originalmente z relativo 0–3, con z efectivo −10…−7 detrás de actores
y pickups. I4 añade las capas de trinchera lateral descritas abajo.

La escena contiene únicamente composición estática de `Node2D` y `Sprite2D`:
una hoja de terreno sin repetición, montañas con alfa, un cielo de
`GradientTexture2D` y piezas de trincheras/bordes que comparten seis regiones
`AtlasTexture`. Los tres PNG originales y sus `.import` viven en
`assets/sprites/levels/monte_calvo/`; se versionan los originales y ajustes,
con importación lossless, corrección del borde alfa y sin mipmaps en esta
iteración. `.godot/` sigue siendo caché regenerable. La [procedencia y regiones](../assets/sprites/levels/monte_calvo/SOURCES.md)
documentan los recursos sin convertir la imagen de referencia en un fondo
con personajes o interfaz incrustados.

La corrección I1 de 004 añade tres sprites estáticos para cubrir únicamente
el margen izquierdo expuesto por la cámara del nivel: prolongación del cielo
y recortes reflejados de las texturas existentes de suelo y panorama, sin
repetición automática ni PNG nuevos. Conserva las piezas de trinchera y sus
posiciones; esta extensión no acredita tileabilidad de las imágenes.

El entorno carece de scripts, señales, controles, física, navegación o cámara
propios. Sus trincheras no otorgan cobertura ni restringen colocación. El arte
se adapta a posiciones definidas por el nivel; `BoardManager` conserva
ocupación/liberación y la whitelist vive en la composición del nivel. 005-I1
oculta sólo la instancia de las trincheras inferiores antiguas y añade
`LaneBoardVisual` como guía provisional de cinco bandas/plazas numeradas,
sin input, física, economía ni autoridad sobre esas plazas. La subescena
ambiental se conserva. I4 retira los recuadros de plaza y conserva bandas
discretas y números de fila. `TrincherasLaterales` añade cinco
pares de sprites centrados en x=144, separados 96 unidades según los hogares:
posterior en hogar+y4, escala 0,1561 y z relativo 6 (efectivo −4); parapeto
en hogar+y21, escala 0,12 y z relativo 11 (efectivo +1). El primero queda
detrás del actor y el segundo oculta parcialmente sus piernas. Dos
`AtlasTexture` con recorte de filtro comparten `trinchera_lateral_atlas.png`.
No se migró `TileMap` ni cambió `canvas_items`/`expand`, la whitelist o la física.
La [comparación de US3](../specs/002-monte-calvo-terreno-trincheras/evidence/us3.md)
y la [matriz de pantallas/entrada](../specs/002-monte-calvo-terreno-trincheras/evidence/native-validation-matrix.md)
registran los encuadres comprobados y el recorte inferior existente.

**Nota sobre `collision_layer`/`collision_mask` (sin convención propia
todavía):** ninguna escena del proyecto (`Soldado.tscn`, `EnemigoBase.tscn`)
declara `collision_layer`/`collision_mask` explícitos — todo `CollisionObject2D`
queda en el default de Godot (layer 1 / mask 1), por lo que `Soldado`
(`CharacterBody2D` desde 005-I2) y `Enemigo` (`CharacterBody2D`) colisionan
físicamente entre sí. La detección original de este gap ocurrió cuando el
soldado era estático; I2 conserva las capas existentes. Esto no es una
convención adoptada de capas — es la ausencia de una, detectada durante T043
de `001-soldado-defensor-oleadas` (ver `docs/SPEC.md` §10). Si en algún
momento se define una convención explícita de capas de colisión para el
proyecto, documentarla aquí.

**Nota (T050-T053):** el síntoma práctico que motivó esta observación (un
`Soldado` que nunca podía morir, bloqueando permanentemente el carril) quedó
resuelto por otra vía — dándole salud/derrota real al `Soldado` (ver
`docs/SPEC.md` §10, "Resueltas") — sin tocar `collision_layer`/`collision_mask`.
La ausencia de convención explícita documentada aquí sigue vigente tal cual.

## 6. Testing

- Framework: **GUT** (Godot Unit Testing) v9.7.1, instalado en
  `res://addons/gut/` y habilitado en Project Settings → Plugins (antes
  asumido por este documento, confirmado en el repo desde `001-soldado-defensor-oleadas`/T002).
- Los tests viven en `res://tests/unit/`, con estructura espejo a la de
  `scenes/` por dominio (`tests/unit/units/`, `tests/unit/enemies/`,
  `tests/unit/systems/` para lo que vive en `autoloads/` y `core/`) — ej.
  `tests/unit/units/test_soldado.gd` prueba `scenes/units/soldado.gd`.
- Cobertura mínima obligatoria (según constitución): cálculo de daño,
  consumo/recolección de munición, acumulación de moral, condiciones de
  victoria/derrota, generación de oleadas — toda lógica que no dependa de
  renderizado.
- **Limitación conocida de `--headless` para simular input real:**
  simular un evento de input crudo (`Input.parse_input_event()`) que
  dependa de coordenadas de pantalla/viewport (ej. un click/tap que
  `_unhandled_input()` convierte a posición de mundo) no es fiable en modo
  `--headless` — el runner no aplica el mismo `canvas_transform`/stretch de
  ventana (`window/stretch/mode="canvas_items"`, `aspect="expand"`) que una
  ejecución real, por lo que la posición que llega al callback no coincide
  con la enviada (confirmado empíricamente en `001-soldado-defensor-oleadas`/
  T035, detalle completo en el comentario de cabecera de la sección de
  tests correspondiente en `tests/unit/levels/test_nivel_montecalvo.gd`).
  Cuando la lógica de negocio bajo prueba está separada de la conversión de
  coordenadas (un método interno invocable directamente, ej.
  `_try_deploy_soldado(cell)` en `nivel_monte_calvo.gd`), el patrón es
  testear ese método directamente vía `Object.call()`/llamada normal en vez
  de simular el evento crudo — deja sin cubrir solo la conversión de
  coordenadas en sí (pantalla → mundo → celda) y el filtro de tipo de
  evento, sin lógica de negocio real.
- **Precedencia de pickup y despliegue** (`002-monte-calvo-terreno-trincheras`,
  T019–T022): seis casos en `tests/unit/levels/test_pickup_input_routing.gd`
  comprueban la ruta normal/emulada y que la recolección no gaste ni cree
  un soldado adicional. El [ciclo RED/GREEN nativo](../specs/002-monte-calvo-terreno-trincheras/evidence/t021-green.md)
  terminó con 189/189 pruebas y 532 aserciones en la suite completa, tras
  importación limpia. Es un resultado fechado de esa entrega, distinto de
  los gestos de SO antes/después registrados en la matriz nativa; GUT no
  certifica por sí solo picking, stretch o toque físico.
- **Cerrado (T046, `001-soldado-defensor-oleadas`):** el hueco de cobertura
  señalado en T044 (existía cobertura de punta a punta con instancias
  reales para la condición de derrota, pero no su simétrico para victoria)
  quedó cerrado por
  `test_completing_all_configured_real_waves_transitions_the_real_gamestatemanager_to_won_end_to_end`
  en `tests/unit/levels/test_nivel_montecalvo.gd`: instancia
  `Nivel_MonteCalvo.tscn` real con `WaveManager`/`WaveSpawner` reales
  (sustituyendo solo el *contenido* de las oleadas por una secuencia corta
  de una oleada/un enemigo, para no depender del tiempo real de las 10
  oleadas de producción) y verifica que el `GameStateManager` real
  (registrado en `project.godot`, no una instancia aislada) transiciona a
  `WON` y emite `game_won` al derrotar a ese único enemigo. Con esto, tanto
  el camino de derrota (T044) como el de victoria (T046) tienen cobertura
  de integración de punta a punta con instancias reales.

La consolidación I5 de 005 mantiene separadas la población de producción
(un inicial y 99 enemigos de diez oleadas), las 99 bajas de oleada necesarias
para WON y la victoria determinista de un fixture reducido. La suite y la
carga del nivel original se revalidan sin cambiar sus Resources. Reutilizar
entrada, visuales y recorridos de una entrega exige comprobar que la fuente
y los recursos relevantes siguen siendo equivalentes; no convierte esa
evidencia en una ejecución nueva ni amplía sus destinos o renderers.

006-I1 añade [`tools/performance/probe.gd`](../tools/performance/probe.gd),
un `Node` optativo sin autoload ni referencias desde las escenas normales.
Calcula intervalos monotónicos y percentiles, lee inventario recursivo por
valor y valida condiciones/cohortes; no monta escenarios, escribe resultados
ni gobierna la partida. Los collectors y experimentos permanecen temporales.
Su [contrato](../specs/006-diagnostico-rendimiento/contracts/profiling-protocol.md)
separa producción variable de render constante y exige procedencia real.
`valid=true` acredita comprobaciones mecánicas del informe: el collector y QA
deben verificar además que cada API observa el dato efectivo. En el motor
usado, los getters nativos de foco y vsync GLES pueden devolver valores fijos;
esa limitación impide acreditar comparabilidad causal nativa. `TIME_PROCESS`
no se interpreta como Self de scripts ni como tiempo GPU. T009 aprueba sólo
el instrumento y diagnóstico limitado, sin parche ni cierre de bases nativas.

## 7. Consideraciones multiplataforma

- **Destinos del producto:** Web solo en navegador de computador y aplicaciones
  Android/iOS instaladas (APK/IPA). itch.io es el primer portal Web previsto.
  Por decisión de la persona del 2026-10-19 y constitución 3.0.0, no se
  continúan pruebas de navegador móvil, tampoco en emulador/simulador. Android
  Emulator prueba el APK; iOS Simulator usa la app nativa `.app` del simulador,
  que no equivale a instalar un IPA en hardware.
  Windows/macOS/Linux nativos se conservan como entornos de editor y prueba
  local, sin instaladores del producto. Las capturas y mediciones históricas
  de PC siguen identificadas como tales; no equivalen a resultados Web.
- Input abstraído vía `InputMap` de Godot; no se hardcodean teclas/toques
  directamente en la lógica de gameplay, para que las aplicaciones móviles
  y Web compartan la misma capa de lógica con toque o ratón. Ejemplo ya en
  el repo (`project.godot`, `001-soldado-defensor-oleadas`/T003): las
  acciones `select_cell` y `collect_pickup` conservan entradas mouse/touch,
  sin tecla de teclado asociada. En la ruta Android comprobada, las acciones
  llegan mediante el mouse emulado del toque; no se debe descartarlo ni
  suponer que `InputEventScreenTouch` activa por sí solo esas acciones.
  La distinción entre recoger y desplegar pertenece al enrutamiento del nivel.
- **Precedencia de recolección validada en 003/T015–T018 y 002/T019–T022:** Godot procesa
  `_unhandled_input()` antes del physics picking. El nivel consulta si el
  punto cae sobre una `AmmoPickup` visible/pickable y cede ese evento al
  picking, evitando desplegar/cobrar con el mismo gesto. Sin pickup conserva
  ocupación y gasto normal. No cambia InputMap, radio ni coordenadas. No recoge desde el
  nivel ni modifica las recompensas de pickups solapadas. La consulta usa
  las formas reales con física 2D en el hilo principal actual; activar un
  hilo separado exigiría revisar ese acceso. RED de dispatch real, GREEN
  normal/emulado y comprobación física Android respaldan esta convención.
  [Corrección Web](../specs/003-web-itchio/evidence/t017-green.md) y
  [regresión nativa](../specs/002-monte-calvo-terreno-trincheras/evidence/t021-green.md),
  con validaciones de entrada propias de cada plataforma.
- UI (`HUD.tscn`) usa contenedores con anclas relativas, no posiciones fijas
  en píxeles, para adaptarse a distintas resoluciones y aspect ratios entre
  aplicaciones móviles y navegadores de computador.
- **Ruta gráfica implementada y validada en 003:** `Mobile` se conserva como
  método nativo y `rendering/renderer/rendering_method.web="gl_compatibility"`
  selecciona Compatibility/WebGL 2.0 para Web. El preset `Web` exporta con un
  hilo, sin GDExtension ni PWA y canvas adaptativo. La evidencia proviene del
  navegador de computador y del Xiaomi horizontal bajo la matriz histórica
  de 003; una captura del editor no la sustituye.
  [Guía y alcance validado](WEB_EXPORT.md).
- **Paquete Web:** `tools/web/export.sh`, con `GODOT_WEB_BIN` estándar 4.7.1,
  produce `build/web/index.html`, sus compañeros, ZIP y manifest exterior.
  Incluye recursos de producción con exclusiones de internos: seleccionar
  solo escenas omitió clases y oleadas cargadas desde scripts. El contenido
  real del PCK, sus diez oleadas y las licencias se inspeccionan además del ZIP.
  `build/.gdignore` evita importar la salida; los artefactos no se versionan.
  El workflow `export-web.yml` adjunta un ZIP descargable, sin publicar en
  itch.io. Su [run remoto anterior](https://github.com/Juanpvivas/demons/actions/runs/38903800209)
  terminó con SUCCESS antes de integrar el cierre de 002; el nuevo estado debe
  comprobarse por separado. [Paquetes y alcance](WEB_EXPORT.md#artefacto-de-ci).
  El CI existente conserva GUT/importación y los deploys nativos no cambiaron.
- Las verificaciones Web identifican navegador, sistema/computador, tamaño,
  entrada y renderer. Deben comprobar carga, partida, redimensionamiento y
  entrada dentro del navegador, incluida su presentación embebida cuando se
  prepare itch.io. Se conserva la exigencia de 60 FPS en el Android de
  referencia para la app nativa; los resultados nativos y Web en computador
  se registran por separado. La autorización de emulador/simulador acredita
  solo ese entorno; Compatibility temporal no certifica Mobile.
- Presets de exportación por plataforma se versionan en
  `export_presets.cfg`, sin credenciales ni keystores/certificados dentro
  del repositorio. Según constitución 4.3.0, merge/push a `main` integra
  desarrollo y no dispara distribución externa. Los workflows
  **Android/Firebase App Distribution** (`.github/workflows/deploy-android-testers.yml`)
  e **iOS/TestFlight** (`.github/workflows/deploy-ios-testflight.yml`) se ejecutan
  manualmente con `workflow_dispatch`, sólo sobre `main`, y requieren una
  `approval_status` con valor inicial `PENDIENTE` frente a `APROBADO PARA
  PUBLICACIÓN`, y `human_authorized` booleano `false` por defecto para esa
  revisión. El guard de evento/main y ambas confirmaciones se comprueba antes
  de checkout, acceso a secrets y build/envío; no certifica por sí mismo el contenido de la confirmación.
  QA y la persona deben revisar el artefacto y los pendientes de publicación
  antes de activar la distribución. Ver los workflows para secrets y controles.
  Para la beta 1.0.1/build 4 se aplica exclusivamente la
  [excepción autorizada de constitución V](../.specify/memory/constitution.md#excepción-autorizada-beta-101-build-4):
  QA identifica la revisión exacta y los pendientes físicos diferidos; firma,
  empaquetado y versión del APK/IPA siguen verificándose antes de cada upload.
  No se modifica el renderer ni se extiende esta excepción a otra versión o canal.
  La excepción 1.0.1 está consumida. La nueva
  [excepción de beta 1.0.2/build 5](../.specify/memory/constitution.md#excepción-autorizada-beta-102-build-5)
  autoriza, con QA y CI, integrar el PR #52 por Squash and merge y un envío
  exitoso manual por destino sobre la revisión exacta de `main` aprobada.
  Sólo difiere las verificaciones físicas delimitadas allí; mantiene los
  controles previos de firma/empaquetado/versionado, los pendientes
  004/T039, 005/T071 y SC-007 y la pausa de 006. No acredita un veredicto de
  publicación ni envíos ejecutados.
  La excepción 1.0.2 también está consumida. La [excepción 1.0.3/build 6](../.specify/memory/constitution.md#excepción-autorizada-beta-103-build-6)
  autoriza un upload exitoso por destino acotado desde el nuevo SHA exacto de
  `main` con QA/CI; firma/paquete/versión se verifican antes de cada upload y
  cualquier fallo bloquea el envío. Sólo se difiere lo físico indicado; #61/#53
  y 006 siguen pendientes/pausada. No afirma QA de publicación, IPA o envío.
- **Firma beta estable de Android:** el workflow conserva un único firmante
  mediante los secrets `ANDROID_BETA_KEYSTORE_BASE64`,
  `ANDROID_BETA_KEYSTORE_PASSWORD` y `ANDROID_BETA_KEYSTORE_ALIAS`; la variable
  `ANDROID_BETA_CERT_SHA256` identifica el certificado esperado. La clave privada
  y su respaldo protegido permanecen fuera de Git. El preflight exige esa
  configuración y un alias válido, restaura el keystore en un temporal con
  permisos restringidos y lo entrega a Godot mediante
  `GODOT_ANDROID_KEYSTORE_DEBUG_PATH`, `GODOT_ANDROID_KEYSTORE_DEBUG_USER` y
  `GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD`. Se elimina la copia temporal también
  ante un fallo. El helper `tools/ci/verify_native_artifact.py` recibe la huella
  mediante `DEMONS_ANDROID_CERT_SHA256` (opcional para uso general, obligatoria
  en distribución) y exige un único certificado firmante coincidente antes del
  upload, además de firma, paquete y versión válidos. Un fallo bloquea el envío
  sin cambiar automáticamente de firma. La transición a esta firma en 1.0.2
  requiere reinstalar manualmente una vez la beta Android anterior, con posible
  pérdida de datos locales; no se desinstala ni borra nada automáticamente.

La [validación nativa de 002](../specs/002-monte-calvo-terreno-trincheras/evidence/native-validation-matrix.md)
separa ratón PC, gestos de SO en Android Emulator, muestreo humano Xiaomi y
gestos humanos sobre iPad Simulator. iPad usó Compatibility en copias temporales;
los presets y el renderer Mobile de producción permanecieron intactos. No se
acredita hardware iOS ni se toma el SoftwareRenderer del simulador como
rendimiento de un iPhone. La [aceptación de rendimiento](../specs/002-monte-calvo-terreno-trincheras/evidence/performance.md)
se limita a 002/Xiaomi 11T Pro físico provisional por la enmienda 1.2.0,
conservada en la constitución 2.1.0,
con los picos y límites del instrumento conservados; no se extrapola a otros
dispositivos o features.

Para I1 de 004, la enmienda 2.2.0 autoriza por separado el Xiaomi 11T Pro
físico provisional; se mantiene el objetivo de 60 FPS. Web y app Android tienen
aceptaciones propias, sin extrapolar por compartir teléfono. La comprobación
iOS corresponde solo a simulador con renderer software, sin acreditar hardware
iOS o Mobile. La aceptación de I1 no certifica estabilidad sostenida fuera de
las muestras revisadas ni sustituye las verificaciones propias de I2/I3.
La constitución 3.0.0 conserva la referencia física nativa y esas aprobaciones
históricas; las nuevas verificaciones siguen los destinos vigentes de esta
sección, sin exigir navegador móvil ni convertirlo en prueba de app instalada.

005-I5 consolida la integración funcional de I1–I4 y conserva la caída observada
en Android software, sin descartarla desde fixtures con cohortes distintas.
iOS acredita sólo la vista disponible de iPad Simulator, con renderizado
software, stdout parcial y aislamiento entre apps no confirmado. Las muestras
de ambos entornos no certifican Mobile, GPU, 60 FPS físicos ni el paquete final.
T071 mantiene esos requisitos, firma/instalación/versionado y matriz de
publicación pendientes; las variantes temporales de QA no modifican los presets
de producción. [Alcance funcional y límites](SPEC.md#8-arte-y-estilo-visual).

004-I3 y su corrección de brillo tienen aprobación funcional para integración
en T027/T043/T049, con caja, gestos y
terminales verificados en sus destinos disponibles. La neutralidad del sprite
no certifica renderer Mobile, GPU, hardware o paquete final; T039 de 004 y
T071 de 005 conservan publicación pendiente y sus propios requisitos físicos.

- **Política de versionado para releases de prueba**: ambos workflows de
  deploy comparan `version/code`/`version/name` (Android) o
  `application/version`/`application/short_version` (iOS) de
  `export_presets.cfg` contra el último deploy exitoso del mismo workflow y
  fallan si la versión no cambió. El guard también se aplica al despacho
  manual, sin bypass de versionado. El bump se prepara para una distribución
  autorizada y no es requisito de un merge que sólo integra código. La revisión
  exacta y su artefacto deben tener `APROBADO PARA PUBLICACIÓN`, incluyendo
  renderer, empaquetado, firma/instalación y rendimiento físico aplicables.
  Compatibility/software de QA no certifican ese destino.
  La comparación identifica un envío real por su paso de subida exitoso, no por
  el resultado global de un run omitido o fallido después de subir. Consulta
  hasta 100 runs completados de main; si agota esa ventana sin confirmar un
  envío previo, o falla API/JSON/Git, bloquea distribución. El operador debe
  resolver el historial antes de reintentar, sin desactivar el guard.

**Adenda administrativa — 2026-10-31**: la aceptación funcional humana autoriza
cerrar únicamente #18, #22, #55 y #58 tras crear [#61](https://github.com/Juanpvivas/demons/issues/61) abierto. Los gates
004/T039/SC-007, 005/T071/SC-007, 014/T014/SC-007 y 015/T015/SC-008 siguen pendientes
con todos sus requisitos, sin marcarse completos por cierre o merge. El cambio
es de seguimiento, no de política global ni certificación/publicación. #53 sigue
abierto si el paquete incluye 013; #30 permanece pausado. Sin cambio de release 1.0.2
ni renovación de excepciones beta.

## 8. Relación con Spec Kit y los agentes

- Spec Kit prepara la especificación, el plan, contratos y tareas. Su
  workflow termina al revisar `tasks.md`; la ejecución pertenece a los
  agentes, coordinados por `project-orchestrator`.
- El flujo compartido está en
  [DEVELOPMENT_WORKFLOW.md](DEVELOPMENT_WORKFLOW.md), enlazado desde
  [AGENTS.md](../AGENTS.md). Para cambios de comportamiento se sigue TDD:
  tester RED → desarrollo → tester GREEN → QA → documentación. Las tareas
  exclusivamente de pruebas, arte o documentación se asignan según su tipo.
- `speckit-implement` es solo un aviso de compatibilidad; no implementa,
  ejecuta pruebas ni marca tareas. Solo el orquestador marca `[X]` tras QA.
- Este documento contiene convenciones de **alcance de proyecto**.
  `specs/NNN-feature/plan.md`, preparado por `speckit-plan`, contiene decisiones
  de **una feature** y debe referenciar las convenciones comunes sin copiarlas.
- Los patrones validados de alcance general se gradúan a este documento por
  `docs-writer`, después de QA y según las responsabilidades del flujo común.

## 9. Historial de cambios

| Fecha | Cambio |
|---|---|
| 2026-08-13 | Versión inicial del documento de arquitectura |
| 2026-09-10 | Se agrega `addons/`, `core/` (lógica compartida no-autoload) y `resources/schemas/` (scripts base de Resource, separados de las instancias `.tres`); se subdivide `assets/` por dominio; se corrige la estructura de `tests/unit/` para reflejar la organización real de `scenes/` en vez de una carpeta `scripts/` inexistente. |
| 2026-09-12 | §5: nota sobre la ausencia de una convención de `collision_layer`/`collision_mask` en el proyecto — todo queda en el default de Godot, lo que permite que `Soldado` bloquee físicamente a `Enemigo`. Gap de diseño detectado en T043 de `001-soldado-defensor-oleadas`, graduado en detalle a `docs/SPEC.md` §10 (pendiente de decisión humana). |
| 2026-09-11 | Correcciones de revisión (`godot-code-review` + `resource-pattern`): raíz de `Soldado.tscn` cambiada de `CharacterBody2D` a `StaticBody2D` (unidad estacionaria); regla explícita de límite dato/estado entre `Resource` de stats y estado mutable por instancia; regla de `@onready` y conexión de señales en `_ready()`; `queue_free()` vs `free()` para limpieza fuera del pool; `@export_range`/`@export_group` para campos de balance; nueva sección 4.6 de convenciones C# |
| 2026-09-11 | §6 y §7 sincronizadas con la realidad del repo tras T002/T003 de `001-soldado-defensor-oleadas`: se confirma versión de GUT (v9.7.1) ya instalada, y se documenta como ejemplo concreto el par de acciones `InputMap` `select_cell`/`collect_pickup` (mouse+touch, sin tecla hardcodeada) — antes ambas secciones solo describían la convención en abstracto |
| 2026-09-11 | §4.1: se agrega la convención de que los scripts de autoload no declaran `class_name` (se referencian por su nombre de singleton) — duda explícita de implementación surgida en T008/T009 (`EconomyManager`, `GameStateManager`) de `001-soldado-defensor-oleadas`, graduada aquí porque aplica a todo autoload futuro (ej. `WaveManager` en T039) |
| 2026-09-11 | §2 y §4.5 sincronizadas con la realidad del repo tras T011/T012/T014 de `001-soldado-defensor-oleadas`: se documenta la API concreta de `ObjectPool` (`setup`/`acquire`/`release`/`available_count`/`in_use_count`/`clear` + hooks opcionales `on_pool_acquired`/`on_pool_released`, antes solo descrita en principio); se agrega `core/board_manager.gd` (`BoardManager`) como segundo ejemplo real (ya no hipotético) del patrón de utilidad no-autoload en `core/`; se agrega nota para T026/T042 sobre que `on_pool_released()` se invoca también sobre instancias recién creadas por el pool, antes de cualquier uso real (comportamiento intencional, observación no bloqueante de `qa-validator` en T011/T012) |
| 2026-09-12 | §6: se agrega la limitación conocida de simular input real (clicks/taps) en modo `--headless` (el stretch de ventana del proyecto desalinea la posición que recibe el callback), y el patrón de testear el método interno de lógica de negocio directamente cuando la conversión de coordenadas está separada de él — observación no bloqueante de `qa-validator` confirmada empíricamente en T035 de `001-soldado-defensor-oleadas`, graduada aquí por aplicar a cualquier futuro test que necesite simular input real bajo `--headless` |
| 2026-09-12 | §4.1: completada la descripción de `EconomyManager` con la señal `deploy_or_reload_rejected(reason)` (faltaba junto a `ammo_pool_changed`) y nota de que el ciclo recolección → gasto → feedback visual queda cerrado de punta a punta con `HUD.tscn`/`hud.gd` (T036 de `001-soldado-defensor-oleadas`, que además cierra la Fase 4/User Story 2 completa: "US1 + US2 funcionan juntas") |
| 2026-09-12 | §4.1: completada la descripción de `WaveManager` (`start_waves`, `get_current_wave`, señal `all_waves_completed` faltante) tras su implementación en T039 de `001-soldado-defensor-oleadas` (validada por `qa-validator`, 25/25 tests de T037 en verde); se gradúa como convención explícita de proyecto el patrón "autoload orquestador no instancia ni temporiza, un spawner externo se lo notifica vía `notify_*()`", ya presente en `EconomyManager.notify_pickup_spawned` (T032) y ahora repetido en `WaveManager.notify_enemy_defeated` (T039) |
| 2026-09-12 | §4.5: completada la nota sobre hooks de `ObjectPool` que ya nombraba a T026/T042 como caso relevante — tras la implementación real de T042 (`WaveSpawner`/`Enemigo`, validada por `qa-validator`), se documenta que esa implementación concreta no usó `on_pool_acquired()`/`on_pool_released()` sino un método explícito propio (`prepare_for_spawn()`) llamado por el dueño del pool justo después de `acquire()`, porque `acquire()` no admite argumentos y el hook automático se dispararía antes de tener los datos correctos del spawn. Se deja como guía para pools futuros con la misma necesidad. |
| 2026-09-12 | §4.2: graduada como convención de alcance de proyecto la regla "una `Area2D` detectora debe pertenecer al lado estático de la interacción, no al que se mueve con `move_and_slide()`" — hallazgo de motor confirmado de forma empírica por `qa-validator` durante T053 de `001-soldado-defensor-oleadas` (una `Area2D` hija de un `CharacterBody2D` que llama `move_and_slide()` no actualiza de forma fiable sus overlaps contra un `StaticBody2D`). §5: agregada nota de que el síntoma práctico que motivó la observación sobre `collision_layer`/`collision_mask` (un `Soldado` indestructible bloqueando el carril) quedó resuelto por T050-T053 sin tocar capas de colisión — la ausencia de convención explícita documentada ahí sigue vigente. |
| 2026-09-12 | §4.2: agregada excepción explícita a la regla de "conectar señales siempre en `_ready()`" para instancias creadas en tiempo de ejecución (conectar en el punto de creación/registro de la instancia, no en un `_ready()` genérico posterior) — convención ya presente de forma implícita en `wave_spawner.gd` (T042) y confirmada por segunda vez, de forma independiente, en `nivel_monte_calvo.gd` (T054, `001-soldado-defensor-oleadas`, validado por `qa-validator`), que la aplicó tanto al soldado colocado a mano como a los desplegados dinámicamente. Se gradúa aquí por ser un patrón repetido en dos features/puntos distintos del código, de alcance de proyecto. |
| 2026-09-12 | §4.1: agregado `GameStateManager.report_reached_defended_position()` (T044, `001-soldado-defensor-oleadas`, aprobado por `qa-validator`) como tercer ejemplo del patrón "autoload orquestador no instancia, un nodo de nivel se lo notifica vía método público" — cierra de punta a punta la condición de derrota (`Enemigo` alcanza real, físicamente, la posición defendida Y `GameStateManager` real transiciona a `LOST`, con test de integración de instancias reales en `test_nivel_montecalvo.gd`). Se documenta también, sin bloquear nada, la inconsistencia cosmética de nombre `report_*()` vs. el prefijo `notify_*()` usado por los otros dos ejemplos del mismo patrón (observación de `qa-validator`, no ameritó reabrir T044). |
| 2026-09-12 | §6: agregado hueco de cobertura de test conocido y no bloqueante — falta el simétrico de victoria (con `WaveManager`/`GameStateManager` reales) al test de integración de derrota de punta a punta agregado en T044 de `001-soldado-defensor-oleadas`. |
| 2026-09-13 | §6: cerrado el hueco de cobertura anterior — T046 de `001-soldado-defensor-oleadas` (validado por `qa-validator`) agrega el test simétrico de victoria de punta a punta con instancias reales (`Nivel_MonteCalvo.tscn`/`WaveManager`/`WaveSpawner`/`GameStateManager` reales, oleada de prueba acortada), cerrando la Fase Final de la feature. Consolidación de fin de feature: se confirma que las graduaciones de T050-T054 (gap de derrota del `Soldado`) y del hallazgo de motor de T053 (§4.2) ya estaban correctamente integradas, sin duplicados. |
| 2026-09-15 | §7: sincronizado con la realidad — iOS/TestFlight ya no está pendiente, quedó operativo (`.github/workflows/deploy-ios-testflight.yml`, firma Manual en vez de Automatic, ver ese archivo para el detalle). Se agrega la política de versionado: ambos workflows de deploy de prueba ahora fallan a propósito si `export_presets.cfg` no tiene un bump de versión desde el último deploy exitoso — se detectó en esta sesión que el pipeline estaba re-subiendo repetidamente la misma versión (1.0/build 1) a TestFlight y Firebase sin ningún control. |
| 2026-10-15 | §8: separación entre preparación Spec Kit y ejecución por agentes, TDD y referencia compartida de desarrollo; rutas de constitución actualizadas |
| 2026-10-15 | §4.6/7: alineación con constitución 2.0.0 y destinos Web + Android/iOS; se retira la excepción C# incompatible con Web. Compatibility específico para Web y Mobile nativo se documentan como ruta pendiente de implementar/validar en 003; se conserva evidencia histórica PC. |
| 2026-10-16 | §4.6/7: estado verificado de 003 en su alcance Web: estándar 4.7.1, Compatibility específico/un hilo, Mobile nativo conservado, ZIP/PCK/licencias y artefacto CI sin publicación. Se gradúa la precedencia pickup→despliegue validada con RED/GREEN y toque físico; las mediciones y entornos no certificados mantienen sus límites. |
| 2026-10-16 | T017 de `002-monte-calvo-terreno-trincheras`, tras QA T016: §2/§5 documentan la subescena visual estática aislada y sus recursos; se corrige la descripción del nivel para reflejar WaveSpawner creado por código y ausencia de HUD integrado. §6/§7 documentan la precedencia de pickup→despliegue aprobada con TDD y distinguen regresión de entrada real, con límites de iPad Simulator y Xiaomi provisional. |
| 2026-10-16 | Integración de main tras PR #16: se preservan la escena visual y la validación nativa 002 junto con Web/Compatibility de 003; constitución 2.1.0 combina sus decisiones sin extrapolar pruebas ni rendimiento entre plataformas. |
| 2026-10-16 | T012 de 004, tras aprobación funcional T011: §2/§4.7/§5 gradúan la presentación observadora y derrota cosmética independiente, con snapshot neutro, pool visual precalentado y callbacks por activación. Solo soldado integrado; enemigo/caja pendientes. §7 delimita Xiaomi provisional propio de 004, Web separado e iOS simulador/software. |
| 2026-10-17 | T037 de 004, tras QA funcional T036: §4.7 gradúa material autorado inmutable/nullable en snapshot y limpieza del efecto; §5/§5.1 describen el encuadre local de Monte Calvo y cobertura decorativa izquierda, conservando la separación entre cámara del nivel y entorno estático. |
| 2026-10-19 | §7: Web solo en computador y Android/iOS como apps instaladas según decisión de la persona y constitución 3.0.0; se preservan las pruebas móviles Web históricas y se distinguen APK/IPA, app de simulador y requisitos físicos nativos |
| 2026-10-19 | Constitución 4.0.0: main de integración separado de publicación; distribución manual sólo main con confirmación explícita QA/humana y guard de versiones sin bypass |
| 2026-10-19 | 005/T015 y 004/T021: geometría de nivel en Resource, cinco actores creados por partida, orientación horizontal y cursor/origen del pool; presentación enemiga observadora con reset por activación, cámara centrada en ambos ejes y arte/controles/publicación delimitados |
| 2026-10-20 | 005/T029 tras QA T028: evolución a dos cuerpos móviles, consultas físicas por tick y hogar estable; estados/velocidades propios y recarga heredada delimitados frente a I3. Se gradúa validar referencias antes de operaciones tipadas y después elegibilidad/activación, conservando el hallazgo histórico de overlaps. |
| 2026-10-20 | 005/T043 tras QA T042: RETURNING físico separado del arma y HUD observador; se gradúan intención con identidad, revalidación de autoridad y guard antes de callbacks síncronos, sin framework nuevo. |
| 2026-10-20 | 005/T056 tras QA T055: extensión del patrón observador con movimiento real, retorno y flips actuales de caída; reset de reproducción y composición estática de cinco trincheras por capas. I4 aprobado en rama, publicación pendiente. |
| 2026-10-21 | 005/T063 tras QA T062: I4 integrado por PR #27 y consolidación funcional I5; distinción entre población/victoria de fixture, evidencia reutilizada y certificaciones pendientes de publicación, sin nuevos patrones. |
| 2026-10-21 | 004/T028 tras QA T027: encaje de la caja pictórica en el pickup existente, sin cambios de lógica/picking; vigencia de la evolución 005 y publicación T039/T071 pendiente, sin patrones nuevos. |
| 2026-10-21 | 004/T044 tras QA T043: escala visual 0,15625 y brillo por recurso de escena, conservando raíz/radio/input y sin patrones nuevos; publicación pendiente. |
| 2026-10-21 | 004/T050 tras QA T049: escala visual 0,234375 y envolvente 60×60, sin ampliar el círculo de recogida ni cambiar animación/recursos; publicación pendiente. |
| 2026-10-21 | 006/T013 tras QA T009: herramienta optativa de diagnóstico en §6, separada del producto; validez mecánica y observabilidad efectiva diferenciadas, sin nuevos patrones de gameplay ni parche de rendimiento. |
| 2026-10-21 | 007/T010 tras QA T009: entrada común con composición local, intención de UI, montaje diferido protegido y estado MENU sin renumeración; sólo US1 funcional, con repetición/regreso y verificación final pendientes. |
| 2026-10-21 | 007/T016 tras QA T015: cierre previo a repetir, cancelación silenciosa y aislamiento por intento; aprobación funcional con fixture reducido, sin entregar aún regreso al menú o validación final. |
| 2026-10-21 | 007/T022 tras QA T021: destino menú mediante el cierre compartido, sin nivel activo y con foco de inicio restaurado; ciclo lógico aprobado, validación final y publicación pendientes. |
| 2026-10-22 | 007/T027 tras QA T026: Theme compartido y alcance local aprobado; variantes internas y cadencia software limitada documentadas, con revisión exacta en PR y publicación pendiente. |
| 2026-10-23 | 010/T009 tras QA funcional T008: §2/§4.7/§4.8 amplían la presentación observadora con snapshot de tiro anterior al daño, pool cosmético separado y cierre por intento; se distinguen poses y efectos de última bala. Comportamiento aprobado en rama, con publicación pendiente y sin nueva campaña de rendimiento. |
| 2026-10-24 | 010/T019 tras QA funcional T018: §4.3/§5 incorporan alcance frontal desde UnitStats con forma propia por actor; §4.7 describe recorrido cosmético de 0,30 s más fade de 0,10 s, conservando snapshot, pooling y autoridad de daño inmediata. |
| 2026-10-24 | 011/T009 tras QA funcional T008: §4.7 incorpora WorldHealthBar compartida fuera del sprite, salud autoritaria del actor, estilos inmutables y limpieza anterior a callbacks de baja; precisa prewarm anterior a ready y activación posterior, sin nueva arquitectura ni publicación. |
| 2026-10-29 | §7 referencia la excepción constitucional 4.1.0 para la beta 1.0.1/build 4; conserva QA, revisión exacta y verificación del paquete antes del upload, sin acreditar pendientes físicos. |
| 2026-10-29 | Constitución 4.1.1 aclara la revisión exacta de la corrección de filtros nativos de la misma beta: nueva QA/CI y verificaciones previas al upload, sin ampliar los pendientes diferidos. |
| 2026-10-29 | 012/T009 tras QA funcional T008: §5 incorpora intención de recarga por hogar/ID, panel informativo, controles por señales y notificación de encuadre aplicado; fuente económica del actor y gates de publicación conservados. |
| 2026-10-29 | 012/T019 tras QA funcional T018: §5 describe TrenchReloadControl transparente sobre el arte, brillo aditivo local por hogar y Tween idempotente/limpiado; autoridad y gates conservados, sin patrón global nuevo. |
| 2026-10-29 | §7 documenta la firma beta Android fija y protegida, verificación obligatoria de su huella antes del upload y transición por reinstalación manual; gates de publicación conservados. |
| 2026-10-30 | §7 referencia constitución 4.2.0 y la excepción acotada de beta 1.0.2/build 5; conserva controles, pendientes físicos y alcance histórico de 1.0.1. |
| 2026-10-30 | 013/T010 tras QA funcional T009: §4.8 incorpora composición local de introducción, Resources narrativos inmutables, recuerdo canónico inyectable y aislamiento por apertura; coste de precarga y límites de validación constan en 013, sin certificar publicación. |
| 2026-10-30 | 013/T022 tras QA funcional T021: §4.8 unifica destino Comenzar, audio de ambiente separado y retorno activo mediante intención HUD/nivel/raíz con cierre común; guards terminales y límites de publicación conservados. |
| 2026-10-30 | 013/T033 tras QA funcional T032: §4.8 documenta prompt inferior aislado por API pública, imagen estable en espera/resize y narrador humano con compañero provisional separado; audio/recuerdo/cierre y gates conservados. |
| 2026-10-30 | Corrección documental 013: aceptación humana definitiva del clip sintético del compañero, sin cambios de recursos de audio ni lógica y con publicación pendiente. |
| 2026-10-30 | 014/T010 tras QA funcional T009: §4.9 documenta audio local, pool8+1, señales confirmadas/consulta letal de sólo lectura y routing Stream/GameplaySFX aislado; CI/integración final, audición y publicación mantienen límites. |
| 2026-10-30 | Actualización documental: 013 integrado por PR #54 (`77be629`) y 014 por PR #56 (`45cd83a`); estado de integración/CI vigente, con publicación y certificación física aún pendientes. |
| 2026-10-30 | 015/T011 tras QA funcional T010: perfiles de fusil enemigo, alcance864 y premio transaccional; snapshot por generación previo al daño y consulta por grupo sin ciclo de scripts. CI/integración final y publicación pendientes. |
| 2026-10-30 | 015/T022 tras QA funcional T021: mezcla continua de 66 asaltantes/33 fusileros WAVE por datos, inicial R1 independiente y tiempos/carriles conservados; CI/integración final I2 y publicación pendientes. |
| 2026-10-30 | Actualización documental: I1/I2 de 015 integrados en `main` por PR #59 (`73c2dff`); conserva CI/QA de sus revisiones previas y pendientes de publicación/hardware, sin distribución nueva. |
| 2026-10-31 | Adenda administrativa autorizada: cierre funcional humano de #18/#22/#55/#58 y publicación pendiente seguida en [#61](https://github.com/Juanpvivas/demons/issues/61); tareas/SC e historia conservados, sin aprobación física ni distribución. |
| 2026-10-31 | Constitución 4.3.0: autorización acotada 1.0.3/build 6 con QA/CI de main exacto y verificadores previos por upload; firma/renderer y pendientes #61/#53/006 intactos. |
| 2026-10-31 | 017/T022 tras QA funcional T021: §2/§4.10 describen Session, Store y CommanderConfig como núcleo aislado, memoria validada y puertos inyectables; integración jugable I2, CI/gate final y publicación conservan sus verificaciones propias. |
