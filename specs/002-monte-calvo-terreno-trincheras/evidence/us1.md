# T007 — Terreno integrado, comprobación visual PC

**Fecha**:2026-10-15. **Rol**:`godot-tester`, verificación de arte sin lógica nueva ni RED artificial. **Rama**:`codex/002-monte-calvo-terreno-trincheras`. Estado probado: integración T006, antes de trincheras. [Hashes del estado](us1-sha256.json), [baseline](baseline.md), [reporte T004/T005](visual-structure.md).

## Ejecución y capturas

Godot4.7.1mono, **Mobile/Metal, AppleM5Pro**, mismas condiciones de render que el baseline. Se copió la integración completa a `/private/tmp/monte-calvo-t001-0pulm9d5/terrain-project/` y se usaron los observadores temporales de lectura `observe_us1_v1.gd` / `observe_us1_v2.gd`; no se alteró gameplay. Cada sesión guardó el viewport tras `frame_post_draw` y terminó con código **0**. No son capturas de clics manuales.

```text
Godot --path <temporal>/terrain-project --script <temporal>/observe_us1_v1.gd --windowed --resolution 1152x648 --position 100,100 --log-file <evidence>/us1-v1.log -- prefix=us1-v1
Godot --path <temporal>/terrain-project --script <temporal>/observe_us1_v2.gd --windowed --resolution 1920x1080 --position 100,100 --log-file <evidence>/us1-v2.log -- prefix=us1-v2
```

`Godot` es el ejecutable absoluto del baseline; `<temporal>` es `/private/tmp/monte-calvo-t001-0pulm9d5`. [LogV1](us1-v1.log), [logV2](us1-v2.log).

| Estado comparable | Antes V1 | Integrado V1 | Antes V2 | Integrado V2 |
|---|---|---|---|---|
| Inicial |[baseline](pc-v1-0.png)|[1152×648](us1-v1-0.png)|[baseline](pc-v2-0.png)|[1920×1080](us1-v2-0.png)|
| Combate/pickups, alrededor de8s |[baseline](pc-v1-1.png)|[1152×648](us1-v1-1.png)|[baseline](pc-v2-1.png)|[1920×1080](us1-v2-1.png)|

Ambas ventanas conservan rect lógico **1152×648** y canvas_transform identidad. V1 mantiene stretch1; V2 mantiene stretch1.666667. Soldado **(576,500), celda(6,5)**; defensa **(576,650)**. El proceso observa la escena natural: los enemigos pueden estar en posiciones ligeramente diferentes entre capturas por el tiempo/frames transcurridos; no se presentan como una comparación de frames idénticos ni como benchmark.

## Resultado visual observado

- Se ve terreno ocre con piedras/grano y horizonte de montañas azul grisáceas, siguiendo la dirección de la referencia en materiales/paleta. No se añadieron personajes ilustrados, HUD, cinco carriles, cuadrícula, marcas de despliegue o nuevas fronteras funcionales.
- Suelo único escalado aproximadamente a **1920×1080 unidades**, `texture_repeat=DISABLED`. En V1/V2 el suelo cubre el rect lógico sin huecos o juntas de repetición. La junta detectada en el ensayo2×2 de T005 no entra en esta composición porque no hay repeat.
- El cielo es un `GradientTexture2D` estático de16×256 renderizado a1920×192; el panorama usa región(0,320,1536,424), escala(1.25,.37735849), aproximadamente1920×160. La tierra que aparecía arriba de los picos en el ensayo provisional se reemplazó por cielo; no se observan rectángulos opacos o halos negros en estas capturas.
- Los placeholders blanco/rojo oscuro y el pickup amarillo se distinguen delante del entorno; el amarillo permanece visible aunque su contraste se evalúa sobre un suelo también cálido. El detalle del suelo sigue visible en el centro y no se ha pintado una banda de selección. La valoración artística de la tranquilidad de esa zona se entrega a QA junto con las imágenes.
- La nueva jerarquía usa Node2D/Sprite2D y recursos de textura/gradiente; no tiene scripts, input, Control, física, colisiones, cámara, luces, shader, partículas o navegación. Efectivos de dibujo de suelo−10 y cielo/panorama−9, debajo de actores/pickups z0.

Esta revisión cubre PC V1/V2 y lectura/continuidad del terreno. No acredita picking por z ni resultados Android/iOS. El nivel no tiene trincheras aún, por diseño de este incremento; se conserva evidencia para compararlas después.

## Estado congelado sin trincheras

Antes de permitir la siguiente edición se guardó `/private/tmp/monte-calvo-t001-0pulm9d5/terrain-without-trenches.tscn` y una copia completa aislada en `terrain-project/`. SHA-256 de `MonteCalvoVisual.tscn` congelada: **5138a1c34b67a677242308bddbf7e62c8891115aae4ac63bba72530e1d39cb0c**. El nivel integrado tiene SHA-256 **9ce9dd7efc14e4d73e187e02ef909ac1f21159c688744bfafd3e9bee543831ad**. [Manifest](us1-sha256.json) registra también los PNG e imports, idénticos a T005.

No se creó otra escena `res://` de comparación ni se editaron tareas/checkboxes o commits. Se entrega a QA junto con [T008](us2.md); QA decide aprobación y límites pendientes.
