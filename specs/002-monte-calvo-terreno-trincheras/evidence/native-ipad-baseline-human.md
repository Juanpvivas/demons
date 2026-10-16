# V4 iPad Simulator — recogida humana BASE sin arte

**I4 con fondos suficientes y una munición aislada aprobado por QA el 2026-10-16.** La persona respondió «Sí, llegué a 15 o más». El resultado se obtiene del registro PRE/POST, sin deducirlo de la respuesta.

Se recuperó el archivo propio sin recargar, detener ni rotar antes de congelarlo: [raw](native-ipad-baseline-human.log), [derivado](native-ipad-baseline-human-derived.json), [app instalada](native-ipad-baseline-human-installed-proof.json), [captura](native-ipad-baseline-human-current.png)/[metadatos](native-ipad-baseline-human-capture.json). Raw 40.283 bytes, SHA256 `86005d04b7cd166d0fa5a018e370de99298ebf2e22d187e6a8661b62d19ba231`; una INITIAL a 615 ms, 12 PRE/12 POST. El último INITIAL identifica esta sesión; la sesión final anterior se conservó antes de sustituir la app.

| Caso | PRE → POST | Observado |
|---|---|---|
| Recogidas iniciales, seq1/2–7/8 | Reserva 0→3→6→9→12; un soldado; PLAYING | Cuatro depósitos reales de 3, sin gasto ni despliegue |
| I4 discriminante, seq9/10, ticks28260→28296 | Gesto `(579.77,449.58)`, celda6,4 libre. Una munición de3 en `(576,451.97)`. Reserva12→15, soldados1→1, ocupación `[[6,5]]` idéntica, PLAYING→PLAYING | Recogida única acreditada; ningún gasto10 ni soldado adicional |
| Confirmación adicional, seq11/12 | Otro depósito único de3, reserva15→18, soldados1→1, celda6,4 libre, PLAYING | Mismo resultado con fondos suficientes |

Cada par mouse/touch de igual posición y separación ≤40 ms corresponde a un gesto humano en el frontend del simulador; se usa PRE más temprano y POST más tardío. La ruta realmente registrada incluye ambos canales. No son dos acciones independientes ni un dedo físico iOS. No hubo eventos automáticos ni llamadas a handlers o cambios de estado por tester.

iPad Pro13-inch(M5), iPadOS27.0, horizontal 2752×2064; viewport lógico1152×864, stretch2.388889, canvas identidad. Pantalla renderizada del gesto I4 aproximadamente `(1385,1074)`; mundo=viewport y celda=floor(posición/96). El clic global macOS no se registró: los eventos de la app y la captura exclusiva del frontend conservan el destino visible.

BASE usa el mismo arreglo a473585/script4e89dce…, observerc628… y telemetría2fbdb… que FINAL. Solo composición sin arte y metadata temporal de renderer Compatibility/logger. PCK instalado `55076ebcf908c6613f081f66382e693cdd351703552dcc90f40c412fc4df4ceb`; binario arm64 `5fa85885290eb55f547b4a8fcba086e50256b2e01d4ba2e5a5909b654882f034`. [Procedencia](native-ipad-setup.md) y [configuración logger](native-ipad-filelog-provenance.json) separan el engine compilado desde tag4.7.1 sin parches y la configuración temporal. Se conservan los avisos de mouse no soportado del display server, sin afirmar runtime libre de avisos. SoftwareRenderer y FPS del simulador no acreditan SC-007 ni hardware iOS.

Esta sesión focalizada cubre I4 de BASE; no rellena I1/I2/I3/I9 de esta sesión. [FINAL anterior](native-ipad-final-human.md) conserva I1/I3 y ruta real. El orquestador coordina la recogida focalizada de FINAL antes de declarar comparación I4 completa.
