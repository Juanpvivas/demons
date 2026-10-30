# Sonidos de combate — procedencia

Todos los archivos son WAV mono PCM de 44.100Hz y 16bits, sin bucles. Se incorporan sólo los nueve clips renderizados; no se añaden motores de síntesis, modelos, referencias de voz ni llamadas de red.

## Disparos

`disparo_01.wav` a `disparo_03.wav` derivan de **Rifle Gun Shot 01.wav**, de **LilMati**, publicado bajo **CC0 1.0**:

- Fuente del autor y licencia: https://freesound.org/people/LilMati/sounds/433858/
- Muestra pública utilizada: https://cdn.freesound.org/previews/433/433858_6142149-hq.mp3

Se decodifica la muestra pública HQ, se convierte a mono44.1kHz, se conserva el primer tramo de 0.82s y se suaviza la cola. Las tres variaciones usan factores de tono/tiempo 1.0,0.981 y 1.022. Es un efecto de fusil genérico; no se afirma que sea una grabación histórica ni de un M1 Garand identificado.

## Bajas

`muerte_soldado_01.wav`, `muerte_soldado_02.wav`, `muerte_enemigo_01.wav` y `muerte_enemigo_02.wav` combinan una exclamación masculina breve y ficticia con caída y ropa, según la elección expresa del usuario.

Las vocalizaciones se generan sin audio de referencia ni clonación mediante **Qwen3-TTS VoiceDesign**, modelo `mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-4bit`, revisión `5c390979e4b93af5f2932f90742ca99c7dd04687`, con `mlx-audio 0.6.3`/`MLX 0.32.4`. Se dirigen como exclamaciones contenidas «¡Ah!»/«¡Uh!», con voces distintas para ambos bandos. No se usa ni se imita la grabación humana del narrador o la voz definitiva del compañero.

- Modelo original: https://huggingface.co/Qwen/Qwen3-TTS-12Hz-1.7B-VoiceDesign
- Conversión utilizada: https://huggingface.co/mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-4bit
- Licencia del modelo: [Apache License 2.0](QWEN-APACHE-2.0.txt), de https://github.com/QwenLM/Qwen3-TTS/blob/main/LICENSE

Foley de terceros bajo **CC0 1.0**, derivado de las muestras públicas HQ de sus páginas:

- **BODY FALL - V HVY - DIRT**, de **leonelmail**: https://freesound.org/people/leonelmail/sounds/504626/
- **Body Fall Over.wav**, de **raubana**: https://freesound.org/people/raubana/sounds/82027/
- **clothes drop 5**, de **ZoviPoland/Bartosz Mazur**: https://freesound.org/people/ZoviPoland/sounds/517729/

Se recorta únicamente el silencio de los bordes, se convierte a mono44.1kHz y se mezcla caída desde 0.12s y ropa desde 0.18s. El segundo golpe de cada familia usa una variación de tono/tiempo 0.975. La licencia [CC0 1.0](CC0-1.0.txt) corresponde a las muestras de terceros; la licencia del modelo no se asigna a la grabación humana del narrador.

## Victoria y derrota

`victoria.wav` y `derrota.wav` son composiciones y renderizaciones originales para este proyecto, mediante síntesis armónica de metales suaves, ruido de aire filtrado y ecos breves. Victoria usa una resolución ascendente mayor y derrota una descendente menor. No utilizan grabaciones de terceros, himnos ni melodías tomadas de otras obras.

## Preparación común y verificación

Los clips se filtran por debajo de 28Hz, se aplican microfundidos de 3ms y 15ms de silencio final, y se normalizan a un pico de −6dBFS. No hay muestras saturadas. La importación de Godot puede codificarlos. El nivel de reproducción y la concurrencia se regulan en el catálogo/controlador del juego.

La procedencia, integridad y niveles técnicos no sustituyen la valoración perceptual por escucha humana. No se atribuyen exclamaciones a veteranos reales ni se presenta una audición del agente como verificación realizada.
