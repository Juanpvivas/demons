# T007 — Interacción Web, avance y bloqueo W02

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
