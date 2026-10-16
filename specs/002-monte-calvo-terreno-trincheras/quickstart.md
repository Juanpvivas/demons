# Quickstart de validación — Monte Calvo visual 1

**Estado**: ejecución por agentes autorizada el 2026-10-15, en curso en `codex/002-monte-calvo-terreno-trincheras`. Este documento define las verificaciones; los resultados reales y sus limitaciones se registran en `evidence/` y requieren revisión QA. No acredita por sí mismo ninguna integración o comprobación aprobada.

**Adenda 2026-10-16, preparación aprobada por QA**: V4 admite iOS Simulator por autorización de la persona; iOS físico no probado. El defecto previo de I4 se trata solo en T019–T022, antes de aceptar T008/T009, sin modificar el arte ni reescribir la línea base histórica. Esta aprobación documental no aprueba T019 ni el arreglo; el [registro del orquestador en tasks.md](tasks.md) conserva el estado vigente.

## 1. Registrar la línea base antes de implementar

Responsable: `godot-tester`, con reporte para el orquestador y QA.

- Confirmar la versión de Godot usada por el proyecto/CI (4.7.1), dispositivo, renderer, tamaño efectivo del viewport y versión del checkout.
- Registrar hashes de scripts, escenas de actores, Resources, `project.godot` y geometría de los nodos de `Nivel_MonteCalvo.tscn` según [el contrato](contracts/visual-boundary.md).
- Capturar el nivel con los actores provisionales y registrar, para cada caso de interacción, coordenadas de pantalla/mundo/celda y estado previo. No asumir un viewport base fijo a partir de la imagen.
- Ejecutar la regresión existente y un smoke de partida antes de añadir arte. Separar fallos preexistentes de los cambios futuros; no reparar el juego dentro de una tarea visual.
- Acordar y registrar el dispositivo Android de referencia y los dispositivos disponibles de la matriz. Una herramienta/dispositivo ausente se registra como comprobación pendiente, no como aprobación.

Guardar el reporte en `evidence/baseline.md`; adjuntar capturas con dimensiones/estado y resultados reales. No almacenar tokens, caché `.godot/`, builds o exportaciones en el repositorio.

## 2. Inspeccionar e importar la integración

Responsables: `dev-godot` integra; `godot-tester` comprueba; `qa-validator` revisa.

- Cambios artísticos permitidos: las tres texturas y sus ajustes de importación, `MonteCalvoVisual.tscn` y su nueva instancia en `Nivel_MonteCalvo.tscn`. El único cambio lógico separado previsto es T020, con el archivo de prueba/UID T019 y límites del contrato.
- Conservar las propiedades y rutas anteriores del nivel. Comparar los nodos originales semánticamente además de los hashes de archivos que no deben cambiar.
- Inspeccionar que el entorno no incorpora scripts, input, física, navegación, cámara, luces, shaders, partículas o UI.
- Comprobar que todos los elementos nuevos quedan por debajo de actores y pickups; no asumir que z por sí solo acredita input.
- Revisar halos, costuras, repetición evidente y márgenes transparentes. Ajustar arte o configuración de sus nodos, nunca el tablero/cámara para que encajen.
- Registrar dimensiones de texturas y estimación `ancho × alto × 4` bytes por hoja RGBA8 sin mipmaps; contrastar con la memoria real del dispositivo. Es una estimación, no una medición de VRAM.

Comandos de verificación desde la raíz para el tester, con el motor disponible:

```bash
godot --headless --path . --import --quit-after 2
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs=true -gexit
```

Estos comandos no se ejecutan como parte de Spec Kit. El tester registra salida y código de retorno; un error de parser, importación o entorno no constituye RED.

## 3. Matriz de pantallas y lectura

Registrar las cuatro configuraciones siguientes antes/después. Las dimensiones de dispositivos son las reales del equipo disponible; no se cambia `project.godot` para forzar equivalencia.

