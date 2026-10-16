# Research: terreno y trincheras de Monte Calvo

**Fecha**: 2026-10-15. Investigación de preparación, sin ejecutar Godot ni GUT.
**Línea base consultada**: commit `e7f2ca9`; archivos del juego leídos directamente. El repositorio estaba limpio al comenzar.

## R1. Dirección artística y referencia

**Decisión**: adaptar únicamente suelo ocre/oliva, montañas azul grisáceo y trincheras de tierra, madera y sacos. Usar [la copia del concepto](references/visual-reference.md) para comparar estilo y materiales.
**Razón**: esta es la dirección aprobada y el alcance solicitado. Los personajes y la interfaz de la imagen no son recursos finales ni reglas del prototipo.
**Alternativas descartadas**: usar la imagen completa como fondo introduciría personajes, HUD y cinco carriles falsos; producir nuevas unidades o interfaz ampliaría la iteración.

La referencia se conserva bajo `references/.gdignore`: no debe importarse ni entrar en las exportaciones automáticas del proyecto como textura documental. Los PNG finales del juego se producirán aparte en la fase de ejecución. [Organización de proyectos y directorios ignorados](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html).

## R2. Conservar el espacio y los límites actuales

**Decisión**: adaptar el dibujo al `TileMap` existente de 96×96 y a las posiciones actuales, sin migrar el tablero, mover actores, cambiar cámara o limitar colocación.
**Evidencia**: `scenes/levels/Nivel_MonteCalvo.tscn` contiene el TileSet vacío y los nodos de gameplay. `nivel_monte_calvo.gd` convierte pantalla a mundo/celda y centra los despliegues nuevos. `core/board_manager.gd` registra ocupación, sin límites de región.
**Razón**: una mejora de presentación no debe cambiar el sistema de coordenadas ni inventar celdas permitidas. El soldado inicial en (576,500) no se debe ajustar al centro de una celda.
**Alternativas descartadas**: cinco carriles, tablero finito, migración a `TileMapLayer`, perspectiva/cámara nuevas o cambios de hitboxes. Son cambios de comportamiento o infraestructura distintos.

## R3. Composición visual mínima

**Decisión**: futura escena `scenes/levels/MonteCalvoVisual.tscn`, raíz `Node2D` al origen, con sprites estáticos para fondo, suelo y decoración. Integrarla como un único hijo nuevo del nivel, detrás de los actores, sin script.
**Razón**: separa arte y lógica y permite revisar o retirar la mejora como una unidad. No requiere recursos de balance, señales, autoloads o actualización por frame.
**Contrato de dibujo**: raíz visual `z_index=-10`; hijos relativos entre 0 y 3, sin excepciones que alcancen el plano de actores. Conservar identidad de transformaciones en el nivel y rutas de sus hijos existentes.
**Alternativas descartadas**: fondo único con toda la decoración horneada, que dificulta ajustar trincheras; controlador visual, física, navegación, luces, parallax o partículas, que no resuelven requisitos de esta iteración.

## R4. Recursos e importación

**Decisión**: ampliar la carpeta de sprites de arquitectura con `assets/sprites/levels/monte_calvo/`: `montanas.png`, `terreno.png` y `trincheras_atlas.png`. Usar regiones/recursos de atlas estáticos en la escena cuando sea útil, compartiendo textura entre segmentos.
**Razón**: pocas imágenes separadas permiten ajustar encuadre, materiales y contraste sin duplicar la escena o crear sistemas nuevos. Las fuentes finales deben estar limpias de UI/personajes.
**Importación**: comenzar con PNG sin pérdidas, transparencia recortada y resolución moderada. Evaluar hasta 2048 píxeles por lado como presupuesto inicial, no como requisito artístico rígido. Registrar dimensiones, memoria estimada y memoria real antes/después; si no alcanza la calidad, justificar el ajuste antes de ampliar el presupuesto.
**Filtro/repetición**: configurar solo los `CanvasItem` del entorno según la escala observada. No cambiar el filtro global, renderer Mobile o ETC2/ASTC existentes. No aplicar automáticamente consejos genéricos de importer: Godot configura filtro y repetición en los nodos desde 4.0.
**Alternativas descartadas**: VRAM Compressed por defecto para todo el arte, debido a posibles artefactos 2D; texturas enormes, muchos planos transparentes o meshes preventivos sin evidencia de perfil.
**Fuente oficial**: [importación de imágenes](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html).

## R5. Input y percepción de la trinchera

**Decisión**: no añadir `Control`, `Area2D`, cuerpos físicos, colisiones o navegación al subárbol visual. Toda la decoración queda debajo de actores y pickups.
**Razón**: el orden de dibujo no controla el manejo de input. Se requiere validar clic/toque real además de inspeccionar el árbol y conservar la conversión actual.
**Evidencia**: `_unhandled_input`, `_screen_to_world`, `_world_to_cell` y `_try_deploy_soldado` en `nivel_monte_calvo.gd`; escena de pickup y pruebas existentes.
**Fuente oficial**: [CanvasItem y orden de dibujo](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html).

## R6. Validación y TDD proporcional

**Decisión**: trabajo de arte estático con revisión visual, importación, pruebas de interacción, regresión existente y QA independiente. No añadir tests que solo enumeren sprites ni fabricar RED.
**Razón**: no se cambia comportamiento. Si aparece una necesidad de lógica nueva, detener esa ampliación, explicitar su alcance y preparar RED válido → desarrollo → GREEN/regresión → QA antes de implementarla; no esconderla bajo una tarea de arte.
**Evidencia**: constitución II; `docs/DEVELOPMENT_WORKFLOW.md`; `tests/unit/levels/test_nivel_montecalvo.gd`, `test_wave_spawner.gd` y suite de sistemas/unidades.
**Límites reales**: HUD existe como escena separada pero no se instancia en este nivel. `reload()` existe sin entrada interactiva de producción encontrada. No añadir esos enlaces aquí ni prometerlos como parte del smoke.

## Skills consultadas

GodotPrompter 1.13.2: `using-godot-prompter`, `2d-essentials`, `scene-organization`, `assets-pipeline` y `godot-testing`; investigación contrastada por agentes en solo lectura. Sus recomendaciones generales de migrar TileMap, añadir parallax o usar compresión no sustituyen las restricciones de este proyecto.

No quedan decisiones de diseño sin resolver para preparar las tareas. Las medidas de rendimiento, capturas y disponibilidad de dispositivos son evidencia futura de ejecución, no resultados obtenidos en este documento.
