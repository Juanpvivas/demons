# T010 — Generación y revisión del paquete Web

Fecha local 2026-10-15. Resultado del tester: **PASS de generación local y
arranque del ZIP extraído**, sujeto a QA. La interacción US2 y el smoke manual
completo siguen pendientes; no autoriza difusión a testers externos ni afirma
publicación en itch.io.

## Dos generaciones reales

Se ejecutó exactamente `tools/web/export.sh` con `GODOT_WEB_BIN` apuntando al
estándar portable 4.7.1 descrito en [toolchain.md](toolchain.md):

1. Checkout compartido limpio en `ed446d9ab4c1e84e3ef84709e0fe5f357848dd76`.
   Script **retorno 0**; import/export reales sin ERROR/SCRIPT ERROR.
2. Clone Git local separado, detached en la misma revisión, estado limpio y
   **sin `.godot` ni `build` antes de ejecutar**. Script **retorno 0**;
   importación desde cero y export completos. Ruta local:
   `/private/tmp/demons-web-package-94yi0goy/project`.

No se cambió la rama compartida ni se repitió GUT: el comportamiento fuente
no cambió desde el baseline 183/183. La revisión posterior `7aaff2d` contiene
solo aclaraciones documentales excluidas del paquete; no requiere otro export.

| Generación | ZIP bytes | SHA256 | Estado registrado |
|---|---:|---|---|
| Checkout | 14 891 347 | `e12501af7950c494a47f07ddffdc56ec2ab3e378fe88b6748a7200840831daa1` | `source_dirty=false`, `build_version=ed446d9` |
| Copia limpia | 14 891 348 | `0ee3096086d58b1f78c3ffd49e78286adf73f08d9d080e32da825b45f83c009b` | `source_dirty=false`, `build_version=ed446d9` |

Los ZIP **no son idénticos byte a byte**: difiere `index.pck`; los otros once
miembros tienen idénticos hashes. Se acredita repetición funcional del
procedimiento y trazabilidad de cada salida, no builds binariamente idénticos.

Evidencia: [verificación independiente](package-verification.json),
[setup limpio](package-clean-setup.json),
[manifest checkout](package-checkout-web-manifest.json),
[manifest limpio](package-clean-web-manifest.json),
[import checkout](package-checkout-web-import.log),
[export checkout](package-checkout-web-export.log),
[import limpio](package-clean-web-import.log),
[export limpio](package-clean-web-export.log).

## Contenido exterior y PCK

Ambos ZIP se extrajeron en directorios nuevos. Los doce miembros son nueve
archivos del exportador (HTML/JS/WASM/PCK/iconos/worklets) y tres avisos en
`licenses/`. `index.html` está en raíz, sin carpeta contenedora. No incluyen
manifest, logs, sidecars `.import`/`.uid`, pruebas, GUT, documentación interna,
herramientas, configuración de agentes/CI ni credenciales.

Se recalcularon tamaño y SHA256 de **cada archivo extraído y cada ZIP** contra
su manifest: todos coinciden. Los tres avisos distribuidos son copias exactas
de `tools/web/licenses/`: GODOT_LICENSE, GODOT_COPYRIGHT y NOTICE. NOTICE
conserva procedencia del arte sin asignar una licencia nueva al juego.

Tamaño extraído **44 651 665 bytes**, 12 archivos, archivo mayor WASM de
39 513 091 bytes y nombres cortos: dentro de los límites registrados en
[research.md](../research.md#5-paquete-y-entrega). Esta revisión comprueba
presencia/integridad de los avisos, no añade una licencia propia.

Se montó cada **PCK extraído** con Godot en un directorio temporal vacío y se
listó `res://`: **retorno 0 sin errores en ambos**, 78 rutas iguales, clases,
autoloads, texturas, escenas, AmmoPickup y las diez oleadas presentes; ningún
recurso interno excluido. [Inventario checkout](package-checkout-pck-inventory.json),
[inventario limpio](package-clean-pck-inventory.json),
[log checkout](package-checkout-pck.log), [log limpio](package-clean-pck.log).

## Arranque desde lo extraído

Servidor local ligado a `127.0.0.1:8061`, limitado a copias de las dos carpetas
extraídas; no sirve la raíz del repositorio. Chrome 155.0.8059.84 visible:

- `http://127.0.0.1:8061/checkout/`: nivel, arte, combate y pickups visibles;
  canvas 1152×648; [consola/dimensiones](package-checkout-browser.json),
  [captura](package-checkout-browser.jpg).
- `http://127.0.0.1:8061/clean/`: mismo arranque del ZIP generado desde cero;
  [consola/dimensiones](package-clean-browser.json),
  [captura](package-clean-browser.jpg).

Consolas de las cargas nuevas sin errores críticos ni archivos ausentes:
WebGL2 / Compatibility, single-threaded, sin GDExtension. No se inyectó lógica
de observación ni input en estas comprobaciones de arranque.

## CI y conservación

Se revisó `.github/workflows/export-web.yml`: usa el mismo script, Godot
estándar 4.7.1 con templates, permisos `contents: read`, artefactos ZIP/manifest
y logs; sin publicación ni credenciales de portal. **Run remoto NOT RUN**:
se validaron localmente sus pasos de import/export/empaquetado, no el runner
Ubuntu ni la descarga desde la acción de terceros.

Contra los 110 hashes T002 al cerrar el reporte: **107/110 idénticos**. Difieren
las dos configuraciones Web autorizadas y los comentarios de `.github/workflows/ci.yml`
aclarados en `ed446d9`; quitando comentarios y líneas vacías, su contenido es
idéntico. No cambió la ejecución GUT/import del CI ni los deploys móviles.
Gameplay, escenas, arte y tests protegidos siguen iguales.
Candidato local: `build/demons-web.zip` y
`build/web-manifest.json`; ambos ignorados por Git y fuera de documentación
versionada. US2, Android Web, rendimiento y aceptación global siguen abiertos.
