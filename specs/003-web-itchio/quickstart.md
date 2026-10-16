# Quickstart — validar Monte Calvo Web antes de itch.io

Guía de ejecución **prevista**: los archivos de herramientas indicados aún
requieren implementación por los agentes. No acredita comandos ejecutados.

## Prerrequisitos

- Enmienda de plataformas y preparación de 003 revisadas por QA.
- Godot **estándar 4.7.1 stable** con templates Web de la misma versión; conservar
  Mono para el entorno nativo existente. Procedencia en [research](research.md).
- Python 3 para servidor local y herramientas ZIP disponibles; navegador
  Chromium de escritorio, Xiaomi con Chrome y conexión USB para pruebas.
- Checkout en `codex/003-web-itchio`; conservar la línea base `b670d86` y los
  pendientes de 002. Todas las salidas locales van bajo `build/` ignorado.

## 1. Línea base e importación

El tester registra hashes de las rutas protegidas del contrato, versiones de
motor/templates/navegadores y disponibilidad de dispositivos. Ejecuta la suite
GUT existente en el entorno nativo. Errores de entorno no constituyen RED.

Comando GUT de referencia desde la raíz, usando el ejecutable instalado:

```bash
"$GODOT_NATIVE_BIN" --headless --path . --script addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs=true -gexit
```

`GODOT_NATIVE_BIN` y `GODOT_WEB_BIN` son variables del operador hacia los
binarios locales; no se versionan rutas personales ni se cambia HOME.

## 2. Generar y servir

Después de implementar la herramienta, desde la raíz:

```bash
GODOT_WEB_BIN="/ruta/al/Godot-estandar-4.7.1" tools/web/export.sh
python3 -m http.server 8060 --directory build/web --bind 127.0.0.1
```

Abrir `http://127.0.0.1:8060/`. El comando debe producir la carpeta Web, un ZIP
y un manifiesto de revisión, hash y tamaño **fuera de la carpeta empaquetada**.
El servidor es solo local de desarrollo; itch.io proporcionará el alojamiento
HTTPS. No abrir el HTML como archivo local ni servir la raíz del repositorio.

## 3. Escritorio

Ejecutar W01–W06 y W08–W12 de [la matriz](contracts/web-delivery.md), registrar
canvas 1152×648 y 960×540, escala real y acciones por clic mediante CUA del navegador. Probar también
un iframe local con esas dimensiones; no afirmar que eso es una publicación en
itch.io. Registrar consola/red, capturas y tiempos de carga en tres sesiones
nuevas, distinguiendo caché fría de caliente.

Para cada clic mediante CUA del navegador, tomar las coordenadas de una
captura del canvas real y registrar evento → Godot → resultado con saldo
y celdas antes/después. No usar `HTMLElement.click()`, `dispatchEvent` ni
métodos del juego para producir la acción. Esta aclaración de método no
sustituye la evidencia funcional exigida ni el toque físico de Android.

## 4. Android navegador

Con USB y depuración autorizada en el teléfono, el tester puede usar el reenvío
local del puerto para abrir el mismo servidor sin exponerlo a la red:

```bash
adb reverse tcp:8060 tcp:8060
```

Abrir `http://localhost:8060/` en Chrome del Xiaomi y girarlo a horizontal.
Registrar versión de Chrome/Android, modelo, tamaño CSS/píxeles y densidad.
Verificar W02–W05/W07 con toque físico; si el teléfono bloquea automatización,
la persona realiza los pasos y se documentan estado previo/resultados. No
confundir la app Android nativa instalada con esta sesión de navegador.

## 5. Partida, otros navegadores y rendimiento

- Jugar manualmente una partida hasta terminal, con oleadas de producción;
  registrar resultado. Verificar victoria/derrota automatizadas por separado.
- Cambiar pestaña y regresar; recargar. Si hay audio, comprobar desbloqueo por
  interacción; si no existe audio, indicarlo sin añadirlo.
- Registrar Firefox, Safari macOS e iOS Web según disponibilidad real; ausencias
  quedan NOT RUN con causa, nunca PASS.
- Medir carga fría, tamaño, memoria disponible y cadencia/frame times con
  método/duración/condiciones; indicar si la evidencia alcanza el gate de
  rendimiento constitucional. No usar la muestra nativa 002 como medida Web.

## 6. Paquete final y automatización

Generar de nuevo desde copia limpia sin `.godot`/`build`; descomprimir el ZIP en
un directorio nuevo, inspeccionar PCK y servirlo. Confirmar `index.html` en raíz
sin carpeta intermedia y todos los archivos requeridos. Verificar exclusiones,
licencias, límites del portal, manifest y hashes. Revisar el workflow y anotar
si hubo run remoto real o solamente validación local de sus pasos.

## 7. Carga manual posterior en itch.io

La feature entrega el ZIP; estos pasos se ejecutan cuando la persona decida:

1. Crear/editar la página del juego, elegir **HTML Game** y cargar el ZIP.
2. Seleccionar que se ejecuta en navegador; comenzar con **Click to play** y
   presentación incrustada **1152×648**, con botón de pantalla completa.
3. Marcar **Mobile Friendly** solo después de validar el navegador móvil.
4. Previsualizar la página con clic/toque, dimensiones y red reales antes de
   decidir la visibilidad. No se realiza publicación automática desde CI.

Referencia: [Guía oficial HTML5 de itch.io](https://itch.io/docs/creators/html5).
Para crear una página pública, cuenta, donaciones y textos comerciales hace
falta una etapa posterior; esta guía no afirma que el juego ya esté subido.

## Aceptación

El tester adjunta logs/resultados y QA revisa spec, diff y evidencia. Solo el
orquestador marca tareas aprobadas. Una entrega WIP conserva pendientes
explícitos; el resumen de 003 no modifica los estados históricos de 002.
