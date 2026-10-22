# Contrato de diagnóstico de 006

I1 quedó integrado mediante PR #31 (`d86543f`), con base histórica `5d50cb0`.
Su contrato e invalidaciones se conservan. I2 parte de `2272aa2` y añade al final
un carril específico de componente GPU Web; no acredita resultados de I2.

## Escenarios y comparabilidad

1. **Producción**: nivel y reglas intactos; capturar carga/estado y recorrido funcional. Si las poblaciones divergen, sus tiempos son descriptivos, no una prueba causal.
2. **Render constante**: montaje temporal explícito con cinco dueños, enemigos declarados por el fixture y 19 cajas incluyendo descendientes de pools. Fijar lógica/movimiento sólo en ese escenario, conservando animaciones/poses y render. No atribuir sus resultados al coste del gameplay.
3. **Ablación**: variar un solo factor de la base en una copia temporal (material, dibujo, pulso o pacing/foco/vsync según hipótesis). Declarar diferencias; nunca distribuir ni sustituir con ella la candidata normal.

Cada condición usa 10 s de calentamiento y 30 s de reloj monotónico medidos. La pareja base B/candidata C usa seis runs en orden B,C,C,B,B,C: tres repeticiones por variante. Usar el mismo probe, collector y flags en ambas fuentes. Reiniciar escenario entre runs y no mezclar carga fría/caliente. Registrar cualquier interferencia y repetir sólo la ventana invalidada; no seleccionar la mejor muestra.

La clave de comparabilidad incluye revisión y modificaciones QA, engine/build, renderer, escenario/carga/semilla, geometría real, escala/DPR, orientación, límite/vsync/foco y estado inicial esperado. La revisión/artefacto distinguen B/C; los demás factores permanecen equivalentes. Web conserva DOM/DPR contemporáneos al inicio/final; APK conserva 2400×1080 horizontal/lógica1440×648 y density420 sin override; iPad declara lógica1152×864 y área observada en DeviceHub. No imponer geometría a un destino distinto para ocultar una regresión histórica.

## Instrumento mínimo

`tools/performance/probe.gd` es un Node optativo, instanciado sólo por un collector de QA en copias temporales. El juego normal no lo referencia ni lo activa. Su API se preparó como esqueleto invocable antes de RED y quedó aprobada funcionalmente en T007:

- `start(config: Dictionary, initial_snapshot: Dictionary, at_usec: int) -> bool`: limpia todo run previo; exige `run_id`, contexto y conteos iniciales esperados independientes de la función de snapshot. Copia por valor la configuración y valida la observación inicial contra ella; rechaza inicio incompatible o incompleto.
- `record_wall_interval(at_usec: int) -> void`: recibe marcas absolutas monotónicas y almacena diferencias positivas desde la marca de `start`, fijada después del calentamiento externo. No usa delta de juego; cero/regresión invalida el run. Se registra el intervalo que alcanza o supera `window_usec` y se conserva su duración real, incluido ese último frame.
- `snapshot_recursive(root: Node) -> Dictionary`: lee descendientes reales, incluidos pools, y devuelve inventario/estado por valor sin mutar la partida. No infiere DOM, foco, preset ni otros datos externos; el collector completa esa observación como se indica debajo. Activo se determina por estado real del actor/pool, no sólo por visibilidad: ocultar dibujo en una ablación no elimina actores.
- `finish(final_snapshot: Dictionary) -> Dictionary`: exige al menos dos intervalos, duración acumulada ≥`window_usec`, observación final vinculada al run, condiciones esperadas/observadas y cohorte constante compatibles; devuelve copia del informe cerrado. Es idempotente; registrar después de cerrar no modifica el resultado. Una muestra vacía, corta o incompatible no devuelve PASS ni tiempos cero ficticios.
- `compare_runs(base: Dictionary, candidate: Dictionary) -> Dictionary`: comprueba por código que ambos runs son válidos y sus condiciones observadas ya validadas y cohorte lógica coinciden, permitiendo distinta revisión/artefacto/run_id. No basta que sus configuraciones esperadas sean iguales ni se exige igualdad de IDs de instancia entre procesos. Devuelve `valid` y `errors`; no decide una ganancia causal por una única pareja.

