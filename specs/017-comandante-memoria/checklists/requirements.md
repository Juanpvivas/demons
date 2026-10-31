# Calidad de especificación017

**Fecha**: 2026-10-31.
**Documento**: [spec.md](../spec.md).
**Estado**: preparación aprobada independientemente; núcleo I1 implementado y
aprobado funcionalmente. Documentación y gate final de integración en revisión;
I2 y publicación pendientes. Las casillas siguen refiriéndose sólo a preparación.

**Planificación técnica**: [plan](../plan.md), [investigación](../research.md),
[modelo](../data-model.md), [contrato](../contracts/commander.md) y
[guía de validación futura](../quickstart.md) preparados el2026-10-31.

Las casillas registran sólo preparación aprobada por qa-validator; no acreditan
implementación o integración. [tasks.md](../tasks.md) contiene55 tareas propuestas,
I1 en cierre del núcleo aislado; I2/publicación pendientes.

## Contenido

- [X] Alcance centrado en valor para el jugador y única variación de carriles.
- [X] Escenarios de usuario, requisitos, entidades y criterios presentes.
- [X] Tipos/cantidades/intervalos contrastados con las diez oleadas y spec015.
- [X] Inicial R central separado del reparto y de la experiencia WAVE.
- [X] Ninguna decisión de API, clases o algoritmo de implementación prescrita.

## Completitud

- [X] Q1 incorporada: permutación por bloque global, continuidad y borde explícitos.
- [X] Q2 incorporada: memoria local, sólo terminales y opción de borrado.
- [X] No quedan marcadores de aclaración.
- [X] Criterios de aprendizaje distinguen memoria de aleatoriedad.
- [X] Requisitos y criterios trazables, con casos de interrupción y corrupción.
- [X] Equilibrio exige observación manual, sin prometer invencibilidad o tasa inventada.
- [X] Alcance Web de computador/Android/iOS y gates constitucionales conservados.

## Preparación para la siguiente fase

- [X] Política de producto cerrada antes de planear implementación.
- [X] Revisar crédito por avance/censura, bloques, exploración, olvido y
  compatibilidad concretados en plan/modelo/contrato antes de pruebas RED.
- [X] Revisar semillas/muestra y criterios de equilibrio definidos en quickstart
  antes de ejecutar; no confundirlos con resultados obtenidos.
- [X] Revisión de preparación sin confundirla con QA funcional o de publicación.

## Observaciones de revisión documental

- La tabla conserva 99 WAVE = 66 A + 33 R en diez oleadas; el inicial suma otro R.
- El único cambio admitido a la secuencia es el carril. El calendario conserva
  su semántica: una transición condicionada por combate no se vuelve de reloj fijo.
- La V1 no puede aliviar presión añadiendo delays o pausas tácticas.
- El catálogo sintético de 016 no se importa al juego ni se extiende su aprobación.
- T009–T011 de 016 permanecen pendientes; seleccionar 017 para preparación no
  cierra el experimento ni cambia la rama de ejecución.
- No hay hooks configurados en `.specify/extensions.yml` en este checkout.
- **Q1/Q2 resueltas por la persona (2026-10-31)**: cinco carriles una vez por
  bloque global; memoria local borrable que aprende sólo de WON/LOST.
- Se aclaran 19 bloques completos y uno de cuatro, continuidad entre oleadas,
  repetición posible en frontera y ausencia de un límite de ocupación simultánea.
- Abandono/cierre previo al terminal descarta experiencia pendiente; terminal y
  Retry no la duplican. El borrado no afecta progreso narrativo u otros datos.
- Preparación e implementación del núcleo I1 tienen aprobación independiente.
  No se ha integrado el comandante al juego ni acreditado playtesting, destinos
  o publicación; los resultados de ejecución y CI se reportan en el PR.
- Diseño técnico:360 contextos, memoria congelada por partida, resultados sólo de
  muertes/cruces WAVE confirmados, censura de vivos y consolidación única por
  terminal. Preferencia acotada, persistencia en dos slots y borrado de ambos.
- Candidatos de balance: exploración0.25, gain0.25, aprendizaje0.15, retención0.98;
  confianza3 y máximo20 visitas efectivas. No constituyen balance jugable
  aprobado ni validación física.
- Quickstart separa los escenarios aislados de selección de las12 partidas
  comparables más entrenamiento real, que siguen pendientes para I2.
- Plan aplica constitución antes/después del diseño; no identifica excepciones
  necesarias. La preparación fue revisada independientemente; [Issue #65](https://github.com/Juanpvivas/demons/issues/65)
  y rama I1 están identificados en el plan. Los estados de tareas pertenecen al
  orquestador y no certifican publicación.
- Investigación y revisión cruzada documental en sólo lectura comprobaron
  integración/lifecycle y fórmulas. Se cerraron rangos de confianza compatibles,
  rollback de propuesta/RNG y borrado TRANSIENT con feedback propio. Esta revisión
  no sustituye al qa-validator ni acredita funcionamiento implementado.
