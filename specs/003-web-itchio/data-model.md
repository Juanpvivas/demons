# Data Model — 003-web-itchio

No se añaden entidades, Resources, estado persistente o reglas de gameplay.
Se conserva [el límite de la partida](contracts/web-delivery.md#partida-conservada).

## Preset Web

| Campo | Valor/validación |
|---|---|
| Identidad | `name="Web"`, `platform="Web"`, único sin modificar Android/iOS |
| Salida | `build/web/index.html` |
| Renderer | override Web `gl_compatibility`; Mobile global intacto |
| Variante | `thread_support=false`, `extensions_support=false` |
| PWA | deshabilitada; no service worker/contrato offline |
| Canvas | Adaptive, stretch existente; cambios solo Web ante evidencia |
| Recursos | dependencias jugables, sin GUT/pruebas/documentación interna |

Se registra en `export_presets.cfg`; el renderer por plataforma en
`project.godot`. No se guardan rutas personales ni credenciales.

## Entrega Web

| Dato | Significado |
|---|---|
| Revisión de origen | commit SHA y estado dirty explícito si se construye WIP |
| Motor/templates | 4.7.1 stable estándar y procedencia oficial |
| Artefacto | ZIP en `build/`, con inicio en raíz y archivos relativos intactos |
| Integridad | lista, tamaños y SHA256 del ZIP/archivos en manifiesto exterior |
| Contenido | inspección exterior + PCK; exclusiones y licencias revisadas |
| Estado | generado → verificado localmente → revisado por QA; publicar es externo |

El manifiesto y logs de desarrollo no se mezclan en la carpeta que se comprime
para jugadores. El nombre de salida puede incluir SHA, sin exigir ZIP idéntico
byte a byte entre plataformas; sí exige mismo contenido funcional trazable.

## Evidencia de sesión

| Dato | Regla |
|---|---|
| Entorno | navegador y versión, OS, modelo físico y versión, renderer real |
| Geometría | tamaño CSS del canvas, tamaño físico/densidad, orientación |
| Interacción | clic mediante CUA del navegador o toque físico; no intercambiar esas etiquetas |
| Caso | ID W01–W12 del contrato, estado previo, acción y resultado |
| Medición | duración, carga fría/caliente, frame times/cadencia, método |
| Resultado | PASS, FAIL o NOT RUN con causa y artefacto enlazado |

Las capturas son apoyo visual; no prueban por sí solas saldo, ocupación,
consumo único o toda una partida. GUT y escenarios acelerados se etiquetan como
pruebas automatizadas, separados del smoke manual con datos de producción.
