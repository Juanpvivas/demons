# Decisiones — La carta

Las decisiones originales y el alcance aprobado de I1 se conservan abajo como
historia, junto con R2. R3 rige comportamiento y narrador; la sección R4 rige
el compañero actual. Los resultados históricos no certifican medios o plataformas posteriores.

- Secuencia nativa ilustrada: reutiliza siete cuadros y permite texto/controles adaptables. Fundidos y encuadre, sin animar manos/capas inexistentes.
- GameRoot ya posee menú/nivel y guard de reentrada. IntroPlayer temporal mantiene una autoridad local; GameStateManager queda MENU sin nivel ni renumeración.
- Datos en IntroSlide/IntroSequence inmutables; estado temporal sólo en IntroPlayer. Consultar skills `resource-pattern`, `scene-organization`, `godot-ui`, `responsive-ui`, `tween-animation`, `audio-system`, `save-load`, `input-handling` antes de cada sistema.
- Voz provisional: Piper1.8.0 `es_MX/claude/high`, masculina/acento México, dataset/modelcard Apache2 verificado por provisionamiento. Incluir atribución/licencia al incorporar clips; no usar voces macOS redistribuidas ni añadir motor/modelo a la app. No imitar personas reales.
- Recursos incorporados: siete PNG originales en `assets/narrative/la_carta/` y ocho WAV locales en `assets/audio/narrative/la_carta/`, con catálogos de procedencia y licencia; no se incorpora el motor/modelo de síntesis. El compañero usa la misma voz provisional después del narrador.
- Duración nominal7,8,8,10,10,10,7s; cada escena permite clips completos más pausa legible. Compañero de escena6 después del narrador, con su propio subtítulo.
- ConfigFile versión/estado en user:// con ruta inyectable. Lectura ausente/corrupta→no visto; Error real de escritura comprobado. No serializar scripts externos ni borrar datos ajenos.
- START_GAME espera Comenzar; REPLAY termina/omite regresando al menú. Contexto vive en GameRoot y no en el recurso narrativo.
- Perder foco pausa hasta Continuar. Cierre cancela audio/avance/animación e invalida eventos antes de emitir salida única.
- Producción incorpora assets/licencias. Conservar output/ previo y excluirlo de imports/export locales mediante `.gdignore` local no versionado; CI checkout limpio no lo contiene. No tocar presets.

## Alcance funcional aprobado y límites

T009 aprueba funcionalidad de 013-I1 en rama, todavía pendiente del gate final
T012 tras CI. El guion/recurso conserva siete cuadros y ocho clips de voz;
su procedencia está en [arte](../../assets/narrative/la_carta/SOURCES.md) y
[voz provisional](../../assets/audio/narrative/la_carta/SOURCES.md). La revisión
estructural y automatizada no sustituye audición perceptual ni aprobación de
la interpretación vocal definitiva.

Chrome de computador permitió observar primera entrada, pausa/continuación,
omisión/Comenzar, partida posterior directa tras recargar y replay natural con
regreso al menú. Android AVD permitió comprobar toque en tramos de la secuencia,
pausa/continuación y Comenzar con Mobile/Vulkan sobre SwiftShader, sin audio.
La reapertura Android no quedó certificada por una captura de arranque negra,
sin atribuirla a un fallo de la feature. iPad Simulator mostró el menú mediante
shell ARM64 reutilizado con PCK actual; su interacción con la introducción no
pudo verificarse. No se acredita observación completa de los siete cuadros,
audición perceptual, toque iOS, victoria manual de producción ni hardware.

