# Data model: recursos visuales existentes

No hay datos de negocio, red o persistencia nuevos.

- **Atlas de marcha**: dos PNG RGBA originales del mismo enemigo hacia −X, con importación independiente. El primero aporta cuatro poses seleccionadas de su fila superior y el segundo cuatro poses opuestas. Sus límites de importación 1024 y 720 producen texturas 1024×512 y 720×480 con encaje común; regiones y apoyo se definen sobre esas texturas importadas. No se editan los píxeles originales ni se usan las poses restantes del primer atlas.
- **`SpriteFrames` compartido**: conserva los nombres `advance`, `contact` y `defeat`; sólo las texturas/duración de `advance` pueden cambiar en esta entrega. Contacto y caída mantienen sus referencias y tiempos vigentes.
- **Actor y presentador**: conservan instancia, generación, salud, fila, desplazamiento, colisiones y reinicio actuales. Cada actor mantiene su propio progreso de reproducción; el recurso no escribe gameplay.

El [contrato visual](contracts/advance-visual.md) describe las transiciones observadas, sin añadir estados ni callbacks.
