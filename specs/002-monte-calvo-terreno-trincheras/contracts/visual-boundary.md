# Contrato interno: entorno visual y mecánicas existentes

**Estado**: contrato vigente para la implementación por agentes autorizada el 2026-10-15, en curso en `codex/002-monte-calvo-terreno-trincheras`. La integración y sus verificaciones requieren las aprobaciones de tareas. Vincula FR-004 a FR-011 y SC-002 a SC-006. No define una API externa.

## Integración permitida

Añadir `scenes/levels/MonteCalvoVisual.tscn`, sus recursos gráficos y una instancia hija directa de `Nivel_MonteCalvo`. El root visual queda en (0,0), escala (1,1), rotación 0, `z_index=-10`; hijos con z relativo 0–3. Todas sus hojas se dibujan por debajo de los actores existentes, sin excepciones de z global.

No añadir scripts, señales, autoloads, `Control`, cuerpos/áreas, colisiones, navegación, cámaras, partículas, shaders, luces o parallax. No alterar procesos o estado de los nodos actuales. La decoración no captura input ni llama a gameplay.

## Invariantes de escena y coordenadas

| Elemento existente | Valor / comportamiento que se conserva |
|---|---|
| `Nivel_MonteCalvo` | Raíz `Node2D`, mismo script y transformación |
| `Tablero` | Hijo directo, tipo `TileMap`, transformación actual y TileSet de 96×96; sin migración a `TileMapLayer` |
| `Soldado` inicial | Hijo directo, posición (576,500), escena y geometrías actuales; no centrarlo ni ajustarlo al arte |
| `Enemigo` inicial | Hijo directo, posición (576,50), escena y geometrías actuales |
| Spawn de oleadas | `wave_spawn_position=(576,50)`; avance en +Y, sin rutas o carriles nuevos |
| `PosicionDefendida` | Hijo directo, posición (576,650), rectángulo 960×64 y configuración existente |
| Actores | Escalas y colisiones 48×48; detecciones, offsets, grupos y señales sin cambios |
| Entrada / celda | Inversa de `canvas_transform` → local de Tablero → `local_to_map`; despliegues nuevos en `map_to_local(cell)` |
| Ocupación | `BoardManager` mantiene solo ocupación/liberación; no existe filtro de región que esta feature deba añadir |
| Proyecto | Escena principal, autoloads, InputMap, `canvas_items`/`expand`, renderer y exportaciones sin cambios |

No confundir tamaño de celda con tamaño total del tablero: no hay límites finitos implementados. Los bordes de rocas, montañas y trincheras no deben prometer zonas inaccesibles. La posición inicial del soldado es distinta de la alineación de los despliegues nuevos y ambas se preservan.

## Invariantes de comportamiento

- Scripts de `scenes/`, `core/`, `autoloads/` y schemas de `resources/` sin cambios previstos.
- Escenas de Soldado, EnemigoBase, AmmoPickup y HUD sin cambios.
- Los mismos recursos de unidades, enemigos y diez oleadas, en el mismo orden. Los costos, munición, daño, moral y recarga no cambian; los valores reales siempre proceden de sus Resources existentes.
- Mismos resultados de colocación, celda ocupada, fondos insuficientes, recolección, muerte/liberación, combate y fin de partida.
- Mantener pickup con su sprite, radio físico y recepción de entrada actuales. No compensar un fallo de picking modificando el controlador del nivel dentro de esta tarea artística.
- `HUD.tscn` no está instanciado en el nivel consultado y no se añade aquí. La recarga se conserva como método y se verifica mediante cobertura existente; no se inventa un botón de producción.

## Verificación del contrato al implementar

1. El tester registra hashes y propiedades de la línea base antes de cambios.
2. El desarrollador limita el diff a los recursos, la nueva escena y la instancia visual añadida a `Nivel_MonteCalvo.tscn`.
3. El tester confirma importación, regresión y matriz de clic/toque. La inspección de z no demuestra por sí sola el comportamiento de input.
4. QA compara el diff semántico y la evidencia antes/después, sin modificar el checkout ni marcar tareas.

La estructura estática puede verificarse con inspección; la lectura, el picking con stretch, el encuadre y el rendimiento requieren ejecución futura real. Si para cumplir el requisito se necesita lógica nueva, se detiene esa ampliación y se prepara un alcance con TDD; no se añade silenciosamente al subárbol visual.
