# Datos autorados y transacciones

EnemyStats: campos nuevos `rifle_range: float`, `rifle_damage: int`, `rifle_interval: float`. Setup histórico neutral 0; producción vigente 864 y tabla de [spec](spec.md). Mantener max_health15/move_speed40/melee_damage5/ammo_drop3 en cada perfil. Base .tres es perfil1 y el inicial; perfiles2–10 distintos sin mutación compartida.

UnitStats: nuevos `machete_moral_per_kill: float` y `machete_heal_per_kill: int`; setup histórico 0, producción vigente 2/3. Sólo rifle_range pasa 864; HP30/ammo10/damage5/fire_rate1.5/base_machete3/multiplicador1/moral_fusil1 y resto intactos.

Estado enemigo por activación: blanco/identidad, lane_id, fase marcha-fusil-contacto, cooldown y generación. Reset explícito en prepare_for_spawn/on_pool_released/cierre. Nada de munición nueva.

Snapshot enemigo: origin_world, target_world, activation_generation, todos datos; no Node. Recompensa: dueño vivo+ataque machete confirmado+target id/generación capturados, crédito único antes de invalidar la transacción. No serialización/persistencia nueva.
