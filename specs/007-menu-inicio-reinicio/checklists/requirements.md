# Specification Quality Checklist: Menú de inicio y nueva partida

**Purpose**: Revisar calidad y completitud antes de planificar.
**Created**: 2026-10-21
**Feature**: [spec.md](../spec.md)
**Estado**: 16/16 criterios documentales aprobados por QA independiente; marcado por el orquestador. No acredita implementación.

## Content Quality

- [X] Sin detalles de implementación en los requisitos de producto.
- [X] Centrado en valor para el jugador y necesidades del juego.
- [X] Comprensible para participantes no técnicos.
- [X] Todas las secciones obligatorias completas.

## Requirement Completeness

- [X] Sin marcadores de aclaración pendientes.
- [X] Requisitos verificables y no ambiguos.
- [X] Criterios de éxito medibles.
- [X] Criterios de éxito sin prescribir implementación.
- [X] Escenarios de aceptación definidos.
- [X] Casos límite identificados.
- [X] Alcance delimitado.
- [X] Dependencias y supuestos identificados.

## Feature Readiness

- [X] Cada requisito tiene criterios de aceptación claros.
- [X] Los escenarios cubren los recorridos principales.
- [X] Los criterios permiten comprobar los resultados solicitados.
- [X] La especificación no sustituye el plan técnico ni declara implementación.

## Notes

- Alcance confirmado: menú pictórico → «Jugar» → Monte Calvo → victoria/derrota → «Volver a jugar» o «Menú principal», sin refrescar ni reabrir la app.
- Menú sin combate, reinicio completo y exclusión de gestos/eventos residuales. Sin pausa, ajustes, tutorial, guardado, selección de niveles o cambios de balance.
- Publicación y pendientes previos conservan su alcance separado. La revisión documental no aprueba el comportamiento futuro.
