# Datos: Carrera del soldado colombiano

No se añaden entidades de gameplay ni persistencia. El `SpriteFrames` compartido conserva ocho clips: sólo cambian las poses de `melee_march` y `returning`, ambos repetibles con ciclo total de 0,60 s.

Los atlas nuevos contienen el mismo soldado con distinto equipo según recorrido; las regiones y márgenes mantienen lienzo 384×288 y apoyo (192,264). El estado mutable, la dirección y la selección del clip permanecen por instancia en los componentes actuales. Los recursos visuales no generan daño ni movimiento.
