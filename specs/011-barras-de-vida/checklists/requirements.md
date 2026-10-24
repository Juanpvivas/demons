# Specification Quality Checklist: Barras de vida

**Purpose**: revisar calidad de requisitos antes de ejecución; no acredita implementación.
**Created**: 2026-10-24 | **Feature**: [spec.md](../spec.md)
**Estado**: autoría completa; revisión independiente pendiente. Casillas reservadas al orquestador tras QA.

## Content Quality

- [ ] Requisitos de producto sin APIs ni decisiones de implementación.
- [ ] Valor para el jugador definido en US1.
- [ ] Escenarios comprensibles sin conocer Godot.
- [ ] Secciones obligatorias completas.

## Requirement Completeness

- [ ] No quedan decisiones UX críticas ni marcadores de aclaración.
- [ ] Proporción, visibilidad y límites exactos permiten aceptación objetiva.
- [ ] SC-001–004 son medibles por comportamiento/revisión visual.
- [ ] Los resultados no dependen de una tecnología específica.
- [ ] AC1–5 cubren ambos bandos y su ciclo.
- [ ] Edge Cases incluyen simultáneos, sobre-daño, reuso y entrada.
- [ ] Alcance excluye cambios de balance y nueva campaña de rendimiento.
- [ ] Dependencias, destinos y publicación pendiente explícitos.

## Feature Readiness

- [ ] FR-001/002/003→SC-001; FR-004/007→SC-002; FR-005/007→SC-003; FR-006→SC-004.
- [ ] US1 cubre aparición, daño, caída, recarga y otra partida.
- [ ] Los resultados están definidos sin afirmar ejecución ni aprobación.
- [ ] Detalles técnicos separados en plan/contrato.
