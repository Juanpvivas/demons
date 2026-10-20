# Implementation Plan: Cinco carriles horizontales

**Feature ID**: `005-cinco-carriles` | **Planned Branch**: `codex/005-cinco-carriles-preparacion` | **Date**: 2026-10-19 | **Spec**: [spec.md](spec.md)

**Estado**: preparación aprobada; I1 implementado con GREEN y revisión funcional parcial. Integración conjunta con 004-I2 pendiente de QA según constitución 4.0.0; publicación pendiente. I2–I5 no se inician con esta transición.

## Summary

Cinco filas con soldados cargados en trincheras izquierdas, reserva inicial
cero y enemigos hacia −X. El soldado vacío sale con machete a 40 unidades/s
solo en su fila; una recarga válida cobra una vez y lo devuelve físicamente
a 40, vulnerable y sin atacar hasta llegar. Su plaza se reserva mientras viva.
El control mínimo permite seleccionar la trinchera y pulsar «Recargar»,
mostrando carga/moral individuales.

Se reutilizan economía, stats, oleadas, pooling y presentación de I2. Su base
`f90e888` permanece en `codex/004-i2-enemigo`: la transición conserva IDs,
aprobaciones e historia de 004 y registra sus pendientes de publicación, sin
aprobarlos por esta enmienda. La imagen aprobada orienta piezas
de arte separadas; no sustituye al juego con actores/controles incrustados.

## Technical Context

| Aspecto | Decisión |
|---|---|
| Lenguaje/motor | GDScript tipado, Godot 4.7.1 existente; sin actualizar motor o plugins |
| Dependencias | GodotPhysics2D, GUT 9.7.1 y servicios/pools existentes; sin addons nuevos |
| Persistencia | Ninguna nueva; Resources compartidos de solo lectura y estado local por actor/partida |
| Testing | GUT unitario/integración con cuerpos reales; gestos de SO y revisión visual separados |
| Destinos | Web en computador; APK Android Emulator; `.app` iOS Simulator; PC nativo solo desarrollo |
| Rendimiento | Comparación base/candidato por entorno para integración; 60 FPS físicos de constitución IV/SC-007 antes de publicación; emulación no certifica hardware |
| Alcance | Cinco plazas, cinco soldados iniciales, un atacante inicial +99 de diez oleadas, sin multiplicarlos |
| Restricciones | Costos/daño/cargas/moral/cadencias vigentes; recolección manual/precedencia; renderers/presets sin cambios |

## Constitution Check

Gates evaluados antes de investigación y tras diseño:

| Principio | Cumplimiento diseñado y límite de entrega |
|---|---|
| I — Datos/separación | Geometría en `LaneBoardConfig`; velocidades propias en `UnitStats`/`.tres`. Vida/carga/moral/fila/origen son estado runtime. Presentación sin autoridad económica/física. |
| II — TDD | Tester RED semántico → dev → tester GREEN/regresión → QA → docs por comportamiento. Arte/documentos usan revisión proporcional; no fabricar RED de cobertura existente. |
| III — UX/plataformas | Estados y recarga claros, mismo significado ratón/toque; cinco filas visibles; solo apps instaladas en móviles. |
| IV — Rendimiento | Inicial/oleadas en mismo pool, sin cambiar `ObjectPool`; efectos conservan pooling. SC-007 pendiente sin hardware. No heredar referencias Xiaomi de 002/004. |
| Governance | Spec/plan/tareas revisados; enmienda 4.0.0 autorizada explícitamente por la persona separa integración de publicación, conserva aceptación física pendiente y no acredita resultados. |

**Gates vigentes (enmienda autorizada del 2026-10-19):** integración requiere
TDD/GREEN, regresión, compilación/exportación aplicables, verificaciones
funcionales de Web/APK/.app disponibles, documentación, CI y `APROBADO PARA
INTEGRACIÓN` independiente. Fallos reales de fuente, build o funcionalidad
bloquean ese gate. La certificación física, renderer de producción o paquete
final ausentes mantienen pendiente publicación y no bloquean por sí solas
integración. QA examina las diferencias de rendimiento observadas y sus límites.

Publicación requiere además `APROBADO PARA PUBLICACIÓN`, artefacto/configuración
de destino, matriz completa y medición física de IV/SC-007; no queda aprobada
por integrar. No se pedirá reconexión física ni se reabrirán navegadores móviles.
Compatibility/software de QA no certifican Mobile, GPU/hardware, empaquetado
final ni 60 FPS. El umbral global de carga sigue pendiente. Ninguna feature se
declara completa ni el Issue se cierra con requisitos restantes.

## Diseño técnico

