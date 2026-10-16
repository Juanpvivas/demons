# Exportación Web para itch.io

**Estado al 2026-10-15: paquete WIP generado y arranque local aprobado.** La
interacción Web de escritorio/Android, el smoke manual hasta terminal y las
mediciones de rendimiento siguen pendientes. Este documento es un borrador
parcial de T011, pendiente de completar tras T008 y de revisión documental QA;
no declara la demo lista para testers externos ni publicada en itch.io.

## Requisitos

- Godot **estándar oficial 4.7.1 stable**, con sus templates de exportación de
  igual versión. El script rechaza Mono/.NET y otras versiones. Se puede
  conservar Mono para el trabajo nativo existente.
- Python 3.8 o posterior, Git y Bash. No hace falta instalar Butler ni tener
  credenciales del portal para generar el paquete.
- Un checkout que incluya la feature 003 y sus archivos de `tools/web/licenses/`.
  No ejecutar dos exports/importaciones sobre el mismo checkout al mismo tiempo.

El preset Web usa Compatibility/WebGL2, un hilo, sin extensiones ni PWA. La
configuración Mobile y los presets/deploys Android/iOS se conservan.
[Herramientas verificadas](../specs/003-web-itchio/evidence/toolchain.md).

## Generar el ZIP

Desde la raíz del repositorio, indicar la ruta del ejecutable estándar local:

```bash
GODOT_WEB_BIN="/ruta/al/ejecutable/Godot" tools/web/export.sh
```

Si `godot` ya resuelve a la edición correcta en PATH, basta con
`tools/web/export.sh`. El script importa y exporta release, prepara
`build/.gdignore` antes de importar, limpia **solo las salidas Web conocidas**
y rechaza enlaces simbólicos inseguros. No borra los builds Android/iOS.

| Salida | Uso |
|---|---|
| `build/demons-web.zip` | Archivo que se seleccionará al cargar el juego web |
| `build/web/` | Juego sin comprimir, con `index.html` en raíz y `licenses/` |
| `build/web-manifest.json` | Revisión, estado WIP, versión del motor, tamaños y hashes |
| `build/web-import.log`, `build/web-export.log` | Diagnóstico de importación y exportación |

`build/` está ignorado por Git. El manifest y los logs quedan fuera del ZIP.
No renombrar `index.html` o sus archivos compañeros después de exportar. Si el
script devuelve un error, revisar los logs antes de considerar utilizable la
salida. Los patrones de exclusión registrados en el manifest son una política;
la ausencia real de recursos internos se verifica también dentro del PCK.

## Abrirlo localmente

```bash
python3 -m http.server 8060 --directory build/web --bind 127.0.0.1
```

Abrir `http://127.0.0.1:8060/`; no abrir `index.html` como archivo ni servir la
raíz del repositorio. Este servidor es para desarrollo local. Para probar el
ZIP, extraerlo en una carpeta nueva y servir esa carpeta con el mismo método.
Las instrucciones de toque físico, iframe y casos controlados están en
[quickstart](../specs/003-web-itchio/quickstart.md).

## Qué está comprobado

QA aprobó de forma acotada el preset/arranque T004–T006 y la generación local y
paquete T009/T010. Se preserva el primer fallo de exportación: la selección de
escenas omitió clases/oleadas cargadas desde scripts; se corrigió a recursos de
producción con exclusiones explícitas. El PCK corregido contiene **78 rutas**,
incluidas las diez oleadas y las clases necesarias, sin pruebas, GUT,
documentación interna ni configuración de agentes.

T010 ejecutó dos generaciones reales en la revisión `ed446d9`, una desde una
copia Git limpia sin caché ni `build`. Ambos ZIP extraídos iniciaron el nivel,
arte y combate en Chrome. El candidato del checkout mide **14 891 347 bytes**
(aproximadamente 14.89 MB) y su SHA256 es
`e12501af7950c494a47f07ddffdc56ec2ab3e378fe88b6748a7200840831daa1`.
Sus 12 miembros incluyen 9 archivos del exportador y 3 avisos. Los ZIP de ambas
generaciones difieren en un byte de tamaño y en el PCK; los otros 11 miembros
coinciden. Se acredita reproducción funcional, no identidad binaria.
[Informe y manifests](../specs/003-web-itchio/evidence/web-package.md).

| Entorno/caso | Estado y alcance actual |
|---|---|
| Chrome 155.0.8059.84 en computador | PASS de arranque: tres sesiones nuevas, combate y pickups; sin prueba de caché fría. |
| Canvas 1152×648 y 960×540 | PASS de render; interacción posterior a resize aún pendiente. |
| Clic/recolección/despliegue/rechazos en Web | Pendiente T007/T008; el arranque no los acredita. |
| Chrome en Xiaomi físico | Web aún pendiente; las pruebas de la app Android nativa de 002 no lo sustituyen. |
| Firefox y Safari macOS | NOT RUN en esta entrega; sin soporte anunciado por extrapolación. |
| Navegador iOS | NOT RUN; sin soporte anunciado por extrapolación. |
| Partida manual Web hasta terminal y rendimiento | Pendientes; no se declaran 60 FPS estables. |
| Workflow Web en GitHub Actions | NOT RUN remoto; sus pasos de generación se verificaron localmente. |

Fuentes: [arranque T005](../specs/003-web-itchio/evidence/web-startup.md) y
[paquete T010](../specs/003-web-itchio/evidence/web-package.md). Las pruebas
GUT 183/183 del baseline son regresión nativa, no evidencia de picking Web.
La feature 002 continúa abierta con sus propios pendientes.

## Artefacto de CI

`.github/workflows/export-web.yml` está configurado para Pull Requests y
activación manual. Instala Godot estándar 4.7.1 con templates y ejecuta el
mismo script; adjunta `demons-web-<SHA>` con ZIP/manifest y un artefacto separado
de logs. El CI existente mantiene GUT/importación y los deploys móviles.
Todavía no hay un run remoto acreditado de este workflow Web. No publica en
itch.io ni requiere secretos de esa cuenta.

## Preparar una carga manual posterior en itch.io

Cuando el smoke y la validación de entrada estén aprobados:

1. En la página del juego elegir **HTML Game** y cargar `demons-web.zip`.
2. Marcar que se ejecuta en navegador; comenzar con **Click to play**, iframe
   **1152×648** y botón de pantalla completa.
3. Activar **Mobile Friendly** únicamente tras comprobar la versión Web móvil.
4. Previsualizar la página y comprobar clic, toque y carga antes de decidir su
   visibilidad. Cuenta, textos comerciales y donaciones se gestionan aparte.

[Guía oficial de itch.io](https://itch.io/docs/creators/html5). Esta feature
no inicia sesión, sube archivos ni publica la página.

## Avisos del motor y del arte

El ZIP incluye `licenses/GODOT_LICENSE.txt`, `licenses/GODOT_COPYRIGHT.txt` y
`licenses/NOTICE.txt`. Los dos primeros conservan textos oficiales del tag
Godot 4.7.1-stable; NOTICE identifica el origen del arte de Monte Calvo, generado
con la herramienta de imágenes de Codex. Se mantiene esa declaración al
presentar la demo; si el portal solicita información sobre contenido generado
con IA, la respuesta debe reflejar esa procedencia.

Estos avisos no asignan una licencia nueva al código, al arte ni a la propiedad
intelectual del juego. No se incluyen prompts ni documentación interna en el
paquete. [Fuente oficial de atribuciones de Godot](https://docs.godotengine.org/en/4.7/about/complying_with_licenses.html).