| ID | Entorno / encuadre | Entrada | Evidencia obligatoria |
|---|---|---|---|
| V1 | PC, ventana 1152×648 (16:9) | Ratón | Capturas equivalentes y coordenadas del mismo despliegue/recolección |
| V2 | PC, ventana 1920×1080 (16:9) | Ratón | Continuidad de suelo/horizonte y encuadre sin huecos nuevos |
| V3 | Android de referencia, pantalla panorámica cercana a 19.5:9 | Toque real | Resolución/viewport efectivos, capturas, picking y rendimiento |
| V4 | iOS Simulator, tablet o teléfono de proporción distinta a V3 | Gesto sobre la app en la UI del simulador | Modelo/runtime, tamaño/proporción, método de gesto, recorte, lectura y picking; no acredita hardware iOS |

Para V4, preferir tablet simulada si está disponible para ampliar la cobertura de proporciones. Registrar dispositivo/runtime, resolución física y lógica, escala y transformaciones; realizar clic/gesto humano o mediante CUA sobre coordenadas visibles de la app en iOS Simulator, que el sistema entrega como toque simulado. Registrar pantalla→mundo→celda y estado PRE/POST (saldo, soldados y ocupación) con capturas/logs; no invocar handlers o métodos de gameplay como sustitución. Puede usarse observación de solo lectura en una copia temporal con scripts de producción idénticos, sin mutar reglas/estado ni incorporar un HUD a producción. La aceptación de V4 queda acotada al simulador; iOS físico permanece **no probado** y no se extrapola desde Android. Exportar/instalar para simulador solo en copia temporal cuando necesite configuración local, conservando presets, firma y versiones versionados.

