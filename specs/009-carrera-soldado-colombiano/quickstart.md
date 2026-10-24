# Validación: Carrera del soldado colombiano

Usar la rama/revisión declarada en el PR y Godot 4.7.1. Preservar cambios locales, apps y datos; preparar variantes de QA en copias aisladas. Esta guía define los recorridos de comprobación; el [alcance local aprobado y sus límites](research.md#alcance-funcional-y-visual-de-i1) distinguen lo observado en cada destino. El cierre exacto se mantiene en [tareas](tasks.md) y el PR.

1. Importar/cargar recursos y exportar con las rutas existentes (`tools/web/export.sh` para Web); confirmar ambos clips nuevos y los demás intactos. No certificar otro renderer o destino desde esa carga.
2. Reproducir realmente cada clip durante al menos tres vueltas, ampliado y a tamaño de juego; comparar contra el arte previo. Inspeccionar ambas transferencias alcance → apoyo y última → primera, anclaje, escala, alfa, identidad y armas. En los cambios A↔B, comprobar además continuidad del tono oliva y de la luz mate, sin destello, nuevo desvanecimiento o recorte.
3. En Web de computador, iniciar partida con entrada real; seguir salida con machete, pausa/contacto/ataque, solicitud de recarga aceptada y regreso con fusil bajo hasta el hogar. Repetir con actores/filas distintos y confirmar que quieto no corre.
4. Comprobar impacto/baja y nuevo intento, con sus consecuencias y limpieza vigentes. Hacer el smoke de apertura, nivel y partida completa; distinguir recorridos manuales de regresión/fixtures y reutilizar sólo evidencia todavía válida.
5. En apps Android/iOS disponibles, repetir el recorrido visual/funcional aplicable con entrada del SO. Identificar app, dispositivo/emulador/simulador, renderer y limitaciones; conservar datos y dejar una única app normal. No probar Web móvil.
6. Ejecutar la regresión existente pertinente de `tests/unit/units/test_soldado_visual.gd`, `test_soldado.gd` y flujos de nivel/recarga afectados. Confirmar suite completa de `tests/unit/` con `python3 tools/ci/run_gut.py`, import/build y exportación Web en la CI exacta del PR.
7. QA independiente contrasta requisito, arte real, recursos, reportes y revisión exacta antes de APROBADO PARA INTEGRACIÓN. Resultados y límites van en el PR; capturas/logs temporales fuera de Git.

La [corrección de color](research.md#corrección-de-color-e-iluminación) tiene revisión de reproducción real y Chrome; el color nuevo no se observó en Android/iPad. La función y los recorridos anteriores no afectados se reutilizan sólo en su alcance original. No convertirlos en pruebas visuales nuevas ni repetirlos por rutina.

Sin probes, benchmarks, nuevas mediciones de rendimiento, despliegue o distribución. Hardware, Mobile/paquete final y publicación siguen pendientes cuando no estén acreditados; no se completan desde simuladores ni por el merge.
