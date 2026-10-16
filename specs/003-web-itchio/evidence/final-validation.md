# Validación final parcial — 003 Web / candidato4a2915c

2026-10-15/16, Bogotá. **Candidato verificable con límites de validación**:
corrección de input, build y Chrome escritorio aprobados de forma acotada
por QA; W02–W05 físicos observados y la corroboración de producción/retorno
móvil también aprobados en T007/T008 con el alcance descrito.
Los gates constitucionales no medidos siguen abiertos; no es publicación
en itch.io ni cierre histórico de002.

Actualización móvil2026-10-16: [toques físicos y producción](android-validation.md).
La persona confirmó «Funcionó y pude volver al juego»; el wrapper registra
una ejecución con ocultación y regreso sin recarga observada. No se repitieron
GUT ni exportación.

## Artefacto y pruebas conservadas

`build/demons-web.zip`, **14 893 307 bytes**, SHA256
`205d3916f21ce8c2b29eaf4bbbd804908dab7e9c93356355f4a335212eabfd71`.
Generado con estándar4.7.1 desde clone limpio **4a2915c**, sin caché/build;
manifest exterior `build/web-manifest.json`, `source_dirty=false`.
Doce miembros, licencias presentes, index.html raíz,78 recursos PCK sin
internos. [T017 GREEN/paquete](t017-green.md),
[manifest](t017-web-manifest.json), [verificación](t017-package-verification.json).
El ZIP y su manifest están en `build/` ignorado; no contienen este reporte,
observador ni wrappers de prueba.

Mismas seis pruebas de input **6/6**, suite completa **189/189 y532 aserciones**;
import limpio y export reales sin errores. Los tres avisos GUT preexistentes
están inventariados en T017; no se ocultaron. No se repitieron suite ni build
por los posteriores cambios exclusivos de observación.

[Invariantes](t017-invariants.json):106/110 archivos baseline idénticos. Solo
difieren dos configuraciones Web autorizadas, comentarios CI y el script de
enrutamiento corregido. InputMap, presets nativos, escenas, arte, Resources y
tests históricos permanecen iguales; se agregó el archivo de regresión y UID.

## Matriz actual

PASS indica el alcance exacto de la columna de evidencia. El PASS de una
columna no se extiende a Android ni a los límites pendientes de otra.

Android **PASS observado** corresponde solo a la copia con diagnóstico: W02
11→14/2→2, W03 12→2/1→2, W04 14→14/1→1 y W05 0→0/1→1, todos
PLAYING y con condiciones previas discriminantes. El [reporte móvil](android-validation.md)
contiene coordenadas reales y PRE/POST. El ZIP sin observador se repitió
con corroboración humana favorable de recoger/desplegar y regreso registrado.
No se atribuyen al ZIP saldos/estado ocultos ni se repiten W04/W05 como
nuevos controles de producción. Las cifras de las otras filas describen
escritorio salvo ampliación explícita del reporte móvil.

| Caso | Chrome escritorio155.0.8059.84 | Android Chrome154.0.8037.94 | Evidencia/límite |
|---|---|---|---|
| W01 arranque | **PASS** | **Verificado local** | Tres cargas finales de escritorio; producción móvil visible y funcional según relato/captura; [escritorio](desktop-validation-summary.json), [móvil](android-production-summary.json) |
| W02 recoger una vez sin desplegar | **PASS acotado** | **PASS observado** | Observador PLAYING: único pickup natural,12→15/soldados1→1; producción confirma visualmente desaparición sin nueva unidad; [T017](t017-green.md) |
| W03 celda libre con fondos | **PASS acotado** | **PASS observado** | Observador PLAYING:15→5/soldados1→2; producción confirma el despliegue explícito; no atribuir saldo oculto al ZIP |
| W04 ocupada con fondos | **PASS acotado** | **PASS observado** | Celda6,5, saldo12≥10, permanece12 y1soldado; registro PRE/POST durante PLAYING |
| W05 libre sin fondos | **PASS acotado** | **PASS observado** | Celda2,5, saldo0, rechazo y ningún gasto/unidad; registro PRE/POST |
| W06 tamaños/resize/clic/iframe | **PASS acotado** | **Horizontal observado** | Escritorio resize/clic/iframe; Android horizontal2400×1080 con toques, no rotación durante partida ni aspecto universal |
| W07 Android horizontal/toque | No aplica | **APROBADO acotado** | W02–W05 físicos durante PLAYING y corroboración manual de producción; [reporte móvil](android-validation.md) |
| W08 partida manual hasta terminal | **APROBADO observado** | **APROBADO observado** | Partida manual con datos idénticos hasta LOST en copia de solo lectura; ZIP sin HUD terminal, no se atribuye estado oculto ni victoria manual |
| W09 victoria/derrota automatizadas | **PASS automatizado nativo** | No sustituye Android | Ambas transiciones en suite189; no es una partida manual Web |
| W10 pestaña/regreso/recarga/audio | **PARCIAL: foco NOT RUN** | **APROBADO retorno** | Recargas nuevas sesiones en escritorio; Android un run/uniframe-load, hidden3.6535s y4.9536s→visible con relato de otra pestaña; sin audio actual |
| W11 limpio/ZIP/PCK/extraído | **PASS local** | Arranque local verificado | Candidato reconstruido/extraído y servido por HTTP; CI remoto NOT RUN |
| W12 carga/rendimiento/memoria | **Medido con límites** | **Medido con límites** | Proceso observado, rAF externo, Navigation/ResourceTiming y heapJS disponible; cold/memoria exclusiva/VRAM/60estables no certificados |

