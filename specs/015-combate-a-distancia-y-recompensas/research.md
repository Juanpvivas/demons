# Decisiones basadas en la fuente actual

- Soldado filtra mismo carril o diagonal inmediata por celda y luego solape físico; ampliar sólo .tres no cambia esa geometría permitida.
- Enemigo actual sólo marcha; su fusil exige estado/consulta físicos nuevos, sin recuperar el bug histórico de Area2D en cuerpos móviles.
- WaveSpawnEntry ya referencia EnemyStats: perfiles autorados por ola, sin fórmula global o mutación runtime. Tabla humana en spec es la fuente del balance.
- take_damage retorna true sólo en daño letal; capturar contexto antes de callbacks evita crédito al objeto reciclado. El dueño puede morir o activarse terminal durante la llamada: revalidar vida sin exigir PLAYING después de la baja final.
- CombatVisualEffects exige actualmente2coords y CombatAudio valida Soldado: ampliar adaptadores para enemigo/gen sin romper payload previo ni retener referencias Node en efectos.
- No nuevos medios obligatorios: reusar CC0 de fusil y sistema cosmético/audio014. Toda prueba headless o preview acredita sólo su entorno; balance sí exige playtesting proporcional, sin cerrar publicación física.
