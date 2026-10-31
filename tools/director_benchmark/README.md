# Benchmark aislado de directores

Compara una heurística local nueva con Gemma 4 E2B real sobre ocho snapshots
sintéticos y siete planes permitidos. Es una herramienta de PC: no controla
Godot ni modifica oleadas, gameplay, apps móviles o releases.

El comportamiento está aprobado funcionalmente por QA T007 sobre `b30f9a6`.
La consolidación documental y CI/gate final de integración siguen pendientes en
[Issue #63](https://github.com/Juanpvivas/demons/issues/63). [Especificación y contrato](../../specs/016-gemma-director-benchmark/contracts/benchmark.md).

## Preparación y ejecución

Usa Python 3.12 con su biblioteca estándar (en estos ejemplos, `python3`). No hay
paquetes del benchmark que instalar. Ejecuta desde la raíz del repositorio:

```sh
python3 -B -m tools.director_benchmark --backend baseline --output-dir /tmp/director-baseline
python3 -B -m tools.director_benchmark --backend gemma --model-manifest /ruta/externa/provenance.json --model-file /ruta/externa/gemma-4-E2B-it.litertlm --output-dir /tmp/director-gemma
```

Baseline funciona sin modelo/servidor. Para Gemma, el modelo, manifest y runtime
se provisionan por separado fuera de Git; esta herramienta no los instala,
descarga, inicia o configura. El servidor de la corrida ya está detenido;
reproducir Gemma exige arrancarlo explícitamente. Debe estar disponible LiteRT-LM/runtime/API 0.19
con alias `gemma4-e2b` en `http://127.0.0.1:9379`. Sólo se admiten los endpoints
locales `/v1/models` y `/v1/chat/completions`, sin proxies o redirecciones.

Con el entorno y alias ya importados por root, el arranque local verificado
contra `litert-lm serve --help` es el siguiente. Las rutas corresponden a esta
sesión externa; adáptalas a la instalación local existente, sin descargar modelos:

```sh
LITERT_LM_DIR=/tmp/demons-gemma4-runtime /tmp/demons-gemma4-e2b-env/bin/litert-lm serve --config /tmp/demons-gemma4-runtime/config.json --host 127.0.0.1 --port 9379
```

Mantén ese proceso abierto durante el batch y detenlo al terminar. El servidor
no lo inicia el harness. El Python 3.12 de ese entorno está en
`/tmp/demons-gemma4-e2b-env/bin/python` si `python3` no señala esa versión.

El manifest debe corresponder al modelo fijado en el contrato:
`litert-community/gemma-4-E2B-it-litert-lm`, revisión
`1caa527c1e88b55f046fcd8d2b4265606680663d`, archivo 2.588.147.712 bytes y SHA256
`181938105e0eefd105961417e8da75903eacda102c4fce9ce90f50b97139a63c`.
Antes del batch se verifican manifest, tamaño/hash del archivo real y alias
GET models. Hash+alias no atestiguan los bytes cargados dentro del runtime.
No hay fallback a otro modelo ni sustitución por mocks en una corrida real.

Cada backend hace un warmup separado y 24 intentos (ocho casos×semillas
solicitadas 42/43/44), en el mismo orden reproducible local. No reintenta ni
reemplaza respuestas. Escribe `results.json` y `report.md` fuera del checkout;
si omites `--output-dir`, usa un temporal externo. No añadas modelos, raw o
informes a Git. Código de salida 0 significa 24 intentos registrados, no 24 aciertos;
1 indica preflight/identidad/IO fallido y 2 argumentos inválidos.

## Configuración declarada de la corrida real

El runtime externo fue LiteRT-LM 0.19 sobre GPU de Apple M5 Pro, con 24GB de
capacidad del host. Su configuración aportada para reproducir el contexto fue:

```json
{"default":{"backend":"gpu","max_num_tokens":4096,"thinking":false,"temperature":0.6,"top_k":40,"top_p":0.95,"cache":"disk"}}
```

Es configuración del servidor, no defaults supuestos del CLI. El harness
solicita por POST temperature 0.2, top_p 0.95, reasoning_effort `none`,
max_completion_tokens 64 y seeds 42–44; top_k 40 queda heredado del servidor.
Solicita JSON-schema `director_decision` con una sola propiedad string
`action_id`, sin enum de IDs. No garantiza que runtime/modelo respeten todas
las opciones; los informes distinguen lo solicitado de lo observado. El modo
estructurado forma parte de esta comparación, sin generalizar su formato a
otros modos de Gemma.

Ambos directores reciben la misma whitelist táctica y catálogo. Ni case_id ni
conjuntos aceptables/metadata de oráculo pasan a baseline o HTTP/prompt. Un
validador independiente rechaza formato/IDs/planes ilegales; no extrae JSON de
fences/prosa ni sustituye por pause. Los conjuntos suaves se evalúan después
de decidir, sin definir acierto por coincidencia con la heurística.

## Resultado exploratorio aprobado

Una corrida por backend, fuente `b30f9a6`, ocho casos y 24 intentos más warmup:

| Backend | Legales/intentos | Oráculo/intentos | Oráculo/legales | Mediana wall(ms) |
|---|---:|---:|---:|---:|
| Heurística | 24/24 | 21/24 | 21/24 | 0.102 |
| Gemma 4 E2B | 18/24 | 3/24 | 3/18 | 1410.861 |

Gemma eligió `center` en 24/24 intentos: seis fueron ilegales (tres terminales y
tres por presupuesto insuficiente), sin errores de formato/HTTP/timeout. Se
confirmaron 24 pares comparables y ocho hashes tácticos distintos; no se usaron
fakes ni fallback. La causa de repetir center es **desconocida**: esta muestra
no separa efectos del orden del prompt, esquema JSON, driver, runtime o modelo.
El baseline falló el oráculo suave de defensa fuerte en tres intentos: su
fórmula prioriza menor apilado y no fue ajustada para forzar 100%.

Latencia Gemma: p95 nearest-rank exploratorio 1435.398ms, máximo 1504.476ms;
warmup 1708.210ms separado de los 24 intentos. Baseline mide la decisión local,
Gemma el roundtrip HTTP completo; hash/preflight quedan fuera. El servidor ya
estaba cargado: arranque frío `not_measured`. Dos smokes anteriores no pertenecen
al batch. No se midieron RAM/RSS/GPU/CPU o FPS; 24GB describe capacidad.

Acuerdo dentro de un caso con semillas solicitadas diferentes no prueba
reproducción determinista con seed fijo. Diversidad entre casos y distribución
de planes/roles/carriles tienen denominadores separados en los informes;
AAR es fijo y no representa diversidad aprendida. Con n=24 el p95 es exploratorio.
Estos resultados no prueban incapacidad universal de Gemma, estrategia óptima,
diversión, victoria, robustez o viabilidad Android/S24.

## Verificación y límites de entrega

```sh
python3 -B -m unittest discover -s tests/director_benchmark -p 'test_*.py' -v
```

La validación aprobada incluye 19 unittest offline, 41 controles CI existentes y
el batch real; los dobles de transporte en unittest sólo prueban el adaptador.
El paso CI nuevo conserva GUT/importación del juego; el CI de la revisión final
y QA de integración aún están pendientes. Los informes completos y sus raw
escapados permanecen temporales externos, sin copiarlos aquí.

#61/#53 conservan publicación/físicos pendientes, 006 sigue pausada y beta 1.0.3
no cambia. Este spike no autoriza integrar un director al juego ni desplegarlo.