V3 y la comparación de rendimiento usan el Xiaomi físico disponible: registrar modelo, SO, resolución, renderer y condiciones reales. El modelo `2107113SG` corresponde al [11T Pro](https://alsgp0.fds.api.xiaomi.com/xiaomi-b2c-i18n-upload/user-guides/7c14b4e9e2c9407999521d60bd3fcdc8.pdf), con [Snapdragon 888/Adreno 660](https://www.mi.com/sg/product/xiaomi-11t-pro/specs/), una [generación de septiembre de 2021](https://www.mi.com/es/service/support/sales2021/serie-xiaomi-11t.html). Es útil para comparar antes/después, pero no es la referencia nominal de gama media de los últimos ~3 años; Android 14 no cambia su generación. Conservar ese límite de SC-007 y no deducir conservadurismo universal por antigüedad. La autorización de emuladores no sustituye medición ni certifica el objetivo de 60 FPS.

En cada configuración revisar: terreno sin huecos nuevos; montañas frías y centro ocre legible; tierra/madera/sacos de las trincheras; actores y municiones reconocibles y por encima del entorno. Registrar un estado inicial, uno con soldados desplegados/combate y otro con pickup cerca de la decoración. Comparar con [la referencia](references/visual-reference.md), no con sus personajes o HUD.

## 4. Matriz de interacción y conservación

Preparar el mismo estado previo en la línea base y la versión con arte. Aprovechar los escenarios existentes y el flujo real para obtener munición; no añadir botones, comandos de gameplay o un harness nuevo para esta feature.

| ID | Caso | Resultado que se conserva | Cobertura |
|---|---|---|---|
| I1 | Celda libre, fondos suficientes | Mismo costo, misma celda y centro de despliegue | Ratón y toque; centro y borde decorativo |
| I2 | Celda ya ocupada | Sin segundo soldado ni gasto nuevo | Ratón y toque |
| I3 | Fondos insuficientes | Mismo rechazo, sin despliegue ni gasto | Ratón y toque |
| I4 | Pickup sobre suelo o junto a trinchera | Se recoge y no se despliega además un soldado | Ratón y toque, estado vacío/ocupado cuando corresponda |
| I5 | Soldado inicial | Mantiene (576,500), celda ocupada y geometría | Inspección y pruebas existentes |
| I6 | Muerte/liberación de soldado | Se libera la celda correcta y puede reutilizarse con las mismas reglas | Regresión existente y revisión de estado |
| I7 | Combate, consumo, moral y recarga | Mismos estados/valores; recarga mediante el método cubierto por tests | Regresión existente; no inventar UI |
| I8 | Oleadas y fin de partida | Mismo spawn/orden de diez oleadas; mismos resultados de victoria y derrota | Suite y escenarios separados de estado |
| I9 | Punto fuera del centro ilustrado que antes recibía input | Mismo comportamiento; sin nuevos límites o bloqueos por decoración | Ratón/toque en puntos equivalentes visibles |

No hay HUD instanciado en la línea base consultada. La validación del fin de partida observa el estado/señales existentes, sin exigir una pantalla nueva. Un headless no demuestra por sí solo alineación visual/input con stretch: registrar las pruebas manuales reales por separado.

### I4 — corrección separada y comparación artística

Conservar sin cambios los manifests/reportes de T001 y `b670d86`. El diagnóstico nativo actual ejecutó las seis pruebas de 003/`4a2915c` contra copias originales sin/con arte: importación correcta, cuatro controles PASS y dos FAIL esperados por recoger y desplegar en el mismo gesto. T019 puede adoptar esa evidencia previa al cambio tras guardar logs, revisión y hashes para QA; no se recrea un RED histórico ni se repite por rutina una ejecución válida.

Tras T020, T021 repite exactamente los seis casos por dispatch real de Viewport: pickup normal/emulado con reserva 12 y cantidad 3 → 15, mismo número de soldados/celda libre; sin pickup y celda libre, el despliegue normal/emulado conserva 12→2 y una unidad nueva. Los dos controles de picking completan los seis. Son pruebas de enrutamiento, no toque físico ni equivalencia del stretch de todos los dispositivos.

Comparar luego las composiciones sin/con arte usando en ambas **el mismo script corregido**, con gesto real aplicable a V1/V3 y gesto simulado V4; registrar fondos suficientes, un pickup aislado, celda/estado PRE y POST, importe acreditado y ausencia de gasto/unidad extra. Si hay varios pickups superpuestos, registrar cuántos y sus importes sin cambiar sus recompensas para obtener el resultado. Mantener separado el diagnóstico original y no atribuir al arte la corrección. T008/T009 requieren T022 aprobada y aún deben completar sus matrices.

## 5. Regresión, partida y rendimiento

- Reutilizar la suite completa de `tests/unit/`, en especial nivel, spawner, datos de oleadas, tablero, economía, estado de partida, soldado y enemigo. No debilitar aserciones ni añadir tests que solo enumeren sprites.
- Completar un smoke de partida y documentar escenarios separados de victoria y derrota. Si un fallo previo impide completarlo, registrar la limitación y devolver el cierre al orquestador; no declarar aprobación ni ampliar a corregir lógica aquí.
- En Android de referencia comparar gameplay típico antes/después, manteniendo dispositivo, resolución, carga y condiciones. Registrar FPS, tiempos de frame, memoria de texturas y tiempo de carga medido. No se inventa un objetivo absoluto de carga que la constitución aún deja pendiente.
- El objetivo del proyecto es 60 FPS estables. Una línea base que ya incumpla o una regresión nueva requiere diagnóstico y decisión explícita antes de aprobar; no se oculta con una media o una captura estática.
- Verificar lectura/interacción en PC e iOS según matriz. No publicar builds en Firebase/TestFlight ni cambiar versión o firma como parte de esta feature visual.

## 6. Evidencia y aprobación

Reportes futuros: `evidence/us1.md`, `evidence/us2.md`, `evidence/us3.md`, `evidence/regression.md`, `evidence/smoke.md` y `evidence/performance.md`, con tarea, entorno, pasos, esperado/observado, resultado y limitaciones. Los assets/capturas de evidencia deben quedar identificados y sin datos privados.

QA revisa de forma independiente spec, contrato, diff, reportes y referencia; emite veredicto sin modificar archivos o tareas. Solo el orquestador marca `[X]` después de `APROBADO`. La aprobación de estos documentos no sustituye esa aceptación de la entrega.