1. **Tablero**: Resource de nivel con rectángulo 1152×648, celdas 96×96 y cinco
   plazas/entradas explícitas; [modelo](data-model.md). `BoardManager` conserva
   ocupación por origen; el nivel valida whitelist antes de gastar. Moverse
   no altera `home_cell`, por lo que morir fuera libera la plaza correcta.
2. **Movimiento/contacto**: `Soldado` pasa de `StaticBody2D` a
   `CharacterBody2D`, movimiento horizontal en `_physics_process()` y colisión
   real. Modo de arma y desplazamiento separados. Consultas físicas puntuales
   con filtros semánticos sustituyen la dependencia de overlaps almacenados
   del modelo estático anterior. No escalar cuerpos/formas ni mover solo sprites.
3. **Objetivos**: broadphase físico suficientemente amplio, después filtros
   de fila/frente/diagonal contigua y alcance longitudinal autorado. Mantener
   blanco elegible activo; al perderlo elegir el más avanzado (`−X`). Machete
   puede buscar un frontal lejano para acercarse, pero solo daña dentro del
   rango vigente. Validar identidad y activación antes de usar un blanco.
4. **Spawns**: `WaveSpawner` mantiene cursor 1→5 continuo y origen por
   activación `INITIAL`/`WAVE`. Inicial t0/fila 3 usa el pool sin consumir cursor
   ni notificar baja de oleada; conserva drop 3/moral/visual/derrota. Los 99
   restantes conservan Resources/orden/Timers, incluido retraso del primer
   spawn. Registro visual y conexiones una vez por instancia física.
5. **Recarga/UI**: nivel resuelve plaza→dueño actual; actor valida/acepta
   atómicamente antes de notificar gasto. Solo vivo/vacío/fondos/PLAYING,
   bloqueo desde aceptación y todo retorno. UI observa señales y revalida
   identidad; deshabilitar botón no es la única protección. [Contrato](contracts/horizontal-combat.md).
6. **Composición**: mantener `canvas_items/expand`, centrar localmente rectángulo
   de diseño en ambos ejes y adaptar HUD con anclas/contenedores. Terreno
   aislado sin física. Arte lateral para fusil/machete/retorno; no rotar toda
   la ilustración 90° como sustituto de poses apropiadas.

### Evolución de convenciones existentes

[ARCHITECTURE §4.2/§5](../../docs/ARCHITECTURE.md) describe soldado estático y
consulta desde ese lado.005 cambia esa premisa: ambos cuerpos serán móviles;
contacto, separación y daño entrante durante retorno requieren instancias reales.
Se conserva enum del arma y se añade estado de movimiento pequeño, sin framework
de FSM, navegación libre o autoload nuevo. Tras QA se documenta esta evolución,
sin reescribir los hallazgos históricos de física.

## Incrementos previstos

La preparación partió de I2 `f90e888`; sus aprobaciones históricas se conservan.
Transición autorizada: `codex/005-i1-tablero` contiene 004-I2 y 005-I1 y se usa
para un único PR contra `main` (base de revisión `2dc532d`). QA revisa el conjunto,
no solo el diff de 005. Se justifica el tamaño excepcional para consolidar una
base funcional ya acumulada, sin fragmentar TDD ni reescribir historial. El PR
usa `Refs #18` y `Refs #22`, sigue en borrador y no cierra las features. No se
fusiona automáticamente ni distribuye builds. Tras integrarlo, las ramas
superadas pueden eliminarse conservando el código en `main`. Los incrementos
posteriores vuelven a ramas breves por resultado; no se inicia I2 en este PR.

| Incremento | Resultado y rama propuesta | TDD y gate de destinos propio, antes de QA/docs |
|---|---|---|
| I1 | Tablero horizontal, cinco plazas/soldados, fusil orientado, 100 enemigos/cursor/pool y derrota izquierda. `codex/005-i1-tablero` | RED geometría/economía/spawn/targets/terminal → dev → GREEN/regresión. Web/APK/.app: carga y partida a terminal, fusil/derrota visibles, entrada real en plazas/pickups y resize. Comparar carga/frame times base-candidato; población/consultas/pool introducen riesgo de FPS: QA evalúa las muestras disponibles para integración; la medición física queda en el gate de publicación. Machete móvil sigue pendiente de I2. |
| I2 | Salida/espera/contacto real de machete, 40/40 propios y liberación de origen. `codex/005-i2-machete` | RED movimiento/daño mutuo/objetivos/reciclado → dev → GREEN/regresión/playtest. Web/APK/.app: ciclo machete por filas, contacto visible/real, gestos de recolección/reemplazo, resize y partida a terminal. Comparar rendimiento base-candidato para integración; medición física por cuerpos/consultas nuevos antes de publicación. |
| I3 | Recarga atómica/regreso vulnerable y selección/panel/botón integrados. `codex/005-i3-recarga` | RED elegibilidad/cobro/retorno/selección obsoleta/entrada → dev → GREEN/regresión. Web/APK/.app: ratón/toque real, UI/retorno/daño visibles, saldo antes/después, resize y partida. Comparar rendimiento base-candidato para integración; medición física del nuevo retorno/contacto/UI antes de publicación. |
| I4 | Arte lateral/trincheras, presentación de todos los estados y encuadre/HUD adaptables. `codex/005-i4-presentacion` | RED de conducta nueva de presentador/resize → dev → GREEN/regresión pertinente; arte sin RED artificial. Web/APK/.app: QA visual filas1/3/5, input real tras resize, carga y partida. Comparar carga/frame times base-candidato para integración; medición física de recursos/efectos antes de publicación. |
| I5 | Consolidación integrada y documentación final. `codex/005-i5-validacion` | Suite completa y trazabilidad de gates I1–I4; repetir solo evidencia invalidada por integración o pendiente. Defectos nuevos vuelven a TDD. No sustituye verificaciones de cada PR; SC-007 pendiente impide publicación y cierre completo, sin impedir integrar el alcance funcional aprobado. |

