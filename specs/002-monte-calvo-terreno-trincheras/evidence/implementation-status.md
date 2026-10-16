# Monte Calvo — evidencia consolidada para revisión final

**Actualización2026-10-16, godot-tester.** La evidencia de ejecución está congelada para auditoríaT016. QA ya aprobó los mínimos por vía; la aceptación global, consolidaciónT017 y revisiónT018 corresponden a sus roles. Este informe no marca tareas ni sustituye esos dictámenes finales. El reporteWIP original del2026-10-15 se conserva íntegro más abajo como historia.

- Arteestático: sueloocre, cielo/montañasfrías, una posición amplia de tierra/madera/sacos y bordes. Escenavisual43eec852… y recursos invariantes; composición/recorteV1–V4 en [US3](us3.md)/[matriz](native-validation-matrix.md). NingúnHUD, colisión, control o mecánica incorporada por el arte.
- CorrecciónI4 separada: [REDT019](t019-red.md)→sourcea473585/script4e89dce…→[GREEN6y189/189/532aserciones/importlimpia0](t021-green.md)→QAcoreT022. Se conserva el defectohistórico antes/después delarte y no se inventaREDartístico. Invariantes95/97originales exactos: únicamente instanciaartística yfixI4 aprobados; geometría/datos/oleadas/balance/InputMap/presetsproductivos intactos.
- RatónhumanoOS: [BASEI2](native-pc-base-cd-human.md), [BASEI1/I4/I9](native-pc-base-cd-human-run2.md), [FINALI1/I2/I4/I9](native-pc-arte-cd-human.md), PRE/POSTPLAYING y dictámenesQA aprobados; I3previo reutilizado. AppsDEBUG con bundle/userdirs separados y labelsIGNORE/FOCUSNONE, [proveniencia](native-pc-cd-readable-provenance.json). No inputinterno ni modificación de estado.
- Android: [AVDcontroladoantes/después](native-avd-input.md) cubreI1–I4/I9 en su vía autorizada. [Xiaomihumano](native-android-input.md) aporta muestreofísicoI1/I3 y partida≈51s; I2/I4físicos no demostrados, sin rellenarlosconAVD ni exigirlosporrutina. APKnormal finalsinobserver restauradoycerrado.
- V4: [iPadPro13M5/iPadOS27.0](native-ipad-setup.md) Compatibilitytemporal, enginearm64 deltag4.7.1sinparches, ruta realmouse+touch humana; I1/I3finales eI4conpre≥10BASE/FINALaprobados. I2/I9iPadno demostrados y no crean repetición porSO; hardwareiOSno probado. La captura estática del soldado por encima del frente se reutiliza aunLOST, sin inventarframeactivo.
- Rendimiento: [medicionesGodotfísicas](native-device-performance.md), [humana≈50s](native-human-performance.md) y [controlguardado35→45](native-save-control.md), con SC-007 aprobado porQA **solo002/Xiaomi11TProprovisional** conforme decisiónhumana/constitución1.2.0. Se conservan valle54/55FPS/frame24,453ms, estados/seleccionesy límites; no60universales/cargafríaabsoluta ni equivalenciaSoftwareRenderer.
- [Smoke](smoke.md) conserva derrota natural humana y escenarios separados de victoria/derrota automatizados, sin atribuir victoria manual de10oleadas. No hay otra ejecución pendiente deltester; quedan QAglobal/documentación final por sus roles.

## Límites que se mantienen

Las capturas históricasPC se reutilizan por identidad de arte, sin atribuirles fuenteI4corregida. Capturasposteriores aLOST se etiquetan como estáticas, eventosLOSTno apruebanPLAYING. La capturasecundariaBASErun2fallósetup/SIGTRAP y no se repitió; raw/derivado/proofconcluyentesse conservaron. Los avisos deldisplayserveriOS y warningsGUTpreexistentes permanecen, sin declaración de runtimeceroavisos. No se certifican hardwareiOS, otrosmóviles/Web, ausencia de todo frame largo, carga fríacompleta ni memoriaexclusivadeljuego. Esta entrega es002y no cierra003.

---

## Historial literal — ejecuciónWIP del2026-10-15

# Monte Calvo — estado de ejecución WIP

**Fecha**: 2026-10-15, Bogotá. **Rol**: `docs-writer`, reporte de evidencia FR-012.
**Estado**: trabajo en curso, con aceptación global de la feature pendiente. No sustituye los gates de [tasks.md](../tasks.md), ni constituye T017 de consolidación.

## Arte y estructura disponibles

La escena estática `MonteCalvoVisual.tscn` compone suelo ocre, cielo y montañas azul grisáceo, rocas/hierba laterales y una posición amplia de tierra, madera y sacos. Usa tres PNG, seis regiones compartidas de atlas y un gradiente nativo de cielo; todo queda detrás de actores y pickups, sin scripts, input, física, cámara, HUD o sistemas nuevos. [Procedencia, dimensiones, regiones y prompts](../../../assets/sprites/levels/monte_calvo/SOURCES.md).

El terreno real mide 1254×1254 y se usa como hoja única sin repetición, pues el ensayo 2×2 mostró juntas. Montañas y atlas miden 1536×1024. La cobertura se resuelve solo con la composición del arte; la [guía de producción](../references/production-brief.md) conserva la máscara de bajo ruido y las coordenadas jugables.

