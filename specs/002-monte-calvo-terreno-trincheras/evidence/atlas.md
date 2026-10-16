# T010 — Atlas de trincheras, verificación del recurso aislado

**Fecha**:2026-10-15enBogotá. **Rol**:`godot-tester`, arte/setup sin lógica nueva ni RED artificial. **Rama**:`codex/002-monte-calvo-terreno-trincheras`. Recurso WIP adelantado por autorización del orquestador; este reporte no apruebaT008/T009 ni la integraciónT011.

## Importación y carga

Godot4.7.1mono; importación y verificador temporal externo, ambos con **retorno0**. [Importación](atlas-import.log), [carga](atlas-load.log).

```text
Godot --headless --path . --import --quit-after 2 --log-file <evidence>/atlas-import.log
Godot --headless --path . --script <temporal>/validate_atlas.gd --log-file <evidence>/atlas-load.log
```

`Godot` es el motor del baseline; `<temporal>` es `/private/tmp/monte-calvo-t001-0pulm9d5`. Solo se materializó `trincheras_atlas.png.import`; no se editó elPNG original ni escenas de producción.

- PNG **RGBA1536×1024**, SHA-256`bf5b38cf2b4b2920bd0566195c15d5b0c94297d9124ee1ca38105e1cde340c5b`.
- Alfa0..254; **58.242861%** de píxeles completamente transparentes.
- Godot cargó `CompressedTexture2D`,1536×1024, formatoRGBA8, alpha blend, sin mipmaps; `T010_LOAD_PASS true`.
- `.import`: lossless(`compress/mode=0`), `mipmaps/generate=false`, `fix_alpha_border=true`, `premult_alpha=false`, `size_limit=0`.
- Estimación conservadora RGBA8 sin mipmaps **6,291,456bytes/6MiB**; las tres hojas suman **18,872,976bytes/~17.999MiB**. No es VRAM/memoria real medida. El atlas se reutiliza por regiones sin duplicar esa hoja por sprite.

## Seis regiones y ensayo visual

Se cotejaron las regiones propuestas en `assets/sprites/levels/monte_calvo/SOURCES.md`. La distribución generada no respeta celdas512×512 exactas; se usan regiones variables registradas, sin recortar a una cuadrícula inventada:

| Pieza | Región(x,y,w,h) |
|---|---|
| Madera/tierra |(0,168,544,336)|
| Sacos |(540,256,520,240)|
| Esquina |(1056,112,480,424)|
| Unión madera/sacos |(0,616,520,336)|
| Rocas/hierbaA |(520,608,512,352)|
| Rocas/hierbaB |(1040,680,496,280)|

El ensayo temporal `preview_atlas.gd` creó unSubViewport1152×648 con el terreno congeladoUS1 y las seis regiones en una distribución de inspección, **no la ubicación final del nivel**. Todas usan escala0.6, filtro lineal local, repeat desactivado y recorte de filtro de región. Renderer **Mobile/Metal**; retorno **0**. [Log](atlas-preview.log), [captura](atlas-regions-preview.png).

En la captura se distinguen madera envejecida, tierra excavada, sacos y dos conjuntos de roca/hierba seca, con materialidad coherente con el suelo. Las piezas conservan sus siluetas; no se observan rectángulos de fondo, líneas de celda, bleed de la pieza vecina o halos blancos/negros manifiestos en este ensayo. La esquina alcanza el borde derecho delPNG con alfa tenue; no se ve un corte duro en esta vista. Esto no sustituye revisar márgenes y solapamientos a la escala/posición deT011.

No hay personajes, HUD, armas, banderas, texto o cinco puestos horneados. La presencia de varias piezas separadas en la captura es únicamente la hoja de inspección: la composición final debe formar una posición amplia y respetar la máscara de lectura central, sin aparentar límites funcionales.

## Conservación y entrega

Los seis hashes del estadoUS1 en `us1-sha256.json` permanecen idénticos tras la importación: nivel, escena visual, terreno/montañas y sus imports sin cambios. No se alteraron gameplay, pruebas, proyecto, exportaciones, versión o firma. No se ejecutó GUT de nuevo para un recurso aislado.

Se entrega a QA la importación/carga/alpha y el ensayo de regiones. Quedan paraT011/T012 la colocación real, z con actores/pickups, continuidad, solapamientos, recorte PC/móvil y picking sobre la decoración. No se marca ninguna tarea desde testing ni se atribuye aprobación global a las verificaciones pendientes.
