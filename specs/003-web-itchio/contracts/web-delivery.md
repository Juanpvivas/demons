# Contract — ejecución y entrega Web

## Frontera de publicación

El repositorio entrega `build/web/index.html`, sus archivos compañeros y un ZIP
listo para cargar manualmente. No autentica contra itch.io, usa `butler`, crea
cuenta, cobra, sube el paquete ni publica página. CI adjunta un artefacto de
compilación descargable, con revisión y versión; no un deploy.

## Formato del paquete

```text
<archivo>.zip
├── index.html
├── index.js
├── index.wasm
├── index.pck
└── demás archivos requeridos por el exportador estándar
```

- `index.html` está en raíz; no existe una carpeta contenedora `web/` adicional.
- Rutas relativas y mayúsculas/minúsculas coinciden con la salida de exportación;
  no renombrar el HTML o sus dependencias después.
- Sin hilos, extensiones o PWA; sin dependencia de COOP/COEP o service worker.
- Se sirve por HTTP localhost en pruebas de escritorio, con MIME correcto de
  `.wasm`, o HTTPS para alojamiento. No se valida abriendo `file://`.
- Pruebas, GUT, evidencia, documentación interna, herramientas y credenciales
  están ausentes tanto del ZIP exterior como del PCK. Se verifica la lista de
  recursos real; no se supone que un patrón de exclusión funcionó.
- Cumple los límites de archivo y tamaño vigentes del portal registrados en
  [research.md](../research.md#5-paquete-y-entrega). Las licencias necesarias se
  incluyen con la entrega o en una atribución distribuida apropiada.

## Partida conservada

Permanecen intactos `scenes/levels/Nivel_MonteCalvo.tscn`,
`MonteCalvoVisual.tscn`, actores, PNG/imports, scripts de gameplay, autoloads,
`core/`, `resources/` e `InputMap`. No se añaden cámara, HUD, tutorial, control
de recarga, guardado, cambios de oleadas o geometría. El combate continúa
mediante las mismas conexiones y Resources.

Configuración permitida: preset Web, override renderer `.web`, filtros de
exportación y scripts/workflow de empaquetado. Un ajuste de presentación
`.web` requiere un fallo de compatibilidad observado y prueba antes/después.
Un cambio de lógica exige tareas adicionales tester RED → dev → tester
GREEN/regresión → QA; no se oculta dentro de la tarea de preset.

## Matriz mínima de aceptación

| ID | Precondición y acción | Resultado requerido |
|---|---|---|
| W01 | 3 cargas nuevas en Chromium escritorio; red/caché registradas | Nivel con arte, combate iniciado, sin error crítico/archivo ausente |
| W02 | Recoger un pickup con clic/tap; saldo y soldados antes/después | Aumenta exactamente una vez; no despliega un soldado con ese gesto |
| W03 | Fondos suficientes, celda libre, una interacción | Exactamente un soldado y un cobro del costo existente |
| W04 | Celda ocupada **y fondos suficientes**, repetir interacción | Sin duplicado ni gasto; el saldo permite distinguir rechazo por ocupación |
| W05 | Celda libre **y fondos insuficientes**, intentar desplegar | Sin soldado ni gasto |
| W06 | Canvas 1152×648 y 960×540, y resize con clic posterior | Combate visible; acción corresponde a lo mostrado |
| W07 | Chrome Android físico horizontal, canvas/densidad registrados | W02–W05 funcionan por toque físico; no doble efecto mouse/touch |
| W08 | Jugar manualmente con datos de producción hasta terminal | Sin cierre/error crítico; declarar resultado observado, no inventar victoria |
| W09 | Victoria y derrota en escenarios automatizados existentes | Ambas transiciones conservadas; no equivale a W08 manual |
| W10 | Cambiar de pestaña y regresar, reiniciar por recarga | Retorno sin fallo crítico; recarga crea sesión nueva; documentar suspensión |
| W11 | Reexportar desde copia limpia, inspeccionar ZIP/PCK y servir extraído | Inicio correcto, archivos completos/exclusiones y trazabilidad verificadas |
| W12 | Sesión web Android y escritorio con medición de carga/rendimiento | Método, duración y cifras registradas; limitaciones y gate constitucional explícitos |

W02–W05 requieren evidencia en escritorio y Android físico. Un input sintético
headless o emulación táctil de escritorio no sustituye el dispositivo. Los
casos pueden usar instrumentación de observación en copia temporal para
verificar saldo/celdas, pero la confirmación final se repite sobre el build de
entrega sin modificar su lógica. Si no es observable de forma concluyente,
queda pendiente; no se baja el requisito.

Firefox, Safari macOS y Web iOS se agregan con sus resultados reales cuando
estén disponibles. No se anuncian como soportados por extrapolación. Los
pendientes de 002 conservan su identidad y matriz histórica.

## Resultado y gate

Cada caso usa PASS/FAIL/NOT RUN, entorno y evidencia. QA distingue aprobación
del preset/empaquetado, aceptación web acotada y aceptación global. Un ZIP WIP
puede existir con pendientes; no se comparte con testers externos sin el
smoke constitucional. Ningún reporte parcial declara FPS estables, soporte
universal ni cierre de 002.
