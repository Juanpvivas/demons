# Datos — Sonidos de combate

CombatAudioProfile es Resource compartido inmutable: cinco arrays tipados de AudioStreams (`rifle`, `enemy_death`, `soldier_death`, `victory`, `defeat`), niveles por cue, capacidad de voces de combate, rango de pitch cosmético y nivel de resultado. Los valores no son stats de combate.

Interfaz autorada: los cinco campos son `Array[AudioStream]`;
`combat_voice_count: int = 8`, `volume_db: Dictionary[StringName, float]`
con esas cinco claves, `pitch_range: Vector2 = Vector2(0.97, 1.03)` y
`volume_variation_db: float = 1.5` como variación máxima absoluta de combate.
Ganancias iniciales: rifle/bajas−18dB, victoria/derrota−12dB. Resultado tiene
pitch1 y volumen fijo, sin variación. Ningún bus global o dato jugable cambia.

Con pico de cada WAV no mayor a−6dBFS, ocho voces de combate a su máximo−16.5dB
y una de resultado−12dB dan cota de amplitud lineal menor a0.73, dejando margen
antes de1. Verificar esta cota con los archivos/configuración reales al integrar;
no es certificación perceptual, del dispositivo o de un Master modificado.

Perfil inicial: 3 variantes de disparo, 2 de baja enemiga, 2 de baja colombiana,
1 victoria y 1 derrota. Selección mediante RNG local de presentación, sin
consumir el global. Archivos en `assets/audio/combat/`:
`disparo_01.wav`…`disparo_03.wav`, `muerte_enemigo_01.wav`…`02.wav`,
`muerte_soldado_01.wav`…`02.wav`, `victoria.wav`, `derrota.wav`.

CombatAudio conserva sólo estado local de sesión: pool/reproductor terminal, registro idempotente de actores, identidad/activación de bajas, guard de resultado, actividad/cierre y generación de cada voz reutilizada.

No mutar el perfil ni guardar preferencias nuevas. Una baja aceptada no se deduplica por nodo físico para siempre: el reciclado permite otra baja en una activación nueva. El resultado pertenece al intento, no al singleton global.