En cada fila de esta tabla, Web significa navegador de computador, APK app en
Android Emulator y .app app nativa de iOS Simulator. Son entornos de verificación
funcional separados; no acreditan la medición física indicada. Comparar base y
candidato del incremento con carga/recorrido equivalentes, identificando renderer
y límites. Reutilizar solo evidencia del mismo estado aún válida; no posponer a
I5 entrada, visual, resize, partida o rendimiento pertinentes al PR actual.
Los detalles de medición y los gates separados se concentran en
[quickstart](quickstart.md#gate-de-cada-incremento).

Objetivo por PR: ≤400 líneas manuales sumando adiciones/eliminaciones y ≤20
archivos relevantes, declarando binarios/generados aparte. I1 puede excederlo:
eje/detección/defensa deben cambiar juntos para no entregar orientación rota.
Antes de ejecutar, orquestador revisa tamaño y separa setup/contratos independientes
cuando sea comprobable, o justifica la unidad mínima. No acumular incrementos
independientes ni fusionar RED con implementación pendiente. PR en borrador,
`Refs #22` (y `Refs #18` en la transición conjunta); solo último elegible usa `Closes #22`, nunca merge automático.

## Project Structure

```text
specs/005-cinco-carriles/
├── spec.md / plan.md / research.md / data-model.md / quickstart.md
├── contracts/horizontal-combat.md
├── references/                          # concepto, no arte final
└── tasks.md                             # siguiente etapa; no creado por plan
resources/schemas/lane_board_config.gd    # nuevo Resource de geometría
resources/levels/monte_calvo_board.tres   # nuevo dato de nivel
resources/schemas/unit_stats.gd          # velocidades propias
resources/units/soldado_base_stats.tres
core/board_manager.gd                    # mapa existente, no autoload nuevo
scenes/levels/                           # nivel/spawner/cámara/entorno
scenes/units/                            # cuerpo móvil/presentador
scenes/enemies/                          # fila/activación/progreso/visual
scenes/ui/                               # selección y recarga mínimas
assets/sprites/{levels,units,enemies}/   # piezas/poses y procedencia
tests/unit/{systems,levels,units,enemies,ui}/
```

## Trazabilidad y siguiente gate

| Requisitos | Diseño y verificación principal |
|---|---|
| FR-001–003/010; SC-001/002/005 | Plazas, inicial 3+cursor 99, cuentas/tiempos, terminales reales |
| FR-004; SC-002/003 | Frente/diagonales directas, límites longitudinales y prioridad −X |
| FR-005/006/008; SC-003 | Cuerpos móviles, estados/salud/moral/origen, objetivos y baja única |
| FR-007/009; SC-004 | Orden atómica/UI/selección, pickups con precedencia/solapadas |
| FR-011/012; SC-006 | Presentación observadora, pooling/generación, cámara/input y matriz |
| SC-007 | Mediciones separadas; hardware pendiente sin excepción implícita |

[Research](research.md), modelo, contrato y [quickstart](quickstart.md) resuelven
el diseño sin volcar registros. C4–C6 resueltos. La preparación y tareas tuvieron
su revisión; el siguiente gate de esta transición es QA de integración del
estado conjunto. Esta enmienda documental no lo aprueba ni ejecuta nuevas
mecánicas.

## Complexity Tracking

Hardware pendiente se conserva como aceptación de publicación sin cumplir,
no como excepción ni prueba aprobada. El tamaño de la transición conjunta se
justifica y revisa por QA conforme al flujo, sin rebajar el gate de integración. No hay hooks `before_plan/after_plan`
que ejecutar: `.specify/extensions.yml` no existe en este checkout.
