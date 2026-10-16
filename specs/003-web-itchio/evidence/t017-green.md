# T017 — GREEN de input y nuevo candidato Web

2026-10-15 local. Resultado: **GREEN código y Web escritorio**, validación
Android físico y resto de matriz T007 todavía pendientes. Se conservan los
RED originales [T015](t015-red.md) y [W03 emulado](t017-w03-red.md).

## Pruebas sin debilitar aserciones

La entrega enmendada solo modifica el enrutamiento en
`scenes/levels/nivel_monte_calvo.gd`: query de pickups antes de desplegar,
dejando recoger al picking. No conserva la guarda que bloqueaba el mouse
emulado. `ammo_pickup.gd`, InputMap, escenas, balance, Resources y arte no
cambiaron. [Invariantes/hashes](t017-invariants.json).

- Mismas seis pruebas aprobadas: **6/6,36 aserciones,1.565s, retorno0**;
  [log focal](t017-green-focused.log). Mouse normal/emulado: recoger12→15,
  sin unidad/gasto extra; despliegue explícito12→2 y exactamente una unidad.
- Suite completa: **189/189,532 aserciones,16 scripts,38.194s, retorno0**;
  [log completo](t017-green-full.log). Mismos tres avisos previos: helper que
  no extiende GutTest, siete hijos sin liberar en enemigo y tres en integración.
- Las cuatro T015 originales siguen como prefijo byteidéntico del archivo
  ampliado; no se cambiaron expectativas para obtener GREEN. SHA final del
  test `ac55c141e87f74939d3432dccf89caa62a888b149e0db69df4f8ae1ef9e34dbd`.
- Import estándar en raíz para UID: [retorno0](t017-import-uid.log). UID
  agregado del test, incluido antes de exportar la copia limpia.

## Candidato reconstruido desde cero

Clone detached limpio en **4a2915c5ceb075fbaa3ec7ce1e129a4c34aa497a**,
sin `.godot`/`build` previos: [setup](t017-clean-setup.json). El script
`tools/web/export.sh` realizó import limpio y export reales con **retorno0**;
[import](t017-web-import.log), [export](t017-web-export.log).

ZIP candidato `build/demons-web.zip`: **14 893 307 bytes**, SHA256
`205d3916f21ce8c2b29eaf4bbbd804908dab7e9c93356355f4a335212eabfd71`.
Manifest exterior [t017-web-manifest.json](t017-web-manifest.json) registra
`source_dirty=false`, revisión4a2915c y estándar4.7.1. Esto describe el checkout;
no implica que la aceptación global ya esté completa.

[Verificación](t017-package-verification.json): doce miembros, index.html en
raíz, 44 652 145 bytes extraídos, hashes y tamaños de cada miembro correctos,
tres licencias exactas y ausencia de sidecars/internos. El ZIP revisado se
copió idéntico a `build/` del checkout compartido. No se publicó en itch.io.

PCK extraído: **78 recursos**, sin internos; clases/escenas/pickup y diez
oleadas presentes. [Inventario](t017-pck-inventory.json), [log](t017-pck.log),
retorno0 sin errores. La configuración de física2D consultada es
`physics/2d/run_on_separate_thread=false`. No se alteró esa configuración.

## Confirmación real en Chrome

Chrome155.0.8059.84 visible, clic CUA de navegador documentado, sin llamadas
directas a lógica. En copia observada con fuente de producción exacta y
marcadores sin input, **todos los PRE/POST siguientes están PLAYING (0)**:

| Caso | Resultado registrado |
|---|---|
| W05, A libre/reserva0 | Rechazo, saldo0 y un soldado sin cambio |
| W04, B ocupada/reserva12 | Saldo12, un soldado; ningún gasto ni duplicado |
| W02, un pickup natural/reserva12 | Gesto7 en576,452 a27.8s: **12→15, soldados1→1**, celda libre |
| W03, A libre tras recoger | Gesto8 en240,528: **15→5, soldados1→2**, celda2,5 ocupada |

[Logs aceptables durante partida](t017-observer-playing.json),
[W02 antes](t017-playing-w02-before.jpg),
[W02 después](t017-playing-w02-after.jpg),
[W03 después](t017-playing-w03-after.jpg).
El ensayo anterior [t017-observer-desktop.json](t017-observer-desktop.json)
llegó tarde a esos dos gestos y estaba LOST: se conserva como evidencia
limitada, no se usa para afirmar que ocurrieron durante una partida activa.

En el **ZIP extraído sin observador**, se repitió la secuencia: el amarillo
desaparece sin crear unidad y el gesto explícito posterior en A crea una.
[Acciones/consola](t017-production-actions.json),
[antes recogida](t017-production-w02-before.jpg),
[después recogida](t017-production-w02-after.jpg),
[despliegue explícito](t017-production-w03-after.jpg). Sin errores de consola.
Esta confirmación es visual: no adjudica saldo/estado ocultos al build sin HUD.

## Pendientes conservados

La instrumentación exacta [t017-observer-readonly.gd](t017-observer-readonly.gd)
vive exclusivamente en copia temporal. Labels IGNORE/focusNONE y observación
de FPS/gestos no forman parte del paquete candidato. Un wrapper temporal
[de inicio manual](t017-phone-gate.html) permite leer instrucciones antes de
cargar el iframe. Las métricas instrumentadas y rAF del contenedor se
reportarán por separado; no certifican60FPS constitucionales.

El toque físico Chrome Android, resize con clic, iframe, retorno de pestaña,
smoke terminal y métricas completas continúan por sus casos T007/T012. No se
anuncian soporte universal, ejecución CI remota ni cierre histórico de002.
