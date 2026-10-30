# Datos — La carta

## IntroSlide (Resource inmutable)

`image: Texture2D`, `subtitle: String`, `companion_subtitle: String` opcional, `caption: String`, `narration: AudioStream`, `companion_voice: AudioStream` opcional, `minimum_duration: float`, encuadres `start_zoom/end_zoom` y desplazamiento acotado. Ningún campo cambia durante reproducción.

## IntroSequence (Resource inmutable)

`version: String` inicialmente `la_carta_v1`; `slides: Array[IntroSlide]` exactamente siete; `transition_duration: float` independiente de duración de voz.

## IntroPlayer (estado por instancia)

Secuencia, índice/tiempo, fase de clip/fundido, pausa, cerrado y guard/generación. Fases: reproducción, pausa, espera Comenzar y cerrado. Eventos no sobreviven a la instancia; audio y animación pertenecen a ella.

## IntroProgress (dependencia local)

`storage_path` predeterminado user:// sustituible en tests; versión completada/omitida, sin tiempo parcial ni progreso jugable. `has_seen(version)` false ante ausencia/corrupción/versión distinta; `mark_seen(version)` devuelve Error real, sólo éxito cuenta como persistido.

## Contexto de apertura

START_GAME espera Comenzar tras final/omisión. REPLAY vuelve al menú. El contexto lo posee GameRoot; no reutilizar instancias cerradas.
