# PC BASE — primera sesión humana con ratón

**I2 aprobado por QA; I1/I4/I9 no acreditados en esta sesión.** La persona informó que no completó los seis pasos y vio naranja el soldado antes del clicB. El color no se interpreta como muerte: el PRE/POST deB confirma que seguía vivo y ocupaba6,5.

Se recuperó sin cerrar, relanzar o cambiar foco: [raw](native-pc-base-cd-human.log), [derivado](native-pc-base-cd-human-derived.json), [hashes/procedencia](native-pc-base-cd-human-proof.json), [captura solo de nuestra app](native-pc-base-cd-human-current.png)/[metadatos](native-pc-base-cd-human-capture.json). Raw75.880bytes/SHA326e305b74940137bd67ff6c9db0535426d1cf2ff00655be9dc6e654f533bf05; unaINITIAL2539ms,9PRE/9POST, canal realmente recibido mouse.

| Caso | PRE→POST | Resultado |
|---|---|---|
| Recogidas seq1–4 | 0→3→6→9→12,1→1soldado,PLAYING | Recogida real con pre<10 |
| I2 B seq5,t18998 | Ratón628,529/celda6,5 ocupada, sinpickup;12→12/1→1/PLAYINGambos | APROBADO QA: sin gasto ni segundo soldado |
| C seq6,t40514 |537,624/celda5,6 libre,12→2/0→1,LOSTambos | No PASS I1 durante partida |
| Pickupseq7,t47672 |581,449,pre2→8 por DOSpickups3solapados,LOST | No PASS I4 fondos≥10/PLAYING |
| Dseq8–9,t84992–86072 |59,148 y58,148/celda0,1,8→8/1→1,LOST | No PASS I9 |

El ratón es acción humana del SO sobre la app exportada local; no CUA sintetizado, CGEvent, handler ni modificación de estado. Naranja/MELEE conserva ocupación mientras vivo; no se deduce que la celda quede libre hasta que los snapshots lo muestran. El registro posterior aLOST se conserva sin presentarlo como prueba activa ni añadir una corrección de gameplay fuera del alcance.

Fuentea473585/script4e89dce…/observerbasec628…; extensiónCDlegible123c0a98…/manifest91847b7c… previamente aprobados porQA. Binario/PCK y siete archivos deapp coinciden conmanifest. BASEsinartesolo incluye metadata temporal deapp/userdirCD y labelsC/DIGNORE/FOCUSNONE. La captura pública se limita al bundle/ruta propios; ventana576×356puntos, render1152×712incluyebarra32puntos, contenido lógico1152×648. Coordenadasdelobserver son viewport=mundo; convertir a host requiere añadir origen224,152 ybarra32puntos, escalarcontenido×0,5. El clicB equivale aproximadamente a host538,448,5puntos; no se afirma haber registrado la posiciónglobaldelpuntero.

Se congelan todos estos archivos ANTES de cerrar nuestra app. Una futura sesión BASE se registrará en otro prefijo y solo cubre I4/I1/I9 restantes, sin repetirB/I2 aprobado. No se marcan tareas.
