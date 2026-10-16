# T021 — GREEN automatizado y comparación de conservación

2026-10-16. Tester. Fuente **a473585ca62e3d35fa1d81d47e052646826032c3**, rama002. Se probó una copia
extraída deGit sin `.godot`, no una mezcla de archivos de003. Script de nivel
SHA256 `4e89dce236868c4203079e06937b5c8dbcbbd564382f373d2216d4aa8c700d7f`; test175líneas y UID byteidénticos aT019.

## Ejecuciones terminadas

Godot4.7.1Mono/GUT9.7.1, en copias aisladas y con procesos serializados:

| Verificación | Resultado | Evidencia |
|---|---|---|
| Importación limpia final, caché inicialmente ausente |EXIT0|[log](t021-clean-import.log)|
| Mismas seis pruebas T019, arte final |6/6,36aserciones,1.580s,EXIT0|[GREEN](t021-green-six.log)|
| Suite completa final |189/189,532aserciones,16scripts,38.199s,EXIT0|[regresión](t021-green-full.log)|
| Comparativo sin arte con el mismo arreglo I4 |ImportEXIT0;6/6GREEN,EXIT0|[GREENbaseline](t021-baseline-green-six.log)|

No se debilitaron aserciones ni repitieron ejecuciones por rutina. El contraste
sin arte adopta el snapshot histórico y agrega **el mismo script corregido y
las mismas seis pruebas/UID**. Ese baseline comparativo se distingue de la
línea base original sin corregir, cuyo fallo y logs siguen en [T019](t019-red.md).

Los dos casos I4 ahora conservan reserva12→15, una sola ganancia3, soldados1→1
y celda libre. Los controles sin pickup conservan12→2/una unidad y pasan tanto
mouse normal como emulado. Los controles de picking también pasan. El cambio
observable respecto al RED es recoger sin despliegue adicional.

Permanecen los tres avisos GUT previos: helper noGutTest,7hijos sin liberar en
enemigo y3en integraciónsoldado/enemigo. No hay nuevos errores de importación
ni fallos de tests. No se ocultaron ni repararon esos avisos dentro del arte.

## Invariantes y procedencia

[Comparación](t021-invariants.json): **95/97archivos originales idénticos**.
Las únicas diferencias protegidas son la instancia visual permitida del nivel
y su script por el arreglo I4 aprobado en preparación. Quitando las tres
adiciones permitidas de la escena, sus nodos/propiedades originales coinciden.
El arte final conserva SHA43eec852…; tests históricos, InputMap, presets,
Resources, balance y geometría permanecen iguales. Los nuevos test/UID son
la adenda explícita, no modificación de expectativas anteriores.

Comandos completos, códigos y manifests congelados:
`/private/tmp/monte-calvo-validation-002-v333ghu2/t021-executions.json`,
`t021-baseline-executions.json` y `corrected-manifest.json`.
Las copias son `corrected-final/` y `corrected-baseline/`; los proyectos
originales con fallo se preservaron separados y no se presentan como finales.

## Alcance nativo y pendientes

Este GREEN acredita el dispatch/picking del motor en el fixture y la regresión
nativa headless, no un dedo físico ni la alineación visual con stretch.
La matriz nativa ratónPC/toqueAndroid/gesto iOSSimulator sigue separada enT008.
Los ensayos PC anteriores aT020 están [etiquetados por revisión](resume-pc-profile.md)
y no se convierten en prueba del estado corregido. Los nuevos exports/pruebas
nativas llevarán revisión/manifest identificables; no se reutilizará un APK
b670d86 previo como si contuviera el arreglo. QA decide el alcance T022 y el
orquestador marca tareas; este reporte no cierra la matriz visual/rendimiento.
