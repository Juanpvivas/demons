# T007 — Interacción Web: estado actual e historial

Actualizado2026-10-16. Candidato fuente **4a2915c**, ZIP SHA256
`205d3916f21ce8c2b29eaf4bbbd804908dab7e9c93356355f4a335212eabfd71`.
El FAIL inicial W02 fue corregido mediante T015RED→T016→T017GREEN→T018QA;
no se reescribe su evidencia histórica ni se reutiliza su paquete anterior.

## Evidencia actual consolidada

- [GREEN189, invariantes y paquete](t017-green.md): seis casos de input,
  suite completa189/189, import limpio y exportación del candidato final.
- [Escritorio y matriz completa](final-validation.md),
  [derivado escritorio](desktop-validation-summary.json): clic CUA del
  navegador en Chrome155.0.8059.84, copia de solo lectura y confirmación
  visual en producción, resize e iframe con clic posterior.
- [Android físico](android-validation.md),
  [PRE/POST observados](android-observed-cases.json),
  [registros originales](android-observed-sessions.jsonl): Chrome154.0.8037.94
  sobre Xiaomi2107113SG/Android14 horizontal. W02–W05 observados aprobados
  por QA con fondos/ocupación discriminantes y PLAYING.
- [Producción Android y retorno](android-production-summary.json),
  [13 mensajes pasivos](android-production-probe.jsonl),
  [captura](android-production-return-current.png): relato humano favorable
  y una misma ejecución visible→hidden→visible; sin HUD del juego, no se
  atribuyen saldo ni resultado terminal ocultos al paquete.

| Caso | Escritorio | Android físico | Alcance y límites actuales |
|---|---|---|---|
| W01 | Tres cargas finales verificadas | Producción cargada y visible | Arranque local; no portal publicado |
| W02 |12→15/1→1 observado y producción visual |11→14/2→2 observado, corroboración manual producción | Un pickup aislado; ningún gasto10 ni unidad adicional observado |
| W03 |15→5/1→2 observado y producción visual |12→2/1→2 observado, corroboración manual producción | Celda libre comprobada antes; sin saldo oculto atribuido al ZIP |
| W04 |12→12/1→1, ocupada y fondos |14→14/1→1, celda5,5 ocupada | Aprobado observado; no sustituir por rechazo sin fondos |
| W05 |0→0/1→1, libre |0→0/1→1, celda5,5 libre y REJECTED | Aprobado observado |
| W06 |Resize1152×648→960×540 y clic; iframe960/1152 |Horizontal2400×1080 y toques reales | No se afirma rotación durante partida ni universalidad de aspecto |
| W07 |No aplica |Toque físico observado y producción manual | Método humano; no inyecciónADB ni emulado usado como sustituto |
| W08 |Inputs manualesCUA→LOST natural observado |Inputs físicos→LOST natural observado, datos idénticos | Sin forzar transición; ZIP sin pantalla terminal, no victoria manual |
| W09 |189tests conservan victoria/derrota |No sustituye toque físico | Automatizado nativo separado de W08 |
| W10 |Recarga nueva sesión; foco no verificable por CUA |Mismo run, hidden3.6535s y4.9536s, retorno visible | Relato identifica otra pestaña; no se inspecciona su contenido ni suspensión interna |

El relato de producción **«Funcionó y pude volver al juego»** responde a
recoger cuatro amarillos y otro antes de desplegar, desplegar una unidad en
suelo libre y abrir otra pestaña unos cinco segundos antes de volver. No
convierte cada gesto en un nuevo control con saldo instrumentado. Los pares
mouse/touch del observador se correlacionan como un único gesto humano.

W08 acredita la partida manual con los datos de producción hasta LOST en
copia observada sin mutación. El terminal del ZIP sin HUD no está expuesto;
no se inventó una pantalla ni se forzó victoria. QA aceptó este alcance a partir del contrato y de estas limitaciones.

No se repitieron suite/build por cambios documentales o del wrapper externo.
T007/T008 están **APROBADOS de forma acotada** por QA. T012/T013 reciben
las medidas y limitaciones consolidadas; este reporte no marca tareas. W12 y los gates constitucionales pendientes se detallan en
[validación final](final-validation.md). No hay Firefox/Safari/Web iOS
verificados ni publicación en itch.io.

## Registro histórico del FAIL inicial — conservado

Lo siguiente describe exclusivamente el candidato anterior y su fallo inicial.
Sus estados FAIL/NOT RUN no son la matriz actual de4a2915c.

2026-10-15 local. **Registro histórico del FAIL W02 inicial**; motivó T015–T018.
La corrección posterior y GREEN están en [t017-green.md](t017-green.md);
el estado actual de T007/T008/US2 está en [final-validation.md](final-validation.md).
Este reporte conserva el fallo original y no se reescribe como si hubiera pasado.

## Canal de input y observación

Chrome 155.0.8059.84 visible, canvas 1152×648. Se utilizó
`cua.getTab(URL, {browser: "1"})` y su `Target.click([x,y])`, con capturas y
estado de la pestaña entre acciones. **Clic CUA del navegador**: no se afirma
ratón físico humano ni se atribuye un protocolo interno no documentado.
No se usó `evaluate(element.click)`, inyección de eventos JavaScript, métodos
de gameplay ni input headless para estos casos.

