## Molde de datos que describe una oleada autorada (ver `research.md` §4).
## Instancias concretas en `resources/waves/*.tres`, referenciadas en orden
## por el nivel.
##
## Solo dato de configuración de solo lectura — sin lógica de spawn en
## tiempo de ejecución (esa vive en `WaveManager`/`WaveSpawner`,
## `docs/ARCHITECTURE.md` §4.3).
class_name WaveData
extends Resource

## Orden de esta oleada dentro de la secuencia del nivel; informativo/depuración.
@export var wave_number: int = 1

## Composición de la oleada: qué tipos de enemigo, cuántos de cada uno, y
## con qué intervalo entre spawns (ver `WaveSpawnEntry`).
@export var spawn_entries: Array[WaveSpawnEntry] = []
