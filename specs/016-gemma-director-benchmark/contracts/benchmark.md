# Contrato016 — Datos, interfaces y comparación

## Catálogo y snapshots sintéticos

Catálogo cerrado: cada plan contiene `action_id`, `cost_slots`,
`initial_delay_s`, `cadence_s` y lista `spawns` de `{role, lane}`. Carriles 0–4
corresponden a filas 1–5. Pausa tiene coste 0, spawns vacíos y tiempos0; cualquier
otro plan cuesta3, contiene A,A,R en ese orden y cadencia exacta 1.0s. Sus tiempos
sintéticos son initial_delay+i×cadence; no se ejecutan spawns en el juego.

| ID | Roles/carriles en orden | Delay(s) |
|---|---|---:|
| pause | ninguno | 0 |
| left | A0,A1,R0 | 0 |
| center | A1,A2,R3 | 0 |
| right | A3,A4,R4 | 0 |
| spread | A0,A2,R4 | 0 |
| delayed_left | A0,A1,R0 | 3 |
| delayed_right | A3,A4,R4 | 3 |

Snapshot: `case_id`, `terminal` bool, `budget_slots` entero≥0,
`lane_loads`/`lane_caps` cinco enteros≥0, `defense` cinco números finitos 0–1,
`recent_death`/`high_pressure` bool, `previous_action_id` string|null y
`allowed_actions` lista de IDs. Nunca se importa WaveData ni estado real.
`case_id`, los conjuntos aceptables y cualquier metadata de oráculo/reporte se
usan sólo para identificar/evaluar resultados después de decidir. Baseline y
Gemma reciben la **misma proyección whitelist**: terminal, budget_slots,
lane_loads, lane_caps, defense, recent_death, high_pressure, previous_action_id
y allowed_actions, más el catálogo. El selector no lee ni ramifica por case_id,
acceptable_actions o metadata de evaluación.
Defaults de los ocho casos: terminal=false, budget 3, loads[0,0,0,0,0],
caps[3,3,3,3,3], defense[.5,.5,.5,.5,.5], flags=false, previous=null,
allowed=los siete IDs. Cambios respecto al default y oráculos **suaves**:

| case_id | Cambios | Conjunto aceptable declarado |
|---|---|---|
| balanced | ninguno | cualquier plan legal |
| empty_lane | loads[2,2,2,0,0] | right, delayed_right |
| strong_defense | defense[1,1,.2,.2,.2] | right, delayed_right |
| recent_loss | recent_death=true; loads[1,0,0,0,0] | pause, delayed_left, delayed_right |
| high_pressure | high_pressure=true; loads[2,2,2,2,2]; caps[4,4,4,4,4] | pause, delayed_left, delayed_right |
| previous_repeat | previous_action_id=center | cualquier legal distinto de center |
| insufficient_budget | budget_slots=2 | pause |
| terminal | terminal=true | pause |

Estos conjuntos se fijan antes de correr y QA los revisa independientemente;
no son predicciones de victoria. No repetir el plan previo si existe otra opción
legal es una preferencia separada; alta presión/baja reciente favorecen alivio.
Los demás errores duros nunca se convierten en aciertos del oráculo.

## Validador y baseline independientes

`validate` acepta sólo texto JSON UTF-8 completo de objeto con exactamente
`action_id` string, sin campos/keys duplicadas, NaN, prosa, fences o trailing
JSON. Resuelve el ID en catálogo e impone shape del plan, coste 0/3, tres roles
A,A,R/no pausa, lanes enteros0–4, allowed_actions, budget y
load[lane]+spawns_en_lane≤cap[lane]. Terminal sólo permite pause. Rechaza bool
como entero. No enum del modelo ni heurística sustituyen este control.

Baseline: terminal/presupuesto<3→pause; baja reciente/alta presión→pause. En
otros casos elige entre planes no pausa legales; si no hay, pause. Minimiza en
orden `(repite_previo, suma_cuadrados_cargas_proyectadas, suma_defensa_en_spawns,
action_id)`; sin RNG. La legalidad debe contrastarse sin llamar al selector.
La coincidencia Gemma/baseline se muestra descriptivamente, nunca como score
principal ni como definición del conjunto correcto. En strong_defense la
fórmula prioriza `center` (carga² 3 frente a 5 de `right`); puede no acertar el conjunto
suave `right`/`delayed_right` sin ser ilegal. No ajustar la fórmula para forzar 100%.

