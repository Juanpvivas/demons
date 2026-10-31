# 016 — Benchmark aislado de Gemma y director local

**Fecha**: 2026-10-31 · **Rama**: `codex/016-gemma-director-benchmark` · **Base**: main `e8407ec`.
**Estado**: preparación para QA; spike de PC, sin implementación aprobada.
**Tracking**: [Issue #63](https://github.com/Juanpvivas/demons/issues/63).

## Alcance y escenarios

La persona autoriza comparar Gemma 4 E2B real con una heurística local nueva,
fuera del juego. Ambos reciben los mismos ocho snapshots sintéticos, catálogo
cerrado de siete planes y presupuesto. Sólo eligen `action_id`; no generan
código, spawns, stats o reglas. No se integra un director jugable, SDK móvil,
Godot, S24 o servicios cloud. No se toca gameplay, oleadas de producción,
release 1.0.3, #61/#53 ni la pausa de 006.

### US1 — Comparación interpretable (P1)

Quiero ver qué planes propone cada backend, su legalidad, adecuación a oráculos
declarados y tiempo observado, sin confundir coincidencia con la heurística con
superioridad estratégica.

- Ocho casos: equilibrado, carril vacío, defensa fuerte, baja reciente, alta
  presión, repetición previa, presupuesto insuficiente y terminal.
- Cada backend produce24 intentos medidos (ocho×tres semillas solicitadas), más
  un calentamiento separado. No se ocultan fallos, se sustituyen respuestas o
  se reintenta hasta conseguir 24 válidas.
- El informe permite revisar decisión, validación, pertenencia al conjunto
  aceptable y latencia de cada intento, incluidos fallos distintos de formato.

### US2 — Ejecución local acotada y repetible (P1)

Quiero ejecutar baseline sin modelo, probar el adaptador con dobles en CI y
comparar después con el modelo real verificado localmente, sin introducir
modelos o informes en Git.

- Terminal y presupuesto insuficiente sólo admiten pausa; no hay fallback oculto.
- Fences, texto extra, IDs inventados, campos extra, sobrepresupuesto/capacidad y
  respuestas malformadas se rechazan; un fallo HTTP no se presenta como decisión.
- El endpoint sólo admite loopback 127.0.0.1, sin redirects ni cloud. Las respuestas
  se tratan como datos y tienen límites de tamaño/tiempo.

## Requisitos

- **FR-001**: Comparar los dos backends con ocho fixtures, tres repeticiones/semillas
  solicitadas 42/43/44 y orden reproducible independiente del RNG del juego.
- **FR-002**: Usar sólo los siete planes del [contrato](contracts/benchmark.md):
  pausa coste 0 o tres spawns A,A,R/coste 3, carriles 0–4, cadencia1s y delays0/3s.
  Respetar presupuesto, opciones y capacidad de cada fixture, sin leer WaveData.
- **FR-003**: Un validador independiente impone JSON estricto `action_id` único,
  ID conocido y restricciones; separa ilegalidad, formato y transporte. No
  tolerar fences, extraer JSON de prosa o sustituir silenciosamente una decisión.
- **FR-004**: Baseline determinista legible y nuevo, con alivio ante baja/presión,
  selección legal poco repetida/apilada y desempate estable; no es verdad óptima.
  Oráculos por conjuntos aceptables se revisan por QA y se puntúan sólo después
  de decidir. case_id/oráculos/metadata de reporte no son observables tácticos:
  ambos directores reciben la misma whitelist del contrato, sin respuestas
  aceptables ni nombres de casos en prompts o ramas del baseline.
- **FR-005**: Gemma usa el modelo/manifest verificado, alias y parámetros reales
  del contrato. JSON-schema estructurado sin enum del catálogo permite evaluar
  IDs ilegales. Registrar semillas/parámetros como solicitados, no garantizados.
- **FR-006**: HTTP stdlib sólo 127.0.0.1:9379, timeout 30s, petición/respuesta 64KiB y
  64 tokens solicitados. Sin redirecciones, cloud, descargas o ejecución de salidas.
- **FR-007**: Producir JSON y Markdown legibles en directorio temporal externo,
  con decisiones/denominadores, latencias y trazabilidad de entorno/modelo,
  fixtures/catálogo/prompt y parámetros. No versionar modelos, informes o logs.
- **FR-008**: CI ejecuta unittest offline/fakes y conserva GUT/importación del
  producto. Batch Gemma real sólo tras GREEN y disponibilidad del endpoint root;
  un mock no acredita el modelo real ni sustituye una dependencia no disponible.

## Criterios de éxito

- **SC-001**: Cada backend registra24 intentos y un warmup separado con los mismos
  snapshots/planes; conserva inválidos y fallos y permite inspección por caso.
- **SC-002**: Controles positivos/negativos confirman presupuesto, AAR, carriles,
  capacidades, terminal y parseo estricto; baseline es determinista sin RNG jugable.
- **SC-003**: Adapter/CLI rechazan endpoint no permitido, redirect, timeout,
  tamaños excesivos, identidad incorrecta y errores de protocolo sin fallback.
- **SC-004**: Un batch real identifica Gemma 4 E2B mediante manifest/hash y alias;
  informa legalidad, oráculos, acuerdo/diversidad y latencias con denominadores
  y límites. No concluye diversión, victoria, robustez, FPS o viabilidad S24.
- **SC-005**: RED semántico→desarrollo→GREEN/unittest, regresión/CI, QA y
  documentación sostienen un PR borrador del spike; no autoriza despliegue.

## Dependencias y límites

Modelo/runtime ya provistos por root fuera de Git; ningún agente los descarga.
Python 3.12 y LiteRT-LM 0.19/API 0.19 locales. M5 Pro 24GB describe capacidad del
host, no consumo medido. Ocho casos/tres intentos son exploratorios, sin prueba
de estrategia óptima, reproducción determinista de Gemma o percentil 95 estable.
