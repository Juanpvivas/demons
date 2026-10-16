# T003 — Toolchain Web estándar4.7.1

**Rol de provisión**: dev-godot; **verificación y documentación**: godot-tester. Entorno preparado fuera del repositorio, sin reemplazar GodotMono. No acredita aún exportación o ejecución Web.

## Procedencia y versiones

El responsable de provisión informó descarga de la [release oficial4.7.1stable](https://github.com/godotengine/godot-builds/releases/tag/4.7.1-stable). El tester volvió a calcular los SHA-256 locales y coinciden con el reporte recibido:

| Archivo | Bytes | SHA-256 |
|---|---:|---|
|Godot_v4.7.1-stable_macos.universal.zip|166,939,858|897cb7f9799796c717ae75f31446aed883dc92b1d6c3b33d893cc7843fff2fa9|
|Godot_v4.7.1-stable_export_templates.tpz|1,280,486,955|86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72|

[Hashes verificados](toolchain-sha256.json). El tester comprobó`--version`, retorno0: **4.7.1.stable.official.a13da4feb**, edición estándar. No se actualizó la versión del proyecto.

## Instalación portable disponible

Raíz temporal local:`/private/tmp/demons-web-tools-pdApeK/portable/`. Ejecutable:`Godot.app/Contents/MacOS/Godot`. Existe marcador`_sc_` junto a la app, fuera del bundle. Templates en`editor_data/export_templates/4.7.1.stable/`:

| Archivo instalado | Bytes | SHA-256 |
|---|---:|---|
|version.txt(4.7.1.stable)|13|233b4ce93ffa3c6bc967b45dcfcdf2d29c7d65878d0af6d2fc7c95661d585013|
|web_nothreads_debug.zip|10,231,638|eb6ca0ca168c405e73b20a4439d6dc048d74ae65eb31cc7675b6bc3cf7ad1815|
|web_nothreads_release.zip|10,246,274|b7b7d7da29fc6cc2f4934fdd26cc571a40e7af57f716ea3eb7e18da720dae28a|

GodotMono sigue presente en`/Applications/Godot_mono.app`; sus presets nativos permanecen idénticos según el baseline. No se guardaron ejecutables,templates o rutas personales en la configuración versionada del proyecto. Las rutas anteriores identifican este entorno de prueba; futuras máquinas usan sus variables de operador.

## Verificación y límites

El estándar completó importación limpia y GUT183/183del juego compartido enT002. No se ejecutó exportaciónWeb, servidor o navegador todavía. La disponibilidad de templates no demuestra que el paquete esté completo ni que se haya usado la variante correcta; T005debe comprobar export real, renderer Compatibility, archivos/PCK y arranque.

Se consultaron GodotPrompter export-pipeline,input-handling,responsive-ui y las skills de testing/2D aplicables. Las opciones concretas provienen del contrato003 y documentación4.7de research: no se copian ejemplos genéricos de butler, hilos, C# o cambio global de renderer. No se usó una actualización automática de SpecKit o del motor.

QA revisa provisión y evidencia antes del uso del presetWeb. Este reporte no marcaT003 ni publica nada.
