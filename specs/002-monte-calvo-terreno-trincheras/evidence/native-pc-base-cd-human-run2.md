# PC BASE — segunda sesión humana con ratón

**I1/I4/I9 aprobados por QA el 2026-10-16.** La persona respondió «Logré hacer todos los pasos». Los resultados se acreditan por PRE/POST, sin asumir que siguió el saldo15 indicado en la guía: el primer despliegue ocurrió con12, suficiente para discriminar costo10.

[Raw](native-pc-base-cd-human-run2.log), [derivado](native-pc-base-cd-human-run2-derived.json), [proof/app/manifest](native-pc-base-cd-human-run2-proof.json). Raw61.021bytes, SHA`0a8ecbc65976f3ec5f4c3f409269ebfb48bf097355ec49efb29264dfe40cf794`; una INITIAL398ms,13PRE/13POST, canal mouse. Recuperados sin relanzar/cerrar/cambiar foco. La [sesión1 I2](native-pc-base-cd-human.md) permanece intacta en otro prefijo.

| Caso | PRE → POST | Resultado |
|---|---|---|
| I1 C,seq5,t17198 | Clic `(530,634)`, celda5,6 libre, sinpickup. Reserva12→2, soldados1→2, nuevo centro528,624; PLAYINGambos | Costo10/unaunidad y centro correcto |
| I4,seq9,t30456 | `(588,438)`, celda6,4 libre; UNpickup3centro576,439.33. Reserva11→14, soldados2→2, ocupación igual; PLAYINGambos | +3 sin gasto ni despliegue adicional |
| I9 D,seq10,t31972 | `(49,160)`, celda0,1 libre, sinpickup. Reserva14→4, soldados2→3, nuevo centro48,144; PLAYINGambos | Mismo despliegue fuera del centro ilustrado, sin límite nuevo |
| I4 junto al frente,seq13,t49346 | `(588,580)`, celda6,6 libre; UNpickup3centro576,576. Reserva10→13, soldados2→2, ocupación igual; PLAYINGambos | Recogida discriminante en posición que contiene decoración final |

Los depósitos y posiciones reales se conservan, incluyendo caída de un soldado entre gestos. No se exige saldo exactamente12o15: pre≥10 y la diferencia+3/−10, ocupación y recuento discriminan el requisito. El observador no da recompensas, consume eventos, muta reglas ni prolonga la partida; C es un despliegue normal elegido por la persona.

Fuentea473585/script4e89dce…/observerbasec628…/extensiónCDlegible123c0a98…, manifest91847b7c… aprobado. Siete archivos reales de app coinciden con manifest. Mundo=viewport lógico1152×648/canvasidentidad; celda=floor(posición/96). No se registraron coordenadas globales macOS del ratón en esta sesión.

La captura secundaria pública de ventana falló con SIGTRAP5 antes de generar imagen; [registro del límite](native-pc-base-cd-human-run2-capture-unavailable.json). No se repite ni se atribuye a gameplay. La captura de sesión1 y los renders históricos conservan evidencia visual separada, sin presentarlos como imágenes contemporáneas de los gestos de esta sesión.

QA aceptó el mínimo BASE completo reutilizando I2sesión1 e I3previo. No se requiere otra sesión BASE. Todo se congela antes del cierre exacto de nuestra app; FINAL se prepara sin iniciar hasta que el orquestador coordine con la persona. No se marcan tareas.
