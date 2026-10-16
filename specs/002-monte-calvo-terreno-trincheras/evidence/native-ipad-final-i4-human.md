# V4 iPad Simulator — recogida humana FINAL con arte

**I4 con fondos suficientes y comparación con BASE aprobados por QA el 2026-10-16.** La persona respondió «Sí, llegué a 15 o más». No se deduce el resultado de esa respuesta: lo acredita el PRE/POST recuperado de la app sin reiniciar, recargar, rotar ni enviar gestos.

Evidencia: [raw](native-ipad-final-i4-human.log), [derivado](native-ipad-final-i4-human-derived.json), [app instalada](native-ipad-final-i4-human-installed-proof.json), [captura exclusiva del objetivo](native-ipad-final-i4-human-current.png)/[metadatos](native-ipad-final-i4-human-capture.json). Raw 36.507 bytes, SHA256 `0630c220b9e38825d58e5e43794e4dfcce3b9a777eed57083878f54534dda6b1`; una INITIAL a687ms,12PRE/12POST. El último INITIAL distingue esta nueva sesión del ensayo anterior conservado.

| Caso | PRE → POST | Observado |
|---|---|---|
| Recogidas iniciales seq1/2–7/8 | Reserva0→3→6→9→12; un soldado; PLAYING | Depósitos reales de3, sin despliegue |
| I4 discriminante seq9/10, ticks29643→29775 | Gesto `(584.37,452.51)`, celda6,4 libre. Una munición3 en `(576,451.95)`. Reserva12→15, soldados1→1, ocupación `[[6,5]]` idéntica, PLAYING→PLAYING | Acredita3 sin gasto10 ni soldado adicional |
| Recogida adicional seq11/12 | Otro depósito único3,15→18, soldados0→0, celda6,4 libre, PLAYING | Sin despliegue; la muerte del inicial ocurrió entre gestos y no se atribuye a la recogida |

Los pares mouse/touch de igual posición y ≤40ms son un gesto humano en el frontend del simulador, usando el PRE más temprano y POST más tardío. No se afirman dos acciones independientes ni dedo físico iOS. La celda del gesto y la del depósito coinciden en el caso discriminante; en recogidas previas pueden diferir por un borde de celda y se conservan sus coordenadas reales.

iPad Pro13-inch(M5)/iPadOS27.0, horizontal2752×2064, viewport lógico1152×864, stretch2.388889/canvas identidad. El gesto discriminante corresponde aproximadamente al píxel renderizado `(1396,1081)`, mundo igual al viewport, celda=floor(posición/96); no se registraron coordenadas globales macOS del clic humano. La captura se limita a la ventana Device Hub verificada para este iPad y nuestra app.

Fuentea473585/script4e89dce…; observerc628…/telemetría2fbdb… y renderer Compatibility/logger temporales, según [procedencia](native-ipad-setup.md). PCK realmente instalado `e6fbeaa3c092d0a464ee038d8541e5fe39339f0f9a8b8b582a730d2df29a9352`; binario arm64 `d4c1f14a87fc61fdf9f8b2983b27ca6a1a7525da8472a90635af88a58bdca096`. Ambos coinciden con la app exportada y el engine local del tag4.7.1 sin parches. Se conservan los avisos de mouse del display server; AppleSoftwareRenderer/FPS del simulador no acreditan SC-007 ni hardware iOS.

[BASE sin arte](native-ipad-baseline-human.md) probó el mismo caso con el mismo arreglo: celda6,4 libre, un depósito3,12→15,1→1soldados, PLAYING. Esta comparación separa la corrección lógica ya aprobada de la presentación artística. [Sesión FINAL anterior](native-ipad-final-human.md) conserva I1/I3; I2/I9 controlados están acreditados en la vía AVD sin fingir cobertura humana iOS adicional. El dictamen de aceptación de V4 corresponde a QA; no se han marcado tareas.
