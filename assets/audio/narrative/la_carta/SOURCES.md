# La carta — narrador humano, compañero provisional y ambiente

## Narración humana — toma 3

`narracion_01.wav` a `narracion_07.wav` proceden de la grabación humana
`toma-3.wav`, aportada, elegida y autorizada expresamente por la persona autora
del proyecto para incorporarla al juego. SHA256 de la toma elegida:
`0ce5db14e4f5ab43ea1da83c5107c34c8bd569312a3834f3238e6e96e14ef705`.

Los siete segmentos conservan la toma completa y su orden, cortada en pausas;
son WAV mono PCM de 44.100Hz y 16 bits. El procesamiento previo aplica −1dB de
ganancia constante y microfundidos de 5ms en límites internos. No hubo
resíntesis, cambio de tono/tempo, reducción de ruido ni compresor dinámico.
La importación habitual de Godot puede codificar los clips; esto no implica
una promesa de audio sin pérdida en el paquete exportado.

La selección perceptual de esta toma corresponde a la persona que la eligió;
las verificaciones técnicas de integridad y reproducción no son una audición
propia del agente. El guion/subtítulos conservan el texto autorado. No se
atribuyen carta ni interpretación a un veterano identificado.

El uso de esta grabación propia se basa en la autorización recibida para el
proyecto. No se le asigna Unlicense, CC0 ni la licencia del modelo sintético.
La toma original, ASR y metadatos temporales no forman parte de estos recursos.

## Compañero Ald — único clip provisional

`companero_06.wav` sigue siendo voz sintética provisional, separada del narrador
humano. La toma elegida no incluye esa frase y no se la atribuye a la persona.
WAV mono PCM de 22.050Hz sintetizado con `piper-tts 1.8.0`, `es_MX-ald-medium`,
volumen 0.85 y length_scale 1.0. No se imita una persona real.

La siguiente procedencia y licencias corresponden sólo a este clip Ald:

- Repositorio: [rhasspy/piper-voices](https://huggingface.co/rhasspy/piper-voices).
- Voz: [es/es_MX/ald/medium](https://huggingface.co/rhasspy/piper-voices/tree/b4e358ffcb232591bf73a540e70f7de528e4174a/es/es_MX/ald/medium).
- Revisión: `b4e358ffcb232591bf73a540e70f7de528e4174a`.
- SHA256 del modelo: `019b3803293c93e34a206dd2e53a3889209a514e786fd7144f7b70196c579b63`.
- [MODEL_CARD.txt](MODEL_CARD.txt) original: dataset
  [Ald Mexican Spanish](https://huggingface.co/datasets/rmcpantoja/Ald_Mexican_Spanish_speech_dataset)
  bajo [Unlicense](UNLICENSE.txt).
- Base de entrenamiento DaveFX: [DAVEFX_MODEL_CARD.txt](DAVEFX_MODEL_CARD.txt)
  declara dataset [OHF-Voice/voice-datasets](https://github.com/OHF-Voice/voice-datasets)
  bajo [CC0](CC0-LICENSE.txt).

Las voces sintéticas anteriores del narrador pertenecen a la historia en Git.
El juego contiene sólo los WAV grabados,
sin motor Piper, modelos ONNX, llamadas de red o voces del sistema operativo.

## Ambiente original

`ambiente_trinchera_loop.wav`: veinte segundos, estéreo PCM a 22.050Hz,
generados para este proyecto con viento filtrado y rumor grave sintéticos.
No contiene grabaciones, melodías ni samples de terceros. Es material original
del proyecto. El bucle periódico se configura Forward al importar el WAV,
sin modificar el Resource compartido durante reproducción.

La secuencia autora un volumen de fondo de −18dB, separado de la voz en otro
AudioStreamPlayer. Cambiar de imagen no reinicia el fondo; pausa, foco y cierre
afectan ambos canales. El balance y el resultado perceptual se revisan por
escucha; la configuración por sí sola no acredita voz definitiva ni fluidez.
