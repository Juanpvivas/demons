# La carta — narrador humano, compañero sintético definitivo y ambiente

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

## Compañero sintético — voz definitiva R4

`companero_06.wav` contiene únicamente «Compañero. Ya es hora.» y permanece
separado de las siete narraciones humanas. Es el clip `companero_cercano`,
preparado para esta frase: WAV mono PCM de 24.000Hz y 16 bits, 82.560 frames y
3,44 segundos. No se atribuye al narrador humano ni a un veterano identificado.
La persona aprobó perceptualmente este mismo archivo y decidió conservarlo
como voz definitiva: «Esta voz me gusta, dejémosla como la voz definitiva del
compañero». Esa aceptación humana corresponde al SHA256 indicado abajo; no es
una audición del agente ni una inferencia de ASR/metadatos. La fase de candidata
con naturalidad pendiente se conserva como historia de R4, ahora resuelta por
esa decisión. La voz sigue siendo sintética y no un testimonio histórico.

Generada sin audio de referencia ni clonación con Qwen3-TTS VoiceDesign,
`mlx-audio 0.6.3` y MLX `0.32.4`. El procesamiento previo aplica ganancia lineal
−2,185573dB y microfundidos de 5ms, sin recorte, cambio de tono/tempo ni compresor
dinámico. La importación habitual del juego puede codificar el WAV.

- Modelo: [mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-4bit](https://huggingface.co/mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-4bit).
- Revisión: `5c390979e4b93af5f2932f90742ca99c7dd04687`.
- Modelo original: [Qwen/Qwen3-TTS-12Hz-1.7B-VoiceDesign](https://huggingface.co/Qwen/Qwen3-TTS-12Hz-1.7B-VoiceDesign).
- SHA256 del modelo: `d8627de7ef411f6775182925059e140a9e1edb1fde8feeb540b4fba0edee1e58`.
- SHA256 del clip definitivo aceptado: `0c8e5bb5bf9aa476b70686c1846c4dd6b8dd836390a5161e11051eba3cd8c1d8`.
- Licencia del modelo: [Apache License 2.0](QWEN-APACHE-2.0.txt), conservada de su fuente.

Esta procedencia describe sólo el compañero sintético; no asigna Apache 2.0 a
la voz humana. Las voces Ald/Claude y sus licencias anteriores se conservan
como historia en Git, sin mantener atribuciones a recursos que ya no están en
uso. Todos los clips se reproducen offline: no se incorpora el modelo, motor
de síntesis, audio de referencia, variante descartada ni llamadas a servicios.

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
