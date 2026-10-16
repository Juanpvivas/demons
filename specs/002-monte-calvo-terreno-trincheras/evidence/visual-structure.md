# T004 y comprobación técnica de T005 — escena aislada y texturas

**Fecha**:2026-10-15. **Rol**:`godot-tester`. **Modo**:verificación de arte/setup, sin RED artificial. **Rama**:`codex/002-monte-calvo-terreno-trincheras`. Referencias: `spec.md`, `contracts/visual-boundary.md`, `references/production-brief.md` y reporte del desarrollador de T003/T005. No es aceptación del terreno integrado, picking o rendimiento final.

## T004 — carga y estructura aislada

Se cargó e instanció `scenes/levels/MonteCalvoVisual.tscn` con Godot4.7.1mono en headless mediante verificador temporal fuera del repositorio (`/private/tmp/monte-calvo-t001-0pulm9d5/validate_visual.gd`). Ejecución real con retorno **0** y `T004_STRUCTURE_PASS true`: [log completo](visual-structure.log).

```text
Godot --headless --path . --script <temporal>/validate_visual.gd --log-file <evidence>/visual-structure.log
```

`Godot` es el mismo motor registrado en [baseline.md](baseline.md). Se creó el árbol aislado y se leyeron sus propiedades; no se cargó el nivel jugable ni se cambió su estado.

| Nodo | Tipo | Transformación | z_index | z_as_relative | Scripts / hijos |
|---|---|---|---:|---|---|
| MonteCalvoVisual | Node2D | Identidad | -10 | true | Sin script;4 hijos |
| Suelo | Node2D | Identidad |0|true|Sin script;0 hijos|
| FondoMontanas | Node2D | Identidad |1|true|Sin script;0 hijos|
| Bordes | Node2D | Identidad |2|true|Sin script;0 hijos|
| Trincheras | Node2D | Identidad |3|true|Sin script;0 hijos|

Inspección del `.tscn`:5 nodosNode2D, sin recursos externos, conexiones de señales, scripts, Control, física/áreas/colisiones, navegación, cámara, luces, partículas, shader o parallax. Las transformaciones omitidas se comprobaron como identidad al instanciar. Los z efectivos del subárbol son−10,−10,−9,−8,−7: todos quedan detrás del z0 actual de los actores.

SHA-256 de la escena probada:`ec22167a4e0e55ca89f1ffa3073184b6a4e4fbf48079702c40b0d44551421c57`. La escena sigue **sin integrar** en `Nivel_MonteCalvo.tscn`. Los **97/97 archivos protegidos del baseline siguen idénticos**; el nivel, scripts, Resources, proyecto, exportaciones y tests no se editaron. Esta comprobación no acredita input por el mero orden de z.

## T005 — importación y carga de las dos imágenes terminadas

Se ejecutó una única importación sobre las imágenes terminadas, sin editor/importador concurrente:

```text
Godot --headless --path . --import --quit-after 2 --log-file <evidence>/assets-us1-import.log
Godot --headless --path . --script <temporal>/validate_textures.gd --log-file <evidence>/assets-us1-load.log
```

Ambos retornaron **0**. [Log de importación](assets-us1-import.log), [log de carga](assets-us1-load.log). Solo se materializaron los `.png.import` estándar. El segundo verificador, también temporal externo, cargó ambas `CompressedTexture2D` y leyó sus imágenes; `T005_LOAD_PASS true`.

| Asset | PNG / tamaño real | Carga en Godot | Estimación RGBA8 sin mipmaps |
|---|---|---|---:|
| terreno.png | RGB1254×1254 |1254×1254, formatoRGB8, sin alpha ni mipmaps|6,290,064bytes (~5.999MiB)|
| montanas.png | RGBA1536×1024 |1536×1024, formatoRGBA8, alpha blend, sin mipmaps|6,291,456bytes (6MiB)|

Total estimado de estas dos hojas:**12,581,520bytes (~11.999MiB)**. No es VRAM medida, memoria de la app ni tamaño de descarga. El terreno llegó a1254×1254 en vez de la propuesta1024×1024 del brief; se registra la dimensión real sin redimensionarlo ni ocultar su costo. La evaluación final de memoria corresponde al dispositivo y T015.

