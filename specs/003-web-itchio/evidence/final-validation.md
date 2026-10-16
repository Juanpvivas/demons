# Validación final parcial — 003 Web / candidato4a2915c

2026-10-15 local. **Candidato WIP verificable**: corrección de input, build y
Chrome escritorio aprobados de forma acotada por QA; Android físico, matriz
completa y gate de rendimiento siguen pendientes. No es aceptación global
de003, publicación en itch.io ni cierre histórico de002.

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

| Caso | Chrome escritorio155.0.8059.84 | Android Chrome154.0.8037.94 | Evidencia/límite |
|---|---|---|---|
| W01 arranque | **PASS** | NOT RUN | Tres cargas del candidato final sin errores: directa, iframe960 y iframe1152; [resumen](desktop-validation-summary.json) y consola/capturas enlazadas abajo |
| W02 recoger una vez sin desplegar | **PASS acotado** | NOT RUN | Observador PLAYING: único pickup natural,12→15/soldados1→1; producción confirma visualmente desaparición sin nueva unidad; [T017](t017-green.md) |
| W03 celda libre con fondos | **PASS acotado** | NOT RUN | Observador PLAYING:15→5/soldados1→2; producción confirma el despliegue explícito; no atribuir saldo oculto al ZIP |
| W04 ocupada con fondos | **PASS acotado** | NOT RUN | Celda6,5, saldo12≥10, permanece12 y1soldado; registro PRE/POST durante PLAYING |
| W05 libre sin fondos | **PASS acotado** | NOT RUN | Celda2,5, saldo0, rechazo y ningún gasto/unidad; registro PRE/POST |
| W06 tamaños/resize/clic/iframe | **PASS acotado** | NOT RUN | Resize y clic verificados con estado observado; iframe y producción corroborados; detalles abajo |
| W07 Android horizontal/toque | No aplica | **NOT RUN** | Dispositivo conectado, gate abierto pero aviso introductorio de Chrome y giro horizontal pendientes; ningún toque de juego acreditado |
| W08 partida manual hasta terminal | **PARCIAL** | NOT RUN | Interacciones CUA durante PLAYING y LOST observado a33.840s; producción sin cierre/error, pero no expone estado terminal; no se acredita victoria manual ni smoke humano móvil |
| W09 victoria/derrota automatizadas | **PASS automatizado nativo** | No sustituye Android | Ambas transiciones en suite189; no es una partida manual Web |
| W10 pestaña/regreso/recarga/audio | **PARCIAL** | NOT RUN | Recargas crean partida nueva; cambio efectivo a segundo plano y regreso NOT RUN por herramienta; no hay audio en recursos actuales |
| W11 limpio/ZIP/PCK/extraído | **PASS local** | Arranque móvil pendiente | Candidato reconstruido/extraído y servido por HTTP; CI remoto NOT RUN |
| W12 carga/rendimiento/memoria | **PARCIAL** | **NOT RUN** | Proceso observado y cadencia del contenedor medidos, memoria/caché fría pendientes; no certifica gate constitucional |

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

Todas las cargas finales registraron Compatibility/WebGL2, single-threaded,
sin GDExtension y sin errores críticos/archivos ausentes. Mismo perfil/caché;
no se llamó «fría» a una recarga.

## Smoke y límite de foco

En la sesión de resize se recogió munición y desplegó durante PLAYING; la
partida natural luego emitió **LOST a33.840s**, sin cierre. La captura de
diagnóstico permite ver ese estado: [terminal](w08-observed-terminal.jpg),
[log completo](w08-w12-observer-desktop.json). No se alteraron oleadas ni se
forzó victoria/derrota. El ZIP carece de una pantalla terminal integrada,
limitación previa fuera del alcance de003; por ello W08 conserva el límite
de observación anterior.

Para W10, crear una pestaña adicional dejó ambos documentos reportados
`visible`; no produjo cambio de foco verificable. La API de gestión rechazó
`tabs.update({active:true})` como propiedad no soportada. Se cerró la pestaña
temporal y no se recurrió a AX nativo ni a vías alternativas no autorizadas.
[Registro de limitación](w10-tool-limitation.json). No se declara PASS del
cambio a segundo plano. Recargas/nuevas sesiones sí quedaron observadas.

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
- Memoria JS/VRAM/PSS y carga con caché fría: **NOT RUN**. No se inventan cifras
  ni se equipara memoria del proceso completo de Chrome con la del juego.

Estas muestras registran cadencia disponible, incluidos picos; **no certifican
60FPS estables**, dispositivo constitucional de referencia ni rendimiento
de Android/Web iOS. El gate de rendimiento permanece abierto.

## Dispositivos y siguiente comprobación

Xiaomi2107113SG, Android14, Chrome154.0.8037.94, conectado por USB y reenvío
temporal del puerto8063. Página `http://localhost:8063/phone-gate.html` espera
inicio manual; botones **«Comenzar prueba observada»** y **«Comenzar producción»**.
[Preflight actual](android-preflight-blocked.png): vertical y aviso de
notificaciones de Chrome pendiente de «No, gracias». No se aceptaron permisos
ni se cambiaron ajustes del dispositivo. La persona recibió petición de giro
y cierre del aviso, **sin iniciar la partida todavía**; respuesta pendiente.

Tras verificar el preflight horizontal, secuencia prevista: A con0 (W05),
recoger hasta≥12, B ocupada (W04), otro amarillo con≥10 (W02), A libre (W03).
El contador temporal de solo lectura muestra reserva/soldados y PRE→POST;
el build de producción se repite después sin él. No usar un rechazo con
saldo2 para atribuir un PASS a ocupación. Ninguna prueba física se da por hecha.

Firefox no instalado; Safari macOS instalado pero sin superficie de control
habilitada en esta validación; Web iOS sin dispositivo físico. **NOT RUN**
para los tres, sin extrapolar Chrome. No se hicieron instalaciones adicionales
ni publicación remota. T007/T008/T012/T013 permanecen pendientes de su matriz
y veredictos; solo el orquestador actualiza tareas.
