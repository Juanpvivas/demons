# Contrato de presentación — WorldHealthBar

**Estado**: `011-I1` APROBADO PARA INTEGRACIÓN (T011); [PR #43 en borrador](https://github.com/Juanpvivas/demons/pull/43), con revisión humana y publicación pendientes; [FR-001–007](../spec.md).

## Composición e interfaz

- `class_name WorldHealthBar extends ProgressBar` en `scenes/ui/world_health_bar.gd`; escena `scenes/ui/WorldHealthBar.tscn`.
- Hijo directo `HealthBar` del root de Soldado y EnemigoBase; separado de AnimatedSprite2D/visual para no heredar flip, modulate o pulsos del sprite.
- `set_health(current: int, maximum: int) -> void`: si máximo ≤0 o actual ≤0, limpiar/ocultar; en otro caso asignar máximo y valor limitado a [0, máximo], mostrar y escoger relleno por proporción.
- `clear() -> void`: ocultar y dejar valor 0; idempotente y utilizable antes de `_ready()`.
- Observables de producto: `value`, `max_value`, `visible` y estilo `fill` del ProgressBar. Sin getters de prueba, nueva autoridad de salud ni señales artificiales.
- `show_percentage = false`, `mouse_filter = MOUSE_FILTER_IGNORE`, `focus_mode = FOCUS_NONE`; llenado izquierda→derecha, sin tween ni procesamiento por frame.
- Tres StyleBoxFlat mates con borde oscuro; seleccionar/reemplazar override local sin mutar recursos compartidos. Oliva >0,50; ocre >0,25 y ≤0,50; rojo ≤0,25.
- Inicio visual de revisión: 48×6 unidades de mundo, centrada, con margen mínimo de 6 sobre el casco durante el ciclo. Ajuste de colocación/tamaño por QA visual, sin alterar sprite, arma o mecánicas.

## Integración y ciclo de vida

- El actor conserva `_current_health` como autoridad y obtiene máximo de sus stats: hoy 30 colombiano y 15 enemigo, sin hardcodear esos valores en la barra.
- Inicializar/activar un actor vivo llama `set_health`; un enemigo inactivo sigue oculto al entrar al árbol. Daño actualiza inmediatamente. Recargar, regresar o cambiar de arma no cura ni reinicializa.
- Daño letal limpia la barra antes de callbacks/señales de derrota que puedan reciclar o reactivar síncronamente al enemigo; no limpiar después una activación nueva.
- `Enemigo.on_pool_released()` limpia incluso en prewarm anterior a `_ready()`; resolver el hijo sin depender exclusivamente de `@onready`.
- Tras `_ready()`, `prepare_for_spawn()` restaura barra completa con los stats de esa activación, incluido un máximo distinto; ninguna llamada anterior puede ocultar la nueva activación. Su uso antes de `_ready()` no forma parte de este contrato.
- La caída cosmética sólo usa su sprite actual: no copiar barra. Retirada, cierre del nivel y Retry no conservan indicadores del intento anterior.

## Alcance de verificación

Componente: carga neutral antes de RED, proporciones/límites exactos/invalidación/clear repetido y dos instancias independientes. Actores: 30/30 y 15/15 iniciales, daño, recarga sin cura, baja oculta antes de callbacks, release de prewarm antes de ready → ready inactivo → prepare después de ready, máximo distinto, reuso síncrono y Retry. Estado UI real y estilos se comprueban funcionalmente; anclaje/lectura se revisan visualmente, con alcance propio de cada entorno ejecutado.
