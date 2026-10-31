# Plan016 — Spike local de comparación

**Base/rama**: main `e8407ec` / `codex/016-gemma-director-benchmark`.
**Estado**: preparación; Issue único pendiente del orquestador.
**Entradas**: [spec](spec.md), [contrato y ejecución](contracts/benchmark.md), [tareas](tasks.md).

## Decisión y arquitectura

Python stdlib en `tools/director_benchmark/{__init__,__main__,benchmark}.py`:
fixture/catálogo, heurística, validador independiente, transporte y reporte
pequeños, sin framework o dependencias del juego. Unittest en
`tests/director_benchmark/test_*.py`; un paso nuevo mínimo en `.github/workflows/ci.yml`
ejecuta esos tests offline. No modificar deploys, GUT, escenas o Resources.

El contrato reúne datos, interfaces, ocho casos, parámetros y comandos; no se
crean anexos redundantes de research/data-model/quickstart. LiteRT-LM ya corre
fuera del repo: el runner no instala, descarga, inicia ni cambia el servidor.
Manifest/hash real aportado por root y alias de GET `/v1/models` se contrastan
antes de medir Gemma. La capacidad24GB no es una medición RSS/GPU.

## TDD mínimo

El paquete no existe: setup neutral de como máximo 30 líneas con firmas del
contrato y retornos `None`, sin HTTP/validación/selección/fixtures/reporte. Así
RED falla por aserción semántica sobre retorno neutro, nunca por ModuleNotFoundError
ni NotImplementedError. El tester confirma import y neutralidad y ejecuta RED;
QA distingue aprobación del setup de aprobación RED, sin entregar funcionalidad.
Después dev implementa y tester verifica GREEN, CLI offline y controles HTTP
con servidor falso local. El batch real se ejecuta sólo tras GREEN, sin fakes.

## Ejecución y métricas

Orden común de 24 pares caso/seed con `random.Random(20261031)` local y shuffle;
cada backend consume ese mismo orden y un warmup equilibrado/seed 42 excluido.
El baseline repite decisiones deterministas; las semillas de Gemma sólo se
solicitan. No reintentos automáticos: timeout/HTTP/formato/ilegalidad quedan visibles.

Se mide `perf_counter` alrededor de cada decisión/roundtrip completo y el primer
warmup por separado; el arranque frío del proceso es `not_measured` salvo control
externo explícito, no se infiere del warmup de un servidor ya iniciado. Mediana,
mínimo/máximo y p95 exploratorio con n=24 no son garantía de rendimiento. Separar
acuerdo entre repeticiones del mismo caso, variedad entre casos y distribución
de roles/carriles condicionada a planes no pausa. No puntuar por coincidencia
con baseline; usar conjuntos del contrato y motivos independientes.

## Constitución y entrega

I: datos sintéticos inmutables/separados; II: TDD/QA por roles adaptados a Python;
III: reporte legible; IV: mediciones proporcionales sin extrapolar GPU/FPS o
hardware móvil; V: CI y PR borrador, sin distribución ni integración de IA jugable.
Se reutiliza GUT/CI del producto sin runs locales Godot por rutina; cualquier
fallo real bloquea. Modelos/runtime/raw/reportes sólo temporales externos,
sin nuevas evidencias Git. #61/#53, pausa 006 y release 1.0.3 conservan sus límites.
