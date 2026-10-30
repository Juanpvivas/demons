# Decisiones — La carta

- Secuencia nativa ilustrada: reutiliza siete cuadros y permite texto/controles adaptables. Fundidos y encuadre, sin animar manos/capas inexistentes.
- GameRoot ya posee menú/nivel y guard de reentrada. IntroPlayer temporal mantiene una autoridad local; GameStateManager queda MENU sin nivel ni renumeración.
- Datos en IntroSlide/IntroSequence inmutables; estado temporal sólo en IntroPlayer. Consultar skills `resource-pattern`, `scene-organization`, `godot-ui`, `responsive-ui`, `tween-animation`, `audio-system`, `save-load`, `input-handling` antes de cada sistema.
- Voz provisional: Piper1.8.0 `es_MX/claude/high`, masculina/acento México, dataset/modelcard Apache2 verificado por provisionamiento. Incluir atribución/licencia al incorporar clips; no usar voces macOS redistribuidas ni añadir motor/modelo a la app. No imitar personas reales.
- Provisión temporal: `/tmp/demons-intro-voice/` contiene narracion_01…07.wav y companero_06.wav, clips.json con duración/hash y provenance.json. Copiar sólo WAVs y procedencia portable a assets; no versionar temporales/manifiestos de validación. Duraciones aproximadas6.52,5.25,5.67,8.72,7.16,5.09,4.32s; compañero1.87s. Los datos finales se verifican al importar.
- Duración nominal7,8,8,10,10,10,7s; cada escena permite clips completos más pausa legible. Compañero de escena6 después del narrador, con su propio subtítulo.
- ConfigFile versión/estado en user:// con ruta inyectable. Lectura ausente/corrupta→no visto; Error real de escritura comprobado. No serializar scripts externos ni borrar datos ajenos.
- START_GAME espera Comenzar; REPLAY termina/omite regresando al menú. Contexto vive en GameRoot y no en el recurso narrativo.
- Perder foco pausa hasta Continuar. Cierre cancela tweens/audio e invalida eventos antes de emitir salida única.
- Producción incorpora assets/licencias. Conservar output/ previo y excluirlo de imports/export locales mediante `.gdignore` local no versionado; CI checkout limpio no lo contiene. No tocar presets.
