# Data model: recursos visuales existentes

No hay datos de negocio, red o persistencia nuevos.

- **Atlas de marcha**: PNG RGBA de ocho poses del mismo enemigo, hacia −X, más su importación. La región de cada pose y el apoyo se miden tras importar.
- **`SpriteFrames` compartido**: conserva los nombres `advance`, `contact` y `defeat`; sólo las texturas/duración de `advance` pueden cambiar en esta entrega. Contacto y caída mantienen sus referencias y tiempos vigentes.
- **Actor y presentador**: conservan instancia, generación, salud, fila, desplazamiento, colisiones y reinicio actuales. Cada actor mantiene su propio progreso de reproducción; el recurso no escribe gameplay.

El [contrato visual](contracts/advance-visual.md) describe las transiciones observadas, sin añadir estados ni callbacks.