## API pública (setup neutral histórico antes de RED)

En `tools/director_benchmark/benchmark.py` se declaran estas funciones con
retorno neutral `None` en el setup histórico T002 (sin comportamiento). El spike
implementado quedó aprobado funcionalmente en T007 sobre `b30f9a6`; CI/gate final
pendientes. [Uso, configuración declarada y límites](../../../tools/director_benchmark/README.md). Todos los datos finales
usan dict/list estándar; no framework ni nuevas clases obligatorias:

```text
catalog() -> dict
scenarios() -> list[dict]
baseline(snapshot, plans) -> str
validate(raw_text, snapshot, plans) -> dict
verify_identity(manifest_path, model_file, *, opener=None) -> dict
gemma(snapshot, plans, seed, *, opener=None) -> dict
run(backend, output_dir, *, manifest_path=None, model_file=None, opener=None) -> dict
main(argv=None) -> int
```

`validate`: `{valid: bool, reason: string}` con razón `ok`, `invalid_json`,
`invalid_shape`, `unknown_action`, `invalid_plan`, `not_allowed`, `over_budget`,
`over_capacity` o `terminal`. Backend devuelve `{status, action_id, raw_text,
latency_ms, error}`; status `ok`, `invalid_output`, `illegal_action`,
`transport_error`, `timeout`, `http_error`, `protocol_error` o `identity_error`.
Campos no disponibles son null, no inventados. Error breve acotado como dato.
Una decisión parseable pero ilegal conserva su ID; fallo de transporte no lo
inventa. `run` retorna resumen/reporte; `main` devuelve 0 si completó 24 intentos,
1 ante preflight/identidad/IO fallido (reportado),2 por argumentos inválidos.
Una corrida completa con intentos inválidos no se declara 24 éxitos.

Formas públicas mínimas, sin APIs nuevas:

```text
verify_identity -> {status: 'ok'|'identity_error', error: null|string, metadata: dict}
run -> {attempts: list, warmup: dict|null,
        summary: {total_attempts: int, legal_count: int, evaluable_count: int,
                  oracle_hit_count: int, status_counts: dict}, metadata: dict,
        outputs: {json: path|null, markdown: path|null},
        error: null|{status: string, message: string}}
```

Si falla preflight, `run` devuelve attempts=[], warmup=null y ambos paths de
outputs=null, con error clasificado; CLI devuelve 1. No inventa decisiones,
latencias o metadata ausentes. Las causas HTTP de GET models pueden conservarse
en error de verify_identity con status identity_error; no se cuentan como una
decisión ilegal del modelo.

`opener` sólo permite doubles explícitos inyectados por unittest, no por CLI.
Mismos guards de URL y límites preceden a todo envío; no representa Gemma real.
Producción CLI usa stdlib y proxies deshabilitados; no hay `--fake` ni fallback.

```text
python3 -B -m unittest discover -s tests/director_benchmark -p 'test_*.py' -v
python3 -B -m tools.director_benchmark --backend baseline --output-dir /tmp/director-baseline
python3 -B -m tools.director_benchmark --backend gemma --model-manifest /tmp/demons-gemma4-e2b-provenance.json --model-file <modelo-local-root> --output-dir /tmp/director-gemma
```

El directorio de salida debe resolver fuera del checkout (por defecto temporal);
no se escribe en rutas resueltas dentro del repo, tampoco mediante symlink.
Unittest usa temporales propios. JSON (`results.json`) y Markdown (`report.md`)
no contienen secretos ni se añaden a Git; raw≤64KiB se escapa como dato, nunca
se ejecuta, evalúa o interpola en shell/código.

## Identidad y transporte Gemma REAL

Modelo ya provisto fuera de Git por root, sin descarga por agentes:
`litert-community/gemma-4-E2B-it-litert-lm`, revisión
`1caa527c1e88b55f046fcd8d2b4265606680663d`, archivo
`gemma-4-E2B-it.litertlm`,2.588.147.712 bytes y SHA256
`181938105e0eefd105961417e8da75903eacda102c4fce9ce90f50b97139a63c`.
`verify_identity` coteja manifest con estos valores y hash/tamaño del archivo
real leído por bloques antes del batch; GET `/v1/models` debe ofrecer alias
`gemma4-e2b`. El alias solo no prueba el hash del archivo cargado: se registra
esta limitación y la provisión/arranque identificados por root, sin afirmar
atestación del runtime. Sin Gemma3 ni otro modelo de fallback.

