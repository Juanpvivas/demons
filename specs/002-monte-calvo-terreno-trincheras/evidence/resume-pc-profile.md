# PerfilPC002 previo a T020 — ensayo comparativo de arte

2026-10-16. Se ejecutaron **dos observaciones31s, ambas EXIT0**, en copias
baseline sin arte y final002/b670d86. Este ensayo precede aT020 y no certifica
por sí mismo su código corregido. No hubo interacción: el callback modificado
porT020 no se ejercita aquí, pero esta evidencia conserva su revisión original.
No se repitió GUT ni se cambió configuración/implementación de producción.

El observador002 existente se copió y amplió solo con lecturas Performance y
RenderingServer; activó medida de render del viewport, sin input, setters de
estado, controles o nuevo framework. Se desactivaron las capturas históricas
para no sobrescribirlas ni añadir readback durante el perfil.
[Resumen y hashes](resume-pc-profile-summary.json). Fuente, raw y ejecuciones:
`/private/tmp/monte-calvo-validation-002-v333ghu2/observe_002_telemetry.gd`,
`telemetry-provenance.json`, `pc-profile-executions.json`,
`baseline-pc-telemetry.json` y `final-pc-telemetry.json`.

## Ventana y resultados

Godot4.7.1Mono, Mobile/Metal, AppleM5Pro, ventana1152×648. Se seleccionó
exclusivamente **PLAYING5..30s**,1870muestras por copia; autoplay de combate
inicial, no partida típica sostenida ni diez oleadas. No se mezcló tiempo
posterior aLOST. El instrumento y la caché del sistema limitan la comparación.

| Métrica | Sin arte | Artefinalb670d86 |
|---|---:|---:|
| EngineFPS reportados |74–75|74–75|
| Deltams, mediana/p95/máximo |13.333/13.333/18.216|13.333/13.636/18.299|
| TIME_PROCESSms, mediana/p95 |14.179/21.241|14.040/25.942|
| TIME_PHYSICS_PROCESSms, mediana/p95 |0.417/3.378|0.373/0.936|
| CPUrender viewportms, mediana/p95 |0.041/0.070|0.049/0.080|
| CPUsetup renderms, mediana/p95 |0.010/0.023|0.010/0.023|
| GPUrender viewport |No disponible: lectura0|No disponible: lectura0|
| Texturemem Godot bytes |1215232|20368128|
| Videomem Godot bytes |27475968|52920320|

TIME_PROCESS es el monitor de tiempo de frame del motor, no una medición
exclusiva de CPU ocupada por scripts; CPUrender y setup se reportan separados.
GPU devolvió cero en todas las muestras pese a medición habilitada: se registra
como **no disponible**, nuncaGPU0ms. Texturemem/videomem son contadores de
asignación del renderer, distintos dePSS/RSS y de una auditoría del driver.
El aumento de texturemem reportado es19152896bytes; no se multiplica el atlas
por el número de sprites ni se sustituye ese contador por una fórmulaRGBA.

## Carga y límites

Primerpostdraw en reloj de motor903ms baseline/424ms final. Escena→postdraw:
29.432/90.329ms; inicialización del script→postdraw39.934/105.494ms. Miden
carga del nivel hasta su primer render en el instrumento; no incluyen la
creación del proceso antes del script y la caché no se limpió/controló. No
se atribuye la diferencia de reloj total únicamente al arte ni se certifica
carga fría del dispositivo.

Las APIs oficiales definen renderCPU/GPU enms y los monitores de memoria en
bytes: [RenderingServer4.7](https://docs.godotengine.org/en/4.7/classes/class_renderingserver.html),
[Performance4.7](https://docs.godotengine.org/en/4.7/classes/class_performance.html).

No es medición del Xiaomi, iOS físico o un dispositivo constitucional de
referencia. No acredita60FPS estables móviles. No reemplaza SF/PSS histórico,
los casos de input, la matriz de simuladores o el perfil Android final que se
hará de forma coordinada y con revisión/fuente identificadas trasT020/T021.
