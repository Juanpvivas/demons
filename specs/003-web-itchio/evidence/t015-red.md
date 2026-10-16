# T015 — RED de recogida sin despliegue accidental

2026-10-15 local. **RED válido del requisito FR-003/W02**, pendiente de QA.
No se cambió implementación. Revisión al ejecutar:
`3996135f2f67f39eeca34a12204f5ed227bacb94`, más el nuevo archivo de pruebas.

Prueba: `tests/unit/levels/test_pickup_input_routing.gd`, SHA256
`7dafcf4089e350f925e41637870fa4b00cdfdee3b0329f0386639ca99db70298`.
Estado de la implementación anterior:

- `nivel_monte_calvo.gd`: `2420d7100eb852b6dee0521df56015784a5ac0a0b2af0274b3fa6d2b3fe27e6b`.
- `ammo_pickup.gd`: `873c828acac56847f57a63b02a25b30e5c85617354637034c1e80727b9c3f13a`.

## Método y ejecución

Godot estándar4.7.1 / GUT9.7.1, ejecutable portable de [toolchain.md](toolchain.md):

```text
Godot --headless --path . --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/levels/test_pickup_input_routing.gd -gexit --log-file <evidence>/t015-red.log
```

**Retorno1; 4 tests, 2 PASS de control y 2 FAIL esperados; 14/22 aserciones;
1.112s.** [Salida completa](t015-red.log). Sin errores de importación, sintaxis,
carga ni setup; no se repitió todavía la suite completa183 del baseline.

La fixture usa un SubViewport1152×648, World2D propio, physics picking activo,
coordenadas locales y `notify_mouse_entered()`. Envía movimiento, presión y
liberación con **`Viewport.push_input(event, true)`**, esperando frames de
física para resolver picking. No invoca `_unhandled_input`, `_input_event`,
`_collect` ni `_try_deploy_soldado`, ni GutInputSender con receptor de nodo.
Así ejercita el orden real del motor y evita la conversión de coordenadas
del Window headless descrita en los tests históricos T035.

Se consultó la [API oficial4.7 de Viewport](https://docs.godotengine.org/en/4.7/classes/class_viewport.html#class-viewport-method-push-input):
`push_input` propaga los callbacks y utiliza picking cuando el evento queda
sin manejar; `in_local_coords=true` conserva las coordenadas del viewport.

Cada regresión instancia **el nivel y el pickup de producción**, sin cambiar
scripts ni Resources. Se fija solo el estado de fixture: saldo12, **un único
pickup amount3** en240,240 / celda2,2 libre. No se necesitan oleadas sintéticas
ni solapamientos; la prueba termina antes del combate. Conserva/restaura
autoloads y libera la escena mediante `add_child_autofree`.

## Controles que descartan falso RED de entorno

Dos controles instancian únicamente el pickup real y lo recogen por el mismo
SubViewport: mouse normal `device=0` y mouse con
`InputEvent.DEVICE_ID_EMULATION` (`-1`). **Ambos PASS**: `input_event` recibe
exactamente una presión, pickup liberado, saldo15 y cambios `[15]`.

Esto comprueba que las formas están registradas, las coordenadas son válidas
y el picking realmente entrega la interacción. Un fallo de esos controles
no habría acreditado RED de gameplay.

## Aserciones del requisito que sí fallan

| Variante | Esperado tras una interacción | Obtenido |
|---|---|---|
| Mouse normal | Saldo15, cambios `[15]`, mismo soldado inicial, celda2,2 libre | Saldo5, cambios `[2,5]`, soldados1→2, celda ocupada |
| Mouse marcado emulado | Mismo resultado esperado | Mismo fallo: saldo5, cambios `[2,5]`, soldados1→2, celda ocupada |

En ambos casos, el pickup **sí recibe una presión y sí se libera**. Las
precondiciones de celda libre/reserva12 pasan. Fallan las cuatro aserciones
que detectan el gasto10 y el soldado accidental; no es un fallo de entrega
de input. Confirma con un pickup aislado lo visto en navegador y en el ZIP
sin observador, registrado en [web-interaction.md](web-interaction.md).

## Límite táctil y siguiente gate

Un ensayo exploratorio previo con `InputEventScreenTouch` crudo no alcanzó
el control de picking ni la acción esperada en esta fixture. Se conserva
[su log de setup](t015-setup-touch-probe.log), **excluido del RED aceptable**.
No se alteró el motor/configuración para forzarlo. La prueba estable cubre
mouse normal y mouse con identificador de emulación; no pretende acreditar
un toque físico, la generación automática mouse/touch ni el navegador Android.

QA debe aprobar este RED antes de T016. Después T017 repetirá estas mismas
pruebas, la suite completa y el gesto con fondos en el build Web actualizado;
Android físico y los demás casos T007 mantienen sus pendientes. Los ZIP
anteriores continúan WIP con el defecto conocido.
