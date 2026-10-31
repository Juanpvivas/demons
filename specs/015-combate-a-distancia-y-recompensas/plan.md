# Implementation Plan: Combate a distancia y recompensas

**Feature ID**: `015-combate-a-distancia-y-recompensas` | **Branch**: `codex/015-combate-a-distancia-y-recompensas` | **Date**: 2026-10-30 | **Spec**: [spec.md](spec.md)
**Base**: main4fb1267. Preparación demons-preparation, agentes ejecutan; no speckit-implement.
**Tracking**: [Issue #58](https://github.com/Juanpvivas/demons/issues/58)
**Estado**: funcionalidad, documentación y CI de `2351798` aprobadas por QA para integración; [PR #59 en borrador](https://github.com/Juanpvivas/demons/pull/59), sin merge. Publicación T015 pendiente. [Alcance y límites](research.md#alcance-funcional-aprobado-y-límites).

## Summary

Tres cambios coherentes: alcance colombiano 864, fusil enemigo por carril con perfiles de oleada y recompensa de machete transaccional. Reutilizar física real, efectos y mezcla existentes; no framework global o assets nuevos.

## Technical Context

**Language/Version**: GDScript/Godot4.x vigente local4.7.1.
**Primary Dependencies**: PhysicsDirectSpaceState2D/solapes de cuerpos, Resources, señales, CombatVisualEffects/CombatAudio, GUT existentes.
**Storage**: Ninguno nuevo.
**Testing**: GUT/runner, física real y escenarios de balance/visual/audio; un export Web final para preview8813, builds/CI pertinentes.
**Target Platform**: Web computador y apps Android/iOS; PC nativo sólo desarrollo.
**Project Type**: Juego2D compartido.
**Performance Goals**: Conservar objetivo constitucional60FPS; observación disponible proporcional, sin campaña006 o certificación física desde software.
**Constraints**: Tres cambios y tabla exacta autorizados; sin otros cambios de stats, UI/red/persistencia, renderer/release o audio013/014 nuevos.
**Scale/Scope**: 015-I1 completo, diez perfiles de enemigo y una configuración de soldado.

## Constitution Check

I: Stats en Resources inmutables; estado/cooldowns/targets/recompensas locales.
II: Setup neutral mínimo→tester RED→QA→dev→GREEN/regresión/playtest de balance→QA→docs.
III: Tiro legible con destello/trazadora/audio y vida/moral actualizadas por observadores existentes.
IV: Reutilizar pools/consultas; no reintroducir detección de movingArea2D históricamente fallida.
V: Integración con build/CI/QA; SC008/publicación separada, pendientes previos intactos. Sin excepciones nuevas.

## Project Structure

```text
resources/schemas/{enemy_stats,unit_stats}.gd
resources/units/soldado_base_stats.tres
resources/enemies/enemigo_infanteria_base.tres      # perfil1/inicial
resources/enemies/enemigo_infanteria_oleada_02.tres … _10.tres
resources/waves/nivel_montecalvo_oleada_01.tres … _10.tres
scenes/units/soldado.gd
scenes/enemies/enemigo.gd
scenes/levels/wave_spawner.gd                       # contexto tablero si hace falta
scenes/visuals/combat_visual_effects.gd
scenes/audio/combat_audio.gd
tests/unit/units/test_soldado*.gd
tests/unit/enemies/test_enemigo*.gd
tests/unit/levels/test_combat_ranged_integration.gd
tests/unit/systems/test_combat_{audio,visual_effects}.gd
```

## Decisiones concretas

- El hogar y entrada distan864; cambiar sólo rifle_range autorado del soldado396→864 y mantener filtro actual same_row/direct_diagonal de columna contigua. La broadphase/forma física debe cubrir el extremo y revalidar solape real.
- Enemigo consulta cuerpos Soldado reales mediante física y filtro de carril/frente/vida. Marcha, fusil estacionario y contacto son fases excluyentes; contacto conserva melee y suprime tiro. No usar Area2D móvil/eventos históricos no fiables ni nuevo NavigationAgent.
- Tiro hitscan captura blanco vivo/identidad y posición y admite snapshot/audio/VFX ANTES del daño que pueda disparar baja/terminal síncronos, conservando tiro+baja+resultado y sus voces ya admitidas. Primer tiro al adquirir, luego rifle_interval; pausa no avanza relojes ni acumula ráfagas, pool/close limpian blanco/reloj. Sin blanco avanza. La autoridad de derrota sigue siendo PosicionDefendida, no la muerte del último soldado.
- EnemyStats agrega rifle_range/rifle_damage/rifle_interval; base perfil1 más nueve .tres y WaveSpawnEntry de cada ola referencia el suyo. No mutar stats de enemigos vivos al cambiar de oleada; inicial conserva perfil1.
- UnitStats agrega machete_moral_per_kill y machete_heal_per_kill; producción2/3. La transacción captura dueño vivo/target id+generación antes de take_damage y bloquea reentrada/crédito doble. Sólo killed=true recompensa al dueño que aún vive, aunque el kill active WON. Vida se limita por stats.max_health; barras/señales existentes reflejan cambios.
- Señal enemiga rifle_shot_visual_requested(snapshot) contiene origin_world/target_world finitos y activation_generation, sin Node. Consumidores validan actor/generación antes de admitir; efecto recibe copia saneada de coordenadas, independiente del actor. Mantener payload2coords del soldado actual compatible. Audio acepta tiros de ambos bandos y conserva bus/Stream/limiter/capacidad9.
- Reutilizar pose/contacto y destello/trazadora de fusil; no exigir atlas nuevo. Presentación no aplica daño ni guarda ownerNode.
- Setup histórico T002 sólo declaró nuevos campos neutros en 0 y señal sin emitir. No .tres/balance, movimiento, premios o conexiones nuevas antes de RED. APIs actuales de daño/física/estado bastan; no query nueva artificial.
- Skills por rol: GodotPrompter resource-pattern/ai-navigation/state-machine/2d-essentials/animation-system/audio-system/input-handling/godot-testing/code-review y consultas físicas de la arquitectura vigente.

## Complexity Tracking

Sin autoload, nuevo backend o motor de IA. Tres cambios usan sistemas actuales; ampliación de snapshots se valida en adaptadores manteniendo contratos anteriores.

## Enmienda 015-I2 — Composición por datos (aprobación funcional T021)

Implementada en `b4fbaf8`; I2 cuenta con CI y APROBADO PARA INTEGRACIÓN de QA sobre `d8826e2`, en rama/PR59 en borrador, sin merge ni publicación. I1 conserva su aprobación histórica.

Misma rama/PR59/Issue58; I1 intacto. Se añadió únicamente
`resources/enemies/enemigo_asaltante_base.tres`, con rifle_range/rifle_damage/
rifle_interval=0 y HP15/move_speed40/melee_damage5/ammo_drop3. Los diez perfiles
R de I1 no cambian; el inicial sigue referenciando perfil1.

`WaveSpawner` ya aplana `WaveData.spawn_entries` en orden. Autorizar los diez
`resources/waves/nivel_montecalvo_oleada_01.tres`…`_10.tres` como entradas
intercaladas A,A,R según índice global WAVE, usando count1 o2 para compactar sólo
runas consecutivas iguales dentro de cada oleada; el array puede reusar los
mismos WaveSpawnEntry inmutables A/count2 y R/count1, más parciales A/count1,
sin99 subrecursos ni nuevo contador runtime. Cada entrada conserva el
spawn_interval original de su oleada; primer spawn y separaciones temporales,
cursor1→5 e inicial independiente conservan la autoridad actual. Sin cursor de
tipo runtime, selector aleatorio o mutación de Resource.

No setup: las APIs y recursos existentes bastan para RED de orden/composición.
El tester carga las oleadas actuales y compara sus datos aplanados; la ausencia
de un nuevo archivo no debe producir un fallo de import/parser usado como RED.
Avance/tiro, contacto mixto y pool se verifican por física/regresión existentes;
no requieren simular RED artificial de IA ya aprobada. Desarrollo previsto sólo
Resources; fuente únicamente si un defecto real comprobado lo exige.

T016–T025 cubren preparación→RED→QA→datos→GREEN/build/preview→QA→docs→CI→QA final→
cierre del mismo borrador. Un export Web final para8813 y APK QA de fuente final
estable: paquete `com.juanpvivas.demons.ranged015qa`, firma debug anterior,
archivo `PR59-S24-prueba2.apk`. Sólo root gestiona la entrega personal autorizada
en el borrador privado existente429670877, sin distribución automática ni cierre
T015. Reutilizar reglas I1/013/014; release1.0.2, pendientes004/005/013/014 y006
pausada permanecen. Sin logs o evidencias nuevas en Git.
