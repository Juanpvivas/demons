## Sub-recurso que describe una entrada de spawn dentro de una oleada
## (`WaveData.spawn_entries`, ver `data-model.md`): qué tipo de enemigo,
## cuántos, y con qué intervalo entre spawns sucesivos.
##
## Solo dato de configuración de solo lectura — sin lógica de spawn en
## tiempo de ejecución (esa vive en `WaveManager`/`WaveSpawner`,
## `docs/ARCHITECTURE.md` §4.3).
class_name WaveSpawnEntry
extends Resource

## Tipo de enemigo a spawnear para esta entrada.
@export var enemy_stats: EnemyStats

## Cuántos enemigos de este tipo genera esta entrada.
@export_range(1, 100, 1) var count: int = 5

## Segundos entre spawns sucesivos de esta entrada.
@export_range(0.05, 10.0, 0.05) var spawn_interval: float = 1.0
