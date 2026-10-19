# Quickstart — validación de 004

Procedimiento para los roles del proyecto; **no sustituye la ejecución ni QA**.
Aplicar [spec](spec.md), [plan](plan.md), [modelo](data-model.md),
[contrato](contracts/visual-presentation.md) y el flujo compartido.

La corrección de legibilidad y encuadre (§7), delimitada en T031, está aprobada
funcionalmente en T036 por sus propias verificaciones. I1 sobre `87a39c6`
conserva su alcance histórico; I2/I3 siguen pendientes. Las [tareas](tasks.md)
y el PR delimitan la consolidación y entrega.

## 1. Antes de implementar

- El orquestador confirma los gates documentales, Issue reutilizable, incremento
  y rama real. Conserva cambios locales y registra la revisión de la línea base.
- Los roles consultan las skills de GodotPrompter aplicables. El tester identifica
  ejecutables, versiones, navegadores y dispositivos realmente accesibles.
- La referencia física de 004 sigue siendo el Xiaomi 11T Pro `2107113SG` de
  2021, autorizado el 2026-10-16 (constitución 2.2.0). Desde el 2026-10-19 la
  persona indica que ya no será posible realizar nuevas pruebas físicas y
  autoriza continuar con Android Emulator. Aplicar la disponibilidad y los
  límites de §4; no volver a condicionar la ejecución emulada a conectar ese
  teléfono.
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
| Web, Chrome Android físico | Sin disponibilidad para nuevas pruebas desde el 2026-10-19; el resultado físico pendiente no se acredita desde el emulador |
| App Android en teléfono físico | Sin disponibilidad para nuevas pruebas desde el 2026-10-19; conservar el alcance aprobado de los resultados físicos históricos |
| Web, Chrome en Android Emulator | Entorno adicional autorizado; identificar AVD, API/imagen Android, ABI, versión de Chrome, viewport/densidad, renderer y gesto de SO usado |
| App Android en Android Emulator | Entorno adicional autorizado; identificar AVD, API/imagen Android, ABI, build del juego, renderer, tamaño/orientación y gesto de SO usado |
| App iOS nativa | Identificar build, renderer y dispositivo o simulador; entrada realmente usada |

**Disponibilidad de Android desde el 2026-10-19.** Por decisión de la persona,
las nuevas verificaciones Android continúan en emulador y no se solicitará
reconectar hardware físico. Cada resultado identifica explícitamente si
corresponde a la app nativa o a Chrome en Android Emulator. Los gestos atraviesan
la entrada del sistema emulado; no se sustituyen por llamadas a métodos del
juego. El tester verifica acceso real antes de declarar disponible un AVD o
navegador.

QA puede aprobar con ese alcance los casos de carga, presentación, entrada,
economía, reutilización y smoke realmente completados. Las mediciones de carga,
frame times, FPS y memoria en emulador describen únicamente ese entorno y su
máquina anfitriona; no acreditan 60 FPS en el Xiaomi ni en otro teléfono. Los
resultados físicos históricos se conservan sin ampliar su alcance. La falta
definitiva de nuevas pruebas físicas mantiene pendiente SC-007 y la aceptación
física exigida por la constitución 2.2.0; esta actualización de disponibilidad
no los exime ni autoriza el cierre global de I2/004.

La ejecución nativa PC complementa desarrollo. No acredita Web. Un simulador
iOS solo acredita su propia comprobación; no hardware iOS ni rendimiento físico.
Cada entorno ausente queda pendiente, sin pasar por extrapolación. Registrar
recortes existentes separadamente de errores nuevos. Solo T031 permite el
ajuste de cámara/cobertura delimitado en §7; input y reglas permanecen protegidos.
Otras versiones/navegadores no heredan estos resultados.

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
estables en el Xiaomi provisional autorizado para 004 se evalúan de forma
independiente por QA con nuevas mediciones; la autorización no acredita resultados.
Una media favorable no oculta caídas ni sustituye esa aceptación. Web y nativo
tienen mediciones distintas incluso sobre el mismo teléfono.

## 6. Entrega de cada incremento

El tester entrega comandos/pasos, resultados y límites al orquestador. QA
revisa el estado final y documentación útil después de sus correcciones.
El PR en borrador resume comprobaciones y veredicto, enlazando CI cuando exista;
no añade capturas, logs, JSON o informes nuevos de evidencias a Git.
Pendientes de hardware, visuales, GREEN o QA siguen pendientes, sin cerrar la
feature ni extrapolar las aprobaciones históricas de 002/003.

## 7. Corrección I1 — procedimiento de validación

1. QA T032 revisa la enmienda antes del RED T033. El tester comprueba resize:
   cámara sin zoom, mundo x=576 al 50 % del ancho lógico (error ≤1 unidad),
   origen vertical efectivo del canvas y=0. No confundir position.y=0 con ese
   origen ni usar limit_left=0 para impedir mostrar mundo negativo.
2. Comparar iPad 1152×864 (distribución conservada), Xiaomi 1440×648 y Web
   aproximadamente 1684×648 (márgenes equilibrados), identificando dimensiones
   lógicas y CSS reales. Cielo/panorama/suelo deben cubrir el nuevo margen
   izquierdo reusando texturas; no mover trincheras, actores, grid o detectores.
3. Revisar el soldado neutro: altura opaca objetivo aproximada de 72 unidades,
   pie raíz+y24 y pivote entre poses ≤1 unidad. En CSS 794×305 medir ≥32 CSS px
   de figura opaca, excluyendo lienzo transparente, contorno y pulsos. Comprobar
   reconocimiento sobre suelo sin overlay y también en una vista temporal en
   grises. Luz/contorno mate discreto, sin anillos/HUD; reutilizar el atlas.
4. RED debe cubrir material de estilo compartido inmutable en snapshot neutro,
   reset y diez activaciones, incluyendo un snapshot con material null después
   de otro con material. La caída conserva el estilo; no captura tintes/pulsos
   de daño o moral ni comparte estado mutable entre instancias. No fabricar RED
   para píxeles o recortes de archivos; la lectura artística es revisión visual.
5. Tras desarrollo T034, T035 confirma GREEN y regresión, los cuatro gestos de
   economía por entrada real tras el cambio de proyección, estados/derrota del
   soldado, cobertura y legibilidad; compara rendimiento por entorno (§5).
   Las verificaciones pertinentes incluyen Android físico y Web separados;
   iOS identifica simulador/software sin extrapolar hardware ni Mobile.
6. QA funcional T036, consolidación T037 y QA final T038 preceden a la entrega
   corregida. La corrección tiene aprobación funcional T036; el estado de
   consolidación y entrega figura en las tareas y el PR. Conservar T001–T013
   como historia sobre `87a39c6`; resultados nuevos al PR, temporales o CI,
   sin archivos de evidencias nuevos en Git ni inicio de I2/I3.
