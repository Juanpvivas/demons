# Contrato de presentación de avance

Sólo se sustituye `advance` de `enemigo_lateral_frames.tres`. La corrección de continuidad tiene validación funcional y visual local en T013; el cierre de integración de la revisión exacta se registra en [tareas](../tasks.md) y PR.

| Situación real | Presentación conservada |
|---|---|
| Desplazamiento confirmado hacia las trincheras | `advance`, bucle completo; continuar el mismo clip sin reiniciarlo cada tick |
| Sin desplazamiento o contacto/bloqueo | `contact`, pose vigente; sin simular pasos ni añadir daño |
| Impacto confirmado durante avance/contacto | Feedback actual, sin nueva autoridad ni interrupción arbitraria del ciclo |
| Baja y efecto independiente | `defeat` y snapshot vigentes, sin seguir una instancia reciclada |
| Nuevo acquire o nuevo intento | Reset vigente: transitorios y progreso anterior no contaminan el siguiente uso |

Las ocho poses, aunque procedan de dos texturas con tamaños importados distintos, deben compartir identidad, orientación, altura de encaje, lienzo y apoyo. El ajuste se resuelve en importación/regiones y márgenes; no mediante edición de píxeles ni cambios de escala/offset de escena. En el encaje inicial se conserva el ciclo de 0,60 s; la revisión visual debe comprobar también la unión de la última pose con la primera y la lectura a altura aproximada de 72 unidades. Rifle y equipo completos, transparencia limpia y sin figuras vecinas. Contacto/caída y valores de escena permanecen intactos.

El orden temporal sigue la transferencia de apoyo, no la posición de una pose en su hoja. Al enlazar una pierna que alcanza hacia delante con el contacto del pie, el apoyo debe recaer en esa misma pierna; revisar ambas mitades y el cierre del ciclo. Esto describe la continuidad de la marcha y no cambia el clip `contact` del presentador.

Si resulta necesario modificar código, stats, colisiones o ese contrato de estados, detener esa parte y devolver el alcance al orquestador antes de implementarla; no eludir TDD mediante una tarea de arte.
