# Investigación017 — decisiones de diseño

**Origen del diseño**: 2026-10-31 / `c227982`; I1 parte de `main` / `e8407ec`.
El núcleo I1 está implementado y aprobado funcionalmente; la composición de
nodos y menú descrita para I2 sigue prevista. Los parámetros iniciales no
acreditan equilibrio en partidas o rendimiento de destino.

## 1. Integración local y autoridad temporal

**Decisión**: `CommanderSession` y `CommanderMemoryStore` instanciables, sin
autoload o EventBus nuevos. En la integración futura I2, `GameRoot` poseerá el
almacén y lo inyectará al nivel
antes de añadirlo al árbol. El nivel compone la sesión antes de iniciar WAVE.
`WaveSpawner` pide únicamente un carril al dispararse su Timer actual.

**Motivo**: `scenes/levels/wave_spawner.gd` ya separa cola aplanada, Timer,
activación y cursor de carriles. `_on_wave_started()` espera también el primer
intervalo; `_on_spawn_timer_timeout()` mantiene la autoridad de emisión.
El inicial pasa por `spawn_initial_enemy()` con lane2 y queda excluido.
`WaveManager` conserva el avance de oleada por bajas: preservar intervalos no
equivale a preservar tiempos absolutos de final de partida.

**Alternativas**: rechazar un nuevo gestor global, árbol de comportamiento o
servicio HTTP: añaden dependencias y no resuelven mejor la elección de cinco
carriles. El catálogo de planes sintéticos016 no se reutiliza.

## 2. Memoria pequeña y aprendizaje acotado

**Decisión**: tabla de 360 contextos como máximo; memoria congelada durante cada
partida y aprendizaje sólo en WON/LOST. Cada decisión usa observaciones actuales,
por lo que puede responder a la defensa sin aprender de un abandono.
Mezclar exploración uniforme con pesos aprendidos limitados; media de resultados
por contexto y partida, olvido por partidas con muestras y confianza saturada.
Las fórmulas y valores iniciales están en [el contrato](contracts/commander.md).

**Motivo**: una sola partida no domina por tener muchas bajas; ninguna memoria
puede eliminar alternativas ni permitir un carril usado en el bloque. Los
parámetros viven en un Resource de balance inmutable, no en lógica ni guardados.

**Alternativas**: elegir siempre el mejor carril pierde variedad; azar puro no
aprende; Q-learning/red neuronal añade entrenamiento y atribución retardada
innecesarios para esta V1. Este estimador contextual no aprende una estrategia
óptima de partida completa ni mide diversión.

## 3. Observación y crédito por activación

**Decisión**: leer `Soldado.get_reload_state()` y `get_lane_id()`, y observar
enemigos activos por origen/carril/generación sin campos privados. Una muerte
WAVE confirmada recibe avance longitudinal normalizado; un cruce WAVE confirmado
recibe1. Los vivos restantes al terminal se censuran y excluyen. INITIAL puede
influir en la carga visible, pero nunca aporta su propia muestra de aprendizaje.

**Motivo**: `Enemigo.get_advance_progress()` es −X, no un valor normalizado. La
zona defendida usa colisiones del cuerpo: no inferir cruce por X del centro.
La posición de baja llega en `enemy_defeated`; registrar antes de
`WaveManager.notify_enemy_defeated()` y de liberar al pool, porque ese notify
puede emitir WON síncronamente. `_die()` ya desactiva al actor antes de emitir:
no rechazar una muerte válida porque `is_targetable()` devuelva falso.

**Límites**: censura introduce sesgo y los actores se ayudan mutuamente. El
avance subvalora fusileros que hacen daño sin avanzar. Separar A/R evita mezclar
perfiles, pero no elimina ese límite. No atribuir causalidad ni premiar la mera
duración, el cleanup o toda una victoria a la última aparición.

## 4. Persistencia versionada y borrado

**Decisión**: JSON de datos primitivos, con dos slots alternados propios y
validación completa; no cargar Resources desde `user://`. En modo persistente,
sólo publicar en RAM una memoria cuyo guardado se haya verificado. El borrado elimina ambos slots,
primero el inactivo y después el activo, y verifica su ausencia antes de
comunicar éxito y sustituir la memoria en RAM por la neutral.

**Motivo**: el patrón inyectable de `core/intro_progress.gd` sirve para propiedad
y errores, pero la tabla contextual requiere esquema y validación mayores.
Dos slots mantienen una copia anterior ante una escritura incompleta sin exigir
que un rename sea atómico en todas las plataformas. Borrar sólo el archivo más
nuevo permitiría resucitar un respaldo; eliminar todas las copias evita ese caso.

**Alternativas**: ConfigFile es válido para preferencias pequeñas y ya existe
en el proyecto; aquí JSON acota explícitamente tipos y estructura. No se añade
base de datos, migración inventada de versiones futuras o sincronización.

## 5. Interfaz y plataformas — I2 pendiente

**Decisión**: añadir una intención de borrado al menú existente, con confirmación
y feedback textual; raíz autoriza sólo en MENU sin transición, nivel o intro.
Reutilizar Theme, safe area, controles de64px y navegación de foco existentes.
No añadir ajustes de IA ni cambiar el HUD del combate.

**Fuentes primarias consultadas**:

- [Godot: persistencia Web](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html#using-cookies-for-data-persistence):
  `user://` depende de IndexedDB y del contexto del navegador; el detector de
  persistencia puede dar falsos positivos. Comprobar recarga real por navegador
  y origen, sin prometer durabilidad sólo porque una operación devuelve OK.
- [Godot: RNG](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html):
  fijar seed permite reproducir una secuencia, pero el algoritmo subyacente es
  un detalle del motor. Limitar la reproducción al mismo motor/configuración.
- [Godot: ConfigFile](https://docs.godotengine.org/en/stable/classes/class_configfile.html):
  alternativa de datos por secciones y claves, considerada frente a JSON.

## Skills y resultado de investigación

Consultados `using-godot-prompter` y su adaptación Codex, `resource-pattern`,
`save-load`, `event-bus`, `godot-ui`, `godot-testing` y `godot-brainstorming`.
Aplicar señales locales, parámetros inmutables, servicios inyectables y pruebas
GUT; las convenciones del repositorio prevalecen sobre sus ejemplos genéricos.
La instalación se descubre en cada entorno, sin rutas personales en Git.

La investigación de preparación no equivale a QA de implementación. I1 ya
cuenta con aprobación funcional independiente de sus servicios; CI y el gate
final de integración se comprueban por separado. La conexión al nivel, el
equilibrio del juego, los destinos y la publicación conservan sus verificaciones
pendientes. El [contrato](contracts/commander.md) distingue la verificación local
de archivos de la durabilidad y de los fallos simulados por etapa.
