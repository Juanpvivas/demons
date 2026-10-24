# Contrato de presentación de disparo

## Productor y snapshot

- `Soldado.rifle_shot_visual_requested(snapshot: Dictionary)` comunica un tiro ya aceptado por las reglas existentes. Una emisión por bala consumida, después del consumo y antes de `target.take_damage`; sin emisión en machete, regreso, falta de blanco o fuera de PLAYING.
- `SoldadoVisual.capture_rifle_shot_snapshot(target_world: Vector2) -> Dictionary` retorna exactamente `{origin_world: Vector2, target_world: Vector2}` por valor. Resuelve la boca del fusil de la pose autorada con las transformaciones del visual; el destino es el `global_position` del blanco al disparar. No cambia pose, arma, color, escala ni gameplay.
- El snapshot se captura antes de callbacks síncronos; nunca contiene `Node`, `Callable`, material, referencia al enemigo o consulta diferida. El servicio copia los valores recibidos; mutar el Dictionary original o mover/reutilizar actores no mueve el efecto.
- Sin listener visual, daño instantáneo, munición y cadencia se resuelven igual. La última bala solicita su efecto antes del cambio de modo; los callbacks de baja no sustituyen el destino capturado.

## RifleShotVisualEffect

Escena `scenes/visuals/RifleShotVisualEffect.tscn`, clase `RifleShotVisualEffect`, script `rifle_shot_visual_effect.gd`, raíz `Node2D`, sin cuerpo, input ni grupos jugables.

| API | Contrato |
|-----|----------|
| `play_snapshot(snapshot: Dictionary) -> void` | Resetea, copia endpoints, inicia una única activación visible y su reloj. |
| `on_pool_acquired() -> void` / `on_pool_released() -> void` | Limpian presentación/reloj y callbacks previos; release oculta y es seguro antes de `_ready()`. |
| `get_activation_id() -> int` | Identidad del uso actual; reset invalida usos anteriores. |
| `get_shot_snapshot() -> Dictionary` | Copia de endpoints que gobiernan el dibujo; vacío cuando está inactivo. No expone estado mutable interno. |
| `complete_activation(activation: int) -> void` | Sólo termina el uso activo coincidente, una vez; una identidad obsoleta no tiene efecto. |
| `finished(effect: Node2D, activation: int)` | Solicita al dueño devolver únicamente ese uso al pool; no toca actores ni combate. |

Flash y trazo se dibujan en coordenadas locales derivadas de los endpoints de mundo, con alpha decreciente, tonos cálidos moderados y sin iluminar el sprite. Duración inicial 0,16 s, siempre ≤0,20 s activo. Sin daño/collision/audio/tiempo de vuelo; la línea indica el disparo instantáneo y no sigue a un blanco. Pausa de árbol o PAUSED congela progreso; WON/LOST permite completar activaciones existentes.

## Servicio e integración

- `CombatVisualEffects.setup(initial_size: int = 10)` conserva su firma; prepara un segundo `ObjectPool` con la misma precarga inicial, crecimiento existente y conexiones por instancia física.
- `register_actor(actor: Node)` conserva bajas y conecta la nueva señal sólo si existe, de forma idempotente. Los cinco soldados iniciales y reemplazos usan el registro existente del nivel; no cambia `WaveSpawner`.
- `request_rifle_shot(snapshot: Dictionary) -> void` acepta snapshots válidos sólo en PLAYING y con servicio abierto/preparado. No guarda actores. Las señales sin listener o las solicitudes rechazadas no alteran combate.
- `get_active_rifle_effect_count() -> int` y `get_available_rifle_effect_count() -> int` informan sólo tiros. Los getters de bajas existentes conservan exactamente su significado.
- `close_match() -> void` es idempotente: invalida/cancela y devuelve tiros activos, desconecta lo necesario y rechaza registros/peticiones posteriores del intento. `nivel_monte_calvo.gd.close_match()` lo invoca antes de deshabilitar hijos.
- Observar `GameStateManager.game_state_changed`: WON/LOST rechazan nuevas peticiones sin congelar las confirmadas; MENU cierra. PAUSED congela y PLAYING reanuda las activaciones válidas; un servicio cerrado nunca se reabre por otra partida. No se crea UI ni API de pausa.

## Frontera de setup anterior a RED

Dev puede declarar señal, clase/escena y firmas anteriores con retornos neutros para que GUT cargue: helpers de snapshot devuelven `{}`, conteos/identidad devuelven `0` y métodos `void` no hacen nada. No emite, conecta tiros, dibuja, activa, avanza el reloj ni finaliza efectos. Tester debe alcanzar la acción real y fallar en una aserción del comportamiento ausente; validar presencia/tipos de claves antes de indexar evita que un Dictionary vacío produzca sólo un error. Parser/import/preload no acreditan RED. El ancla y cualquier lógica de snapshot se implementan después del RED aprobado.
