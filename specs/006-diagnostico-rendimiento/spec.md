# Feature Specification: Diagnóstico y estabilización del rendimiento

**Feature ID**: `006-diagnostico-rendimiento` · **Planned Branch**: `codex/006-i1-rendimiento` · **Created**: 2026-10-21
**Status**: T009 aprueba para integración el instrumento y diagnóstico limitado, sin parche. Bases nativas T008/SC-001 y US2 pendientes; publicación pendiente.
**Input**: «Continúa con el diagnóstico y estabilización del rendimiento desde main actualizado, siguiendo el flujo de agentes y QA. Actualiza la documentación y prepara el PR en borrador, manteniendo la publicación pendiente».

## Contexto y alcance

Monte Calvo tiene el alcance funcional de 004/005 integrado en `main` (`5d50cb0`, PR #29). Las muestras históricas registran caídas en Android emulado y rendimiento muy limitado en iOS Simulator; no permiten atribuir la causa al hardware, al arte, al pulso o a una función concreta. I1 prevé un diagnóstico reproducible y la primera corrección segura que ese diagnóstico justifique. La entrega actual se limita al instrumento aprobado y al diagnóstico sin mejora causal acreditada; no completa US1/US2 ni autoriza el parche. Las bases nativas y los problemas restantes conservan seguimiento en [las tareas](tasks.md); no se amplía gameplay ni se distribuye una versión.

## User Scenarios & Testing

### User Story 1 — Comprender una caída reproducible (Priority: P1)

Como responsable del juego, quiero distinguir el coste del juego, del instrumento y del entorno para decidir una corrección con evidencia comparable.

**Independent Test**: repetir la misma carga sobre la revisión de referencia, verificar el instrumento y rechazar una comparación cuyas condiciones o poblaciones no coincidan.

**Acceptance Scenarios**:

1. **Given** dos revisiones identificadas y el mismo entorno/carga, **When** se toman muestras repetidas, **Then** se conservan tiempos de frame, carga inicial, población y contexto suficientes para repetir e interpretar la comparación.
2. **Given** una población anidada o inactiva y una ventana con condiciones diferentes, **When** se valida la muestra, **Then** el inventario distingue el estado real y la comparación incompatible no se usa para afirmar mejora.
3. **Given** una medición sin tiempo gráfico o memoria de proceso disponible, **When** se comunica el diagnóstico, **Then** esa ausencia se declara y no se sustituye por otro contador con distinto significado.

### User Story 2 — Estabilizar sin cambiar el juego (Priority: P2)

Como jugador, quiero conservar la misma partida y lectura visual mientras se elimina un coste que el diagnóstico haya demostrado innecesario. Depende del diagnóstico US1.

**Independent Test**: comparar base/candidata con la misma carga, verificar la operación corregida y repetir las regresiones y entradas afectadas.

**Acceptance Scenarios**:

1. **Given** un cuello de botella confirmado, **When** se aplica una corrección acotada, **Then** se reduce el trabajo innecesario o el tiempo pertinente de forma repetible, conservando reglas, arte y entrada.
2. **Given** una diferencia menor que la variación de la base o un destino no comparable, **When** se revisa el resultado, **Then** no se presenta como una ganancia confirmada ni como aprobación de ese destino.
3. **Given** una entrega funcional aprobada, **When** se prepara el PR, **Then** permanece en borrador con publicación y certificaciones físicas pendientes.

### Edge Cases

Cajas/actores anidados o reciclados; escena terminada antes de acabar la ventana; cambio de viewport o renderer; carga fría frente a caché caliente; observador que cuesta más que el cambio; métricas ausentes; destinos software; referencias obsoletas al reciclar; ninguna mejora medible con el experimento disponible.

## Requirements

### Functional Requirements

- **FR-001**: El diagnóstico DEBE identificar revisión, artefacto, entorno, renderer, geometría real, límite de frames y carga de cada muestra; sólo compara condiciones equivalentes.
- **FR-002**: El instrumento DEBE validar inventario y estados inicial/final, incluidos elementos anidados e inactivos, y distinguir medición, preparación del escenario e intervención experimental.
- **FR-003**: Las muestras DEBEN conservar distribución de tiempos de frame, carga inicial y contadores disponibles de procesamiento, dibujo y memoria con unidades y límites explícitos, sin confundir memoria gráfica con memoria del proceso.
- **FR-004**: La instrumentación DEBE ser optativa y ajena a la autoridad jugable; su coste y sesgos se comprueban antes de usarla para decidir una corrección.
- **FR-005**: Antes de optimizar DEBE contrastarse al menos una hipótesis mediante perfilado o experimento de un solo factor, distinguiendo causa confirmada, indicio y limitación del entorno.
- **FR-006**: La primera corrección DEBE limitarse al coste confirmado. Conserva geometría, objetivos, daño, cadencias, economía, moral, oleadas, pooling, terminales, recarga, arte y brillo actuales.
- **FR-007**: El comportamiento nuevo del instrumento o de una corrección DEBE seguir RED → desarrollo → GREEN y regresión pertinente; cobertura existente se verifica sin fabricar RED. QA revisa independientemente código, mediciones y neutralidad funcional.
- **FR-008**: Una mejora DEBE distinguirse de la variabilidad entre repeticiones. Si no se distingue, se informa sin ganancia acreditada; las regresiones observadas y los destinos no verificados permanecen explícitos.
- **FR-009**: El juego normal DEBE conservar su arranque sin controles ni observadores de QA activos; archivos de resultados nuevos permanecen fuera de Git y se resumen en el PR.
- **FR-010**: La integración DEBE conservar publicación pendiente: 004/T039, 005/T071 y sus requisitos propios no se cierran desde emulación o por un merge. No se altera renderer de producción, firma, versiones ni workflows de distribución.

### Key Entities

**Muestra**: revisión/entorno/carga/ventana y valores observados. **Comparación**: muestras equivalentes con dispersión y limitaciones. **Hipótesis**: coste propuesto, experimento y resultado. **Corrección**: alcance mínimo vinculado a una hipótesis confirmada y sus invariantes.

## Success Criteria

- **SC-001**: Cada destino disponible de la matriz tiene una base identificada con tres repeticiones comparables; las muestras incompatibles se identifican y excluyen de conclusiones de mejora.
- **SC-002**: El instrumento detecta población anidada/inactiva y condiciones incompatibles, y sus pruebas nuevas pasan con trazabilidad RED/GREEN antes de aceptar las muestras.
- **SC-003**: Se confirma o descarta al menos una hipótesis con perfilado o un experimento controlado. Una primera corrección sólo se aprueba con reducción repetible del coste pertinente y sin una regresión no explicada/aceptada por QA en los demás destinos disponibles.
- **SC-004**: Las regresiones de la corrección y la suite completa pasan; la presentación, entrada y el recorrido funcional afectados se verifican en sus destinos, sin reinterpretar fixtures como partida de producción.
- **SC-005**: Documentación y PR describen alcance, forma de reproducir, resultados y límites revisados por QA; ningún registro nuevo de validación se añade a Git y el PR queda en borrador.
- **SC-006**: T039/T071 siguen pendientes y no se ejecuta distribución. Ningún resultado software/emulado se presenta como 60 FPS físicos o certificación del paquete final.

## Assumptions y dependencias

La matriz disponible es Web en computador, APK en Android Emulator y app nativa en iPad Simulator; no se prueban navegadores móviles. El objetivo físico de 60 FPS de la constitución sigue vigente para publicar, sin exigirlo al renderer software. Se reutilizan reglas y evidencias no invalidadas de 004/005, distinguiéndolas de las verificaciones nuevas. Si no hay una causa y corrección justificadas, se entrega el diagnóstico sin marcar US2 como completada ni dar por terminada la estabilización.
