# Decisiones de preparación (base 4fb1267; historia)

- Soldado filtra mismo carril o diagonal inmediata por celda y luego solape físico; ampliar sólo .tres no cambia esa geometría permitida.
- Enemigo actual sólo marcha; su fusil exige estado/consulta físicos nuevos, sin recuperar el bug histórico de Area2D en cuerpos móviles.
- WaveSpawnEntry ya referencia EnemyStats: perfiles autorados por ola, sin fórmula global o mutación runtime. Tabla humana en spec es la fuente del balance.
- take_damage retorna true sólo en daño letal; capturar contexto antes de callbacks evita crédito al objeto reciclado. El dueño puede morir o activarse terminal durante la llamada: revalidar vida sin exigir PLAYING después de la baja final.
- CombatVisualEffects exige actualmente2coords y CombatAudio valida Soldado: ampliar adaptadores para enemigo/gen sin romper payload previo ni retener referencias Node en efectos.
- No nuevos medios obligatorios: reusar CC0 de fusil y sistema cosmético/audio014. Toda prueba headless o preview acredita sólo su entorno; balance sí exige playtesting proporcional, sin cerrar publicación física.

## Alcance funcional aprobado y límites

### I2 vigente aprobado funcionalmente

QA T021 aprueba `b4fbaf8`: A,A,R continuo entre 99 WAVE (66 A/33 R), inicial R1
independiente, stats/tabla/ritmos/carriles conservados y hasta tres entradas
inmutables reutilizadas por oleada. No hay nueva IA o colisiones. GREEN/regresión,
import y export Web están verificados. CI de `d8826e2` y QA final aprobaron
integración I2, en rama/PR59 en borrador, sin merge. La comprobación de esa
revisión no se atribuye automáticamente a cambios documentales posteriores.
Chrome en macOS observó asaltantes avanzando, fusileros detenidos, transición
a machete, derrota real al cruzar la defensa, Retry limpio y salida al menú
durante combate activo, ahora observado manualmente en I2.

El APK QA2 conserva el mismo paquete/firma de prueba y root ya realizó su entrega
personal autorizada en el mismo borrador privado existente. No se ha observado
su instalación en el S24 ni se certifica victoria de producción en diez oleadas,
conteo manual de 99 bajas, audición, latencia Web, FPS/hardware o paquete final.
La mezcla no cierra T015/SC008, pendientes 004/005/013/014 ni pausa 006; release 1.0.2
se conserva. El riesgo táctico anterior sigue sin justificar otro cambio de balance.

### I1 — Historial de alcance y aprobación

QA T010 aprueba los tres cambios de 015-I1: alcance físico 864 desde el hogar,
enemigos estacionarios con fusil por carril y perfiles de la tabla, y recompensa
letal de machete +2 moral/+3 vida con cap y protección de reentrada/reciclado.
El snapshot enemigo se admite antes del daño; generación y revalidación aíslan
activaciones, y la consulta por grupo evita dependencia circular entre scripts.
Intro 013, voces definitivas, mezcla 014 y demás reglas se conservan.

GREEN dirigido y regresión afectada están verificados tras corregir expectativas
históricas incompatibles con las nuevas reglas. CI de `2351798` confirmó la suite
completa, imports, guard y export Web; QA emitió `APROBADO PARA INTEGRACIÓN`
para esa revisión. Esta comprobación no se atribuye automáticamente a cambios
documentales posteriores. Chrome en macOS observó tiros desde la entrada, enemigos
que paran/reanudan marcha, aumento de moral 3→5 tras baja de machete, derrota real,
Retry y regreso al menú/nuevo intento limpio. La curación exacta y su cap se
acreditan por GUT; la barra manual sólo cualitativamente. Pausa se cubre por GUT,
sin UI nueva; salida al menú durante combate activo se conserva por GUT/014,
sin atribuir una nueva observación manual a 015.

Android instalado en emulador Mobile/SwiftShader llegó mediante gestos a ola 3;
iOS sólo tiene proyecto Xcode exportado. No se certifican victoria en ola 10/99 bajas
manuales, audición/latencia Web, FPS/hardware o paquete final. Macheteros sin
munición deben cruzar bajo fuego y pueden morir antes del contacto: se observaron
derrotas tempranas, sin demostrar imposibilidad de ganar ni autorizar un nerf.
Las muestras de coste son descriptivas, sin benchmark ni causalidad de RSS/GPU.
Publicación T015/SC008, pendientes 004/005/013/014 y pausa 006 permanecen; release 1.0.2
no cambia. La entrega sigue en su rama mediante [PR #59 en borrador](https://github.com/Juanpvivas/demons/pull/59),
aprobada para integración y aún sin fusionar ni publicar.
