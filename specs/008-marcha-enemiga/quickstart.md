# Quickstart: validar la marcha enemiga

Guía para los agentes tras aprobar la preparación; no informa pruebas ejecutadas. Rama `codex/008-marcha-enemiga`, base `90cc824`; [spec](spec.md) y [contrato](contracts/advance-visual.md).

1. Confirmar checkout y cambios locales. Usar copia aislada y procesos propios; conservar servidores, apps y datos existentes. Consultar GodotPrompter correspondiente antes de escribir/revisar recursos.
2. Importar/cargar el atlas real y `enemigo_lateral_frames.tres`: transparencia, regiones completas, ausencia de vecinos/halos y referencias válidas. Verificar que sólo cambian `advance` y su arte/importación; escena, lógica, stats, contacto y caída siguen iguales.
3. Observar varios ciclos ampliados y a tamaño de juego, sobre el suelo de Monte Calvo: apoyos de ambas piernas, fases intermedias, balanceo coherente y unión final→inicio sin salto. Revisar varios enemigos/filas y clips de contacto/caída junto al arte nuevo.
4. En una partida real observar avance → bloqueo/contacto, impacto y baja; comprobar reaparición por pool y «Volver a jugar». Un fixture acotado puede cubrir casos difíciles, declarado aparte de la producción y sin forzar un resultado como sustituto del recorrido.
5. Ejecutar la regresión existente pertinente de `tests/unit/enemies/test_enemigo_visual.gd` y los actores/pool afectados; confirmar la ruta real antes de usarla. La suite completa `tests/unit/` puede acreditarse con `python3 tools/ci/run_gut.py` o CI automática de la revisión exacta. No crear pruebas de texto o número de frames para fabricar RED de arte.
6. Comprobar exportación Web y lectura funcional/visual por navegador de computador y app Android/iOS disponibles, identificando cada destino/variante. Antes de instalar una copia QA, respaldo fresco de app/datos; al terminar, retirar extras y conservar sólo la app normal y sus datos. No probar navegadores móviles ni distribuir.
7. Reportar resultados y límites a QA, que evalúa integración independientemente. No ejecutar probes, benchmarks, comparaciones FPS ni nuevos lotes de 006: la persona dejó ese trabajo hasta aquí por ahora. No certificar publicación ni resolver pendientes físicos desde estas comprobaciones.
8. Tras QA, consolidar procedencia y documentación útil; conservar registros/capturas nuevos en temporales o CI. PR en borrador, sin promoción o merge automático.