| Estado comparable | Antes del arte | Terreno sin trincheras | Arte completo WIP |
|---|---|---|---|
| Inicial, PC V1 | [Baseline](pc-v1-0.png) | [US1](us1-v1-0.png) | [Final V1](final-v1-0.png) |
| Combate y pickups, PC V2 | [Baseline](pc-v2-1.png) | [US1](us1-v2-1.png) | [Final V2](final-v2-1.png) |

Son estados aproximados capturados del viewport, no frames idénticos ni pruebas de clic OS. V1 es 1152×648 y V2 es 1920×1080 físicos; ambos muestran el mismo rectángulo lógico 1152×648, con stretch 1 y 1.666667. Las ocho capturas con decoración y su comparación completa están en [US3](us3.md).

## Verificación y aprobación acotadas

- QA aprobó T006/T007 para integración estática y lectura PC V1/V2; [US1](us1.md) registra continuidad sin juntas en la composición de hoja única. T010 aislado y T011 técnico/visual PC recibieron aprobación WIP anticipada, sin corrección visual bloqueante ni aceptación global.
- La [regresión final](regression.md) pasó **183/183 pruebas, 496 aserciones, 0 fallos**, con los mismos tres warnings de la línea base. Importación del checkout con caché y GUT retornaron 0. Una [importación limpia adicional](final-clean-import.log), en copia final sin `.godot`, también retornó 0, generó tres `.ctex` nuevos y conservó **10/10 hashes** del manifest final; [resumen](final-clean-import-summary.json). Las pruebas existentes permanecen intactas; no se repitieron GUT o capturas tras esa importación adicional.
- El [manifest final](final-sha256.json) conserva **96/97 archivos originales idénticos**. La única diferencia protegida es `Nivel_MonteCalvo.tscn`: referencia e instancia del entorno más `load_steps`; sus nodos, propiedades y lógica originales se conservaron. No cambian balance, Resources, oleadas, geometría, InputMap o exportaciones.
- El [smoke PC](smoke.md) observó combate natural y derrota en V1/V2. Los escenarios separados de victoria/derrota pasan en GUT; no se acredita una partida ganada manualmente con las diez oleadas.
- [US2](us2.md) separa cobertura automatizada y conservación estática de la matriz de entrada real aún incompleta. Z y regresión headless no acreditan picking.

El registro actual mantiene **7/18 checkboxes aprobados, T001–T007**. Las aprobaciones técnicas anticipadas de T010/T011 no cierran sus dependencias ni marcan esas tareas. Solo el orquestador actualiza los checkboxes después de QA.

## Android: evidencia parcial final

En Xiaomi `2107113SG`, Android 14, renderer Mobile/Vulkan, la app debug final se exportó e instaló localmente sin cambios de versión, firma o configuración. Las capturas muestran el juego con arte a 2400×1080. La [sesión humana sin arte](android-human-baseline.md) y la [sesión final con decoración](android-human-final.md) registran recolección/despliegue; en la última, la persona confirmó: **«Recogí, desplegué y no se duplicó»**. [Captura de la sesión final](android-human-final-18s.png).

No se registraron por toque las coordenadas, celda o saldo. La confirmación de ausencia de duplicación no distingue celda ocupada de fondos insuficientes ni acredita por sí sola que recoger un pickup no cause un despliegue adicional. I2/I3 pasan en GUT, pero esos casos físicos y toda I4/I9 controlada siguen pendientes. Las capturas acreditan lectura de actores delante de la decoración, sin convertirlas en una matriz completa de picking.

La [comparación de rendimiento](performance.md) midió dos ventanas de aproximadamente 30 s de autoplay, separadas de la sesión humana. Cadencia de presentación estimada: **60,464→60,462 FPS**; intervalo medio **16,538732→16,539286 ms**, sin intervalos >20 ms en esas ventanas. El PSS total aumentó 4579 KiB alrededor de 8 s y 5020 KiB alrededor de 38 s. SurfaceFlinger mide presentación y PSS mide el proceso completo: son muestras acotadas, no FPS instrumentados por Godot, VRAM ni evidencia de 60 FPS estables constitucionales. La prueba no controló temperatura/carga máxima ni verificó la categoría del dispositivo como referencia objetivo.

## Gates pendientes

Permanecen pendientes la matriz completa de ratón/toque e I1–I9 aplicables, clic OS PC y casos de pickup sobre/junto a decoración sin despliegue adicional; iOS físico y el resto de proporciones de pantalla exigidas; rendimiento sostenido constitucional, tiempos CPU/GPU, memoria real de texturas/VRAM y carga completa. Capturas, cadencia de SurfaceFlinger o PSS total no sustituyen esas mediciones.

T008/T009 y los gates T012–T018 conservan sus requisitos. No hay aceptación global SC-001–007, graduación a `docs/SPEC.md`/`docs/ARCHITECTURE.md` o cierre de la feature. Los reportes de tester documentan sus resultados disponibles y limitaciones; no aprueban por sí solos las tareas completas. Este reporte no modifica gameplay, pruebas o tareas, ni acredita verificaciones nuevas.
