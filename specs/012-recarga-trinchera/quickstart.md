# Verificación prevista — 012-I1, revisión visual

Guía del [spec vigente](spec.md) y [contrato](contracts/trench-reload.md), no registro de pruebas ejecutadas. Rama `codex/012-recarga-trinchera`, [Issue #49](https://github.com/Juanpvivas/demons/issues/49), [PR #50](https://github.com/Juanpvivas/demons/pull/50). T001–T012 y la prueba humana Xiaomi corresponden al botón anterior; T018 delimita el [alcance propio de la revisión roja](spec.md#alcance-de-la-aprobación-funcional). Resultados/variantes en temporales y PR, sin archivos nuevos de evidencias en Git.

## 1. Preparación y TDD

1. Confirmar checkout, tareas y aprobación T013; consultar GodotPrompter de testing/UI/input/2D/Tween. No ejecutar `speckit-implement`.
2. Escribir RED mediante la interfaz Button importable existente para texto vacío, nueva área sobre trinchera y estados visuales. Guardar consultas de capacidades nuevas sin preload de script inexistente; fallo de parser/import no demuestra RED. QA revisa antes de implementar. T002 neutral pertenece sólo a la historia anterior y no debe repetirse como setup de esta revisión.
3. Tras desarrollo, repetir RED y regresión de HUD, selección/pickup/input, framing, recarga/retorno y GameRoot. Adaptar sólo expectativas de presentación sustituidas y conservar protecciones de identidad/economía/ciclo. Suite completa/importación con `python3 tools/ci/run_gut.py` y CI exacto del PR.

## 2. Casos de aceptación vigentes

| Caso | Verificación |
|---|---|
| R01 · Señal | Dueños cargados normales; agotar carga sin selección muestra rojo en su propia trinchera, incluso fuera. Repetir filas 1/3/5 y cinco simultáneos; cero texto/cartel/botón visible. |
| R02 · Acción directa | Selección vacía y luego otro seleccionado: tocar HOME/arte real ordena sólo al dueño correcto, un cobro y carga repuesta; rojo retirado inmediatamente. No pulsar exclusivamente el centro del Button como sustituto de HOME. |
| R03 · Conservación | Herido/con moral, dentro/fuera: misma vida/moral y stats; regreso físico vulnerable sin ofensiva antes de HOME. Texto informativo del panel sin botón antiguo. |
| R04 · Tenue/pulso | Sin fondos rojo tenue estático; al añadir fondos pulso suave mientras elegible. Muestrear más de un ciclo y repetir señales: una sola animación/copia, sin saltos o parpadeo de trinchera completa. Gasto puede pasar otros hogares a tenue. |
| R05 · Bloqueos e identidad | Pausar sin pausar SceneTree detiene pulso/orden; reanudar sólo si elegible. Terminal/aceptación/retorno sin cobro adicional. Press→muerte/reemplazo→release y callback antiguo no actúan sobre sucesor. |
| R06 · Entrada | Ratón/toque con emulación: máximo una orden por gesto. Dentro del hotspot activo, incluso deshabilitado, no recoger/seleccionar/desplegar debajo. Fuera, pickup conserva prioridad. Hogar cargado mantiene selección normal. |
| R07 · Presentación/resize | Cinco zonas sobre arte/HOME tras resize, mínimo táctil112×48 y frontera correcta, sin vecinos; rojo sólo en las dos piezas de cada trinchera, nunca actor/HP/HUD. Preservar textura/alpha/oclusiones y hotspot inmóvil durante pulso. |
| R08 · Ciclo | Recargar, morir, retirar, reemplazar, cerrar, menú/Retry normalizan efectos y matan animaciones; no copias/conexiones/controles útiles del intento anterior. Un hogar no altera el brillo de otro. |

## 3. Smoke real por destino disponible

- **Chrome de computador**: exportar con `tools/web/export.sh` y motor estándar oficial requerido. Producción inicio→Jugar→partida/terminal→menú; R01–R08 pertinentes. Escenario temporal declarado para cinco vacíos y comparación visual de tenue/pulso/normal, distinto de campaña de 100 enemigos. Resize visible1152×648/960×540; declarar canvas/DOM/DPR y distinguir viewport lógico instrumentado por GUT. No navegador móvil.
- **Android app instalada**: verificar APK/firma/metadatos con herramientas existentes; conservar beta y datos mediante copia QA separada cuando corresponda. Registrar dispositivo/emulador y renderer real. Observar efecto/entrada disponibles, HOME/retorno/panel/ciclo; no cambiar seguridad ni borrar datos para forzar gestos. La persona puede aportar observación humana de esta revisión identificando la app, sin convertirla en FPS/certificación de publicación.
- **iOS app o `.app` de Simulator**: verificar fuente/empaquetado y recorrido disponible; registrar bootstrap, renderer y tamaño. Menú o Compatibility/software no acreditan gesto, IPA final o hardware. Límites concretos de control se declaran, no se sustituyen por Web móvil.
- Conservar el cruce previo aviso de oleada/primera barra de vida como límite si se observa; diferenciarlo de cualquier solape nuevo causado por el efecto. Registrar caídas reales de rendimiento con su alcance sin certificar FPS desde captura o emulación.

QA independiente contrasta spec/código/pruebas, visual/input/build, documentación y CI antes de APROBADO PARA INTEGRACIÓN. No incluye distribución, nueva versión, campaña 006 ni extensión de la excepción consumida de beta build4; pendientes físicos/publicación anteriores permanecen abiertos.
