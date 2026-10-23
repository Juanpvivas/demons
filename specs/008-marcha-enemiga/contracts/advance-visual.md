# Contrato de presentación de avance

Sólo se sustituye `advance` de `enemigo_lateral_frames.tres`.

| Situación real | Presentación conservada |
|---|---|
| Desplazamiento confirmado hacia las trincheras | `advance`, bucle completo; continuar el mismo clip sin reiniciarlo cada tick |
| Sin desplazamiento o contacto/bloqueo | `contact`, pose vigente; sin simular pasos ni añadir daño |
| Impacto confirmado durante avance/contacto | Feedback actual, sin nueva autoridad ni interrupción arbitraria del ciclo |
| Baja y efecto independiente | `defeat` y snapshot vigentes, sin seguir una instancia reciclada |
| Nuevo acquire o nuevo intento | Reset vigente: transitorios y progreso anterior no contaminan el siguiente uso |

Las ocho poses comparten identidad, orientación, lienzo y apoyo. En el encaje inicial se conserva el ciclo de 0,60 s; la revisión visual debe comprobar también la unión de la última pose con la primera y la lectura a altura aproximada de 72 unidades. Rifle y equipo completos, transparencia limpia y sin figuras vecinas. Contacto/caída y valores de escena permanecen intactos.

Si resulta necesario modificar código, stats, colisiones o ese contrato de estados, detener esa parte y devolver el alcance al orquestador antes de implementarla; no eludir TDD mediante una tarea de arte.
