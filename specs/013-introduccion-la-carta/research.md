# Decisiones — La carta

- Secuencia nativa ilustrada: reutiliza siete cuadros y permite texto/controles adaptables. Fundidos y encuadre, sin animar manos/capas inexistentes.
- GameRoot ya posee menú/nivel y guard de reentrada. IntroPlayer temporal mantiene una autoridad local; GameStateManager queda MENU sin nivel ni renumeración.
- Datos en IntroSlide/IntroSequence inmutables; estado temporal sólo en IntroPlayer. Consultar skills `resource-pattern`, `scene-organization`, `godot-ui`, `responsive-ui`, `tween-animation`, `audio-system`, `save-load`, `input-handling` antes de cada sistema.
- Voz provisional: Piper1.8.0 `es_MX/claude/high`, masculina/acento México, dataset/modelcard Apache2 verificado por provisionamiento. Incluir atribución/licencia al incorporar clips; no usar voces macOS redistribuidas ni añadir motor/modelo a la app. No imitar personas reales.
- Recursos incorporados: siete PNG originales en `assets/narrative/la_carta/` y ocho WAV locales en `assets/audio/narrative/la_carta/`, con catálogos de procedencia y licencia; no se incorpora el motor/modelo de síntesis. El compañero usa la misma voz provisional después del narrador.
- Duración nominal7,8,8,10,10,10,7s; cada escena permite clips completos más pausa legible. Compañero de escena6 después del narrador, con su propio subtítulo.
- ConfigFile versión/estado en user:// con ruta inyectable. Lectura ausente/corrupta→no visto; Error real de escritura comprobado. No serializar scripts externos ni borrar datos ajenos.
- START_GAME espera Comenzar; REPLAY termina/omite regresando al menú. Contexto vive en GameRoot y no en el recurso narrativo.
- Perder foco pausa hasta Continuar. Cierre cancela tweens/audio e invalida eventos antes de emitir salida única.
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