El intento previo `cua.getApp("Google Chrome")` quedó bloqueado durante 636s
y fue interrumpido. No produjo prueba de gameplay ni constituye RED. El
acceso directo a la pestaña y sus clics posteriores tardaron menos de un
segundo por grupo; no se repitió la consulta nativa.

Para medir saldo/ocupación sin añadir HUD se exportó una copia temporal desde
`ed446d9` con un Node que solo lee y registra estado/señales. Sus **105 archivos
fuente comparados** son idénticos salvo la escena que añade ese Node; no altera
economía, input, Resources, spawns ni lógica. Fuente exacta preservada:
[observer-readonly.gd](observer-readonly.gd), [escena](observer-level.tscn),
[procedencia/hashes](observer-provenance.json). Vive bajo `evidence/.gdignore`,
sin formar parte del juego exportado. Proyecto temporal:
`/private/tmp/demons-web-observer-003`; [import](observer-import.log) y
[export](observer-export.log) retornaron 0 sin errores. El observador no es el
build de entrega; la confirmación visual se repitió sin él.

## Resultado discriminante

| Caso | Evidencia y resultado observado | Estado |
|---|---|---|
| W05: celda libre, fondos insuficientes | Sesión1 evento1, PLAYING, saldo0, solo celda6,5 ocupada; clic240,480 en celda2,5 libre: rechazo «Munición insuficiente», saldo0 y un soldado antes/después | PASS en copia observada; repetir producción final |
| W04: ocupada con fondos suficientes | Sesión2 evento5: cuatro pickups aislados suman0→3→6→9→12; clic600,500 en celda6,5 ocupada, PLAYING: saldo12 y un soldado antes/después, sin gasto | PASS en copia observada; repetir producción final |
| W02 con saldo inferior al costo | Primeras tres recogidas aisladas, amount3 cada una:0→3→6→9; desaparece cada pickup una vez, sin nuevo soldado | PASS parcial; no discrimina doble efecto cuando hay fondos |
| W02 con saldo suficiente | Sesión3 evento5 descrito abajo; recoge y despliega con el mismo gesto | **FAIL** |
| W03: despliegue explícito libre con fondos | No se ejecutó todavía un caso independiente completo | NOT RUN |
| W06 | Render1152×648/960×540 aprobado T005; falta resize seguido de clic | PARCIAL |
| W07 Android físico | Xiaomi conectado por ADB; no se abrió aún Chrome ni se pidió toque para evitar probar este bug al usuario | NOT RUN |
| W08 manual hasta terminal | Se observó LOST en partidas naturales de la copia (~34s), sin cierre; no se acredita todavía smoke manual completo del paquete final | PARCIAL |
| W09 terminales automatizados | Suite existente183/183 del baseline; no se repitió ni se convierte en prueba manual | Evidencia histórica T002, regresión final pendiente |
| W10 pestaña/regreso/recarga | Recargas crean sesiones nuevas observadas; regreso/suspensión completo aún pendiente | PARCIAL |

## Reproducción W02

1. Iniciar nivel natural; no crear fondos, enemigos ni pickups por código.
2. Recoger los cuatro primeros pickups por clic en sus posiciones visibles.
   El observador registra saldo12, costo existente10 y celda6,4 libre.
3. Esperar otro pickup natural en x576/y≈452. En el evento observado había
   **dos pickups superpuestos de amount3**, no se atribuye un bug a ese
   solapamiento ni se pide cambiar su política.
4. Un clic CUA en576,452: `INPUT_PRE` registra **PLAYING (0)**, saldo12,
   ninguna celda ocupada y cero soldados (el inicial acababa de morir).
5. El mismo gesto registra **12→2→5→8**: gasto10 y dos ganancias3. `INPUT_POST`
   sigue PLAYING, ambos pickups desaparecen y hay un soldado nuevo en
   **624,432 / celda6,4**, ahora ocupada.

Esperado para esos dos pickups: saldo18, sin despliegue ni gasto de10.
Observado: saldo8 y nuevo soldado. La regresión RED posterior usará **un único
pickup aislado** para discriminar el contrato sin discutir solapamientos.

[Logs sesión1](observer-desktop-session1.json),
[sesión2](observer-desktop-session2.json),
[sesión3 con fallo](observer-desktop-session3.json),
[antes](observer-w02-before.jpg), [después](observer-w02-after.jpg).

Se repitieron las cuatro recogidas y el clic posterior en el **ZIP limpio
extraído sin observador** servido en `http://127.0.0.1:8061/clean/`: el amarillo
desaparece y aparece un soldado blanco en624,432 con el mismo gesto.
[Acciones y consola](production-w02-actions.json),
[antes producción](production-w02-before.jpg),
[después producción](production-w02-after.jpg).
Como ese build no expone saldo ni estado terminal, solo se le atribuye la
confirmación visual; los números/PLAYING pertenecen al observador.

## Consecuencia

Los ZIP T010 siguen siendo candidatos **WIP** con arranque/empaquetado
aprobados y gameplay con este fallo. No se publicaron ni difundieron. La
hipótesis de orden de input/picking queda respaldada por la reproducción;
una corrección corresponde a nuevas tareas RED → dev → GREEN → QA. No se
modifica el preset para ocultarla ni se reescribe evidencia histórica de002.
