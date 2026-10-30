# Decisiones — Sonidos de combate

- Señales reales existentes permiten observar tiro válido y baja antes de reciclado; el servicio visual es un patrón de referencia, no una dependencia de que se vean sus efectos.
- CombatAudio local al nivel evita voz residual entre partidas y no toca audio/voz definitiva de013.
- Capacidad finita precalentada y resultado reservado evitan crecimiento/robo del jingle. Variación sólo cosmética con RNG propio.
- Pausa/foco detienen one-shots en vez de reproducir disparos atrasados al volver. Menú/retry cierran toda la sesión.
- La persona eligió exclamación breve+caída para ambos bandos: voces adultas ficticias distintas de narrador/compañero, sin frases o agonía prolongada. Root provee WAV/procedencia/licencias; no incluir motores/modelos o metadatos temporales.
- Recursos y datos son editables; integración técnica/importación no implica audición humana. Registrar límites perceptuales por separado en PR, sin nuevas evidencias Git.
- Root preparó nueve WAV mono44.1kPCM16 de pico−6dBFS. La propuesta inicial de atenuar combate−18dB se sustituye antes de RED: medidas orientativas de energía respecto de narración indican riesgo de quedar casi inaudible, sin que esto sea audición o evaluación perceptual.
- Decisión vigente: GameplaySFX estático con [AudioEffectHardLimiter](https://docs.godotengine.org/en/stable/classes/class_audioeffecthardlimiter.html), ceiling−3/pre_gain0/release0.1; rifle−3, bajaenemiga−1, bajasoldado0, resultado−3dB. Limitar sólo SFX evita tocar Master/intro; variación y voces siguen acotadas. Verificar mezcla/captura runtime si disponible, sin fingir audición ni certificar hardware.

## Alcance funcional aprobado y límites

T009 aprueba cinco cues/nueve variantes de014-I1, pool local8+1, routing Stream
y GameplaySFX aislado, RNG cosmético, eventos reales y cierre de sesión. Las
bajas exigen transacción letal, no sólo actor inactivo: la consulta de sólo
lectura has_confirmed_defeat y la identidad/generación excluyen cleanup vivo.
No cambian señales, stats o reglas, ni la introducción/audio definitivo013.
Medios/atribución están en [SOURCES](../../assets/audio/combat/SOURCES.md).

Las pruebas de audio y regresiones afectadas pasan; se ajustó el oráculo legado
que contaba todos los listeners en vez del consumidor visual, sin relajar su
unicidad. La suite completa de la revisión final queda a CI/T011 antes del gate
T012; no se declara una ejecución completa local sin fallos. Captura software
con nueve voces confirmó contención de mezcla y silencio al cerrar; no es
audición perceptual ni certificación del techo Web o hardware.

Chrome de computador permitió observar partida, oleadas/bajas/pickups y
menú→nuevo intento limpio, sin problemas observados al redimensionar. No se
acredita resultado manual de producción, audición, latencia Web o FPS.
Android de QA sólo acredita exportación/instalación/menú disponibles, sin combate
nativo; iOS sólo proyecto Xcode exportado. Stream Web puede aumentar latencia,
especialmente con un hilo, y aquí no se midió. Una muestra headless mostró
mayor memoria estática/nodos; caché y concurrencia impiden atribuir coste causal,
optimización, RSS o GPU. No reabre la campaña006.

CI/head exacto y T012 siguen pendientes; T014/SC-007, hardware/60FPS/paquete final
y pendientes de004/005/013 permanecen abiertos. Resultados/comandos/CI exactos
se reportan en el PR del Issue55, sin nuevos logs o evidencias versionados.
