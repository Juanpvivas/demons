# Android Emulator 002 — matriz controlada antes/después

**Casos controlados antes/después aprobados por QA el 2026-10-16.** La vía es Android emulado autorizada; no equivale a toque físico Xiaomi ni rendimiento de referencia.

AVD existente `Medium_Phone`, Android API37.1/ARM64 con páginas16KiB, emulador37.2.12; arrancado `-read-only -no-snapshot -no-audio -no-boot-anim`. Display2400×1080 en landscape, viewport1440×648, escala1.666667. Mobile/Vulkan sobre gráficos emulados de software. Se usó siempre `adb -s emulator-5554 shell input tap`: los otros transportes no recibieron inyección. No hubo cambios de gameplay, saldo, recursos, InputMap, límites, pausas o tiempos. El driver temporal solo lee el observador existente y dirige gestos del SO del emulador. No llama métodos del juego.

Ambas variantes usan `a473585`/script fijo4e89dce… y el mismo observador/telemetría. APKs/hashes y proveniencia en [comparación nativa](native-device-performance.md). [Ejecuciones/acciones](native-avd-driver-executions.json), [PRE/POST derivado](native-avd-derived.json), eventos íntegros [anterior](native-avd-baseline-events.json)/[final](native-avd-final-events.json), logs [anterior](native-avd-baseline.log)/[final](native-avd-final.log).

| Caso | Anterior al arte | Arte final |
|---|---|---|
| I3, libre sin fondos | Reserva0→0, soldados1→1 | Reserva0→0, soldados1→1 |
| I2, celda6,5 ocupada con fondos | Reserva12→12, soldados1→1 | Reserva12→12, soldados1→1 |
| I4, un pickup aislado de3 con fondos | Reserva12→15, soldados1→1, ningún gasto10 | Reserva12→15, soldados1→1, ningún gasto10 |
| I1, click sobre franja de trinchera `(528,600)`, celda5,6 libre | Reserva15→5, soldados1→2; nuevo centro528,624 | Reserva15→5, soldados0→1; nuevo centro528,624 |
| I9, punto `(1300,528)` fuera del centro ilustrado, celda13,5 libre | Reserva11→1, soldados2→3; nuevo centro1296,528 | Reserva11→1, soldados1→2; nuevo centro1296,528 |

Todos los PRE/POST citados están en **PLAYING**. El soldado inicial de la variante final murió entre el gesto I4 y el I1; se conserva el recuento0→1 real, sin atribuir al arte una diferencia de ocupación o muerte que ocurrió entre gestos. El pickup I4 es único según la geometría del círculo20px y snapshotPRE; no se rebajó la recompensa por solapamientos. Mouse emulado y touch del mismo gesto se agrupan por posición y proximidad temporal; no se cuentan como dos taps físicos.

I1 comprueba la misma conversión de click a celda/centro sobre una posición que tiene decoración final. I9 prueba conservación de entrada más allá de la zona central detallada; **no presupone un grid finito ni introduce límites**. Capturas de acciones: [anterior ocupada](native-avd-baseline-action6.png), [anterior pickup](native-avd-baseline-action7.png), [anterior trinchera](native-avd-baseline-action8.png); [final ocupada](native-avd-final-action6.png), [final pickup](native-avd-final-action7.png), [final trinchera](native-avd-final-action8.png). Raw de las demás acciones permanece en la copia temporal indicada por ejecuciones.

I5 y muerte/liberación/costos/moral/recarga/oleadas conservan su regresión189/189 en [T021](t021-green.md); el AVD no se presenta como una nueva victoria manual de diez oleadas. La sesión humana final aporta [muestreo físico separado](native-android-input.md), con sus I2/I4 físicos aún no demostrados. V1 PC y V4 iOS Simulator se informan por separado.
