# Research: Cinco carriles horizontales

Investigación local para planificación; sin juego/builds/pruebas ejecutados.
Fuentes: [spec](spec.md), constitución 3.0.0, arquitectura/flujo y código real
conservado de I2. Skills GodotPrompter consultadas: Resources, estados, física,
entrada, testing, cámara, UI adaptable y animación; no fijar rutas personales.

| Decisión | Motivo y alternativas descartadas |
|---|---|
| Geometría 96×96 en Resource | Reutiliza grid y limita a cinco plazas verificables. No inferir estadísticas de imagen ni restringir mediante decoración. |
| Soldado `CharacterBody2D`, física ±X | `StaticBody2D` es la premisa anterior; mover sprite/Tween no cumple contacto real. Sin navegación libre. |
| Arma y desplazamiento separados | Carga llena durante retorno no permite atacar. Dos enums pequeños evitan framework innecesario. |
| Consultas en física y filtros semánticos | Hay hallazgo histórico de overlaps no fiables con cuerpo móvil/estático. No extrapolar su fiabilidad a dos móviles; probar cuerpos reales. |
| Broadphase amplio, alcance/filtro explícitos | Fusil actual 144×240 offset(0,−144): orientado+X conserva tramo[24,264]. Filas 96/cuerpos 48 pueden ser tangentes transversalmente; filtro de celda resuelve diagonal contigua sin ampliar alcance. |
| Progreso −X y blanco activo elegible | Mayor valor sigue siendo más cercano a defensa. No dividir fuego o robar foco continuamente. |
| Pool compartido, origen por activación | Hay un inicial real t0 adicional a 99 de oleadas. Conservarlo en fila 3 sin cursor/contador, con combate/drop/moral/visual; no cambiar `ObjectPool`. |
| Cursor continuo solo para WAVE | Decisión humana 1→5 entre oleadas; reset solo nueva partida. Mantener orden/Timers. |
| Recarga validada por actor; selección por nivel | Bloqueo previo a callbacks económicos evita reentrada. No confiar solo en botón ni referencias obsoletas; no recarga parcial o fusil fuera. |
| Cámara local y stretch existente | `expand` conserva diseño y amplía márgenes; resize no mueve actores. UI anclada; input convierte canvas inverso. |
| Arte observador separado | Trinchera/piezas/poses y caída independiente. Rechazar fondo con actores incrustados, cobertura estadística o girar todo 90°. |

## Datos conservados

- Soldado: vida 30, carga 10, daño fusil 5, cadencia 1,5/s; machete 3+moral×1,
  moral por baja de fusil 1 y costo 10. Velocidades propias nuevas 40/40 no se
  leen de `EnemyStats`.
- Enemigo: vida 15, velocidad 40, daño 5, drop 3. Daño entrante conserva intervalo 1s;
  machete conserva cadencia de `UnitStats.fire_rate`.
- Cantidades de diez oleadas:3,4,5,6,8,10,12,14,17,20, suma 99. Inicial completa 100.
  El inicial nunca notifica baja a WaveManager. WON histórico sigue dependiendo
  de las 99 bajas de oleadas, no se añade matar al inicial como requisito nuevo.
  Inicial sí puede causar LOST. Conservar número literal de oleada, orden y
  esperas, incluido primer spawn.
- Recolección manual, formas/radio de pickup y cajas solapadas se mantienen;
  selección/recarga no se agregan al mismo gesto de recogida.

## Riesgos que guían pruebas

Distancia de entrada a trinchera cambia respecto al tablero vertical aun sin
cambiar stats. Playtest observará aproximación, tensión y legibilidad con
cinco cargas/reserva 0; cualquier rebalance exige decisión/tarea, no ajuste
silencioso para ganar.

Dos cuerpos móviles requieren colisión/separación/daño real, sin atravesar ni
heredar objetivos reciclados. Baja puede liberar pool e iniciar oleada
síncronamente: capturar contexto/generación para no contar/recompensar otro uso.
Probar misma instancia inicial → WAVE → inicial en fila distinta y no solo dos nodos.

Aprobaciones heredadas corresponden al estado anterior. Repetir recorridos
que afectan tablero/input/presentación. Compatibility temporal no certifica
Mobile; iOS Simulator no certifica IPA físico. Sin hardware no se aprueba
SC-007, pero preparación y desarrollo funcional siguen posibles. No quedan
aclaraciones de producto pendientes para generar tareas.