Una muestra headless comparativa frente a la base mostró aproximadamente
339 ms adicionales de carga y 32,4 MiB de memoria estática del motor al
precargar la secuencia. Es un aumento observado y un riesgo de carga/memoria;
no mide RSS, VRAM o FPS ni establece causalidad general. Se conserva para
revisión de integración y certificación física futura, sin reanudar 006.
Exportaciones Web, APK de QA y proyecto Xcode disponibles no certifican paquete
final, instalación/firma, GPU/hardware ni 60 FPS físicos. SC-008/T014 y los
pendientes 004/005 permanecen abiertos. Resultados exactos, comandos y CI
corresponden al PR de [Issue #53](https://github.com/Juanpvivas/demons/issues/53),
sin nuevos registros de evidencia versionados.

## Revisión autorizada R2

- La persona percibió femenina la voz anterior: sustituir los ocho clips por
  voz provisional claramente masculina tras escucha, sin atribuir identidad
  real. Root prepara medios y procedencia; el modelo no entra en el juego.
- Ambas entradas finalizan/omiten en Comenzar. La persona confirmó mantener ese
  gesto explícito: no autoarranque y nunca regreso al menú al terminar la carta.
- Quitar todos los textos superiores de las siete imágenes (contador,
  captions y aviso de ficción), manteniendo subtítulos hablados/controles.
  La ficción y créditos permanecen en documentación fuera de las imágenes.
- Añadir fondo original de viento/rumor grave discreto, offline y separado de
  Voice. Comprobar pausa/foco/continuación/cierre sin acumulación y escuchar
  mezcla inteligible. No añadir música, campaña o capas animadas.
- Botón Menú principal durante PLAYING/PAUSED reutiliza intención y cierre
  nivel/raíz; Retry sigue terminal y el retorno no guarda partida ni pide modal.
- RED usa APIs/nodos ya observables: destinos, visibilidad superior, segundo
  canal de ambiente y guard de salida activa. No fabricar error de parser ni
  un setup nuevo cuando una aserción sobre ausencia actual demuestra RED.
- Conservar recuerdo `la_carta_v1`: no se reescribe el guion hablado ni se
  obliga a repetir la introducción por una corrección de voz/presentación.

Medios candidatos R2: ocho WAV preparados con Piper `es_MX-ald-medium`, dataset
bajo Unlicense (base de ajuste DaveFX CC0), y ambiente original periódico de
20 segundos de viento/rumor grave sin samples de terceros. La atribución y
licencia deben corresponder al modelo nuevo; Apache2 de la voz anterior sólo
conserva su historia, no se reutiliza como licencia del reemplazo. El nivel
inicial de ambiente propuesto es -18 dB, sujeto a escucha de mezcla. Disponer
de los archivos o su etiqueta no acredita aprobación perceptual.

Actualización humana: gusta el timbre Ald pero suena robotizado; la persona
elige leer los siete párrafos. Ald sólo sirve de preview mientras llega el
archivo. T026 incorpora/segmenta la grabación humana y revisa texto, naturalidad,
fluidez y mezcla con QA; el compañero humano es opcional. Las cuatro correcciones
restantes y la integración técnica de audio provisional continúan sin esperar
ese archivo. No marcar SC-009 satisfecho ni voz definitiva aprobada en esa entrega.

## Alcance funcional R2 y límites

T021 aprueba cuatro correcciones e integración técnica de Ald provisional y
ambiente; T024 espera CI de la revisión exacta. Ambas rutas terminan/omiten en
Comenzar, imágenes sin cabecera y Menú principal activo/pausado quedan en el
alcance funcional. El botón ocupa la franja superior segura, independiente de
panel informativo y zonas HOME/recarga. Se conservan cierre único y Retry
terminal. La procedencia actual es [Ald/Unlicense y ambiente original](../../assets/audio/narrative/la_carta/SOURCES.md);
Claude/Apache2 sólo pertenece a la historia de I1.

Chrome de computador permitió observar cuadros de la secuencia sin cabecera,
pausa/omisión y replay natural hacia Comenzar, entrada al juego y retorno activo
al menú sin superposición con trinchera/recarga. Android de QA permitió observar
el botón corregido y su retorno al menú. La verificación técnica de dos canales
de audio, pausa/cierre y exportaciones no acredita escucha perceptual de voz,
mezcla o fluidez, ni recorrido/input de la introducción iOS. La voz humana
elegida sigue pendiente del archivo en T026/SC-009; no se entrega 5/5 ni se
aprueba voz definitiva desde este preview.

Una muestra headless de R2 observó aproximadamente +4,5 ms y +0,4 MB de memoria
estática respecto de I1, con caché/concurrencia sin controlar; no establece
benchmark causal ni FPS. Permanece el riesgo histórico de precarga de I1
(aproximadamente +339 ms/+32,4 MiB observados). Builds de QA/export Xcode no
certifican paquete final, firma/instalación, hardware/GPU, 60 FPS o victoria
manual de producción. T014/SC-008, pausa006 y publicación004/005 se conservan.

## Alcance funcional R3 y límites

T032 aprueba función R3 y T026/SC-009: siete narraciones de toma3 aportada,
elegida y autorizada por la persona, incorporadas con comprobaciones técnicas
de integridad, texto/duración y reproducción. Su aceptación perceptual es humana;
no se atribuye audición subjetiva a los agentes. El compañero mantiene un único
clip Ald sintético/provisional, no atribuido al narrador humano. La preparación
corta pausas con ganancia constante y microfundidos, sin cambiar timbre/tempo o
resintetizar; la importación normal de Godot puede codificar audio, sin promesa
de exportación sin pérdida. [Procedencia actual](../../assets/audio/narrative/la_carta/SOURCES.md).

La espera de final/omisión muestra sólo Comenzar inferior, conservando imagen
opaca/encuadrada incluso al redimensionar, sin panel/banda/textos/audio residual.
Se observó en Chrome de computador y APK Android de QA con gesto a la partida;
el menú activo y las zonas de recarga conservan su separación. La exportación
Xcode no acredita interacción de la introducción iOS. El harness técnico de
audio no es audición subjetiva ni aprobación humana del compañero.

CI/head exacto y gate final T035 siguen pendientes; publicación T014/SC-008,
hardware/FPS, partida manual completa y paquete final no se certifican. Persisten
los riesgos descriptivos de precarga de I1/R2, sin nuevo benchmark ni reanudar006;
los pendientes004/005 no cambian. No se versionan toma original, ASR o metadatos
temporales de comprobación.

## Candidata R4 — compañero sintético

Sólo `companero_06.wav` se sustituye por una candidata Qwen3-TTS VoiceDesign,
con procedencia y Apache2 del modelo en el [catálogo de audio](../../assets/audio/narrative/la_carta/SOURCES.md),
sin referencia/clonación ni modelo runtime. Los siete WAV humanos, guion/montaje,
ambiente y comportamiento R3 permanecen idénticos. T040 aprueba integración
técnica; gate final T043 pendiente. La naturalidad requiere escucha humana pendiente,
no desde ASR/metadatos o una audición atribuida al agente.
