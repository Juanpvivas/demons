# Quickstart — PREPARACIÓN de la validación de 004

Guía futura para los roles del proyecto; **no acredita ejecución ni aceptación**.
Aplicar [spec](spec.md), [plan](plan.md), [modelo](data-model.md),
[contrato](contracts/visual-presentation.md) y el flujo compartido.

## 1. Antes de implementar

- El orquestador confirma los gates documentales, Issue reutilizable, incremento
  y rama real. Conserva cambios locales y registra la revisión de la línea base.
- Los roles consultan las skills de GodotPrompter aplicables. El tester identifica
  ejecutables, versiones, navegadores y dispositivos realmente accesibles.
- Acordar el Android físico que cumpla la referencia constitucional nominal.
  El Xiaomi provisional de 002 no queda autorizado para aceptar rendimiento de 004.
- Conservar capturas comparables antes/después con igual encuadre, tamaño y
  estado. Las salidas de verificación van a temporales o CI, nunca a Git.
- Registrar la línea base de reglas protegidas, importación y GUT, además de
  carga/rendimiento con el mismo protocolo que se usará al comparar el cambio.

El runner existente importa y exige una suite GUT no vacía y exitosa:

```bash
python3 tools/ci/run_gut.py --godot "/ruta/al/binario-Godot"
```

La ruta es del operador; no se versionan rutas personales. Esta guía no ejecuta
el comando. No basta un proceso exitoso si no hubo pruebas realmente corridas.

## 2. Arte y contratos antes de RED

Revisar diseños de soldado, enemigo y caja contra el concepto y los cinco
aspectos de SC-001. Comprobar transparencia, recortes, apoyo en el suelo,
huellas, fotogramas y procedencia/permisos antes de integrar cada recurso.
El arte y sus ajustes de importación usan inspección/carga/revisión visual;
no se inventan fallos RED para aprobarlos.

Para sincronización, prioridades y reciclado nuevos, el tester escribe y ejecuta
RED antes de la implementación. Si faltan interfaces para cargar el caso, el
orquestador asigna primero un esqueleto mínimo explícito sin comportamiento.
Un error de parser/importación, método ausente o harness roto no acredita RED.
QA distingue un fallo esperado válido de esos problemas de infraestructura.

## 3. Casos de comportamiento y GREEN

| Caso | Comprobación requerida |
|---|---|
| Soldado | Espera/disparo fusil; espera/golpe machete; último disparo y cambio inmediato; recarga por ruta existente; daño y derrota |
| Prioridad | Muerte prevalece; cambio de modo interrumpe fuego; callbacks viejos no restauran poses incompatibles |
| Enemigo | Avance por desplazamiento real; contacto al quedar bloqueado; feedback no letal; derrota sin retrasar pool/drop |
| Reutilización | Diez ciclos tras daño/muerte; frame, flip, offset, escala, tinte, tween/colas y generación limpios |
| Independencia | Dos actores/efectos en estados distintos no comparten progreso ni callbacks |
| Efecto de derrota | Snapshot fijo; 0,40 s; sin física/input; actor/celda se liberan inmediatamente; efecto vuelve a su pool |
| Munición | Caja disponible/recogida conserva posición, radio 20 y valor; la imagen no redefine picking |

El tester confirma GREEN de los casos RED y la regresión pertinente de salud,
munición, moral, economía, objetivos, oleadas y resultados. Al cerrar la feature
ejecuta la suite completa. QA revisa independientemente contrato, pruebas y
resultados antes de que el orquestador marque tareas.

## 4. Verificación visual y gestos reales

Comparar el mismo estado contra la línea base y el concepto: sin bloques
provisionales, armas legibles, bandos distintos, escala/apoyo coherentes y caja
separable del terreno. Revisar pausa de imagen y reproducción de clips; no
confundir un destello aislado con feedback de derrota completo.

Realizar por entorno los cuatro resultados de economía: recoger una vez sin
desplegar sobre celda libre con fondos; desplegar en libre y cobrar el costo
real; rechazar ocupada; rechazar fondos insuficientes. Clic/toque deben llegar
por la entrada real del entorno, no por llamadas directas a métodos del juego.
El saldo y la ocupación se corroboran con observación temporal de solo lectura.
Probar dos cajas solapadas sin cambiar su semántica ni sus formas físicas.

| Entorno mínimo planificado | Tamaño/entrada y alcance |
|---|---|
| Web, Chrome escritorio | Canvas 1152×648 y 960×540; clic; resize entre ambos |
| Web, Chrome Android físico | Horizontal; registrar viewport, densidad y versión; toque físico |
| App Android nativa | Identificar build, renderer, teléfono y orientación; toque físico |
| App iOS nativa | Identificar build, renderer y dispositivo o simulador; entrada realmente usada |

La ejecución nativa PC complementa desarrollo. No acredita Web. Un simulador
iOS solo acredita su propia comprobación; no hardware iOS ni rendimiento físico.
Cada entorno ausente queda pendiente, sin pasar por extrapolación. Registrar
recortes existentes separadamente de errores nuevos; no cambiar cámara/input
para ocultarlos. Otras versiones/navegadores no heredan estos resultados.

## 5. Partida y rendimiento antes/después

Jugar una partida manual con oleadas de producción hasta terminal. Como no hay
pantalla de resultado, identificar victoria/derrota con un observador temporal
de solo lectura del estado real; corroborar la ruta en producción. No anunciar
un resultado oculto solo por apariencia o por una partida de recursos reducidos.
Verificar además victoria y derrota por separado mediante las rutas existentes.

Antes de medir fijar estado/revisión, dispositivo, batería/temperatura, renderer,
resolución, herramientas, acciones/oleadas y duración. Usar iguales condiciones
antes/después: tres cargas frías y tres calientes por separado, y tres sesiones
tras 30 s de calentamiento,
con objetivo de 120 s de gameplay típico por sesión. Si la partida termina
antes, registrar la duración real y ampliar la muestra; una muestra corta no
se presenta como estabilidad sostenida. Incluir la mayor carga de combate
alcanzable sin modificar los datos de producción.

Registrar tiempo de carga, FPS por ventanas de 1 s, tiempos de fotograma
p50/p95/p99 y picos, y memoria inicial/pico/final con el alcance real del
instrumento. Señalar perturbación del observador y carencias de medición.
No inventar un límite de carga aún pendiente en la constitución. Los 60 FPS
estables en el Android nominal se evalúan de forma independiente por QA;
una media favorable no oculta caídas ni sustituye esa aceptación. Web y nativo
tienen mediciones distintas incluso sobre el mismo teléfono.

## 6. Entrega de cada incremento

El tester entrega comandos/pasos, resultados y límites al orquestador. QA
revisa el estado final y documentación útil después de sus correcciones.
El PR en borrador resume comprobaciones y veredicto, enlazando CI cuando exista;
no añade capturas, logs, JSON o informes nuevos de evidencias a Git.
Pendientes de hardware, visuales, GREEN o QA siguen pendientes, sin cerrar la
feature ni extrapolar las aprobaciones históricas de 002/003.
