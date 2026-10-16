# Rendimiento de la sesión humana final — complemento, 2026-10-16

Esta es **la misma sesión física ya realizada**, no otra ejecución ni reemplazo de la comparación autoplay. Fuente `a473585`/script4e89dce…, APK final instrumentado37b465…, Xiaomi11TPro/Android14/Mobile-Vulkan. Hubo recolección y despliegue humanos, de1a2soldados y combate hasta derrota natural cerca de51s. [Gestos/condiciones](native-android-input.md), [raw de proceso](native-android-final-human.log), [archivo por frame hasta35s](native-android-final-human-telemetry.json), [resumen y serie crítica](native-human-performance-summary.json).

## Perturbación observada, conservada

- A epoch1792161979.717, elapsed35.000179s, estadoPLAYING: Godot61FPS, tiempo de proceso17.938ms.
- A epoch1792161979.824: `NATIVE_TELEMETRY_SAVED rows=2099`, **107ms después** de la línea anterior. El observador serializa todas las filas con `JSON.stringify` y las escribe sincrónicamente dentro de `_process`, justo después de35s.
- A epoch1792161980.824, elapsed36.002607s, todavíaPLAYING: **54FPS, `TIME_PROCESS`114.607ms**, GPU2.807ms; no se oculta ni se presenta como60.
- A epoch1792161981.816, elapsed37.000634s: vuelve a61FPS, proceso17.482ms, GPU2.781ms.

La correlación temporal y la operación síncrona son **consistentes con una perturbación fuerte del instrumento**. No demuestran causalidad con un contrafactual ni exoneran automáticamente al juego. En las muestrasPLAYING posteriores a5s, el único valorFPS inferior a60 es el54a36s; no se identificó otro valle sin esta explicación. Los contadores se muestrean a1Hz: no detectan todos los frames largos.

El derivado separa arranque y la ventana del guardado: PLAYING5≤t<35 y37≤t≤50.1, conservando íntegra la serie cruda. Retira el frame de guardado y el siguiente intervalo del monitorFPS; no elimina silenciosamente valores para declarar estabilidad. En esa selección, las lecturasFPS son60–61. Los cuantiles del resumen son de **snapshots de1segundo**, no distribución completa por frame después de35s; `TIME_PROCESS` no es CPUexclusiva y memoria de texturas/video son contadores del renderizador. La observación humana de≈50s aporta una sesión con interacción, sin convertirla en certificación de todos los frames o de todos los móviles.

QA solicitó un único control del observador con guardado aplazado35→45s, autorizado por el orquestador y **posteriormente ejecutado una sola vez** según [control preservado](native-save-control.md). Ese control no pidió toques ni cambió el juego; estuvoLOST en34–37s y no se llama gameplay. Conservó fuente original/diff/hash, separando ambas cargas. El dictamenSC007 corresponde aQA y a la referencia provisional002 aceptada por la persona, no se marca desde este complemento.

ActualizaciónQA: el control desplazó el valle alguardado45s(55FPS/111.074ms a46s), con34–37s a61/60/60/61FPS; suestadoLOST y elhumanoPLAYING se mantienen separados. QA aprobóSC007 solo paraXiaomi como referencia provisional002 autorizada; no equivale a certificar todoslosframes, otrosdispositivos o rendimientoiOS.
