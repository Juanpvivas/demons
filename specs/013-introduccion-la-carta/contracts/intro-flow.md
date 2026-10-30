# Contrato mínimo de introducción

**Vigencia**: contrato original de T002 preservado como interfaz base; R2
actualiza destino de replay, presentación/audio y salida de partida. La
descripción de setup neutral es histórica y no requiere repetirlo.

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
- `request_intro_start() -> void`: en R2 aceptar sólo Comenzar tras fin/omisión de cualquiera de las dos aperturas y montar un nivel diferido.
- `get_current_intro() -> Node`: vigente o null; conservar get_current_level.
- Ningún nivel durante reproducción/espera. Final/omisión comprueba mark_seen; error no bloquea destinos ni falsea persistencia. En R2 ambas aperturas esperan Comenzar; el regreso al menú de REPLAY pertenece sólo a I1.
- Capturar generación/instancia en conexiones, ignorar eventos viejos, bloquear reentrada y consumir/diferir dispatch de input.
- Retry/menu conservan contratos vigentes; Retry no inserta introducción.

## Revisión R2 — sonido y presentación

- IntroSequence puede añadir `ambience: AudioStream` y
  `ambience_volume_db: float` como configuración autorada sin estado mutable.
  Voice y ambiente usan AudioStreamPlayers distintos; nombre recomendado
  `Ambience` para el segundo. El ambiente empieza con play, permanece de fondo
  entre escenas y nunca se reinicia/solapa por cada frase.
- Pausa/foco usan la misma autoridad para ambos reproductores. Continuar retoma;
  close/skip/finished silencian voz y ambiente antes de emitir salida.
- La ausencia de ambiente en fixtures antiguos es válida; usar el recurso
  autorado existente para RED de la nueva configuración, sin cargar un WAV
  inexistente ni depender de nuevas propiedades antes de declararlas.
- En siete imágenes sólo subtítulo de voz y controles; Counter, Caption y el
  aviso de ficción superior están ausentes u ocultos y no reservan una cabecera
  vacía. La documentación/créditos conservan la ficción fuera de las imágenes.
- Ald puede integrarse sólo como preview provisional; la persona acepta timbre
  pero lo percibe robotizado y grabará los siete párrafos del narrador. T026
  reemplaza clips cuando llegue el archivo y verifica texto, fluidez, timbre y
  mezcla por escucha. La toma humana del compañero es opcional. Los tests
  comprueban reproducción/ciclo; no sustituyen escucha ni fuerzan RED artificial.

## Revisión R2 — retorno activo al menú

- HUD añade un botón visible `Menú principal` durante PLAYING y PAUSED. Emite
  `menu_requested` consumiendo el gesto; no altera Managers ni monta escenas.
  El acceso activo no habilita acciones de resultado ocultas: sus botones y
  callbacks conservan sus guards terminales; puede usarse un botón separado.
- Nivel propaga esa intención al padre para la instancia vigente; GameRoot
  `request_menu()` acepta PLAYING/PAUSED además de WON/LOST, sólo con nivel
  vigente y sin transición pendiente. `request_retry()` continúa sólo terminal.
  La propagación de nivel existente, antes restringida a terminal, se amplía
  de forma controlada para la nueva intención activa/pausada.
- Reutilizar cierre común: bloquear reentrada, invalidar generación/desconectar
  intenciones, entrar MENU, cancelar oleadas y close_match, retirar/liberar nivel
  y audio/pools/inputs antes de mostrar menú. Un evento viejo no monta otra
  partida ni afecta otra instancia. No crear modal o guardado de partida.
- Sin interfaz nueva obligatoria para RED: tester puede llamar request_menu,
  comprobar el guard existente y consultar el botón mediante get_node_or_null
  o búsqueda de texto, con aserciones válidas y sin parser roto.

## Fixtures

Ruta ConfigFile temporal y secuencias breves con AudioStream local válido, sin tocar preferencias reales. RED debe ejecutar aserciones: parser/import roto no vale. Audición/encuadre requieren verificación proporcional, no pruebas artificiales de píxel.

## Enmienda R3 — prompt y toma humana

- `show_start_prompt()` conserva firma/señal actuales; GameRoot sigue llamando
  la API pública, sin rutas a nodos privados. No se requiere setup neutral nuevo.
- Tras final natural u omisión en cualquiera de las aperturas, la última imagen
  sigue visible y sólo aparece Comenzar centrado abajo en la franja segura de
  Pausar/Omitir, con su estilo y mínimo 52 px de alto. No panel central o banda
  de fondo, títulos/ficción/rótulos, Subtitle, Pause o Skip visibles/reservando
  espacio. Resize y foco mantienen un botón alcanzable.
- Voz/ambiente están detenidos y no reaparecen durante espera. El gesto de
  omisión/final no activa Comenzar; sólo un gesto nuevo emite start_requested
  una vez y permite un nivel. Conservar guards de generación/reentrada.
- T026 reemplaza sólo siete narraciones por segmentos de `toma-3.wav` elegida
  y autorizada; mantener texto íntegro y adaptar duración si hace falta. Un
  compañero Ald provisional permanece separado/identificado. Procedencia humana
  y aprobación perceptual se atribuyen a la persona; el agente verifica
  técnicamente integridad/texto/duración/reproducción/mezcla sin fingir audición.
  No versionar archivo original, metadatos temporales, ASR o logs innecesarios.
