# Contrato mínimo — tres cambios

## Setup neutral antes de RED (historia T002–T003)

Declarar en EnemyStats rifle_range/rifle_damage/rifle_interval en0 y en UnitStats machete_moral_per_kill/machete_heal_per_kill en0, sin cambiar recursos .tres o conducta. En Enemigo declarar `signal rifle_shot_visual_requested(snapshot: Dictionary)` sin emisiones/conexiones. Interfaces existentes _physics_process/prepare_for_spawn/take_damage/get_reload_state permiten aserciones sobre cuerpos reales; no crear getters artificiales o implementar antes del RED.

## Alcance y enemigo

- Soldado producción rifle_range864. Hogar144/entrada1008 deben producir adquisición real con colisionadores; no vale llamar _fire_at_current_target manualmente como única prueba de alcance.
- Mantener frente, diagonales sólo columna inmediatamente contigua y ±1fila; machete sin cambio de alcance.
- Enemigo: sólo Soldado vivo enfrente (−X), mismo carril y solape físico en range864. Revalidar blanco/generación antes de cada hitscan y antes de reusar referencia tras callbacks.
- Primer tiro al adquirir, luego intervalo del perfil. Con blanco válido no avanza; sin válido retoma avance. Contacto melee tiene prioridad excluyente: nunca sumar fusil+melee del mismo enemigo.
- Pausa/terminal no avanzan ni descargan relojes atrasados. Nueva activación/retiro/close limpia objetivo/fase/cooldown; perfiles siguen inmutables y ningún evento viejo apunta a reemplazo/actor reciclado.
- No nuevo sistema de munición, stats HP/speed/melee/drop o ritmos/conteos de spawn.

## Recompensa machete

Ataque válido captura tipo de arma, dueño, blanco y activation_generation antes de daño; guard de transacción evita reentrada. Sólo la llamada que retorna killed=true acredita una vez2moral+3vida al dueño aún vivo, limitado por max_health. Última baja puede activar WON síncronamente sin perder premio; dueño muerto nunca se resucita. Impactos/fusil/cleanup/segunda llamada no reciben premio machete. Fusil conserva1moral. Emitir actualizaciones de moral/vida/barras mediante mecanismos existentes, sin nueva UI.

## Presentación y audio

Enemigo emite una vez por tiro confirmado snapshot `{origin_world: Vector2, target_world: Vector2, activation_generation: int}` sin Node. Origin/target finitos y generación igual a activación viva registrada. Soldado mantiene su snapshot actual de2coords. Los consumidores conectan una vez por actor físico, validan contexto/generación y descartan eventos previos a reciclado/cleanup/close; al efecto entregan sólo datos saneados, no referencia a dueño. Audio reutiliza cue rifle/Stream/GameplaySFX y9voces; destello/trazadora nunca causan otro daño.

Confirmar/admitir snapshot, audio y VFX del tiro enemigo ANTES de aplicar daño
que pueda emitir baja/terminal síncronos; conservar un tiro, una baja y resultado
sin cortar voces ya admitidas. No añadir derrota por último soldado muerto:
PosicionDefendida sigue siendo la autoridad; la cadena puede probarse con
fixture/observador que use esa autoridad real.

## Datos y tests

Perfil inicial y ola1 iguales a tabla1; ola2–10 refs distintas con sus campos exactos. Test comparar recursos/spawn entries y que activar otra ola no muta un enemigo vivo. Fixtures simulan física real y estado completo además de pruebas puntuales; reset de Managers/pools/actores y contexto de intro controlado, no tocar preferencias reales. Parser/import error no vale RED. Arte reutilizado se revisa proporcionalmente.

## Enmienda 015-I2 — Contrato de composición

Comportamiento funcional aprobado en T021 (`b4fbaf8`); CI/gate final I2 pendientes. El contrato anterior de tiro corresponde a R; A conserva avance/contacto sin fusil.

A = `enemigo_asaltante_base.tres` (tres campos rifle0, HP15/speed40/melee5/drop3);
R = perfil de fusilero I1 de su oleada (alcance864/tabla exacta). A no requiere
una clase o modo de IA nuevo. Estado por activación, contacto y callbacks siguen
el contrato anterior; el inicial siempre usa R/perfil1.

Expandir cada spawn_entry por count y concatenar las diez oleadas: el índice
WAVE base0 es R sólo cuando índice%3=2, A en los otros dos casos. El cursor no se
reinicia entre olas ni incluye INITIAL. Cada entrada mantiene el intervalo
original de su ola; el cursor de carriles y la lógica de Timer no se modifican.
No agrupar tipos fuera de orden; count1/2 puede compactar sólo iguales adyacentes.
La [tabla I2](../spec.md#enmienda-015-i2--dos-asaltantes-por-fusilero) fija totales.

Verificación física: A avanza con blanco colombiano válido; R dispara/parado y
reanuda sin blanco, preservando contacto/colisiones. Reusar un actor R→A→R
limpia objetivo/cooldown y evita tiros/eventos viejos. Estas regresiones no
constituyen una solicitud de nuevo pathfinding o un supuesto bug de colisión.
