# Modelo de medición

No añade entidades ni persistencia al gameplay. Los nombres/campos del instrumento están en el [protocolo](contracts/profiling-protocol.md).

- **Run**: identidad única, revisión/artefacto, entorno, escenario, ventana, serie de reloj y snapshots; termina válido o inválido con razones explícitas.
- **Snapshot**: inventario recursivo y estado observado por valor, distinguiendo activos, inactivos y pendientes de borrado. El collector añade condiciones con procedencia y disponibilidad, vinculadas al run y frontera temporal. IDs de instancia/activación se auditan dentro del run; entre runs se comparan población, estados esperados y claves lógicas.
- **Comparación**: tres runs por variante con condiciones equivalentes, sus distribuciones/dispersiones y conclusiones limitadas al escenario.
- **Hipótesis/corrección**: factor aislado, resultado contrastado y alcance mínimo autorizado por QA; no es un nuevo Resource de balance.

Ciclo: preparado → calentamiento → medición → finalizado o inválido. Reiniciar no reutiliza muestras ni identidad de la ejecución previa. Los datos se mantienen en temporales/CI y no se serializan dentro de la partida normal.
