# Research — 003-web-itchio

**Fecha de consulta**: 2026-10-15. Investigación de preparación, sin exportaciones
ni pruebas ejecutadas. Baseline de partida: commit `b670d86`, dependiente de
las personalizaciones Spec Kit y del arte WIP de 002.

## 1. Exportador y versión

**Decision**: Usar Godot estándar **4.7.1 stable** y sus templates Web de la
misma versión, junto al entorno Mono existente. Instalar fuera del repositorio;
no reemplazar la aplicación Mono ni actualizar de versión el proyecto.

**Rationale**: El checkout usa GDScript. El inventario inicial del orquestador
solo encontró Godot Mono 4.7.1 y sus templates, sin templates Web. La publicación
oficial permite fijar editor y templates compatibles. La ausencia local es un
prerrequisito de entorno, no evidencia RED de un bug del juego.

**Alternatives considered**: Migrar a C# o cambiar de motor agrega trabajo sin
beneficio para este objetivo; actualizar Godot mezcla una migración no pedida.
No compilar templates propios en esta primera exportación.

**Fuentes**: [Release oficial 4.7.1](https://github.com/godotengine/godot-builds/releases/tag/4.7.1-stable),
[restricción C# y Web](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html).

## 2. Ruta gráfica y aislamiento de plataformas

**Decision**: Explicitar en `project.godot`
`rendering/renderer/rendering_method.web="gl_compatibility"`; conservar
`renderer/rendering_method="mobile"`, sus ajustes y los presets nativos.

**Rationale**: Web usa WebGL 2.0/Compatibility; la propiedad `.web` ya tiene ese
valor por defecto en Godot 4.7. Explicitarlo hace revisable la decisión sin
migrar el renderer nativo. La apariencia se compara en navegador real.

**Alternatives considered**: Cambiar el renderer global altera Android/iOS sin
necesidad demostrada. Forward+/Mobile no son la ruta Web disponible.

**Fuentes**: [ProjectSettings: renderer Web](https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html#class-projectsettings-property-rendering-renderer-rendering-method-web),
[exportación Web](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html#webgl-version).

## 3. Variante de exportación y canvas

**Decision**: Preset `Web`, `variant/thread_support=false`,
`variant/extensions_support=false`, `progressive_web_app/enabled=false`,
`html/canvas_resize_policy=2` (Adaptive), shell estándar y salida
`build/web/index.html`. Templates esperados:
`web_nothreads_debug.zip` y `web_nothreads_release.zip` de la versión fijada.

**Rationale**: No hay GDExtension ni uso deliberado de hilos en el juego. La
variante simple permite comenzar sin aislamiento entre orígenes ni service
worker. Canvas adaptativo se prueba con el stretch existente; no implica
modificar coordenadas del tablero.

**Alternatives considered**: Hilos añaden requisitos de hosting; PWA introduce
caché y funcionamiento offline no pedidos. No copiar `rendering/threads/thread_model`
del ejemplo genérico de la skill: la selección correcta es la opción del
exportador verificada en la referencia 4.7.

**Fuentes**: [Opciones oficiales del exportador](https://docs.godotengine.org/en/4.7/classes/class_editorexportplatformweb.html),
[variante de un hilo](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html#thread-and-extension-support).

## 4. Tamaño e interacción

**Decision**: Mantener inicialmente `canvas_items` + `expand` y la resolución
base por defecto 1152×648, ya usada por la evidencia 002. Validar canvas web
1152×648 y 960×540, después de redimensionar, y Chrome Android horizontal con
sus dimensiones CSS/píxeles reales registradas. Recomendar iframe 1152×648
para carga manual y validar también una página local con iframe.

**Rationale**: El nivel contiene posiciones fijas y no tiene cámara; el picking
actual invierte la transformación del canvas. Tamaño de ventana, escala del
sistema y densidad del teléfono no son coordenadas lógicas intercambiables.
La ausencia de dimensiones explícitas no prueba por sí sola un defecto.

**Alternatives considered**: Rediseñar tablero, añadir cámara/HUD o mover
soldados sobre el arte ampliaría la feature. Solo ante recorte demostrado se
considera un override `.web` de tamaño/stretch, conservando valores nativos.
Si aparece un bug de comportamiento/input, se agrega una tarea RED específica
antes de corregirlo; una captura aislada o GUT headless no acredita picking.

**Fuentes**: [ProjectSettings: tamaño y stretch](https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html),
[overrides por feature](https://docs.godotengine.org/en/4.7/tutorials/export/feature_tags.html).
La estructura/input del nivel se contrastó con el checkout y los reportes 002.

## 5. Paquete y entrega

**Decision**: ZIP con `index.html` en la raíz y todos sus archivos compañeros,
sin renombrarlos tras exportar. Exportar solo dependencias del nivel, excluyendo
`tests/`, `addons/gut/`, `specs/`, `docs/`, `tools/` y archivos internos. Verificar
el contenido **del PCK**, además del listado exterior del ZIP. Conservar las
licencias/atribuciones de distribución que correspondan.

**Rationale**: El portal sirve un iframe y exige el punto de entrada correcto.
La exportación de todas las Resources actuales arrastraría contenido de prueba.
El arte conceptual/evidencias de 002 ya tienen `.gdignore`; eso no sustituye la
inspección del paquete final.

**Alternatives considered**: Subir la carpeta completa del proyecto expone
archivos innecesarios. `butler`, cuenta, pagos, página pública y publicación
quedan fuera. Sin precompresión manual inicial; medir el paquete primero.

**Fuente**: [Requisitos de juegos HTML5 de itch.io](https://itch.io/docs/creators/html5).
A esta fecha: máximo 1000 archivos, rutas de hasta 240 caracteres, 500 MB
extraídos y 200 MB por archivo. El portal documenta compresión CDN para
`wasm`/`pck`; prevalece esa fuente del hosting sobre notas antiguas de otros sitios.

## 6. Automatización y trazabilidad

**Decision**: Un comando local documentado, `tools/web/export.sh`, generará la
salida y ZIP en `build/`, con manifiesto exterior de revisión/hashes/tamaños.
Un workflow nuevo `.github/workflows/export-web.yml` reutilizará ese comando,
Godot estándar 4.7.1 y un artefacto descargable; sin despliegue ni credenciales
itch.io. Triggers de PR y manual; cualquier push automático se limita a
construir el artefacto y no invoca distribución nativa.

**Rationale**: Local y CI deben producir el mismo tipo de entrega. La salida
`build/` ya se ignora. No tocar los workflows Android/Firebase e iOS/TestFlight,
ni incrementar versiones móviles para una exportación web local.

**Alternatives considered**: Publicar desde CI exige una decisión adicional y
acceso al portal. Reescribir CI móvil mezcla responsabilidades. La verificación
remota se acredita solo si se ejecutó realmente; revisión YAML no equivale a run.

## 7. Validación y límites

**Decision**: Suite GUT existente como regresión nativa, navegador visible para
entrada real, y Chrome en Xiaomi físico para toque. Registrar Firefox, Safari
macOS e iOS Web como probados/fallidos/no disponibles según evidencia. Smoke
manual hasta resultado terminal antes de compartir con externos; victoria y
derrota se verifican separadamente con las pruebas existentes y se declara el
alcance de esa evidencia. Medir carga fría, tamaño, cadencia/frame times y
sesión/dispositivo, sin convertirlos en cumplimiento sostenido constitucional.

**Rationale**: 002 solo tiene aprobación parcial; su prueba Android nativa no
valida Web Android ni cierra iOS/rendimiento. El port no añade mejoras silenciosas
de UX, balance o estados. Si un requisito constitucional no se demuestra,
QA conserva el gate pendiente y el ZIP se identifica WIP.

**Alternatives considered**: Renombrar PC como Web para cerrar 002, simular toque
en escritorio como Android físico o declarar soporte por una única captura
no aportan la evidencia requerida.

## Estado de resolución

No quedan preguntas técnicas sin decisión para preparar tareas. La enmienda
transversal de plataformas requiere QA antes de implementar; la disponibilidad
de navegadores y los resultados de ejecución aún deben registrarse por los
agentes. Ninguna medición, exportación ni aprobación de implementación se
atribuye a esta investigación.