La instrumentación de saldo usa exclusivamente una copia temporal de la misma
fuente, sin mutar estado de juego. Los resultados de producción se describen
como confirmación visual cuando no hay saldo/estado expuesto. No se rebajó
esa distinción para marcar casos globales completos.

## Pantallas y coordenadas

1. Resize **1152×648→960×540** conservó la misma partida y saldo12.
   Clic CSS200,440 se recibió como240,528 en el mundo y desplegó en celda2,5:
   **12→2, soldados1→2, PLAYING**.
   [Registro](w06-resize-click.json), [captura](w06-resize-click.jpg).
2. Iframe960×540 en origen0,32 dentro de contenedor1280×720:
   clic de página200,472 se convirtió a240,528; **12→2,1→2, PLAYING**.
   [Registro válido](w06-iframe-playing.json), [captura](w06-iframe-playing.jpg).
   El primer ensayo tardío `w06-iframe-960-click.json` estaba LOST; se conserva
   como comprobación limitada de coordenadas y no se usa como caso activo.
3. El **ZIP sin observador** se cargó en iframes960×540 y1152×648. En960 se
   recogió munición y se desplegó visualmente en el lugar correspondiente.
   [Consola960](production-frame960.json),
   [captura960](w06-production-iframe960.jpg),
   [consola1152](production-frame1152.json),
   [captura1152](production-frame1152.jpg).
   Wrappers estáticos de prueba: [960](w06-frame-960.html),
   [1152](w06-frame-1152.html), [observado960](w06-frame-960-observed.html).
   Esto no constituye una página subida a itch.io.

Las cargas finales de escritorio registraron Compatibility/WebGL2, single-threaded,
sin GDExtension y sin errores críticos/archivos ausentes. Mismo perfil/caché;
no se llamó «fría» a una recarga.

## Smoke y límite de foco

En la sesión de resize se recogió munición y desplegó durante PLAYING; la
partida natural luego emitió **LOST a33.840s**, sin cierre. La captura de
diagnóstico permite ver ese estado: [terminal](w08-observed-terminal.jpg),
[log completo](w08-w12-observer-desktop.json). No se alteraron oleadas ni se
forzó victoria/derrota. El ZIP carece de una pantalla terminal integrada,
limitación previa fuera del alcance de003. W08 se fundamenta en juego manual
con datos de producción hasta terminal observado, sin exigir HUD nuevo ni
inventar el estado final oculto del ZIP. En Android las dos sesiones físicas
con datos idénticos también emitieron LOST natural; [raw y límites](android-validation.md).

Para W10, crear una pestaña adicional dejó ambos documentos reportados
`visible`; no produjo cambio de foco verificable. La API de gestión rechazó
`tabs.update({active:true})` como propiedad no soportada. Se cerró la pestaña
temporal y no se recurrió a AX nativo ni a vías alternativas no autorizadas.
[Registro de limitación](w10-tool-limitation.json). Esa limitación se conserva
para **escritorio**. Android añadió registro de otra pestaña/regreso: mismo
run12:39:35.789Z, un inicio/una cargaiframe, dos intervalos hidden3.6535s y
4.9536s y vuelta a visible. El relato humano y la captura corroboran regreso
sin recarga observada; [datos originales](android-production-summary.json).
No se infiere la política interna de pausa/suspensión del juego.

