# Decisiones — Sonidos de combate

- Señales reales existentes permiten observar tiro válido y baja antes de reciclado; el servicio visual es un patrón de referencia, no una dependencia de que se vean sus efectos.
- CombatAudio local al nivel evita voz residual entre partidas y no toca audio/voz definitiva de013.
- Capacidad finita precalentada y resultado reservado evitan crecimiento/robo del jingle. Variación sólo cosmética con RNG propio.
- Pausa/foco detienen one-shots en vez de reproducir disparos atrasados al volver. Menú/retry cierran toda la sesión.
- La persona eligió exclamación breve+caída para ambos bandos: voces adultas ficticias distintas de narrador/compañero, sin frases o agonía prolongada. Root provee WAV/procedencia/licencias; no incluir motores/modelos o metadatos temporales.
- Recursos y datos son editables; integración técnica/importación no implica audición humana. Registrar límites perceptuales por separado en PR, sin nuevas evidencias Git.
- Root preparó nueve WAV mono44.1kPCM16 de pico−6dBFS. La propuesta inicial de atenuar combate−18dB se sustituye antes de RED: medidas orientativas de energía respecto de narración indican riesgo de quedar casi inaudible, sin que esto sea audición o evaluación perceptual.
- Decisión vigente: GameplaySFX estático con [AudioEffectHardLimiter](https://docs.godotengine.org/en/stable/classes/class_audioeffecthardlimiter.html), ceiling−3/pre_gain0/release0.1; rifle−3, bajaenemiga−1, bajasoldado0, resultado−3dB. Limitar sólo SFX evita tocar Master/intro; variación y voces siguen acotadas. Verificar mezcla/captura runtime si disponible, sin fingir audición ni certificar hardware.