Parámetros verificados en ambos `.import`: `compress/mode=0` (lossless), `mipmaps/generate=false`, `process/fix_alpha_border=true`, `process/premult_alpha=false`, `process/size_limit=0`; `vram_texture=false`. No se cambió filtro global, renderer, ETC2/ASTC o proyecto. Filtro/repetición del entorno corresponden a los CanvasItem al componer.

El alfa original de montañas va de0 a254; **68.623%** de los píxeles tiene alfa0. Bounding box para alfa≥4 (extremo derecho/inferior exclusivo): **(0,352,1536,715)**. Se confirmó alpha blend al cargarlo en Godot. El contenido útil debe ajustarse mediante región/escala del sprite sin convertir el lienzo transparente entero en una franja opaca. La propuesta del desarrollador de región(0,320,1536,424) conserva margen alrededor de esa caja; su encaje visual aún debe comprobarse integrado.

Inspección visual de los PNG originales: terreno ocre con grano/piedras pequeñas, sin unidades, UI, cuadrícula o cinco carriles; montañas frías azul grisáceas con neblina pintada y fondo transparente. No hay trincheras todavía. El detalle se reparte por el terreno: al componer debe conservarse el centro tranquilo y comprobarse contraste frente al rojo oscuro del enemigo y amarillo del pickup. No se afirma ausencia de costuras, halos a escala final o lectura sobre el nivel antes de esa composición.

Hashes de assets originales:

- `terreno.png`: `b0c6f46717fc256cb025987f98183e499ba0a27a953bb8ea743795d41761429b`.
- `montanas.png`: `0e1b0fda34559bd7b49258e31f5982617adeaef247b1fe41abe4b20895797194`.

## Render temporal de continuidad y alpha

Se ejecutó `preview_assets.gd`, fuera del repositorio, con **Mobile/Metal** y retorno **0**; [log](assets-us1-preview.log). Solo creó dos SubViewport y sprites de ensayo con las texturas importadas. **No es la escena integrada T006 ni una captura de gameplay.**

- [Repetición2×2 del terreno](assets-us1-tiling.png),1254×1254: usa región2508×2508, repeat activado y escala0.5. Se aprecian juntas rectas en los límites de repetición, alrededor de x627/y627. La fuente **no queda acreditada como tile sin costuras**. Si la integración necesita repetirla, el desarrollador debe corregir ese recurso; una composición con hoja única escalada y cobertura suficiente evita introducir esa repetición.
- [Ensayo de montañas sobre terreno](assets-us1-composition-preview.png),1152×648: región(0,320,1536,424), escala(.75,160/424), solo recursos de ensayo. El alpha desvanece la base, pero revela tierra por encima de los picos. La composición final debe resolver ese fondo superior con arte estático permitido y conservar picos/transición, sin añadir UI, shaders o lógica. Esta vista **no acredita horizonte final correcto**.

Los dos hallazgos se entregaron al desarrollador/orquestador antes de T006. No se corrigieron assets o escenas desde testing. QA debe valorar T005 con estas limitaciones explícitas: carga/materialidad/alpha están comprobados; tileabilidad sin juntas y composición final no se aprueban por estos ensayos.

## Entrega y límites

T004 cuenta con carga real e inspección satisfactoria del contrato estructural. T005 cuenta con importación/carga y alpha real correctos, con desviación de tamaño registrada. Se entrega a QA para valorar estas tareas antes de T006. Composición, continuidad de suelo, márgenes transparentes, recorte, halos, máscara de bajo ruido, lectura de actores/pickups y encuadre PC/Android se comprueban al integrar en T006/T007/T008; no se presenta la inspección aislada como aceptación de esos resultados.

No se modificaron gameplay, tests, tareas o checkboxes, ni se crearon commits. No se repitió GUT por una estructura vacía y carga de imágenes; el baseline183/183 permanece enlazado y la regresión se repite en sus tareas de integración/cierre. QA emite su veredicto independiente; este reporte no lo sustituye.
