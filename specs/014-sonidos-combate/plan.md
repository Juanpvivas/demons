# Implementation Plan: Sonidos de combate

**Feature ID**: `014-sonidos-combate` | **Planned Branch**: `codex/014-sonidos-combate` | **Date**: 2026-10-30 | **Spec**: [spec.md](spec.md)
**Base**: main `77be629`, 013 integrado. Preparación Spec Kit `demons-preparation`; ejecución por roles, sin speckit-implement.
**Tracking**: [Issue #55](https://github.com/Juanpvivas/demons/issues/55)

**Estado**: 014-I1 integrado en `main` por [PR #56](https://github.com/Juanpvivas/demons/pull/56)
(`45cd83a`), con QA de integración T012 y CI de revisión aprobada. Publicación
T014 permanece pendiente; la planificación siguiente conserva su alcance original.

## Summary

Servicio CombatAudio hijo del nivel, configurado por Resource inmutable. Observa confirmaciones reales y mezcla cinco cues en voces precalentadas finitas; no es otro autoload ni autoridad de combate.

## Technical Context

**Language/Version**: GDScript/Godot4.x vigente, local4.7.1.
**Primary Dependencies**: AudioStreamPlayer, AudioBusLayout/AudioEffectHardLimiter de Godot, señales directas, Resources y GUT; sin dependencia externa nueva.
**Storage**: Sólo recursos locales; sin persistencia nueva.
**Testing**: GUT/runner vigente, inspección proporcional de medios, preview/smoke y export/CI por destino disponible.
**Target Platform**: Web sólo navegador de computador, apps Android/iOS instaladas; PC nativo desarrollo.
**Project Type**: Juego2D compartido.
**Performance Goals**: Mezcla/voces acotadas, conservar objetivo constitucional60FPS sin certificarlo desde software.
**Constraints**: Cinco cues, sin stats/RNGglobal/input/UI nuevos ni cambio de audio013.
**Scale/Scope**: 014-I1 completo; ocho voces de combate y una reservada para resultado como capacidad inicial autorada.

Los cinco cues usan arrays de variantes: nueve WAV iniciales (3disparo,
2baja enemiga, 2baja colombiana, 1victoria, 1derrota), sin ampliar eventos.

## Constitution Check

I: Datos sonoros en Resource, estado mutable sólo en servicio del nivel, sin balance o autoload nuevo.
II: Setup neutral mínimo→RED válido tester→QA→dev→GREEN/regresión→QA→docs. Medios sin RED artificial.
III: Hechos audibles coherentes, tono respetuoso y exclamación breve ficticia según decisión humana.
IV: Precalentar reproductores, no crecer con cada cue; registrar observaciones disponibles sin benchmark amplio ni reactivar006.
V: Gate integración con build/CI/QA; publicación separada SC007, sin merge/envíos automáticos. Pendientes004/005/013 intactos.

## Project Structure

```text
scenes/audio/combat_audio.gd
resources/schemas/combat_audio_profile.gd
resources/audio/combat_audio_profile.tres
default_bus_layout.tres                     # Master intacto + GameplaySFX
assets/audio/combat/                         # cinco cues, SOURCES/licencias
scenes/levels/nivel_monte_calvo.gd
scenes/levels/wave_spawner.gd
tests/unit/systems/test_combat_audio.gd
tests/unit/levels/test_combat_audio_integration.gd
specs/014-sonidos-combate/{spec,plan,tasks,research,data-model,quickstart}.md
specs/014-sonidos-combate/contracts/combat-audio.md
```

## Diseño concreto

- Soldado ya emite rifle_shot_visual_requested tras descontar munición, antes de daño, y defeat_visual_requested sólo al morir. Enemigo emite derrota antes de enemy_defeated y reciclado. Observar esas confirmaciones semánticas existentes sin depender de animación/píxeles; no introducir un segundo disparo o daño.
- La integración aprobada verifica `Enemigo.has_confirmed_defeat()` de sólo lectura antes de admitir una baja: cleanup de un actor vivo no es muerte. Conservar dedupe por activación sin modificar emisores/stats.
- Nivel registra soldados iniciales/reemplazos y el spawner registra cada enemigo físico una vez. Cada baja se distingue por instancia+activation_generation (enemigo) o identidad de soldado; no rechazar una muerte porque el actor ya se desactivó antes de emitir.
- GameStateManager emite transición y game_won/game_lost: elegir una sola fuente terminal, con guard por intento. Aceptar baja final antes de resultado; las voces ya admitidas pueden terminar en capacidad acotada, sin nuevos ataques tras terminal.
- Pool local precalentado de8 AudioStreamPlayers para disparos/bajas, con reemplazo del más antiguo si se satura, sin cola de espera; un reproductor reservado para resultado evita que ráfagas lo roben. Los9 players sólo usan GameplaySFX; variación mediante RNG local independiente, resultado sin variación.
- Mezcla revisada antes de RED: bus dedicado GameplaySFX en layout estático con AudioEffectHardLimiter ceiling_db−3, pre_gain_db0, release0.1, envíoMaster sin modificarlo ni tocar audio013. Perfil de producción: rifle−3, enemy_death−1, soldier_death0, victory/defeat−3dB; variacióncombat±1.5dB/pitch0.97–1.03, resultado fijo. WAV individualespico≤−6dBFS mantienen margen en solo; concurrencia se limita en bus. Verificar rutas/efecto/configuración y mezcla/captura runtime disponible; sin inferir audición o techo físico del dispositivo.
- Cada controller sólo detiene/libera sus9 reproductores: no mutea/elimina el bus compartido ni reencamina a Master al cerrar. Cubrir aislamiento entre controllers/fixtures y voces de intro. Setup neutral T002–T003 ya aprobado permanece idéntico; ganancias/layout de producción se implementan en T007 después de RED.
- Web requiere Stream en los9 players de GameplaySFX para que opere AudioEffectHardLimiter: `playback_type = AudioServer.PLAYBACK_TYPE_STREAM`, sin tocar default global/intro/singlethread/presets/renderers. Sample omite AudioEffects según la [fuente oficial](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html#audio-playback). Stream puede aumentar latencia, especialmente singlethread: observar/declarar en T008 Web, sin inferirlo desde nativo. Getters de capacidad/actividad cuentan combate+terminal.
- Pausa/foco silencian one-shots activos y no los reanudan/reencolan; se aceptan futuros cues sólo cuando la sesión/actividad lo permiten. MENU/close_match detiene, desconecta e invalida callbacks; nuevo nivel usa servicio nuevo.
- Setup neutral de clase/Resource sólo para RED importable: sin pool, conexiones, archivos finales o comportamiento. Tester confirma carga y QA neutralidad antes de RED.
- Consultar GodotPrompter using/audio-system+referencia sfx-pooling/event-bus/resource-pattern/godot-testing según rol; usar señales directas por padre común, no aplicar ejemplo de autoload indiscriminadamente.

## Complexity Tracking

Sin autoload/event bus, UI o persistencia nuevos; servicio local, perfil y layout estático con bus exclusivo bastan. El audio observa combate y no modifica economía, daño o resultado; el limiter de SFX no afecta Master o intro.
