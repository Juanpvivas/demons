# T008 — Conservación de mecánicas tras integrar terreno, alcance PC

**Fecha**:2026-10-15. **Rol**:`godot-tester`. **Rama**:`codex/002-monte-calvo-terreno-trincheras`. Estado T006 congelado en [manifestUS1](us1-sha256.json). No hay comportamiento nuevo: regresión existente y contrato, sin RED artificial ni modificación de pruebas/implementación.

## Regresión ejecutada

```text
Godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit/levels,res://tests/unit/systems,res://tests/unit/units -ginclude_subdirs=true -gexit --log-file <evidence>/us2-regression.log
```

Ejecutado en el checkout real con el mismo motor4.7.1mono del baseline. **Código0;13scripts,161/161pruebas,454aserciones,37.24s,0fallos**. [Salida completa](us2-regression.log). Se seleccionaron nivel/spawner, sistemas y unidades por ser las áreas afectadas indirectamente por la instancia visual: tablero, economía, estado, oleadas, daño, munición, moral, recarga y derrota/liberación. No se repitieron aquí los tests aislados de HUD y enemigo; T013 ejecutará la suite completa final.

Dos warnings ya presentes en el baseline: helper `test_double_pooled_node.gd` ignorado por no extenderGutTest y3hijos sin liberar en `test_soldado_enemigo_integration.gd`. No se corrigieron ni debilitaron tests.

## Contrato y archivos protegidos

Se comparó el manifest de T001: **96/97archivos byte idénticos**. El único archivo diferente es `scenes/levels/Nivel_MonteCalvo.tscn`, con estos cambios exactos: `load_steps`6→7; un ext_resource de `MonteCalvoVisual.tscn`; una instancia hija al final sin propiedades adicionales. Al retirar esos tres elementos, el texto original de la escena coincide completo (salvo espacios finales). Se preservan todos los nodos originales, rutas, script, TileSet96×96, posiciones, transformaciones, grupos y geometrías.

La nueva escena no tiene scripts, señales conectadas, input, Control, cuerpos/áreas, colisiones, cámara, navegación, luces, partículas o shader. Ningún costo, estadística, Resource de oleadas, InputMap, autoload, renderer, exportación o versión cambió. `BoardManager` sigue sin límite de región; no se agregó HUD o botón de recarga. Z no se usa como prueba de picking.

## Matriz I1–I9: evidencia disponible y pendiente

| Caso | Evidencia automatizada/inspección | Entrada real |
|---|---|---|
| I1 libre/con fondos |GREEN en nivel: instancia, centro de celda, ocupación y gasto|Ratón/toque pendientes|
| I2 ocupada |GREEN en nivel: sin nuevo soldado ni gasto|Ratón/toque pendientes|
| I3 fondos insuficientes |GREEN en nivel/economía: sin despliegue/gasto y señal de rechazo|Ratón/toque pendientes|
| I4 pickup |GREEN del método de colección y saldo; snapshots muestran pickups delante del terreno|Picking y ausencia de despliegue adicional por el mismo evento pendientes|
| I5 inicial |(576,500), celda(6,5), geometría y escena idénticas; logsV1/V2 yGREEN|No requiere inventar recolocación|
| I6 muerte/liberación |GREEN para inicial, desplegado y reutilización de celda|Sin nueva interacción real acreditada|
| I7 combate/ammo/moral/recarga |GREEN de unidades/integración; observación natural de consumo y bajas; recarga mediante método existente|No se añadió control de recarga|
| I8 oleadas/fin |GREEN de recursos, orden/spawner y escenarios separados de victoria/derrota|Partida completa final corresponde a T014|
| I9 fuera del centro ilustrado |No hay filtro nuevo; scripts y ocupación idénticos|Ratón/toque en coordenadas equivalentes pendientes|

Las pruebas existentes acceden a los métodos de comportamiento. **No prueban por sí solas el trayecto de evento del sistema operativo ni su alineación con stretch.** [Capturas/logsT007](us1.md) acreditan solo render y estado observado.

## Límites operativos

No hay clic OS real acreditado en esta iteración. La consulta UI usada en T001 tardó varios minutos y perdió la ventana de prueba; no se repitió esa exploración, conforme a la instrucción de priorizar el gatePC. No se sustituyó por inyección interna de Godot ni se presentó un test headless como clic manual.

