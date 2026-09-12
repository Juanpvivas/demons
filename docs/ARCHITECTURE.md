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
│   └── object_pool.gd             # ej: ObjectPool genérico para enemigos/proyectiles
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
  Expone `ammo_pool_changed(new_amount)`. Ningún otro nodo debe mantener su
  propia copia de este número.
- **`WaveManager`**: controla la secuencia de oleadas del nivel activo,
  emite `wave_started(wave_number)` y `wave_completed(wave_number)`.
- **`GameStateManager`**: controla condición de victoria/derrota y el
  estado general de la partida (en curso / pausada / terminada).

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
- Referencias a nodos hijos propios (ej. `Soldado.gd` accediendo a sus
  `Area2D` "DeteccionRango"/"RangoMelee") se cachean una sola vez con
  `@onready var` al inicio del script. `get_node()`/`$Path` **nunca** se
  llama dentro de `_process()`/`_physics_process()` — ni para hijos propios
  ni, con más razón, para nodos externos (eso ya lo cubre la regla anterior
  contra `get_node("../../...")`).

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
autoload ni pertenece a una sola feature (por ejemplo, si en el futuro
`Soldado` y `Enemigo` llegan a compartir una clase base, también viviría
aquí).

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
| 2026-09-11 | Correcciones de revisión (`godot-code-review` + `resource-pattern`): raíz de `Soldado.tscn` cambiada de `CharacterBody2D` a `StaticBody2D` (unidad estacionaria); regla explícita de límite dato/estado entre `Resource` de stats y estado mutable por instancia; regla de `@onready` y conexión de señales en `_ready()`; `queue_free()` vs `free()` para limpieza fuera del pool; `@export_range`/`@export_group` para campos de balance; nueva sección 4.6 de convenciones C# |
| 2026-09-11 | §6 y §7 sincronizadas con la realidad del repo tras T002/T003 de `001-soldado-defensor-oleadas`: se confirma versión de GUT (v9.7.1) ya instalada, y se documenta como ejemplo concreto el par de acciones `InputMap` `select_cell`/`collect_pickup` (mouse+touch, sin tecla hardcodeada) — antes ambas secciones solo describían la convención en abstracto |
| 2026-09-11 | §4.1: se agrega la convención de que los scripts de autoload no declaran `class_name` (se referencian por su nombre de singleton) — duda explícita de implementación surgida en T008/T009 (`EconomyManager`, `GameStateManager`) de `001-soldado-defensor-oleadas`, graduada aquí porque aplica a todo autoload futuro (ej. `WaveManager` en T039) |