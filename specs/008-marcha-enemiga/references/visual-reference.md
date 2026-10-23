# Referencia visual: aproximación enemiga

La persona aportó `soldier-metal-slug.gif` el 2026-10-23 como ejemplo de cómo quiere que se vea el avance. Se usa como referencia de movimiento: alternancia de apoyos, piernas que pasan por debajo del cuerpo, flexión de rodillas, oscilación del torso y acompañamiento del arma/equipo. No se incorpora ese GIF ni sus sprites como arte del juego.

Durante la revisión del [PR #37](https://github.com/Juanpvivas/demons/pull/37), la persona señaló un leve brinco al completar los dos apoyos y añadió `Soldado Corriendo lateral y de frente.gif` y `running-soldier.gif`. Ambas referencias sirven únicamente para comparar la continuidad del cuerpo y la transferencia de apoyo entre las dos piernas y al cerrar el ciclo. No se incorporan esos GIF ni sus sprites al juego; la corrección validada localmente en T013 ordena las poses por continuidad de apoyo, manteniendo la identidad pictórica.

La identidad de producción procede del [atlas lateral propio](../../../assets/sprites/enemies/monte_calvo/SOURCES.md): gorra corta, chaqueta gris/marrón, pantalón oscuro, botas, rifle de madera y equipo. Se conserva el acabado pictórico y la dirección hacia −X, con lectura a tamaño de juego. La referencia no cambia la velocidad jugable ni las reglas.

El objetivo del ciclo de ocho fases es recorrer apoyo de una pierna → descenso → paso → elevación → apoyo opuesto → descenso → paso → elevación, cerrando el ciclo. Deben distinguirse los dos apoyos y los cruces; ocho variantes de la misma zancada no cumplen la intención.