V3/V4 siguen pendientes para esta integración. [Android baseline real anterior al arte](android-baseline.md) está disponible; los toques ADB fueron rechazados por INJECT_EVENTS y no constituyen resultado de interacción. El orquestador reservó comparación Android del arte para el estado final con trincheras, evitando reinstalar incrementos de rutina. iOS físico no está disponible. No se reclama cumplimiento móvil, 60FPS estables o aceptación final SC005–007.

**Resultado del tester**: regresión pertinente y conservación estática superadas; la matriz de entrada real de T008 **no está completa** con estos datos. Se entrega a QA como evidencia PC con pendientes explícitos. Ningún checkbox se marca desde testing, ni se atribuye una aprobación final al simple paso de la suite.

## Reanudación nativa 2026-10-16 — estado corregido a473585

El diagnóstico I4 preexistente, anterior y posterior al arte, se conserva en [T019RED](t019-red.md); su arreglo separado y GREEN/QA constan en [T021](t021-green.md). Son189/189pruebas y532aserciones, importación limpia0 e invariantes95/97 originales; las únicas excepciones protegidas son la instancia visual y el arregloI4 aprobado. No se reconstruyeREDhistórico del arte.

[AndroidEmulator antes/después](native-avd-input.md), aprobado porQA en su vía: I1sobretrinchera15→5/+1, I2ocupada12→12/sinunidad, I3libre0→0, I4UNpickup12→15/singasto/unidad extra, I9másalládelcentro11→1/+1; PRE/POSTPLAYING, mismofix y gestosSDK solo emulador. No equivalen a un dedo físico. [Xiaomi humano](native-android-input.md): I1/I3 observados, I2/I4 físicos no demostrados; se conservan honestamente sin convertir carencia de cobertura en fallo.

RatónPC: la recuperaciónCUA sí produjo I3PLAYING y recogidas de reserva0→3→6→9; los gestos posteriores llegaronyaLOST y no apruebanI1/I2/I4. Se preparan appsDEBUG independientes para iniciohumano, sin otrobucle de sesiones caducadas. [iPadSimulator](native-ipad-setup.md): build/render y registro persistente confirmados, gestoV4 pendiente de sesiónhumana. HardwareiOS no probado. La matrizT008/T009 aún no está completa; ningúncheckbox se cambia desde testing.

### Actualización V4 aprobada — 2026-10-16

QA aprobó el mínimo de entrada iPadSimulator/Compatibility: [FINAL I1/I3](native-ipad-final-human.md), picking básico, geometría y [comparación I4 BASE](native-ipad-baseline-human.md)/[FINAL](native-ipad-final-i4-human.md). En ambas composiciones, mismo arreglo a473585, celda6,4 libre y un pickup3 con reserva12→15, sin gasto ni unidad adicional, PRE/POST PLAYING. La persona operó el frontend; el registro muestra mouse y touch correlacionados como un gesto. No se usaron handlers ni cambios de estado.

I2/I9 iPad siguen no demostrados; AVD aporta su cobertura touch autorizada sin presentarla como iOS. Hardware iOS no probado. El pendiente operativo de entrada es el ratón PC antes/después con fondos/ocupación discriminantes; sus apps temporales tendrán registros independientes y no se han iniciado. Estado por vía en [matriz consolidada](native-validation-matrix.md). No se marcan tareas.

## Estado vigente tras comparación PC — 2026-10-16

QA aprobó el mínimo de ratón humano antes/después: [BASE I2sesión1](native-pc-base-cd-human.md), [BASE I1/I4/I9sesión2](native-pc-base-cd-human-run2.md) y [FINAL I1/I2/I4/I9](native-pc-arte-cd-human.md), con fondos suficientes, ocupación/centro correctos y PRE/POSTPLAYING. I3previo se conserva sin repetir una rama ya comprobada. BASEincluye pickupúnico3 junto al frente con10→13/sinunidad; FINALI4discriminante conserva12→15/sinunidad. Los eventos posterioresLOST permanecenraw pero no acreditan interacciónactiva.

Se completó la evidencia asignada al tester para T008, con [matriz consolidada](native-validation-matrix.md), AVDcontrolado antes/después, muestreoXiaomi, mínimoV4iPad y core189/189 ya aprobados en sus alcances. No significa PASSfísicoI2/I4Xiaomi oI2/I9iPad ni hardwareiOS. Quedan las auditorías de entrega y documentación porQA/orquestador, sin nuevas ejecuciones rutinarias ni checkboxesdesde testing. Las secciones de2026-10-15 y actualizaciones anteriores conservan sus pendientes de aquelmomento como historial.