## Rendimiento: método y cifras disponibles

[Datos derivados de los registros originales](desktop-validation-summary.json):

- **Observador Godot, primeros30.0197s de proceso**:3585 frames,
  media119.42FPS calculada desde delta, p50/p95 **8.33ms**, máximo **95.7ms**;
  Engine reportó120FPS. Primer `_process` a192ms desde el arranque del motor,
  **excluye descarga/compilación del navegador**. Sesión CUA con render visible,
  resize e inputs descritos, carga inicial del nivel; no diez oleadas completas.
- **Producción sin observador, dentro del wrapper**: el contador externo
  registró **119.7 callbacks rAF/s, p95 9.9ms, n8013**, acumulados alrededor de67s.
  [Lectura/captura](w12-production-parent-raf.json),
  [imagen](w12-production-parent-raf.jpg). Mide callbacks del **contenedor**,
  no frames renderizados del juego; incluye tiempo posterior a la derrota.
- Ambas mediciones proceden de la sesión de navegador controlada por CUA,
  con viewport de prueba; no equivalen a una sesión física libre de herramientas.
  El perfil/caché existente se conservó. La tabla de tres cargas registra el
  intervalo hasta el log de renderer, que **no es tiempo hasta primer pixel**.
- En escritorio, memoria JS/VRAM/PSS y caché fría: **NOT RUN**. No se inventan cifras
  ni se equipara memoria del proceso completo de Chrome con la del juego.

Estas muestras registran cadencia disponible, incluidos picos; **no certifican
60FPS estables**, dispositivo constitucional de referencia ni rendimiento
de Android/Web iOS. El gate de rendimiento permanece abierto.

Android observado, dos sesiones con30.061/30.050s de proceso: media60.144/60.101FPS,
p95 16.667ms en ambas y máximos133.333/144.133ms. Estos picos y la instrumentación
impiden afirmar60FPS estables. Android **producción sin observador**:
ventana objetivo30s de rAFpadre,1201intervalos/media55.258callbacks/s, p9516.6ms,
máximo1835.7ms, incluye carga/interrupciones. No son FPS del juego.
IframeHTML75.2ms desde botón, Navigation69.6ms; WASM responseEnd1295.8ms y
PCK336.2ms, sin afirmar primer frame ni caché fría. HeapJS no estándar
redondeado10000000bytes; no memoria exclusiva, WASMtotal, PSS o VRAM.
[Valores originales y método](android-validation.md),
[datos de producción](android-production-summary.json).

## Dispositivos y alcance móvil

Xiaomi2107113SG, Android14, Chrome154.0.8037.94, horizontal2400×1080 por acción
humana. Se preservó su giro automático; el intento anterior del agente de
ajustarlo fue rechazado por Android y no cambió ajustes/permisos. Las viejas
grabaciones de espera no se confunden con los toques posteriores.

[Reporte Android](android-validation.md) enlaza PRE/POST físicos aprobados,
cronología de visibilidad de producción y sus capturas. La producción se
sirvió desde el ZIP exacto extraído dentro de un [wrapper temporal](phone-production-check.html),
con botón humano, sin observador dentro del juego. El wrapper solo mide su
propia página; no lee otras pestañas ni modifica el HTML exportado. No se
inyectó entrada por ADB, no se forzó victoria/derrota y no hubo nuevos builds,
suites o grabaciones rutinarias. Los lectores ya están cerrados.

Firefox no instalado; Safari macOS instalado pero sin superficie de control
habilitada en esta validación; Web iOS sin dispositivo físico. **NOT RUN**
para los tres, sin extrapolar Chrome. No se hicieron instalaciones adicionales
ni publicación remota. T007/T008 están **APROBADOS con alcance acotado** por QA: W08 manual observado
hasta LOST con datos idénticos y W10 regreso Android más recarga escritorio.
El foco de escritorio permanece NOT RUN. Este conjunto se entrega para la
revisión T012/T013 con los límites de rendimiento y plataformas anteriores;
solo el orquestador actualiza tareas. No se cierra002.
