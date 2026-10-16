# T013 — Regresión completa del estado final

**Fecha**:2026-10-15Bogotá. **Rol**:`godot-tester`. **Rama**:`codex/002-monte-calvo-terreno-trincheras`. EstadoT011 [identificado por hashes](final-sha256.json). Arte sin cambios de lógica: no se crea RED artificial ni se reconstruyeTDD histórico.

## Ejecuciones reales

```text
Godot --headless --path . --import --quit-after 2 --log-file <evidence>/final-import.log
Godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs=true -gexit --log-file <evidence>/final-gut.log
```

Mismo ejecutable4.7.1mono delbaseline; desde la raíz. **Ambos retornaron0**. La importación usó el caché existente, sin borrarlo; carga/render reales de las escenas y texturas completados enT012. [Importación](final-import.log), [GUTíntegro](final-gut.log).

**15scripts,183/183tests,496aserciones,37.388s,0fallos**. Mismas cifras de tests/aserciones que el baseline, sin cambiar pruebas. Cubre daño, munición, moral, recarga, victoria/derrota, oleadas, economía, ocupación, spawner, nivel yHUDaislado. La suite no acredita por sí sola entradaOS/picking/legibilidad o integración delHUD.

Persisten los3warningsdelbaseline: helper`test_double_pooled_node.gd` ignorado por no extenderGutTest;7hijos sin liberar en`test_enemigo.gd`;3en`test_soldado_enemigo_integration.gd`. No se silenciaron o repararon desde esta tarea visual.

## Conservación verificada

Del manifestT001, **96/97archivos idénticos**. Solo cambió`Nivel_MonteCalvo.tscn`: load_steps6→7, ext_resourcevisual e instancia final. Eliminando esas tres adiciones, el texto original coincide completo salvo espacios finales. Todos los nodos y propiedades originales permanecen: actores, TileMap96×96, posiciones/colisiones, spawn/defensa, script, grupos y señales.

Los nuevos recursos se limitan al arte y la escena visual; no hay scripts/input/física/UI/cámara/shaders/partículas/navegación. Proyecto, InputMap, autoloads, Resources de balance/oleadas, exportaciones, versión y firma sin cambios. El [manifestfinal](final-sha256.json) volvió a comprobarse después de la ejecución sin diferencias.

Se preservaron copia original, US1sintrincheras y final en directorios temporales distintos. El desarrollador mantuvo congelada la escena durante las comprobaciones. No se modificaron implementación o tests; evidencia/imports son el único trabajo deltester. No se marcan tareas, ni se confunde esteGREENde regresión con validación final de la matriz de entrada/plataformas pendiente.

## Importación adicional desde cero, sin caché del proyecto

Para completar explícitamente el criterio de importación limpia, se creó una copia final **sin directorio `.godot`** en `/private/tmp/monte-calvo-t001-0pulm9d5/final-clean-_r7w1yu6/project`. Se conservaron los PNG e imports fuente; no se borró ni alteró la caché del checkout compartido.

```text
Godot --headless --path <copia-final-sin-cache> --import --quit-after 2 --log-file <evidence>/final-clean-import.log
```

**Retorno 0**, sin errores de parser/carga/importación en el [log completo](final-clean-import.log). La caché nueva contiene los tres `.ctex` generados: terreno 1,998,276 bytes; montañas 974,124 bytes; atlas 1,664,902 bytes. Los **10/10 archivos del manifest final** comparados después de importar permanecen idénticos. [Resumen verificable](final-clean-import-summary.json).

Se ejecutó una sola importación adicional. No se repitieron GUT ni capturas válidas: sus fuentes finales seguían idénticas. Esta comprobación completa la evidencia técnica de importación desde cero; no resuelve los pendientes globales de entrada o dispositivos.
