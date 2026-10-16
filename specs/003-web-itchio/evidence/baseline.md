# T002 — Línea base previa a la configuración Web

**Rol**: `godot-tester`. **Rama**: `codex/003-web-itchio`. **Origen**: `b670d86`, con terreno y trincheras de002. Política vigente: AGENTS y constitución2.0.0. Se leyó el plan/tareas final tras aprobación de preparación/T001. No se edita ni cierra002.

## Conservación

Antes de ejecutar se guardó copia aislada en`/private/tmp/demons-web-baseline-2j6an1k9/project`, sin caché`.godot`. [Manifest](protected-sha256.json): **110 archivos** de escenas, gameplay, arte, Resources, pruebas, proyecto/presets y workflows existentes. Al terminar, **110/110 siguen idénticos** en el checkout compartido.

[Segmentos protegidos](baseline-sections.json) registra además hashes separados de InputMap y presets Android/iOS. El estado inicial tiene Mobile global y **ningún preset Web**. Los únicos archivos de este rol están en este directorio de evidencia, excluido por`.gdignore`. No se modificaron implementación, pruebas, checkboxes, rama o commits.

## Ejecuciones nativas reales con Godot estándar

Ejecutable: Godot estándar4.7.1stable del [toolchain](toolchain.md), versión comprobada con`--version`: **4.7.1.stable.official.a13da4feb**, retorno0. La importación y GUT se ejecutaron una vez sobre la copia aislada byte idéntica; es ejecución **nativa headless**, no navegador.

```text
"$GODOT_WEB_BIN" --headless --path <copia-aislada> --import --quit-after 2 --log-file <evidence>/baseline-import.log
"$GODOT_WEB_BIN" --headless --path <copia-aislada> --script addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs=true -gexit --log-file <evidence>/baseline-gut.log
```

`GODOT_WEB_BIN` representa el binario estándar ya preparado; aquí se usa para verificar GDScript nativo antes de Web. `--quit-after2` expresa frames de proceso, no milisegundos. No se añadió un preset para ejecutar estas comprobaciones.

- **Importación desde cero: retorno0**, sin errores de carga/parser/importación en [log completo](baseline-import.log).
- **GUT9.7.1: retorno0**, **15scripts,183/183pruebas,496aserciones,37.4s**, sin fallos. [Salida completa](baseline-gut.log). Cubre daño, munición, moral, recarga, estado terminal, oleadas, ocupación, economía, nivel/spawner yHUDaislado.
- Persisten los **3 avisos conocidos**: helper`test_double_pooled_node.gd` ignorado porque no extiendeGutTest;7hijos sin liberar en`test_enemigo.gd`;3en`test_soldado_enemigo_integration.gd`. No se alteraron fuentes ni pruebas para ocultarlos.

Es regresión de comportamiento existente; no se fabrica RED ni se atribuyeTDDretroactivo. Este resultado no prueba compatibilidadWeb, picking real, HUD integrado o los pendientes constitucionales de002.

## Inventario de entorno, sin abrir apps

| Entorno | Disponibilidad observada |
|---|---|
| Chrome escritorio macOS |Instalado155.0.8059.84; proveedor CUA/extensión disponible|
| Safari macOS |Instalado26.6.2(build21624.5.1.11.3); todavía no probado|
| Firefox |No instalado en la ruta estándar; no probado|
| Xiaomi/Chrome Android |Inventario de cierre: [{"state": "device", "details": {"product": "vili_eea", "model": "2107113SG", "device": "vili"}}]. Android 14; Chrome 154.0.8037.94. No se abrió la app ni se enviaron toques.|
| Navegador iOS físico |No disponible en esta preparación; no probado|

La consulta de cierre del teléfono está fechada **2026-10-16T03:16:12.564492+00:00**, con seriales omitidos en [inventario](device-inventory.json). Una app instalada o proveedor accesible no constituyePASSde navegador. No se abrió una página, servidor, appAndroid o previewWeb duranteT002.

## Preparación de estados controlados para US2

W05 necesita una celda libre con reserva observada<10. W04 exige una celda ocupada **con reserva observada>=10**, antes y después; repetir tras gastar10de12no distingue ocupación de insuficiencia. W02 registrará reserva, pickups y número de soldados para detectar un posible segundo efecto en el mismo gesto, incluyendo el caso con fondos suficientes. Cada caso necesita coordenadasCSS/píxeles/celda y una sola interacción real.

El saldo no está visible en el HUD actual. Se prevé instrumentación de observación en una copia temporal, sin introducir controles de producción ni cambiar las reglas; después se repite sobre el build de entrega. Si la evidencia no permite concluir, se marcaNOTRUN. No se crea instrumentación ni se corrige input durante este baseline. Un fallo real requerirá reproducción/RED antes de desarrollo.

## Entrega a QA

T002 proporciona snapshot, importación/GUT nativos e inventario. No hay exportaciónWeb ni browserPASS todavía; esos resultados pertenecen aT004/T005 y etapas siguientes. Los pendientes de002 conservan sus documentos originales. Sin tareas marcadas por el tester y sin repetir la suite tras este resultado válido.
