# La carta — voz provisional

Clips pregrabados de texto original del proyecto, sintetizados con
`piper-tts 1.8.0` y la voz `es_MX-claude-high` el 2026-10-30. Son ocho WAV mono
PCM de 22.050Hz: `narracion_01.wav` a `narracion_07.wav` y `companero_06.wav`.
Se usaron length_scale 1.12 y volume 0.85. El compañero habla después del
narrador; ambos utilizan esta voz provisional. No se imita una persona real.

La voz es español de México y sirve para revisar ritmo y navegación; no
representa la interpretación colombiana definitiva. El juego reproduce estos
archivos locales y no incorpora Piper, el modelo ONNX, servicios de red ni
voces del sistema operativo.

## Procedencia y licencia

- Repositorio: [rhasspy/piper-voices](https://huggingface.co/rhasspy/piper-voices).
- Voz: [es/es_MX/claude/high](https://huggingface.co/rhasspy/piper-voices/tree/b4e358ffcb232591bf73a540e70f7de528e4174a/es/es_MX/claude/high).
- Revisión del modelo: `b4e358ffcb232591bf73a540e70f7de528e4174a`.
- SHA256 del modelo: `3ef40a71ea63852cd8ab7e6fa7d2ecdcfa67a0b47c9c48e3f10e02ee02083ea0`.
- [MODEL_CARD.txt](MODEL_CARD.txt), conservada con su contenido original,
  identifica el dataset HirCoir/Piper-TTS-Spanish bajo Apache License 2.0.
- [Texto Apache License 2.0](APACHE-2.0.txt) y
  [fuente del dataset](https://huggingface.co/spaces/HirCoir/Piper-TTS-Spanish).

Esta atribución documenta la fuente de la voz; no atribuye el guion a los
autores del modelo, ni presenta los clips como testimonios históricos.
