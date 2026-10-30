# La carta — voz de preview y ambiente

## Narración provisional Ald

Ocho WAV mono PCM de 22.050Hz del texto original del proyecto, sintetizados
con `piper-tts 1.8.0` y `es_MX-ald-medium` el 2026-10-30:
`narracion_01.wav` a `narracion_07.wav` y `companero_06.wav`. Se usó volumen
0.85; length_scale 1.12 para el narrador y 1.0 para el compañero.

Esta voz masculina de español de México es sólo un preview provisional.
La persona prefiere grabar su narración porque percibe robotizada la síntesis.
T026/SC-009 mantienen pendiente la toma humana y su escucha de texto completo,
timbre, fluidez e inteligibilidad. El compañero puede seguir provisional si
no se recibe su frase. No se imita ni se atribuye el guion a un veterano real.

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

Las licencias y la voz Claude de I1 pertenecen a la historia en Git; no se
hereda Apache 2.0 a estos clips Ald. El juego contiene sólo los WAV grabados,
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
