# Datos — La carta

El esquema introducido en R2 conserva su estructura; rige comportamiento R3,
con narrador humano toma3 y compañero sintético Qwen definitivo aceptado por
la persona según [SOURCES](../../assets/audio/narrative/la_carta/SOURCES.md).
Las voces Ald y entregas parciales siguientes describen historia, no el medio actual.

## IntroSlide (Resource inmutable)

`image: Texture2D`, `subtitle: String`, `companion_subtitle: String` opcional, `caption: String`, `narration: AudioStream`, `companion_voice: AudioStream` opcional, `minimum_duration: float`, encuadres `start_zoom/end_zoom` y desplazamiento acotado. Ningún campo cambia durante reproducción.

## IntroSequence (Resource inmutable)

`version: String` inicialmente `la_carta_v1`; `slides: Array[IntroSlide]` exactamente siete; `transition_duration: float` independiente de duración de voz.

R2 añade `ambience: AudioStream` y `ambience_volume_db: float` para un fondo
original discreto. Son datos inmutables, independientes de los clips de voz;
ninguno almacena posición de reproducción. La versión narrativa conserva el
recuerdo existente al no cambiar el guion hablado. `caption` puede conservarse
como dato histórico, pero nunca se presenta durante las imágenes en R2.

Los AudioStream de narración admitían Ald provisional durante la entrega parcial
y sustitución por las siete grabaciones humanas en T026 al recibirse el archivo,
sin nuevo tipo de dato ni persistencia. La opción de compañero humano pertenece
a esa preparación; el medio actual definitivo es sintético, separado del narrador.

## IntroPlayer (estado por instancia)

Secuencia, índice/tiempo, fase de clip/fundido, pausa, cerrado y guard/generación. Fases: reproducción, pausa, espera Comenzar y cerrado. Eventos no sobreviven a la instancia; audio y animación pertenecen a ella.

## IntroProgress (dependencia local)

`storage_path` predeterminado user:// sustituible en tests; versión completada/omitida, sin tiempo parcial ni progreso jugable. `has_seen(version)` false ante ausencia/corrupción/versión distinta; `mark_seen(version)` devuelve Error real, sólo éxito cuenta como persistido.

## Contexto de apertura

I1 distinguía START_GAME→Comenzar de REPLAY→menú. En R2 ambas aperturas esperan
Comenzar tras final/omisión y sólo otro gesto inicia partida; no reutilizar
instancias cerradas. El ambiente tiene estado/pausa por instancia de IntroPlayer,
nunca por Resource ni singleton.
