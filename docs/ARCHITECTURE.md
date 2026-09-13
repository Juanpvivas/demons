# Demonios de las Trincheras — Arquitectura del Proyecto (Godot)

> Documento vivo de referencia técnica **transversal a todo el proyecto**, no
> específico de una sola feature. Los planes generados por `/speckit-plan`
> para cada feature (`specs/NNN-nombre/plan.md`) DEBEN seguir estas
> convenciones; si una feature necesita desviarse de algo aquí definido, esa
> desviación debe justificarse explícitamente en su propio plan, siguiendo el
> principio de Governance de `constitution.md`.

## 1. Propósito

Evitar que cada feature reinvente su propia estructura de carpetas, nombres o
patrones. `constitution.md` define los principios (el "por qué" y las reglas
no negociables); este documento define el "cómo" concreto y compartido para
implementarlos en Godot.

## 2. Estructura de carpetas

```
res://
├── addons/                  # Plugins de terceros (ej. GUT). No se edita a mano.
├── scenes/
│   ├── units/                # Soldado.tscn y futuras variantes de unidades
│   ├── enemies/               # EnemigoBase.tscn y variantes
│   ├── levels/                 # Nivel_MonteCalvo.tscn, futuros niveles
│   └── ui/                     # HUD.tscn, menús, pantallas de victoria/derrota
├── resources/
│   ├── schemas/                # Scripts base de Resource (class_name UnitStats,
│   │                           #   EnemyStats, WaveData) — el "molde", no los datos
│   ├── units/                  # soldado_base_stats.tres, futuras unidades
│   ├── enemies/                # stats de cada tipo de enemigo (.tres)
│   └── waves/                  # definición de oleadas por nivel (.tres)
├── autoloads/                   # Singletons globales (ver sección 4.1)
├── core/                          # Lógica compartida NO-autoload (ver sección 4.5)
│   ├── object_pool.gd             # ObjectPool genérico para enemigos/proyectiles
│   └── board_manager.gd           # BoardManager: ocupación de celdas del tablero, por-nivel
├── assets/
│   ├── sprites/
│   │   ├── units/
│   │   ├── enemies/
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
  estado general de la partida (en curso / pausada / terminada).

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

**Una `Area2D` detectora debe pertenecer al lado ESTÁTICO de la interacción,
no al que se mueve con `move_and_slide()`.** Hallazgo de motor confirmado de
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
puntual). Caso real ya resuelto en el repo con este patrón: el daño cuerpo a
cuerpo que un `Enemigo` (`CharacterBody2D`, se mueve con `move_and_slide()`)
inflige a un `Soldado` (`StaticBody2D`, estático) se detecta y se dispara
desde la `Area2D` "RangoMelee" del propio `Soldado` — la misma que ya usaba
de forma fiable para su ataque a machete (T023) — en vez de una `Area2D`
propia de `Enemigo` (implementación original de T053, descartada tras este
hallazgo). Ver cabecera de `scenes/units/soldado.gd`/`scenes/enemies/enemigo.gd`
para el detalle completo y `docs/SPEC.md` §10 para el gap de diseño que esto
resolvió.

### 4.3 Datos como Resource, nunca hardcodeados

Ya establecido como principio no negociable en `constitution.md`. Cada tipo
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

### 4.4 Modo fusil / modo machete como estado simple

Para el alcance actual (MVP, una sola unidad con dos modos), un enum +
`match` dentro de `soldado.gd` es suficiente — no se justifica un nodo de
máquina de estados formal todavía:

```gdscript
enum SoldierMode { RIFLE, MELEE }
```

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

### 4.6 Convenciones de C# (si se usa)

El proyecto tiene la build .NET habilitada (`project.godot`) y la
constitución permite C# en sistemas puntuales justificados por rendimiento.
Si eso llega a pasar, se siguen estas convenciones (no repetidas por
sistema, se asumen desde este documento):

- Scripts de nodo son `partial class` (requerido para que el generador de
  Godot funcione).
- Métodos y propiedades en `PascalCase`; variables locales en `camelCase`;
  propiedades `[Export]` en `PascalCase`.
- Delegados `[Signal]` siguen el patrón `<NombreEnPasado>EventHandler`
  (ej. `EnemyDefeatedEventHandler`), consistente con la convención de
  señales en tiempo pasado de la tabla de la sección 3.
- Un `Resource` escrito en C# lleva el atributo `[GlobalClass]` — sin eso
  el editor no lo reconoce en "New Resource" ni lo muestra en el picker.
- `GetNode<T>()` se cachea en `_Ready()` igual que `@onready` en GDScript;
  nunca se llama dentro de `_Process()`/`_PhysicsProcess()`.

## 5. Composición de escenas (ejemplo concreto)

- **`Soldado.tscn`**: `StaticBody2D` raíz (el soldado se coloca en una
  celda y no se mueve — no hay `move_and_slide()` en su flujo; `StaticBody2D`
  le da colisión física real para enemigos/proyectiles sin implicar
  movimiento por código, a diferencia de `CharacterBody2D`) → `AnimatedSprite2D` +
  `Area2D` "DeteccionRango" (cono frontal + diagonales) + `Area2D`
  "RangoMelee" + `CollisionShape2D`. Script `soldado.gd`.
- **`EnemigoBase.tscn`**: `CharacterBody2D` raíz (los enemigos sí avanzan
  por el carril con `move_and_slide()`), con `soldado.gd` reemplazado
  por `enemigo.gd`, estructura de hijos análoga.
- **`Nivel_MonteCalvo.tscn`**: `TileMap` (grid de posiciones) +
  `WaveSpawner` (nodo `Timer` + cola de spawns, alimentado por un Resource
  de oleadas) + puntos de spawn + instancia de `HUD.tscn` como
  `CanvasLayer`.

**Nota sobre `collision_layer`/`collision_mask` (sin convención propia
todavía):** ninguna escena del proyecto (`Soldado.tscn`, `EnemigoBase.tscn`)
declara `collision_layer`/`collision_mask` explícitos — todo `CollisionObject2D`
queda en el default de Godot (layer 1 / mask 1), por lo que `Soldado`
(`StaticBody2D`) y `Enemigo` (`CharacterBody2D`) colisionan físicamente entre
sí sin que nadie lo haya decidido a propósito. Esto no es una convención
adoptada — es la ausencia de una, detectada como gap de diseño durante T043
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

## 7. Consideraciones multiplataforma

- Input abstraído vía `InputMap` de Godot; no se hardcodean teclas/toques
  directamente en la lógica de gameplay, para que Android/iOS (touch) y PC
  (mouse/teclado) compartan la misma capa de lógica. Ejemplo concreto ya en
  el repo (`project.godot`, `001-soldado-defensor-oleadas`/T003): las
  acciones `select_cell` y `collect_pickup` mapean mouse click y touch tap
  al mismo evento lógico, sin tecla de teclado asociada; la distinción de
  qué gesto significa cada una queda en la lógica de gameplay, no en el
  `InputMap`.
- UI (`HUD.tscn`) usa contenedores con anclas relativas, no posiciones fijas
  en píxeles, para adaptarse a distintas resoluciones y aspect ratios entre
  dispositivos móviles y PC.
- Presets de exportación por plataforma se versionan en
  `export_presets.cfg`, sin credenciales ni keystores/certificados dentro
  del repositorio.

## 8. Relación con Spec Kit

- Este documento es de **alcance de proyecto completo** y cambia poco.
- `specs/NNN-feature/plan.md` (generado por `/speckit-plan`) es de
  **alcance de una sola feature** y sí cambia con frecuencia. Un plan de
  feature no debe repetir estas convenciones — debe asumirlas y solo
  documentar las decisiones técnicas específicas de esa feature.
- Si un plan de feature introduce un patrón nuevo que debería aplicar a
  todo el proyecto (por ejemplo, adoptar formalmente un State Machine),
  ese patrón se "gradúa" a este documento en una actualización posterior.

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