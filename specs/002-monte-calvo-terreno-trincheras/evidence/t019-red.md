# T019 — RED nativo adoptado: recoger sin desplegar

2026-10-16. Tester. Rama `codex/002-monte-calvo-terreno-trincheras`, base `b670d86`.
La preparación de la adenda T019–T022 fue aprobada por QA antes de materializar
estas pruebas. Implementación todavía **sin corregir**, SHA256 del nivel
`2420d7100eb852b6dee0521df56015784a5ac0a0b2af0274b3fa6d2b3fe27e6b`. No se importa el fix de003 ni se atribuye RED al trabajo histórico.

## Fuente y adopción sin ejecución repetida

Se copiaron **byteidénticos** los seis casos de175líneas y UID desde
`4a2915c5ceb075fbaa3ec7ce1e129a4c34aa497a` a `tests/unit/levels/test_pickup_input_routing.gd` y su `.uid`.
SHA256 del test `ac55c141e87f74939d3432dccf89caa62a888b149e0db69df4f8ae1ef9e34dbd`.
La copia en diagnóstico temporal usa exactamente los mismos bytes. Los
comentarios de procedencia003 se conservaron; en002 cubren I4 y la conservación
de despliegue I1 para mouse normal y mouse emulado. No se añadieron nuevos
frameworks ni controles al juego. No se ejecutó de nuevo por rutina al copiar.

Se adopta la ejecución realizada **hoy**, antes de modificar implementación,
en dos copias aisladas: baseline sin arte y final002. Es RED actual con evidencia
existente reproducible, no reconstrucción de un RED de tareas antiguas.
[Resumen](resume-i4-summary.json), [baseline](resume-i4-baseline.log),
[final](resume-i4-final.log), [fuente de diagnóstico](resume-i4-imported003.gd).

## Procedimiento y resultado

Godot `4.7.1.stable.mono.official.a13da4feb`, GUT9.7.1. Copias:
`/private/tmp/monte-calvo-validation-002-v333ghu2/baseline` y `/final`.
Comandos exactos/códigos/horas en `execution-results.json` y hashes originales
en `manifest.json`, dentro del mismo directorio temporal.

1. Importar cada copia con `--headless --path <copia> --import --quit-after 2`:
   ambas **EXIT0**, sin impedir llegar a las aserciones.
2. Ejecutar `--headless --path <copia> -s addons/gut/gut_cmdln.gd
   -gtest=res://tests/unit/levels/test_pickup_input_routing.gd -gexit`.
3. Fixture: SubViewport propio, picking activado, nivel real, pickup único3,
   reserva12, celda2,2libre. Eventos enviados mediante `Viewport.push_input`,
   sin llamar directamente handlers de nivel/pickup.

| Grupo | Esperado | Baseline sin arte | Final con arte |
|---|---|---|---|
| Controles picking, mouse0/emulado−1 | Un pickup recogido,12→15 |PASS/PASS|PASS/PASS|
| I4 mouse0/emulado−1, pickup y nivel |12→15, sin gasto10/unidad, celda libre|FAIL/FAIL|FAIL/FAIL|
| I1 mouse0/emulado−1, sin pickup |12→2, una unidad, celda ocupada|PASS/PASS|PASS/PASS|

Ambas ejecuciones: **4/6PASS,2FAIL;28/36aserciones;EXIT1**. En los dos fallos,
la aserción sí se ejecuta: reserva **12→2→5**, un único pressed al pickup,
soldados **1→2** y celda ocupada. No es error de sintaxis/importación/entorno:
los controles prueban que picking y despliegue explícito funcionan.

El script del nivel es byteidéntico antes/después del arte. El fallo ya existía
sin decoración y bloquea I4; no se atribuye al arte. T020 debe corregir solo
la prioridad de recogida conservando el despliegue normal/emulado. T021 debe
pasar los mismos seis casos, suite pertinente/completa y verificación real;
QA decide su aceptación. Este reporte no marca checkboxes ni aprueba el fix.

## Límites

`Viewport.push_input` acredita el dispatch/picking del motor en ese fixture.
Mouse emulado no equivale a dedo físico; headless no prueba alineación visual
con stretch ni interacción en emuladores. Esos casos se verifican por separado
con los dispositivos autorizados. No se mutó gameplay para hacer fallar la
prueba ni se debilitó ninguna aserción histórica.
