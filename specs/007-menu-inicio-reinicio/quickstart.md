# Guía futura de validación de 007

Esta guía se ejecutará al implementar, por los agentes asignados. La preparación documental no ha ejecutado GUT, juego, builds o pruebas de dispositivo. Referencias: [spec](spec.md), [modelo](data-model.md) y [contrato](contracts/match-flow.md).

## Preparación y TDD

1. Confirmar rama/SHA, checkout limpio o cambios preservados y binario Godot 4.7.1 disponible. Para resolver esta feature en un clon sin `.specify/feature.json`, proporcionar `SPECIFY_FEATURE_DIRECTORY=specs/007-menu-inicio-reinicio` a los scripts de preparación; no depende del nombre de rama ni requiere versionar ese archivo local. Importación aislada antes de RED; un fallo de entorno no cuenta como fallo semántico.
2. Tras QA del esqueleto, el tester escribe/ejecuta RED de arranque inerte, transición única y cierre/reset de Managers con escenas reales. Desarrollo implementa por grupos y el tester repite esas pruebas para GREEN y regresiones.
3. Pruebas dirigidas futuras (GODOT_BIN representa el ejecutable real localizado, no uno instalado por esta guía):

```bash
"$GODOT_BIN" --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/game/test_game_root.gd -gexit
"$GODOT_BIN" --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/ui/test_main_menu.gd -gexit
python3 tools/ci/run_gut.py --godot "$GODOT_BIN"
```

La suite completa verifica también HUD, `GameStateManager`, `WaveManager`, spawners, encuadre y precedencia de pickups/selección/despliegue. No cambiar tests para ocultar una regresión.

## Recorridos funcionales

1. Abrir la entrada real del proyecto y esperar 60 s: menú pictórico, título/«Jugar», sin nivel, enemigos, oleadas o cambios económicos. Repetir la espera al regresar desde ambos resultados.
2. Activar «Jugar» mediante ratón/teclado y toque según destino: una partida y ningún gesto económico al atravesar la transición. Inspeccionar cinco soldados cargados, reserva cero e inicial en fila 3.
3. Cubrir las cuatro combinaciones WON/LOST × «Volver a jugar»/«Menú principal», al menos tres ciclos consecutivos por combinación en una sesión. El fixture controlado usa bajas WAVE reales o cruce físico; no asignar el enum terminal como sustituto del recorrido.
4. Preparar estado residual (selección, daño, moral, recarga/regreso, cajas y efectos); comprobar nueva salud/carga/moral, reserva/plazas/cursor y ausencia de objetos o recompensas anteriores. Repetir botones rápidamente/alternarlos y observar avisos tardíos, cero duplicados y cierre antes del nuevo spawn.
5. Comprobar por UI los botones terminales, foco y bloqueo del tablero, resize/aspectos vigentes y márgenes utilizables; no confundir llamada directa al controlador con validación de gesto real.
6. Smoke separado de producción: menú → partida autorada → terminal alcanzable → repetir/menú. Verificar 1 inicial + 99 WAVE con reglas vigentes. Un WON determinista de fixture no acredita una victoria manual de la partida de producción con 100 enemigos; declarar cuál se alcanzó.

## Matriz, rendimiento y entrega

- Web: exportar con el procedimiento existente de `docs/WEB_EXPORT.md`, servir localmente sólo para revisión y probar Chrome de computador. Registrar navegador/versión, computador, renderer, viewport y revisión. No probar navegadores móviles.
- Android/iOS: build/importación e instalación de APK/app nativa de los entornos disponibles; registrar dispositivo/emulador/simulador, renderer y revisión. iPad Simulator usa `.app`, sin presentarlo como IPA física o TestFlight.
- Comparar antes/después espera de menú, carga/transición y gameplay equivalente en destinos disponibles; registrar repeticiones, tiempos/población y límites. Caídas observadas requieren evaluación QA; no atribuir mejora causal ni certificar 60 FPS físicos desde software/emulación.
- QA revisa requisitos y evidencia funcional/visual independiente, build/export y CI de la revisión exacta. Docs consolida sólo lo aprobado; orquestador registra tareas y prepara PR en borrador `Refs #32`.
- Resultados, logs y capturas nuevos quedan en temporales/CI y se resumen en el PR. Restaurar apps normales/datos tras fixtures y limpiar sólo procesos propios al terminar pruebas, preservando sesiones que la persona haya pedido mantener.
- No distribuir, cambiar firma/versiones/presets o despachar workflows. Publicación, hardware/artefacto final, 004/T039, 005/T071 y pendientes de 006 conservan su gate separado.
