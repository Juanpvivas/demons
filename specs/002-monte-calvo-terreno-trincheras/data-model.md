# Data Model: entorno visual de Monte Calvo

Esta feature no añade clases, estado persistente, servicios ni Resources de balance. Las entidades de [spec.md](spec.md) se materializan con recursos visuales estáticos.

| Entidad | Representación propuesta | Validación |
|---|---|---|
| Referencia artística | PNG en documentación + criterios y SHA-256 | Coincidencia de bytes; no referenciada por la escena jugable |
| Fondo y terreno | Texturas PNG y sprites del subárbol visual | Continuidad, encuadre, contraste y dibujo por detrás de actores |
| Trinchera decorativa | Regiones de atlas de tierra/madera/sacos | Sin cuerpos, navegación, input, cobertura o cambios de celda |
| Línea base | Capturas y manifiesto de propiedades/archivos previos | Comparación antes/después conservando reglas y posiciones |
| Evidencia | Registros de tester y veredicto QA | Resultado real, entorno, fecha, limitaciones y tarea asociada |

Los nombres y regiones de cada pieza del atlas se registrarán al producirlo; no requieren un esquema JSON ni un recurso de lógica nuevo. No hay transiciones de estado ambientales ni actualización por frame.

Datos que permanecen sin cambios: `UnitStats`, `EnemyStats`, `WaveData`, `WaveSpawnEntry`, economía, ocupación del tablero y estado de partida. No se escriben nuevos valores de costo, cadencia, daño, HP, moral o cantidad de enemigos.
