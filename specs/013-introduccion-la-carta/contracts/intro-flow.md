# Contrato mínimo de introducción

T002 proporciona firmas neutrales que permiten ejecutar RED por aserción. No conectar flujo nuevo ni reproducir/guardar durante setup. Cambios de interfaz se comunican antes al tester.

## IntroPlayer (`Control`)

- `signal finished(skipped: bool)`: una vez al acabar u omitir; detener reproducción antes de emitir, sin montar niveles.
- `play(sequence: Resource) -> void`: comenzar desde escena0 en instancia nueva.
- `pause_intro()`, `resume_intro()`, `skip_intro()`, `close_intro()` →void.
- `get_slide_index() -> int`, `get_elapsed() -> float`, `is_intro_paused() -> bool`, `is_intro_closed() -> bool`: observación para fixtures.
- `advance_intro(delta: float) -> void`: avance determinista compartido con process; no avanzar en pausa/cierre, respetar lectura y clips.
- `set_application_active(active: bool) -> void`: false pausa; true no reanuda sola.
- `show_start_prompt() -> void`, `signal start_requested`: espera gesto explícito sin timeout ni input heredado.

**Setup neutral**: métodos sin reproducción/emisiones/guardado, observadores devuelven index=-1, elapsed=0 y flags falsos; escena mínima importable. Resources declaran campos sin contenido final. IntroProgress devuelve false/ERR_UNAVAILABLE. En GameRoot/MainMenu sólo se declaran las firmas/señales nuevas sin conexiones ni cambios de conducta.

## IntroProgress

- `storage_path: String` asignable antes de uso.
- `has_seen(version: String) -> bool`.
- `mark_seen(version: String) -> Error`.

## MainMenu

Conservar play_requested, añadir intro_requested por botón Ver introducción; consumir su gesto. set_start_enabled incluye navegación mientras hay transición. show_menu restaura controles/foco de Jugar.

## GameRoot

- `intro_scene: PackedScene`, `intro_sequence: Resource` exportados/sustituibles.
- `intro_progress: RefCounted` inyectable antes de ready; crear IntroProgress sólo si no fue inyectado.
- `request_intro() -> void`: replay; `request_start()` decide primer inicio o directo.
- `request_intro_start() -> void`: aceptar sólo Comenzar tras fin/omisión START_GAME y montar un nivel diferido.
- `get_current_intro() -> Node`: vigente o null; conservar get_current_level.
- Ningún nivel durante reproducción/espera. Final/omisión comprueba mark_seen; error no bloquea destinos ni falsea persistencia. REPLAY vuelve al menú; START_GAME espera.
- Capturar generación/instancia en conexiones, ignorar eventos viejos, bloquear reentrada y consumir/diferir dispatch de input.
- Retry/menu conservan contratos vigentes; Retry no inserta introducción.

## Fixtures

Ruta ConfigFile temporal y secuencias breves con AudioStream local válido, sin tocar preferencias reales. RED debe ejecutar aserciones: parser/import roto no vale. Audición/encuadre requieren verificación proporcional, no pruebas artificiales de píxel.
