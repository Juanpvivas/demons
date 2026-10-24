# Specification Quality Checklist: Disparos visibles

**Purpose**: calidad de los requisitos de 010; no aprueba implementación.
**Created**: 2026-10-23 | **Feature**: [spec.md](../spec.md)

## Content Quality

- [X] Los requisitos de producto evitan detalles de implementación; APIs y pool quedan en plan/contrato.
- [X] El alcance se centra en reconocer el disparo para el jugador [US1].
- [X] La historia y escenarios son comprensibles sin conocer Godot [US1/AC1–5].
- [X] Están completas las secciones de escenarios, requisitos y resultados [FR-001–010, SC-001–006].

## Requirement Completeness

- [X] No quedan decisiones críticas sin aclarar dentro del alcance; terminal y cierre se distinguen [FR-008].
- [X] Un efecto por tiro, estados excluidos y duración permiten decidir aceptación [FR-001/002/006].
- [X] Los resultados son comprobables por comportamiento, revisión visual y playtesting del alcance [SC-001–004/006].
- [X] Los resultados no dependen de un framework ni de una API concreta [SC-001–006].
- [X] La historia cubre frente/diagonal, última bala, continuidad de partida y alcance ampliado [AC1–6].
- [X] Simultáneos, reciclado, callbacks obsoletos, pausa, terminal y resize están delimitados [Edge Cases, FR-007/008/009].
- [X] La revisión limita el cambio de balance al alcance frontal confirmado; conserva las demás mecánicas/corrida y excluye proyectil físico, audio y retardo de daño [FR-004/005/009/010].
- [X] Dependencias, destinos, pausa de rendimiento y publicación pendiente son explícitos [Assumptions, SC-005].

## Feature Readiness

- [X] Cada FR tiene criterio asociado: 001/006→SC-001; 002/003/009→SC-002; 004/005→SC-003; 007/008→SC-004; 010→SC-006.
- [X] US1 expresa el recorrido completo de disparo, su ciclo de vida y alcance [AC1–6].
- [X] SC-005 define entrega verificable sin afirmar ejecución, hardware ni publicación aprobados.
- [X] Las decisiones técnicas y tareas se mantienen separadas del spec de producto [plan.md, contracts/].

## Notes

Los 16 criterios de calidad documental conservan sus IDs/estado y se contrastan con el perfil confirmado el 2026-10-24: tamaño doble, alcance frontal +50 %, recorrido de 0,30 s y fade de 0,10 s. Esta autoría T013 queda pendiente de revisión QA; ninguna casilla acredita implementación, tests ni publicación. T001–T012 conservan su aprobación histórica del perfil inicial; las tareas de la revisión permanecen pendientes hasta sus aprobaciones independientes.
