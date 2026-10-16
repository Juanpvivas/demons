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
