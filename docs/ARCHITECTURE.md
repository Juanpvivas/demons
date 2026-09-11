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
├── scenes/
│   ├── units/            # Soldado.tscn y futuras variantes de unidades
│   ├── enemies/          # EnemigoBase.tscn y variantes
│   ├── levels/           # Nivel_MonteCalvo.tscn, futuros niveles
│   └── ui/                # HUD.tscn, menús, pantallas de victoria/derrota
├── resources/
│   ├── units/             # soldado_base_stats.tres, futuras unidades
│   ├── enemies/           # stats de cada tipo de enemigo (.tres)
│   └── waves/             # definición de oleadas por nivel (.tres)
├── autoloads/              # Singletons globales (ver sección 4.1)
├── assets/
│   ├── sprites/
│   ├── audio/
│   └── fonts/
└── tests/
    └── unit/               # Tests con GUT, estructura espejo de scripts
```

Cada escena (`.tscn`) vive junto a su script (`.gd`) en la misma carpeta —
convención estándar de Godot, evita saltar entre carpetas paralelas de
"scripts" y "scenes" para una misma unidad lógica.

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
actual, moral acumulada, modo activo) — eso vive en la instancia, no en un
autoload. Solo el recurso compartido (munición recolectada del jugador) es
verdaderamente global.

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

### 4.3 Datos como Resource, nunca hardcodeados

Ya establecido como principio no negociable en `constitution.md`. Cada tipo
de soldado, enemigo u oleada se define como un `Resource` personalizado
(`.tres`) con un script base (`class_name UnitStats extends Resource`, etc.)
que declara sus campos tipados. Balancear el juego = editar archivos `.tres`
en el editor de Godot, nunca tocar scripts de lógica.

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
se reciclan desde un pool en vez de instanciar/destruir (`queue_free()`) en
cada oleada. Un `ObjectPool` genérico (autoload o utilidad) gestiona esto
para ambos tipos.

## 5. Composición de escenas (ejemplo concreto)

- **`Soldado.tscn`**: `CharacterBody2D` raíz → `AnimatedSprite2D` +
  `Area2D` "DeteccionRango" (cono frontal + diagonales) + `Area2D`
  "RangoMelee" + `CollisionShape2D`. Script `soldado.gd`.
- **`EnemigoBase.tscn`**: estructura análoga, con `soldado.gd` reemplazado
  por `enemigo.gd`.
- **`Nivel_MonteCalvo.tscn`**: `TileMap` (grid de posiciones) +
  `WaveSpawner` (nodo `Timer` + cola de spawns, alimentado por un Resource
  de oleadas) + puntos de spawn + instancia de `HUD.tscn` como
  `CanvasLayer`.

## 6. Testing

- Framework: **GUT** (Godot Unit Testing).
- Los tests viven en `res://tests/unit/`, con estructura espejo a la de
  `scripts/` (ej. `test_soldado.gd` prueba `soldado.gd`).
- Cobertura mínima obligatoria (según constitución): cálculo de daño,
  consumo/recolección de munición, acumulación de moral, condiciones de
  victoria/derrota, generación de oleadas — toda lógica que no dependa de
  renderizado.

## 7. Consideraciones multiplataforma

- Input abstraído vía `InputMap` de Godot; no se hardcodean teclas/toques
  directamente en la lógica de gameplay, para que Android/iOS (touch) y PC
  (mouse/teclado) compartan la misma capa de lógica.
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