Únicas URLs HTTP literales: `http://127.0.0.1:9379/v1/models` y
`http://127.0.0.1:9379/v1/chat/completions`. Sin credenciales/query/fragment,
otros hosts/puertos/esquemas, DNS, redirects o proxies ambientales. Timeout30s,
request y response≤65.536 bytes (leer límite+1 para detectar exceso). No retry
automático. HTTP fallido, socket/timeout y envelope JSON malformado no se
atribuyen como una elección ilegal del modelo; se distinguen en status.

POST usa `model: gemma4-e2b`, `reasoning_effort: none`,
`max_completion_tokens: 64` (no max_tokens), temperature 0.2, top_p 0.95 y
seed 42/43/44 solicitada. `response_format`:

```json
{"type":"json_schema","json_schema":{"name":"director_decision","schema":{"type":"object","properties":{"action_id":{"type":"string"}},"required":["action_id"],"additionalProperties":false}}}
```

Sin enum de IDs. Mensajes consistentes: instrucción de devolver sólo ese objeto
JSON, reglas duras y objetivos tácticos **generales** (alivio, menor apilado y
repetición), proyección táctica whitelist y catálogo canónicos. No incluyen
nombres/IDs de caso, conjuntos de respuestas aceptables ni claves de metadata
del oráculo/reporte. Los conjuntos se comparan sólo después de la decisión. No se pide chain-of-thought ni texto libre. Envelope espera
`choices[0].message.content` string y metadata disponible; no depender de tokens
reportados ni aceptar truncamiento `finish_reason=length` como éxito. Registrar
structuredmode y parámetros como **solicitados**, no como garantía del motor.

## Informe y denominadores

Por backend: un warmup balanced/seed 42 y 24 intentos (ocho casos×42/43/44) en
orden común shuffle con `random.Random(20261031)`. Registrar warmup aparte;
ni warmup ni intentos fallidos se reemplazan/reintentan. Identidad/preflight no
cuentan como decisiones. Preflight fallido impide declarar batch real completo.

JSON conserva caso/seed solicitada/orden/backend/status/raw acotado/ID/razón/
legalidad/oráculo/latencia y metadata disponible, más hashes SHA256 de catálogo,
fixtures, prompt canónico por proyección táctica y manifest/modelo, versiones Python/OS/
runtime declaradas y parámetros. No inventar consumo de memoria: 24GB es
capacidad del host. El runtime 0.19/API 0.19 se registra con procedencia declarada,
no como valor devuelto por GET si ese endpoint no lo devuelve.

Controles de no filtración: renombrar case_id o cambiar sólo metadata del oráculo
no altera baseline, prompt táctico, su hash ni el cuerpo HTTP para el mismo
estado/semilla. El hash de procedencia del fixture completo sí puede cambiar;
no se confunde con el hash del prompt. Unittest inspecciona el body HTTP para
excluir case_id, acceptable_actions y metadata de evaluación, sin añadir APIs.

Resumen: válidos/24 y válidos/respuestas evaluables, fallos por status separados,
aciertos_oráculo/24 y /legales, IDs distintos por caso entre ≤3 respuestas válidas
y acuerdo modal/validas del mismo caso (semillas solicitadas diferentes; no
prueba de repetibilidad con seed fijo). Diversidad entre casos usa ocho casos y
sólo los que tengan respuesta válida; distribución de planes usa decisiones
legales, roles/carriles usa spawns de planes legales no pausa (3 por plan), con
ambos denominadores explícitos. No presentar AAR fijo como diversidad inventada.

Latencia de decisión/roundtrip wall con perf_counter: warmup separado, n/min/
mediana/max y p95 exploratorio con método nearest-rank declarado; agregar por
backend y mostrar fallos/timeouts aparte. `cold_start_ms=not_measured` si no hubo
arranque frío controlado externo. No inferir CPU, RSS/GPU, FPS, S24, robustez,
diversión o probabilidad de ganar desde 24 muestras o desde el baseline.
