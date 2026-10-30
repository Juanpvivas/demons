# Specification Quality Checklist: La carta

**Purpose**: Calidad de preparación; no aprueba implementación ni reemplaza QA.  
**Created**: 2026-10-30  
**Feature**: [spec.md](../spec.md)

## Content Quality

- [X] Especificación centrada en valor/experiencia, sin imponer APIs o lenguaje en requisitos.
- [X] Secciones obligatorias completas y lenguaje de producto.
- [X] Guion/storyboard y decisiones de primera vez/replay/voz identificados.

## Requirement Completeness

- [X] Sin marcadores de aclaración pendientes; detalles técnicos constan como decisiones en plan/contrato.
- [X] FR verificables, escenarios definidos y resultados medibles SC001–008.
- [X] Casos de pausa, guardado fallido, reentrada y cierre identificados.
- [X] Alcance/destinos y dependencias explícitos; sin cambio de balance/publicación.

## Feature Readiness

- [X] US1–US3 y FR/SC tienen cobertura de tareas declarada.
- [X] Setup neutral precede RED; implementación depende de RED revisado y sólo se aprueba con GREEN/QA.
- [X] Integración y publicación conservan gates distintos; tareas nuevas permanecen pendientes.

## Notes

Marcas de este checklist sólo indican revisión de calidad del documento en preparación. La revisión independiente T001 y todas las tareas de implementación aún requieren veredicto QA.

## Revisión R2 — calidad de preparación

Los ítems anteriores y T001–T014 conservan su historia de I1. Estos ítems sólo
revisan que la nueva preparación pueda pasar a T015; no aprueban implementación.

- [X] Cinco correcciones autorizadas explícitas, sin ampliar campaña/publicación.
- [X] Decisión terminal aclarada por la persona: Comenzar en ambas entradas,
  sin retorno al menú ni inicio automático al finalizar/omitir.
- [X] Voz masculina y mezcla requieren escucha, no sólo metadatos; arte sin textos
  superiores y ambiente offline separado tienen criterios proporcionales.
- [X] Salida activa/pausada al menú conserva cierre e invariantes y Retry terminal.
- [X] T015–T025 cubren revisión con RED válido→GREEN→QA→docs→CI→QA integración;
  sin setup artificial ni reseteo de tareas/historia/publicación T014.
- [X] Decisión humana de grabar el narrador separada en T026/SC-009 pendiente
  del archivo; se permiten cuatro correcciones y Ald preview provisional sin
  aprobar voz final, naturalidad o fluidez. Compañero humano opcional.
