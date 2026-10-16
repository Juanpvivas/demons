# T012 — Trincheras integradas: comprobación visual disponible

**Rol**:`godot-tester`. **Fecha**:2026-10-15Bogotá. **Rama**:`codex/002-monte-calvo-terreno-trincheras`. VerificaciónWIP deT011, sin lógica nueva ni RED artificial. Estado final congelado en [final-sha256.json](final-sha256.json); escena visualSHA`43eec852955409b76a172a756cdceaa33689d123a2f8b580880a752925b22be2`.

Godot4.7.1mono, Mobile/Metal, mismo entornoPC del baseline. Tras importación0 se ejecutaron observadores temporales de lectura sobre `/private/tmp/monte-calvo-t001-0pulm9d5/final-project/`; ambas sesiones finalizaron a42s con **retorno0**. Capturas delViewport, sin entradaOS acreditada. [LogV1](final-v1.log), [logV2](final-v2.log).

```text
Godot --path <temporal>/final-project --script <temporal>/observe_final_v1.gd --windowed --resolution 1152x648 --position 100,100 --log-file <evidence>/final-v1.log -- prefix=final-v1
Godot --path <temporal>/final-project --script <temporal>/observe_final_v2.gd --windowed --resolution 1920x1080 --position 100,100 --log-file <evidence>/final-v2.log -- prefix=final-v2
```

| Estado | V1(1152×648) | V2(1920×1080) |
|---|---|---|
| Inicial |[captura](final-v1-0.png)|[captura](final-v2-0.png)|
| Combate y pickups,~8s |[captura](final-v1-1.png)|[captura](final-v2-1.png)|
| Melee,~20s |[captura](final-v1-2.png)|[captura](final-v2-2.png)|
| Tras derrota,~40s |[captura](final-v1-3.png)|[captura](final-v2-3.png)|

## Comparación con/sin decoraciónUS3

Se preservó el estadoUS1 sin trincheras ni rocas del atlas en `terrain-project/`, con escena temporal `terrain-without-trenches.tscn`, SHA`5138a1c34b67a677242308bddbf7e62c8891115aae4ac63bba72530e1d39cb0c`. No se cambió producción para esta comparación. Sus capturas y hashes anteriores permanecen disponibles:

| Comparación | Sin atlasUS3 | Con atlasUS3 |
|---|---|---|
| V1inicial |[US1](us1-v1-0.png)|[final](final-v1-0.png)|
| V1combate |[US1](us1-v1-1.png)|[final](final-v1-1.png)|
| V2inicial |[US1](us1-v2-0.png)|[final](final-v2-0.png)|
| V2combate |[US1](us1-v2-1.png)|[final](final-v2-1.png)|

Son estados equivalentes aproximados, no frames idénticos. T011conserva los8nodos visualesUS1 y añade11sprites con6AtlasTexture. Una posición amplia de madera/tierra/sacos ocupa aproximadamentex92..1058,y552..653; las rocas/hierba enmarcan laterales. No aparecen cinco puestos/carriles o casillas nuevas. La madera y los sacos se distinguen como materiales y quedan detrás de actores/pickups; el soldado inicial permanece encima y separado del frente. No se observan rectángulos opacos, bleed de piezas vecinas o halos negros manifiestos. Los últimos píxeles inferiores del frente quedan recortados por el encuadre lógico648, sin mover la defensa preexistente que ya se extendía hasta682.

V1/V2conservan rect lógico1152×648; canvasidentidad y stretch1/1.666667. Centro de combate, rojo/blanco/amarillo y ejex576 legibles; no se introdujeron límites de despliegue. No se atribuye picking a la posición de z. El subárbol contiene soloNode2D/Sprite2D y recursos de textura/gradiente, sin comportamiento.

## Plataformas y límites

[CapturasAndroid y comparación de rendimiento](performance.md) corresponden a un debug local final. Android e iOS no se dan por aprobados por una captura. La [segunda prueba humana con arte](android-human-final.md) se ejecutó después del autoplay y acredita actividad parcial de recolección/despliegue; mantiene explícitos los casos no discriminados.

**Pendientes**: clicOS PC, matriz completaI1–I5/I9conratón/toque y pickups tocados cerca/sobre la decoración; iOS físico; mediciones sostenidas/VRAM/carga. No se forzó un pickup cerca de la trinchera ni se movieron actores para fabricarlo. Este reporte acredita render/lecturaPC disponible, sin concluir todaT012oSC005–007. [Regresión](regression.md) y [smoke](smoke.md) aportan evidencia separada. No se marcan tareas ni se alteran fuentes/tests.
