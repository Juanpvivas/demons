# Decisiones: Carrera del soldado colombiano

## Dos recorridos del mismo personaje

**Decisión**: renovar salida con machete y regreso con fusil bajo, manteniendo sus diferencias de equipo. **Motivo**: ambos clips de 005-I4 tenían cuatro poses y 0,60 s; repetir o reordenar zancadas similares no produce un apoyo opuesto completo. **Alternativa descartada**: acelerar el clip o añadir rebote de posición; no corrige la cinemática y cambiaría la lectura aceptada.

## Recurso visual y anclaje existentes

**Decisión**: conservar cuatro originales transparentes, dos por recorrido, e integrar cuatro poses de la hoja base y cuatro del apoyo opuesto en cada clip del recurso compartido. Conservar scripts, escena, transformación, timing total y resto de clips. **Motivo**: la presentación observadora ya distingue movimiento real, parada y regreso con espejo; no requiere otra máquina de estados. **Alternativa descartada**: nuevo rig, callbacks o movimiento cosmético de la raíz.

## Continuidad antes de cerrar el arte

**Decisión**: comprobar alcance → apoyo de la misma pierna y ambas mitades del ciclo, incluyendo última → primera, durante varias vueltas reales. **Motivo**: la revisión humana de 008 detectó un intercambio brusco aunque las poses aisladas parecían correctas. Las referencias aportan movimiento, no estilo ni equipo. El orden final es A0,A1,B2,B3,B0,B1,A2,A3: B3→B0 y A3→A0 enlazan alcance y apoyo de la misma pierna. La guía opuesta de 008 orienta la anatomía; el arte final conserva al colombiano.

## Alcance de integración

Sólo arte/recursos: verificación visual, importación y regresión existente, sin fabricar RED. Si aparece una necesidad de cambiar comportamiento, se replantea su tarea con TDD previo. Se conservan la pausa de 006 y los pendientes históricos de publicación; no se añaden campañas de rendimiento.

## Alcance funcional y visual de I1

T004 valida localmente ambos ciclos reales y sus transiciones con las reglas vigentes. Chrome en macOS acredita salida y regreso hasta HOME, derrota y nuevo intento. Android API36 ARM64 acredita salida, baja, derrota y nuevo intento; no se observó manualmente regreso/HOME. iPad Pro13 M5/iOS27 Simulator acredita ambos recorridos, recarga, derrota y nuevo intento; no completó HOME antes del terminal. La regresión comprueba la semántica común sin convertirla en recorrido manual de otro destino.

Las apps internas usan Compatibility y exclusión temporal del loader GUT heredado; iPad conserva una shell ARM64 de Simulator con PCK actualizado. No certifican Mobile, hardware, IPA final o victoria manual de producción completa. La revisión independiente contrasta recursos, renders y capturas runtime; el cierre de integración y la CI exacta se registran en [tareas](tasks.md) y el PR. Los datos y apps normales se conservan; publicación pendiente.
