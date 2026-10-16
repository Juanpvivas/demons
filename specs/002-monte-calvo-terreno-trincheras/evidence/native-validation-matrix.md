# 002 — Matriz nativa consolidada, 2026-10-16

Evidencia del tester; las aprobaciones indicadas son dictámenes independientes ya recibidos de QA. No marca tareas ni sustituye el cierre del orquestador. Fuente corregida a473585/script4e89dce…; evidencia anterior al arreglo permanece histórica, sin atribuirle cobertura nueva.

| Vía | Pantalla/viewport real | Composición y recorte | Entrada y límite actual |
|---|---|---|---|
| V1 PC nativo | Captura1152×648, lógico1152×648, stretch1 | [BASE](pc-v1-0.png), [FINAL inicial](final-v1-0.png)/[combate](final-v1-1.png); arte final idéntico al actual, capturas históricas de render | QA aprobó [BASE I2](native-pc-base-cd-human.md)/[BASE I1/I4/I9](native-pc-base-cd-human-run2.md) y [FINAL I1/I2/I4/I9](native-pc-arte-cd-human.md), PRE/POST PLAYING; I3 previo se reutiliza. Ratón humano de SO, no headless |
| V2 PC nativo | Captura1920×1080, lógico1152×648, stretch1,666667 | [BASE](pc-v2-0.png), [FINAL](final-v2-0.png)/[combate](final-v2-1.png). Suelo sin costura/hueco, horizonte continuo; mismo corte inferior de648 | Evidencia de composición; no se deduce clic/stretch de un screenshot |
| V3 Xiaomi físico 11T Pro | 2400×1080, lógico1440×648, stretch1,666667, Mobile/Vulkan | [Antes8s](native-android-baseline-8s.png)/[después8s](native-android-final-8s.png), [final18s](native-android-final-18s.png)/[30s](native-android-final-30s.png); suelo cubre el ancho adicional | [Humano](native-android-input.md): I1/I3, naturalLOST≈51s; I2/I4 físicos no discriminados. [AVD controlado](native-avd-input.md) aporta I1–I4/I9 antes/después en su vía; no dedo físico |
| V4 iPad Pro13M5/iPadOS27.0 Simulator | 2752×2064, lógico1152×864, stretch2,388889, Compatibility/OpenGL3/SoftwareRenderer | [BASE](native-ipad-baseline-human-current.png)/[FINAL](native-ipad-final-i4-human-current.png), horizontal4:3. Suelo continúa hasta864; frente completo visible; capturas posteriores aLOST; [primera FINAL](native-ipad-final-human-current.png) muestra soldado blanco enA por encima del suelo/frente, sin fingir framePLAYING | QA aprobó mínimoV4: [I1/I3 FINAL](native-ipad-final-human.md), picking básico/ruta y [I4 BASE](native-ipad-baseline-human.md)/[FINAL](native-ipad-final-i4-human.md) con12→15/1→1/PLAYING. I2/I9 iPad no demostrados; hardwareiOS no probado |

## Qué conserva la comparación visual

Los mismos nodos y texturas producen el encuadre; no se cambiaron posiciones, celdas, colisiones, cámara ni límites. V1/V2 a altura lógica648 recortan los últimos píxeles del frente hasta653, igual que la defensa preexistente extendida hasta682. V4 amplía altura visible a864 y muestra más suelo, sin mover el eje576 ni la defensa. V3 amplía ancho lógico a1440; I9 emulado en x1300 sigue aceptando entrada, sin suponer un tablero finito. El terreno de1920×1080 y cielo/panorama cubren estos encuadres.

Las capturas PC/Android muestran rojo/blanco/amarillo por encima del entorno y lectura de materiales; [AVD final](native-avd-final-action8.png) conserva despliegue en el frente decorativo. En iPad, los logs sitúan y discriminan los gestos humanos activos; las capturas congeladas después no se presentan como frames durante esos gestos. No se fabrica una colección junto a trinchera ni se desplaza un pickup para obtenerla. QA determina si esta evidencia disponible satisface la lectura final sin exigir nuevas ejecuciones por rutina.

## Regresión, smoke y rendimiento separados

- [T021](t021-green.md):6/6routing,189/189suite/532aserciones, importación limpia0, invariantes95/97 con dos excepciones aprobadas. No se repite por documentos.
- [Smoke](smoke.md): sesión humana corregida hastaLOST≈51s y escenarios victoria/derrota de la suite; no diez oleadas manuales inventadas.
- [Rendimiento](performance.md): SC-007 aceptado porQA solo002/Xiaomi provisional, comparaciónPLAYING5–30s más sesión humana≈50s y [control del guardado](native-save-control.md). Conserva perturbación54/55FPS/frame24,453ms y límites de métodos. SoftwareRenderer emulado no es benchmark físico.

Las vías de entrada mínimas PC/AVD/Xiaomi/iPad tienen sus dictámenes acotados recibidos. No quedan nuevas ejecuciones asignadas al tester; queda la auditoría global T016 y consolidación documental T017/T018 por sus roles, sin anticipar aceptación global ni marcar tareas. No se requieren más Android/GUT/bench ni repetición de ramas iOS para la distribución aprobada.