Config contiene `run_id`, `revision`, `artifact`, `window_usec`, `conditions` esperadas y `expected_counts`. Revisión/artefacto/run_id identifican la ejecución y no pertenecen a la clave común. El informe conserva esos seis campos de contexto en su nivel superior y devuelve `initial_snapshot`, `final_snapshot`, `valid`, `errors`, `sample_count`, `duration_usec` y `frame_ms` (`mean`, `p50`, `p95`, `p99`, `max`), además de los snapshots. Cada motivo de `errors` identifica la clave invalidada, sin exigir una frase exacta. El informe del probe incluye obligatoriamente la serie original de diferencias como `frame_intervals_usec`, asociada al mismo run_id, para que QA recalcule el resumen. Sin muestras válidas, las métricas quedan ausentes/vacías.

### Condiciones esperadas y observadas

`conditions` requiere las ocho claves siguientes; sus valores son datos serializables, sin Node. El collector obtiene los valores observados de la fuente indicada y de las lecturas externas contemporáneas, no copiando la configuración esperada:

| Clave requerida | Contenido y procedencia observada |
|---|---|
| `engine_build` | Versión/build realmente ejecutado, leído de Godot y del binario/artefacto identificado por el collector. |
| `renderer` | Método/adaptador realmente activo, leído de Godot o del diagnóstico de arranque, no sólo del preset solicitado. |
| `scenario` | ID/semilla/carga y versión del fixture efectivamente montado, obtenidos de sus nodos/argumentos y fuente de montaje verificada. |
| `viewport` | Rectángulo lógico y escala efectivos, leídos del viewport/ventana de Godot. |
| `surface` | Web: rectángulo DOM/canvas y DPR leídos en el navegador. APK: tamaño/orientación/density leídos del SO. iPad: área/vista de DeviceHub y tamaño/orientación efectivos observados. La forma del valor se mantiene dentro de cada destino. |
| `pacing` | Límite de frames, vsync y foco efectivos, leídos de Godot/SO; un valor solicitado no sustituye al efectivo. |
| `configuration` | Configuración/flags efectivos relevantes y manifiesto de montaje/probe/collector verificado desde la copia/artefacto y ajustes reales. |
| `observer` | Versión/hash/modo del instrumento realmente cargado, observado desde el collector y su fuente, incluido modo mínimo o detallado. |

`snapshot_recursive` entrega `counts = {soldiers, enemies_active, enemies_inactive, pickups, queued}` con enteros no negativos; `queued` cuenta elementos relevantes pendientes de borrado, excluidos de los conteos activos. Cada entrada de `entities` contiene `key` lógica no vacía, `type` normalizado (`soldier`, `enemy` o `pickup`), `instance_id`, `activation` y los valores aplicables copiados: `position` global, `health`, `ammo`, `morale`, `movement` y `amount`. No se rellenan campos ajenos al tipo con referencias o valores inventados. La lectura reconoce los actores reales y el estado del pool, sin usar visibilidad como sustituto de actividad. El collector añade `observation = {run_id, phase, at_usec, conditions}`. Cada condición observada tiene `{value, source, availability}`: `source` identifica la lectura real y `availability` debe ser `observed` para comparar. Lecturas externas conservan además su instante/phase de captura y procedencia propios; `at_usec` vincula el snapshot a la frontera en el reloj monotónico del run, sin confundir relojes de distintos procesos.

`start` exige phase `initial`, run_id correcto y `at_usec` igual a su marca de inicio. `finish` exige phase `final`, el mismo run_id y una marca ≥la última muestra; verifica nuevamente todas las condiciones contra las esperadas y el inicio. Cada lectura ausente, `unknown`, `unavailable`, sin procedencia o con distinto valor requerido invalida la comparabilidad con una razón identificable; no se rellena con expected. Esto no obliga a inventar métricas opcionales GPU/Self/memoria ausentes. `compare_runs` comprueba por código las condiciones observadas completas de los runs válidos, sin comparar sus etiquetas de origen o sus instantes como si fueran configuración.

