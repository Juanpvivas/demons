# Contrato mínimo — CombatAudio

## Interfaz neutral para TDD

`class_name CombatAudio extends Node` en scenes/audio/combat_audio.gd:
- `signal cue_started(cue: StringName)`: observación de una reproducción aceptada, no origen de gameplay.
- `setup(profile: Resource) -> void`.
- `register_actor(actor: Node) -> void`: registro idempotente, infiere Soldado/Enemigo.
- `set_application_active(active: bool) -> void`.
- `close_match() -> void`: idempotente.
- `get_active_voice_count() -> int`, `get_voice_capacity() -> int`: límites observables.

Ambos getters cuentan el total combate+resultado: capacidad inicial8+1=9 y
activas incluidas las terminales. Los retornos neutrales de setup siguen0.

CombatAudioProfile declara cinco arrays tipados de AudioStream y configuración del [modelo](../data-model.md). T002 sólo crea firmas/Resource sin conexiones, reproducción o pool y observadores0; el nivel no monta el servicio todavía. No crear .tres con preloads de WAV inexistentes. Tester usa WAV breve válido en memoria y perfil de fixture, sin tocar preferencias/audio013. Parser/import roto no vale RED.

## Confirmaciones y composición

- Nivel monta/configura servicio antes de actores y lo cierra antes de deshabilitar/retirar hijos.
- Soldados se registran al crearse; spawner recibe dependencia opcional al final de setup para preservar llamadas existentes y registra enemigos en instance_created una vez por nodo.
- rifle_shot_visual_requested corresponde al tiro ya consumido; defeat_visual_requested corresponde a baja ya confirmada antes de deactivación/reciclado. Estos eventos pueden observarse aunque no haya efecto visible; no extraer sonido de un frame/animación.
- Distinguir baja por identidad/activación del actor, snapshot de esa transacción y generación de sesión; un callback antiguo no afecta una voz reutilizada o intento nuevo.
- Para enemigo, `has_confirmed_defeat() -> bool` es consulta de sólo lectura de muerte letal confirmada. La mera desactivación por cleanup no autoriza audio de baja, aunque llegue un callback viejo; no modifica señales, salud o stats.
- No cambiar firmas/semántica jugables. Si una conexión adicional exige parámetro, hacerlo opcional y preservar fixtures existentes, notificando al tester.
- Observar resultado por una sola fuente GameStateManager y guard terminal por sesión: exactamente victoria o derrota, nunca por enter_menu/close_match/retry. En la cadena de tiro letal final se aceptan tiro, baja y victoria una vez cada uno; resultado no corta los sonidos ya admitidos.

## Reproducción y ciclo de vida

- Ocho voces de combate iniciales autoradas y una terminal; saturación sustituye voz más antigua sin añadir reproductor/cola. Resultado reservado no se roba por disparos.
- No nuevas peticiones de combate fuera de PLAYING/actividad; las aceptadas antes del terminal pueden terminar. Pausa/foco detienen todas sin replay al regresar.
- MENU/close_match/retry detienen voces y limpian/desconectan registros antes de retirar nivel; callbacks/generaciones viejos se ignoran.
- Sólo RNG local cosmético. Ninguna llamada sonora decide daño, ammo, moral, blanco, oleadas o victoria.
- Perfil de producción: rifle−3, enemy_death−1, soldier_death0, victory/defeat−3dB, variacióncombat±1.5dB/pitch0.97–1.03 y resultado fijo. Stubs neutrales aprobados siguen idénticos hasta implementación T007.
- Nueve players exclusivamente en GameplaySFX, layout estático con HardLimiter ceiling_db−3/pre_gain_db0/release0.1 y envíoMaster. No cambiar volumen/efectos/rutas de Master o intro. RED discrimina routing/capacidad/aislamiento/limpieza; ganancias, picos y propiedades del limiter se revisan proporcionalmente en T008, no mediante tests que sólo repitan datos de arte.
- Los9 players nuevos usan `playback_type = AudioServer.PLAYBACK_TYPE_STREAM`: en Web, Sample no procesa AudioEffects y eludiría el limiter. Es contrato de routing/efectos, cubierto por RED; no cambiar default global, audio013, singlethread, presets o renderers. T008 verifica Web/latencia disponible y declara límites de Stream, sin extrapolar ejecución nativa.
- Cierre sólo detiene/libera players propios; nunca mutea/borra bus compartido ni reencamina a Master. Otra instancia/fixture y audio013 siguen intactos. Tests restauran sólo su configuración temporal sin contaminar otras pruebas.
- Fichero ausente no bloquea jugar; la ausencia es fallo de entrega a resolver, no un aprobado ficticio.

## Medios

Cinco cues offline y nueve WAV del perfil inicial (3/2/2/1/1), sin eventos extra. Bajas con exclamación masculina adulta breve ficticia+foley de caída/equipo. Prohibido clonar voces del narrador/compañero o atribuirlas a veteranos. Comprobar importación, duración, saturación y procedencia; escucha si disponible se declara real, sin inferirla de waveform.
