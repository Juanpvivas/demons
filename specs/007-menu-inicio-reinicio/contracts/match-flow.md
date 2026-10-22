# Contrato de inicio, resultado y repetición

Contrato futuro para [FR-001–013](../spec.md), no prueba de implementación. La raíz decide navegación; Managers conservan economía/oleadas/resultado y UI sólo expresa intenciones.

## Interfaces previstas

| Dueño | Interfaz | Efecto contractual |
|---|---|---|
| `MainMenu` | Señal `play_requested` | Intención de «Jugar», sin crear actores |
| HUD → nivel | Señales `retry_requested`, `menu_requested` | Sólo desde resultado; el nivel propaga a la raíz |
| `GameRoot` | `request_start()`, `request_retry()`, `request_menu()` | Aceptar sólo origen/estado actuales y sin transición pendiente |
| `GameRoot` | Escena de nivel inyectable (`PackedScene`) | Producción usa Monte Calvo; pruebas sustituyen escenario sin activar controles QA en producto |
| `GameStateManager` | `enter_menu()` | MENU sin emitir `game_won`/`game_lost`; conservar IDs previos del enum |
| `WaveManager` | `cancel_waves()` | Vaciar waves, índice -1 y contadores cero; sin `wave_started/completed/all_waves_completed` |
| Nivel/spawner | Cierre local idempotente | Bloquear input/spawn, parar timers y desconectar señales antes de retirar el árbol |

## Orden de una transición aceptada

1. Validar origen actual, estado permitido y guard; bloquear botones/reentrada e invalidar generación anterior antes de tocar Managers.
2. Consumir el gesto de UI; entrar en MENU para impedir acciones/reportes terminales nuevos.
3. Cancelar oleadas sin señal de victoria; cerrar nivel, desconectar sus consumidores de autoloads y retirar su subárbol.
4. Esperar liberación efectiva, sin timers/callbacks/actores anteriores vivos. No montar otra partida mientras el cierre siga pendiente.
5. Destino menú: mostrar/focalizar «Jugar». Destino partida: crear un único nivel; su arranque vigente restablece economía, soldados y oleadas, sin duplicar esa inicialización en la raíz.
6. Conectar una vez las intenciones de la generación actual, ocultar menú y liberar guard. Los emisores/orígenes antiguos no afectan al nuevo intento.

## Presentación e interacción

- `MainMenu`: pantalla completa con fondo pictórico estático, título y «Jugar», contenedores/márgenes y foco inicial. Reutilizar arte existente sin cargar una escena de combate de fondo.
- Resultado: conserva desenlace vigente y añade «Volver a jugar»/«Menú principal», navegación por foco y toque/ratón. Bloquea entrada hacia el tablero; no añade pausa o salida durante PLAYING.
- Redimensionar conserva correspondencia visible/interactiva y área utilizable, sin acciones económicas o navegación espontánea.

## Esqueleto anterior a RED

Escenas `GameRoot`/`MainMenu` cargables, API/señales declaradas y entradas sin efecto; no conectar el flujo funcional, no instanciar el nivel, no resetear/cancelar Managers ni cambiar `project.godot`. Declarar el símbolo MENU al final del enum sin activarlo y las APIs nuevas de Managers como no-op permite RED semántico del estado inicial aún PLAYING. QA revisa el límite; los tests de entrada real fallan porque la entrada vigente aún inicia el nivel.
