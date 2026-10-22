# Research: decisiones de navegación y ciclo de vida

Diseño propuesto para [007](spec.md), aún sin implementar. Investigación local de sólo lectura sobre `main` `d86543f` y skills GodotPrompter: `scene-organization`, `event-bus`, `state-machine`, `godot-ui`, `responsive-ui`, `godot-testing`, `godot-code-review` y `gdscript-patterns`. Se sigue el flujo del repositorio y se conservan sus rutas `specs/`.

## 1. Una raíz local, sin nivel detrás del menú

- **Decisión**: `GameRoot` compone menú y nivel; sólo instancia `Nivel_MonteCalvo.tscn` al aceptar «Jugar». El menú reutiliza `assets/sprites/levels/monte_calvo/terreno.png` y `montanas.png`, conservando procedencia/SOURCES existentes.
- **Motivo**: `nivel_monte_calvo.gd:_ready()` inicia estado, economía, cinco soldados, pool, atacante y oleadas. Los autoloads no arrancan enemigos solos. Separar la presentación impide combate oculto desde su origen.
- **Alternativas**: ocultar o pausar un nivel vivo obliga a controlar timers, física, input y estado global; reutilizar `Nivel_MonteCalvo` como fondo ejecutaría su arranque. Un nuevo autoload de navegación añade estado global innecesario.

## 2. Retirar y recrear el intento

- **Decisión**: destruir el subárbol del nivel completo entre intentos, con cierre explícito e idempotente. Mantener pooling durante el combate, no reciclar un nivel parcialmente reseteado.
- **Motivo**: `WaveSpawner` posee el pool enemigo; éste contiene también cajas, mientras los efectos son hijos locales. La recreación restablece soldados, tablero y servicios mediante su inicialización vigente.
- **Riesgo resuelto**: `queue_free()` es diferido y el spawner antiguo escucha `WaveManager.wave_started`. Retirar/desconectar y esperar liberación efectiva antes de arrancar oleadas nuevas; rechazar intenciones y callbacks de la generación anterior.
- **Alternativa**: resetear en sitio cada campo de cada actor/servicio produce una segunda lógica de inicialización y facilita herencias incompletas.

## 3. Estado fuera de partida y cancelación sin victoria

- **Decisión**: añadir `MENU` al final del enum de `GameStateManager`, preservando `PLAYING=0`, `PAUSED=1`, `WON=2`, `LOST=3`; el arranque de producto queda en `MENU`. `enter_menu()` no emite resultado. `start_new_match()` sigue siendo el único inicio jugable del nivel.
- **Decisión**: `WaveManager.cancel_waves()` vacía secuencia/contadores y deja índice `-1` sin señales de progreso o victoria. No usar `start_waves([])`, que actualmente emite `all_waves_completed`.
- **Motivo**: los reportes terminales ya ignoran estados distintos de `PLAYING`; un estado explícito protege el menú. QA revisará regresión de consumidores/fixtures que suponían el valor inicial previo.
- **Alternativas**: reutilizar `PAUSED` confunde una partida suspendida con ausencia de partida; renumerar el enum cambia consumidores sin necesidad.

## 4. UI y entrada

- **Decisión**: los botones sólo emiten intenciones; HUD conserva «VICTORIA»/«DERROTA» actuales. El nivel las propaga y la raíz decide el destino, valida origen/estado y bloquea reentrada durante la transición.
- **Motivo**: responsabilidades y señales hacia arriba, referencias sólo a hijos propios; sin bus nuevo. `Control` y contenedores gestionan aspecto, márgenes utilizables, foco y activación de teclado. Un evento aceptado no llega a `_unhandled_input` del tablero nuevo.
- **Alternativa**: HUD cambiando escenas o reiniciando Managers mezcla navegación, resultado y presentación.

## 5. RED y verificación proporcional

- **Decisión**: setup mínimo de escenas/API cargables y métodos no operativos antes de RED; probar comportamiento mediante llamadas y UI reales, no existencia de archivos. La entrada real aún apunta al nivel hasta la implementación guiada por RED.
- **Motivo**: permite fallos por inicio/cambio/limpieza ausentes. El fixture existente de `test_horizontal_board.gd` permite WON con baja WAVE real y LOST por cruce físico; usarlo a través del flujo no demuestra victoria manual de producción con 100 enemigos.
- **Alternativa**: un RED causado por importación o comprobar sólo nombres/nodos no prueba el requisito. No son necesarias persistencia, red o bibliotecas nuevas.
