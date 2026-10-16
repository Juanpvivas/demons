# Exportación Web para itch.io

**Estado al 2026-10-16: paquete revisado localmente y entrega 003 aceptada por
QA en Chrome de escritorio y Xiaomi/Chrome horizontal.** Incluye interacción,
corroboración visual de producción y partidas manuales observadas hasta LOST.
El regreso Android conserva el mismo run sin recarga observada; foco de
escritorio, otros navegadores y rendimiento sostenido mantienen sus límites.
La demo sigue en desarrollo y no está publicada en itch.io.

**Integración de main tras PR #16 (2026-10-16):** 002 quedó aprobada con
[22/22 tareas](../specs/002-monte-calvo-terreno-trincheras/tasks.md) y su
[matriz nativa](../specs/002-monte-calvo-terreno-trincheras/evidence/native-validation-matrix.md)
está incorporada en la rama Web. La constitución 2.1.0 conserva tanto los
destinos Web/Android/iOS como la referencia Xiaomi exclusiva de 002. Los
resultados de navegador y el [seguimiento de 003](../specs/003-web-itchio/tasks.md)
siguen siendo propios. El [informe de integración aprobado por QA](../specs/003-web-itchio/evidence/main-integration.md)
acredita el nuevo paquete y su equivalencia, conservando el smoke y las
interacciones anteriores. No se repitieron pruebas de navegador, teléfono o
GUT local; los [Checks del PR #15](https://github.com/Juanpvivas/demons/pull/15/checks)
identifican el CI de cada revisión publicada. No se hereda una certificación
de rendimiento Web.

## Requisitos

- Godot **estándar oficial 4.7.1 stable**, con sus templates de exportación de
  igual versión. El script rechaza Mono/.NET y otras versiones. Se puede
  conservar Mono para el trabajo nativo existente.
- Python 3.8 o posterior, Git y Bash. No hace falta instalar Butler ni tener
  credenciales del portal para generar el paquete.
- Un checkout que incluya la feature 003 y sus archivos de `tools/web/licenses/`.
  No ejecutar dos exports/importaciones sobre el mismo checkout al mismo tiempo.

El preset Web usa Compatibility/WebGL2, un hilo, sin extensiones ni PWA. La
configuración Mobile y los presets/deploys Android/iOS se conservan.
[Herramientas verificadas](../specs/003-web-itchio/evidence/toolchain.md).

## Generar el ZIP

Desde la raíz del repositorio, indicar la ruta del ejecutable estándar local:

```bash
GODOT_WEB_BIN="/ruta/al/ejecutable/Godot" tools/web/export.sh
```

Si `godot` ya resuelve a la edición correcta en PATH, basta con
`tools/web/export.sh`. El script importa y exporta release, prepara
`build/.gdignore` antes de importar, limpia **solo las salidas Web conocidas**
y rechaza enlaces simbólicos inseguros. No borra los builds Android/iOS.

| Salida | Uso |
|---|---|
| `build/demons-web.zip` | Archivo que se seleccionará al cargar el juego web |
| `build/web/` | Juego sin comprimir, con `index.html` en raíz y `licenses/` |
| `build/web-manifest.json` | Revisión, estado WIP, versión del motor, tamaños y hashes |
| `build/web-import.log`, `build/web-export.log` | Diagnóstico de importación y exportación |

`build/` está ignorado por Git. El manifest y los logs quedan fuera del ZIP.
No renombrar `index.html` o sus archivos compañeros después de exportar. Si el
script devuelve un error, revisar los logs antes de considerar utilizable la
salida. Los patrones de exclusión registrados en el manifest son una política;
la ausencia real de recursos internos se verifica también dentro del PCK.

## Abrirlo localmente

```bash
python3 -m http.server 8060 --directory build/web --bind 127.0.0.1
```

Abrir `http://127.0.0.1:8060/`; no abrir `index.html` como archivo ni servir la
raíz del repositorio. Este servidor es para desarrollo local. Para probar el
ZIP, extraerlo en una carpeta nueva y servir esa carpeta con el mismo método.
Las instrucciones de toque físico, iframe y casos controlados están en
[quickstart](../specs/003-web-itchio/quickstart.md).

## Qué está comprobado

QA aprobó de forma acotada el preset/arranque T004–T006 y la generación local y
paquete T009/T010. Se preserva el primer fallo de exportación: la selección de
escenas omitió clases/oleadas cargadas desde scripts; se corrigió a recursos de
producción con exclusiones explícitas. El PCK corregido contiene **78 rutas**,
incluidas las diez oleadas y las clases necesarias, sin pruebas, GUT,
documentación interna ni configuración de agentes.

T010 ejecutó dos generaciones reales en la revisión `ed446d9`, una desde una
copia Git limpia sin caché ni `build`. Ambos ZIP extraídos iniciaron el nivel,
arte y combate en Chrome. Los ZIP diferían en el PCK; se acreditó reproducción
funcional, no identidad binaria. Esos paquetes son históricos y preceden la
corrección de entrada descrita abajo.
[Informe T010](../specs/003-web-itchio/evidence/web-package.md).

El **candidato integrado verificado** (2026-10-16), exportado desde el snapshot
limpio `7309d8fa211637afbd68c4d73181758ee2840a93`, mide **14 893 307 bytes**, SHA-256
`f3b60dfa20ddbc277c12335a10ab43f92b2f676474659a560dfc6c8ab515dc78`.
Importación y exportación finalizaron en 0. Conserva los 12 miembros del ZIP,
las 78 rutas del PCK y las tres licencias; solo cambian IDs internos generados
al compilar seis escenas. QA confirmó la equivalencia para reutilizar las
interacciones y el smoke anteriores en su alcance acotado.
[Informe](../specs/003-web-itchio/evidence/main-integration.md) y
[manifiesto del candidato integrado](../specs/003-web-itchio/evidence/main-integration-manifest.json).

El **paquete local histórico anterior a esta integración** (2026-10-16),
generado desde copia limpia de `4a2915c`, mide
**14 893 307 bytes** (aproximadamente 14.89 MB), con SHA256
`205d3916f21ce8c2b29eaf4bbbd804908dab7e9c93356355f4a335212eabfd71`.
QA comprobó su integridad: 12 miembros, incluidos 3 avisos de distribución,
PCK de 78 rutas y hashes coincidentes. El tamaño extraído es 44 652 145 bytes.
Esta comprobación no aprueba por sí sola la interacción de US2 ni la difusión.
[Manifiesto de ese paquete](../specs/003-web-itchio/evidence/t017-web-manifest.json) y
[verificación del paquete](../specs/003-web-itchio/evidence/t017-package-verification.json).

### Corrección de recogida y despliegue aprobada en escritorio

La prueba de navegador detectó que, con reserva suficiente, un clic sobre
munición también podía cobrar un despliegue. Se corrigió el enrutamiento del
gesto: recoger conserva la prioridad sobre desplegar; hacer clic en una celda
libre sin pickup conserva el costo existente. No cambian cantidades, balance,
InputMap o arte. El ratón emulado de los toques mantiene la misma ruta de
despliegue; no se introdujo un control táctil nuevo.

El tester reprodujo primero el fallo con dispatch real del motor
([RED T015](../specs/003-web-itchio/evidence/t015-red.md)) y añadió cobertura de
despliegue normal/emulado
([RED W03](../specs/003-web-itchio/evidence/t017-w03-red.md)). Después de corregir,
pasaron los **6/6 casos, 36 aserciones**, y la regresión completa
**189/189 pruebas, 532 aserciones**, con los 3 avisos conocidos.
[GREEN focalizado](../specs/003-web-itchio/evidence/t017-green-focused.log) y
[regresión completa](../specs/003-web-itchio/evidence/t017-green-full.log).

QA aprobó T016/T017/T018 para el código y la evidencia Web de escritorio.
Una copia Web con observador de solo lectura registró durante PLAYING
recolección **12→15 sin nuevo soldado** y despliegue posterior **15→5 con un
soldado nuevo**. También comprobó rechazo por fondos insuficientes y por celda
ocupada con fondos suficientes. En el ZIP sin observador se repitieron
visualmente la recogida sin nueva unidad y el despliegue explícito posterior;
esa repetición no atribuye al build sin HUD saldos o estados ocultos.
[Informe GREEN y límites](../specs/003-web-itchio/evidence/t017-green.md).

El tester comprobó además el clic después de redimensionar de 1152×648 a
960×540: el punto CSS `(200,440)` correspondió a mundo `(240,528)`, celda `(2,5)`, y produjo
un solo despliegue, **12→2 durante PLAYING**.
[Registro W06](../specs/003-web-itchio/evidence/w06-resize-click.json).
T007/T008 están aprobadas con alcance acotado a Chrome escritorio y Xiaomi
horizontal; el alcance físico Android se registra por separado a continuación.

| Entorno/caso | Estado y alcance actual |
|---|---|
| Chrome 155.0.8059.84 en computador | W01 PASS: tres cargas del candidato final, directa e iframes de 960/1152; sin prueba de caché fría. |
| Canvas 1152×648 y 960×540 | W06 PASS acotado: render, clic después de resize e iframe con correspondencia mundo/celda y cobro único registrados. |
| W02–W05 de escritorio | PASS controlado con copia observadora y repetición visual acotada sin observador; T007/T008 y corrección T016/T017/T018 aprobadas. |
| Chrome 154.0.8037.94 en Xiaomi físico | W02–W07 aceptados en su alcance horizontal; W02–W05 observados y producción corroborada por la persona, sin atribuir saldo oculto al ZIP. |
| W10 recarga/cambio de pestaña | PASS de regreso Android en el mismo run sin recarga observada y de recarga escritorio. Cambio real de pestaña en escritorio NOT RUN. |
| Firefox y Safari macOS | NOT RUN en esta entrega; sin soporte anunciado por extrapolación. |
| Navegador iOS | NOT RUN; sin soporte anunciado por extrapolación. |
| W08 partida Web hasta terminal | PASS acotado: partidas manuales observadas hasta LOST con los mismos datos, más corroboración visual de producción. El ZIP sin observador no muestra el estado terminal; no se acredita victoria manual. |
| W12 carga/rendimiento/memoria | PARCIAL: muestras de proceso observado y métricas de navegador en producción; carga fría y memoria exclusiva del juego pendientes. No acredita 60 FPS estables. |
| Workflow Web en GitHub Actions | SUCCESS histórico identificado abajo; para cada revisión publicada, consultar los [Checks del PR #15](https://github.com/Juanpvivas/demons/pull/15/checks). |

Fuentes: [arranque T005](../specs/003-web-itchio/evidence/web-startup.md),
[paquete T010](../specs/003-web-itchio/evidence/web-package.md) y los registros
T017 enlazados arriba. La regresión anterior pasó 189/189; la prueba focalizada utiliza
dispatch real en SubViewport, sin sustituir las interacciones del navegador
ni el toque físico.
La feature 002 ya quedó aprobada e integrada en main; su aceptación nativa no
sustituye las verificaciones Web del estado integrado.

En Android se comprobaron por toque humano los cuatro casos: recoger **11→14
sin nueva unidad**, desplegar **12→2 con una unidad**, rechazar una celda
ocupada con reserva 14 sin gasto y rechazar una libre con reserva 0. Los pares
touch/mouse emulado se agrupan como un gesto físico. La observación de solo
lectura no modifica el juego.
[Reporte Android y evidencia PRE/POST](../specs/003-web-itchio/evidence/android-validation.md).

En producción sin observador, la persona confirmó **«Funcionó y pude volver
al juego»** tras recoger, desplegar y cambiar de pestaña. El registro temporal
del contenedor conserva un solo inicio/carga y el mismo `run_id`, con dos
intervalos hidden→visible de **3.654 s y 4.954 s**, sin recarga observada.
Esto corrobora la interacción visual y el retorno, sin añadir saldos,
ocupación o estado terminal que el ZIP no muestra.
[Resumen de producción móvil](../specs/003-web-itchio/evidence/android-production-summary.json).

La [validación final parcial](../specs/003-web-itchio/evidence/final-validation.md)
registra una muestra de proceso Godot **instrumentada de 30.0197 s**:
media **119.42 FPS**, p95 **8.33 ms**, máximo **95.7 ms**. Otra medición de
producción registró **119.7 callbacks rAF/s del contenedor**, que no son FPS
renderizados por el juego. Son muestras de escritorio, sin carga fría ni
memoria. En Android observado, dos muestras de aproximadamente 30 s registraron
medias **60.144/60.101 FPS**, p95 **16.667 ms** y máximos **133.333/144.133 ms**;
incluyen instrumentación y excluyen descarga/compilación. Ninguna muestra
certifica 60 FPS estables; el gate constitucional sigue pendiente.

La medición móvil de producción conserva la caché: documento del iframe
cargado a **75.2 ms** desde el inicio y respuesta WASM de **1227 ms**;
no son tiempo al primer píxel ni a la partida lista. La muestra del contenedor
registró **55.26 callbacks rAF/s**, incluyendo carga, pausas y cambios de
visibilidad, y **10 MB estimados de heap JavaScript de Chromium**. Ese heap
puede estar cuantizado y no representa memoria exclusiva del juego, WASM,
PSS o VRAM; los callbacks tampoco son FPS del juego. Carga fría y medición
de memoria del juego siguen pendientes.

El [informe de la entrega anterior de 003](../specs/003-web-itchio/evidence/implementation-status.md)
consolida el alcance aceptado y los límites globales. El estado vigente de
aprobación se consulta en [tasks.md](../specs/003-web-itchio/tasks.md); solo el
orquestador marca tareas después de QA.

## Artefacto de CI

`.github/workflows/export-web.yml` está configurado para Pull Requests y
activación manual. Instala Godot estándar 4.7.1 con templates y ejecuta el
mismo script; adjunta `demons-web-<SHA>` con ZIP/manifest y un artefacto separado
de logs. El CI existente mantiene GUT/importación y los deploys móviles.
La [exportación Web remota](https://github.com/Juanpvivas/demons/actions/runs/38903800209)
y el [CI del PR](https://github.com/Juanpvivas/demons/actions/runs/38903800369)
terminaron con SUCCESS antes de esta integración. El paquete remoto corresponde
al merge virtual `a3aef472aa80b966e06029970a5274e50b51c47d` de la cabeza
`9e32f1a` sobre la base anterior `b670d86`: artifact `12046938477`, nombre
`demons-web-a3aef472aa80b966e06029970a5274e50b51c47d`, **14 893 929 bytes**, SHA-256
`b3eccb236968f719f827c8c0ef6eb6e04fbfe15bc605623826745828110b97fb`.
Tester y QA comprobaron sus 12 miembros, las 78 rutas del PCK y las licencias
y exclusiones; no se repitieron interacciones de navegador con ese paquete.
Es distinto del ZIP local histórico de `4a2915c` indicado arriba. Ambos
preceden el merge del cierre de 002; el candidato integrado de `7309d8f` se
identifica por separado en esta guía y su informe. Los
[Checks del PR #15](https://github.com/Juanpvivas/demons/pull/15/checks) permiten
comprobar el CI de la revisión publicada, sin atribuirle esos éxitos históricos.
El workflow no publica en itch.io ni requiere secretos de esa cuenta.

## Preparar una carga manual posterior en itch.io

La entrada y el smoke están aprobados en el alcance indicado. Para una carga
manual posterior, conservando los límites de rendimiento y soporte declarados:

1. En la página del juego elegir **HTML Game** y cargar `demons-web.zip`.
2. Marcar que se ejecuta en navegador; comenzar con **Click to play**, iframe
   **1152×648** y botón de pantalla completa.
3. Activar **Mobile Friendly** únicamente tras comprobar la versión Web móvil.
4. Previsualizar la página y comprobar clic, toque y carga antes de decidir su
   visibilidad. Cuenta, textos comerciales y donaciones se gestionan aparte.

[Guía oficial de itch.io](https://itch.io/docs/creators/html5). Esta feature
no inicia sesión, sube archivos ni publica la página.

## Avisos del motor y del arte

El ZIP incluye `licenses/GODOT_LICENSE.txt`, `licenses/GODOT_COPYRIGHT.txt` y
`licenses/NOTICE.txt`. Los dos primeros conservan textos oficiales del tag
Godot 4.7.1-stable; NOTICE identifica el origen del arte de Monte Calvo, generado
con la herramienta de imágenes de Codex. Se mantiene esa declaración al
presentar la demo; si el portal solicita información sobre contenido generado
con IA, la respuesta debe reflejar esa procedencia.

Estos avisos no asignan una licencia nueva al código, al arte ni a la propiedad
intelectual del juego. No se incluyen prompts ni documentación interna en el
paquete. [Fuente oficial de atribuciones de Godot](https://docs.godotengine.org/en/4.7/about/complying_with_licenses.html).
