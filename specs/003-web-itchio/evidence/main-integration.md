# PR #15 — integración de main verificada

2026-10-16, Bogotá. Verificación de integración por `godot-tester`; sin cambios
nuevos de gameplay, pruebas artificiales, publicación o merge del PR.

## Fuente y reproducción

- Snapshot limpio **`7309d8fa211637afbd68c4d73181758ee2840a93`**, merge de Web
  `9e32f1a42c42bc28719270ca3e7d7b1e2c6b8ed7` y main
  `0cc19d070caf16f8586f74d504509fbb39efbcee`.
- Clon local aislado, sin `.godot` ni `build` iniciales; estado Git limpio antes
  y después. Motor estándar **4.7.1.stable.official.a13da4feb**, template sin hilos
  ya existente; hashes y resultados en [manifiesto mínimo](main-integration-manifest.json).
- Reproducir sobre ese commit en un clon limpio, con motor/templates estándar
  4.7.1: `GODOT_WEB_BIN=/ruta/Godot tools/web/export.sh`. El script versionado,
  sin modificaciones, ejecuta import limpio, export release y empaquetado.
- Retorno final **0**, sin `ERROR`/`SCRIPT ERROR` de importación/exportación.
  Primer intento sandbox terminó en 1 por lectura de certificados macOS;
  sus logs se conservaron. Repetición limpia fuera del sandbox pasó, sin
  modificar certificados, permisos, motor ni proyecto.

## Resultado y comparación

- **364/364** archivos de autoloads/core/escenas/Resources/arte/tests/addons
  idénticos a ambos padres. InputMap y opciones Android/iOS conservados;
  Web conserva Compatibility, sin hilos, extensiones ni PWA.
- ZIP nuevo **14 893 307 bytes**, SHA256
  `f3b60dfa20ddbc277c12335a10ab43f92b2f676474659a560dfc6c8ab515dc78`.
  ZIP anterior aprobado: SHA256 `205d3916f21ce8c2b29eaf4bbbd804908dab7e9c93356355f4a335212eabfd71`.
- **12 miembros**, `index.html` en raíz; tres licencias correctas; **78 recursos
  PCK**, cero pruebas/herramientas/documentos internos o credenciales incluidos.
  **11/12 miembros ZIP** idénticos; solo `index.pck` difiere.
- **72/78 recursos PCK** y configuración compilada exactos. Los otros seis
  son escenas compiladas: únicamente cambia el vector de `unique_id` de
  **51 nodos** generado al exportar. Se verificaron bytes anteriores/posteriores
  al rango, valores uint32 y su correspondencia con los IDs leídos por Godot.
  Las seis escenas completas son iguales al normalizar solo esos IDs y los
  aliases de recursos externos generados al guardarlas para inspección.
  Nombres, rutas, propiedades, conexiones y recursos se conservan.
- QA rederivó independientemente este diagnóstico y aprobó reutilizar el
  [smoke e interacción Web anteriores](final-validation.md). No se repitieron
  navegador, teléfono ni GUT local por un merge documental; CI del HEAD final
  debe confirmar la suite completa y la importación. **CI aún NOT RUN al redactar**.

## Evidencia y conservación

Este informe y el manifiesto conservan la prueba mínima versionada. Los logs,
inventarios, scripts de inspección, escenas binarias/textuales y el fallo de
sandbox están en `review-diagnostics.tar.gz` (hash/tamaño en el manifiesto),
fuera de Git, en la carpeta temporal `demons-pr15-integration-ybwsuwu8`.
La copia temporal no es archivo permanente: conservar ese diagnóstico local
durante la revisión o regenerarlo desde la revisión y comando anteriores.
CI adjuntará ZIP/manifiesto/logs con su retención configurada de **14 días**;
no se depende de ellos como única evidencia ni se promete conservación indefinida.
El orquestador enlazará el run real del HEAD final en el PR antes de declararlo listo.

La equivalencia permite conservar los veredictos históricos acotados. No amplía
soporte a Firefox/Safari/Web iOS, no certifica 60 FPS sostenidos en Web y no
extiende a 003 la referencia provisional Xiaomi autorizada solo para 002.