`valid=true` acredita las comprobaciones mecánicas sobre los valores entregados, no que una API mida su significado efectivo. El collector debe comprobar su observabilidad: un getter constante o de fallback se declara no disponible como observación efectiva y no satisface la condición causal, aunque coincida con expected. T009 detectó este límite en foco/vsync nativos del motor usado; véase [la decisión](../research.md#decisión-de-t009-entregar-diagnóstico-sin-parche). No se reinterpretan los informes APK ya recogidos como una base nativa acreditada.

Dentro de un run se auditan IDs de instancia y activación para detectar retiro/reciclado inesperado. Entre runs se compara el manifiesto lógico de roles, conteos y estados esperados, no IDs asignados por otro proceso. Los conteos esperados proceden del montaje independiente; la actividad sigue al estado real del actor/pool y un activo oculto sigue contado como activo.

El esqueleto inicial sólo declaraba estos métodos con resultados vacíos/falsos, sin implementar el contrato. Las pruebas usan series conocidas, reloj regresivo, inicio incompatible y condiciones observadas distintas/ausentes frente a expected en inicio/final/comparación, inventario anidado/activo oculto/inactivo y queued, neutralidad del snapshot y reinicio; no inspeccionan texto del shader ni fijan FPS de CI.

El collector toma snapshots inicial/final y cada 2 s. Comprueba conteos frente a un manifiesto independiente y conserva identidad/activación, salud, carga, moral, posición, movimiento, reserva, ocupación y estado terminal pertinentes. Registra inactivos aparte; arrays vacíos no se interpretan como población cero válida. Un cambio inesperado de geometría o cohorte invalida la comparación constante.

Los intervalos se acumulan en memoria: sin prints, JSON o flush por frame ni durante la ventana. El informe se emite una vez al finalizar. Comparar un observador mínimo de reloj con el detallado permite cuantificar perturbación; si no se puede aislar todo el coste, declararlo. El tiempo propio de snapshot/collector no equivale a todo el impacto gráfico.

## Métricas y decisión

Tiempos en ms: media, p50, p95, p99 y máximo; percentiles por rango más próximo sobre la serie ordenada (`ceil(q*n)-1`). Guardar tamaño/duración de ventana y derivar FPS de la misma serie, sin sustituirla por el promedio del monitor FPS.

Registrar carga inicial con origen/caché declarados, `TIME_PROCESS` (tiempo de frame) y `TIME_PHYSICS_PROCESS`, draw calls y monitores de memoria disponibles con unidad. No etiquetar TIME_PROCESS como Self/CPU ni obtener GPU por resta. Un cero no acredita ausencia de coste: marcar disponibilidad y cadencia conocida. Self de scripts/GPU sólo si el profiler lo proporciona realmente. Memoria de motor/rendering no se convierte en RSS/VRAM física ni en coste exclusivo de un asset.

Comparar medianas y rango de las tres repeticiones para cada métrica relevante. Una ganancia que no se distingue de la dispersión de B se declara no acreditada; no se fija un porcentaje de mejora antes de medir. Investigar cualquier empeoramiento repetible del p95/p99 o carga/memoria y someter su riesgo a QA, conservando métricas contrarias a la hipótesis. La candidata sólo se acepta si satisface SC-003 y la equivalencia funcional/visual; un frame cap puede ocultar una mejora de trabajo, que requiere entonces una medida específica disponible.

Para el shader, la candidata sólo puede evitar lecturas vecinas con alfa central cero, conservando salida RGBA, antialias, bordes, poses, tintes, flips y caída. Sin `discard`, cambio de material/arte, brillo, hitbox, resolución, cadencia o física de producción. Verificar compilación/exportación y equivalencia visual con la base; presentación equivalente no necesita RED artificial.

Publicar exige sus gates separados: estos experimentos no aprueban T039/T071, Mobile, GPU física, firma/paquete final ni 60 FPS físicos. Las fuentes, comandos, resultados y límites nuevos se resumen en el PR; no se añaden evidencias a Git.

## Adenda I2: componente GPU Web

### Base, alcance y preflight

- Rama `codex/006-i2-estabilizacion`, Issue #30. B es `main` `2272aa2`;
  C es esa misma fuente con una sola intervención temporal identificada.
  No sustituir B por I1, `5d50cb0` o un paquete anterior al menú de 007.
- Separar producción, render constante y ablación. Congelar lógica sólo en el
  montaje de render constante, sin cambiar el significado del inventario.
  Usar manifiesto independiente, misma carga, geometría, artefactos identificados,
  collector y flags comunes. Reiniciar entre runs.
- El tester realiza primero un preflight de cobertura y perturbación. Aprobar
  preparación o disponer de la extensión no autoriza un lote; el orquestador
  debe confirmar su alcance tras revisar el preflight con QA.
- Conservar 10 s de calentamiento y 30 s de reloj monotónico medidos, y el orden
  B,C,C,B,B,C con tres repeticiones por condición, también en el carril GPU.
  Mantener observador mínimo/detallado como control de perturbación y conservar
  ventanas inválidas y métricas contrarias a la hipótesis, sin elegir la mejor.

### Medición real del componente

- Sólo aceptar timer queries reales `EXT_disjoint_timer_query_webgl2` sobre el
  mismo contexto WebGL2 que usa Godot para dibujar dentro de cada run. Registrar
  identidad/procedencia del contexto, extensión, fuente y modo del instrumento.
  Un contexto independiente o un temporizador CPU no mide ese componente GPU.
- Demostrar en el export single-thread que el bracket pre/post draw engloba
  los comandos de dibujo pertinentes: no basta nombrar `frame_pre_draw` y
  `frame_post_draw`, ni rodear un callback RAF sin comprobar esa cobertura.
  El preflight debe detectar brackets vacíos, fuera de orden o de otro contexto.
- Abrir/cerrar la consulta alrededor de ese tramo y recuperar resultados sólo
  de forma asíncrona cuando estén disponibles y sin disjoint. Conservar unidad
  original en ns, conversión a ms, asociación al run/frame y estado de cada query.
  No usar `gl.finish`, espera activa, valores cero sustitutivos o tiempo por resta.
- Ausencia de soporte/cobertura, fallo de consulta, resultado ausente o disjoint
  invalida este carril y se declara como tal; no rellenar con una medida CPU ni
  presentar el subconjunto favorable como una ventana completa válida.
- DOM `hasFocus` y `visibilityState` describen literalmente el documento y sus
  eventos observados. RAF describe la entrega de callbacks; ninguno certifica
  foreground efectivo del SO, presentación de frames o VSync físico.

### Relación con el probe y nueva decisión

El carril de componente GPU se evalúa por separado de tiempos globales/FPS y de
`probe.compare_runs`. No modifica el probe: siguen siendo obligatorias sus ocho
condiciones, procedencias, cohortes e invalidaciones. No forzar `valid=true`,
copiar expected o convertir foco/vsync desconocidos en observaciones efectivas.
Una medición GPU válida no completa comparabilidad global, T008/SC-001 nativos
ni certificación de hardware/paquete; sus límites permanecen explícitos.

El nuevo dictamen **T009-I2** sólo puede autorizar una candidata con señal
repetible pertinente, distinguible de la dispersión y del coste del observador.
Quitar el material completo puede aislar coste de esa ruta, pero no demuestra
ahorro de las cuatro lecturas vecinas ni neutralidad visual. La candidata real
necesita después su propia comparación y equivalencia funcional/visual.
Sin señal o cobertura válidas, no se autoriza T010 y T010–T012 siguen pendientes.
El dictamen histórico de I1 sin parche no se convierte en autorización de I2.

Collectors, copias, consultas y resultados de este carril permanecen temporales;
el PR resume fuentes, comandos, resultado y límites. No añadir registros a Git
ni activar el instrumento en el producto normal. Publicación sigue pendiente.
