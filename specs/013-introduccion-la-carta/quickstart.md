# Verificación — La carta

## Escenarios históricos de I1

Escenarios de comprobación reproducibles; su enumeración no afirma que todos
fueran observados en cada destino. T009 aprueba el alcance funcional disponible
con [límites explícitos](research.md#alcance-funcional-aprobado-y-límites);
CI/gate final de integración T011–T012 y publicación T014 siguen separados.

1. Perfil/ruta temporal sin borrar preferencias: menú→Jugar→escena1/voz/texto, sin nivel/oleadas.
2. Recorrer siete escenas completas; escuchar narrador/compañero y comprobar textos/rótulos/fundidos sin cortar voz. Esperar Comenzar y sólo entonces montar partida.
3. Pausar a mitad de frase: voz/tiempo/movimiento detenidos. Perder foco/app, regresar, continuar expresamente sin salto ni voces dobles.
4. Con recuerdo nuevo, omitir en escenas1,4,7 y final simultáneo. Pulsar Comenzar varias veces: un nivel, sin click-through de recogida/despliegue.
5. Reiniciar con recuerdo: Jugar directo. Resultado→Reintentar directo. Menú→Ver introducción→escena1→final/omitir→menú sin nivel.
6. Simular lectura corrupta/versión diferente y fallo escritura en temporal: no crash, no visto ante lectura inválida, Comenzar disponible sin falso guardado.
7. Resize durante reproducción/pausa/espera. Ratón/teclado en Web computador; toque en apps Android/iOS disponibles, foco/áreas seguras y texto completo. No navegador móvil.
8. RED previo por aserción, GREEN y regresión pertinente/completa vía tools/ci/run_gut.py; importación/export Web estándar y build nativo/CI aplicable. Fallo entorno no es RED ni aprobación.
9. Smoke abre→intro→Comenzar→partida→resultado→Reintentar/menú, declarando fixture versus producción1+99. Recursos incluidos/offline y audio Web desbloqueado por gesto inicial.
10. Comparar carga/coste con base disponible y declarar anomalías/límites por entorno/app/renderer. No certificar físicos/paquete final desde software ni cerrar publicación.

No añadir capturas/logs/manifiestos de evidencia a Git. Usar temporales/síntesis PR, mantener pausa006 y pendientes004/005. Distribuir sólo con gate/autorización futura.

## Escenarios vigentes R2

1. Con recuerdo temporal nuevo, Jugar→intro; con recuerdo válido, Ver
   introducción→intro. En ambas, probar final natural y Omitir: aparece Comenzar
   sin volver al menú ni iniciar combate; sólo otro gesto monta un nivel.
2. Recorrer siete cuadros: no contador, caption ni aviso superior, tampoco
   cabecera vacía. Subtítulos exactos de narrador/compañero y controles legibles
   en las relaciones de pantalla disponibles, sin repintar imágenes.
3. En entrega parcial, verificar reproducción/pausa/cierre de Ald preview y
   ambiente sin truncar frases; no declarar voz final, naturalidad o fluidez
   aprobadas. Al recibirse el archivo humano, T026 incorpora siete narraciones
   y compañero humano sólo si se incluye, revisa texto/mezcla y audición real.
   Anotar percepción sin inferirla de metadatos ni contar ejecución sin audio
   como escucha. SC-009 continúa pendiente hasta esa comprobación.
4. Pausar durante frase y durante compañero; perder foco y volver; voz y
   ambiente se detienen/retoman juntos, sin avance oculto ni duplicación.
   Omitir/finalizar/cerrar y abrir otra vez: no ambiente residual o dos loops.
5. En PLAYING y PAUSED, pulsar Menú principal con mouse/teclado/toque disponible:
   salir directo sin modal y con cero niveles/oleadas/audio/controles viejos.
   Repetir pulsación/callback viejo no duplica cierre. Menú→Jugar inicia intento
   limpio; resultado y Retry conservan comportamiento y recuerdo de la carta.
6. Tester ejecuta RED por aserción antes de cambio, GREEN/regresión completa,
   import/export/build/CI correspondientes a la revisión exacta. QA independiente
   revisa medios, datos, función/limpieza y límites por destino. Voz/ambiente y
   arte requieren verificación proporcional, sin RED artificial de percepción.
7. No extrapolar evidencia de I1: declarar los destinos/gestos/audio no observados
   en R2 y conservar límites físicos/paquete/FPS y riesgos anteriores. Sin nueva
   campaña de rendimiento ni distribución; SC-008/T014 permanece pendiente.
