# Quickstart de validación: Cinco carriles horizontales

Guía de ejecución futura por tester/QA; preparación no ejecuta pasos ni
acredita resultados. [Plan](plan.md) · [Contrato](contracts/horizontal-combat.md).

## Preparación y TDD

Confirmar rama/commit, tareas y gate del incremento; preservar I2/004 y
cambios ajenos. Usar Godot 4.7.1/GUT 9.7.1 existentes sin actualizar. Tester
RED semántico antes del cambio; errores de importación/método inexistente no
son RED: asignar setup mínimo sin conducta. Dev no escribe/modifica/ejecuta
pruebas; tester GREEN/regresión, QA independiente y documentación después.

Suite completa al cierre o cuando alcance lo justifique, desde raíz y con
ruta real al binario instalado; opciones contrastadas con runner existente:

```sh
python3 tools/ci/run_gut.py --godot "/ruta/al/binario-Godot"
```

Runner importa y exige suite completa no vacía/pasada. GUT permite seleccionar
scripts pertinentes para RED/GREEN; un subconjunto no certifica toda regresión.
Tests nuevos conservan estructura por dominio en `tests/unit/`.

## Gate de cada incremento

Aplicar la fila correspondiente de [incrementos del plan](plan.md#incrementos-previstos)
antes de QA y entrega de cada PR funcional: los recorridos de entrada real,
visual, resize, partida y rendimiento afectados se hacen en Web de computador,
APK Android Emulator y .app iOS Simulator por separado. I1–I4 no difieren estos
gates a I5. Este último consolida lo válido y repite solo pendientes o evidencia
invalidada por integración; no sustituye verificaciones de los PR anteriores.

Para cada incremento comparar base y candidato identificados con carga y
recorrido equivalentes, midiendo carga y frame times/FPS en cada entorno
aplicable. Declarar diferencias de gestos/carga y límites que impiden atribuir
causalidad. El riesgo de FPS por población, consultas/cuerpos móviles o recursos
visuales exige además medición física según constitución IV antes de
aceptación/merge. Sin hardware puede avanzarse en preparación, RED y desarrollo
funcional, pero el incremento conserva WIP y requisitos pendientes: un PR en
borrador no significa implementación APROBADA ni entregada. No solicitar
reconexión, cambiar referencias o eximir la medición. El paquete documental de
preparación sí puede entregarse tras QA documental.

## Matriz automatizada mínima

| Grupo | Casos y resultado esperado |
|---|---|
| Plazas/economía | Cinco inicios cargados/reserva 0; whitelist primera/central/quinta; exterior/bordes/ocupadas rechazan antes de gasto; salida reserva origen, muerte libera, reemplazo único. |
| Spawns/pool | Inicial t0/fila 3 y 99 WAVE 1→5 continuo; cantidades/tiempos intactos. Inicial no adelanta cursor/contador. Misma instancia INITIAL → WAVE → INITIAL en fila distinta limpia origen/carril/blancos/generación y mantiene registro visual único. |
| Fusil | HOME inmóvil con consumo/daño/moral vigentes; frente/diagonal contigua válida; detrás/diagonal profunda/dos filas/exterior inválidos; límites longitudinales y prioridad −X. |
| Machete | Última bala mata único→espera; si queda frontal→sale. 40 unidades/s propios con dos EnemyStats de velocidades distintas; acercamiento/contacto/daño mutuo real y reanudación; otra fila no bloquea; reciclado no recibe golpe obsoleto. |
| Recarga | Solo vivo/carga 0/fondos/PLAYING; un cobro, carga completa, vida/moral iguales; 40 unidades/s retorno sin ofensiva/vulnerable. Repetidas/parcial/llena/muerto rechazadas; orden antigua tras muerte/reemplazo no cobra al nuevo. |
| Input | Pickup sobre plaza libre/ocupada/actor solo recoge; solapadas conservan regla. Gesto sobre plaza libre despliega una vez; reservada selecciona sin costo; botón no atraviesa tablero. |
| Terminal/visual | Cruce físico por cada fila→LOST único; oleadas cortas con managers/spawner reales→WON único por bajas WAVE; tardíos no alteran terminal. Presentación/snapshot/reset independientes y sin callbacks heredados. |

Movimiento/contacto requieren ticks físicos/cuerpos reales y tolerancias,
no solo invocar callbacks privados. Negocio aislable admite headless; picking,
stretch y entrada de SO se verifican fuera de él. Cobertura existente ya GREEN
no requiere fabricar RED. Fixtures aislados pueden acelerar integración,
sin cambiar datos de producción ni presentarlos como partida normal.

## Recorrido manual y visual

Por fila: fusil a derecha dentro→última bala→salida→contacto frontal→espera
sin enemigos delante→seleccionar su trinchera→recargar→regreso vulnerable→
fusil al llegar. Revisar carga/moral/vida/saldo, selección con dueño fuera,
muerte/reemplazo y rechazos. Comparar movimientos contra distinta velocidad
enemiga sin cambiar la propia. Recorrer producción de inicio a terminal sin
errores críticos; victoria determinista por separado, sin rebalance para ganar.

Recolección con fondos sobre plaza libre/ocupada, bajo actor y cajas solapadas:
solo recogida según contrato. Ratón y toque de SO en sus destinos; un gesto,
una operación económica compatible. Repetir después de resize real.

Revisar arte en filas 1/3/5, poses laterales legibles y retorno distinguible
sin solo color; caída no bloquea plaza y trinchera no da cobertura. Vistas
lógicas 1152×648,960×540,1440×648 y 1152×864; resize ida/vuelta donde exista y
configuración disponible en apps. Las cinco plazas/extremos siguen visibles,
gestos coinciden con lo visto y controles no ocultan plazas ni bloquean canvas.

## Destinos y mediciones

| Destino | Validación y límites |
|---|---|
| PC nativo de desarrollo | Import/smoke/integración local; no acredita navegador ni app móvil. |
| Web de computador | Exportar/servir con [WEB_EXPORT](../../docs/WEB_EXPORT.md); identificar navegador/computador/renderer/build, entrada/resize/partida y carga/rendimiento. Matriz inicial Chrome/macOS disponible; otros navegadores sin certificación inferida. |
| Android Emulator | APK instalado, no Chrome. Identificar AVD/API/renderer/build; gesto y ciclo completo. Mobile requiere ejecución propia; Compatibility temporal se informa separado. No solicitar reconexión física. |
| iOS Simulator | `.app` nativa, nunca Safari; modelo/OS/renderer/build y gesto/estados/ciclo. No acredita IPA físico o renderer Mobile en hardware. |
| Referencia física constitucional | SC-007: 60 FPS pendiente sin hardware; no heredar Xiaomi/resultados 004 ni sustituir con emulación. No impide preparación o desarrollo funcional. |

Antes de compartir builds con testers externos: smoke apertura→nivel→partida
hasta terminal sin errores críticos y política de versiones nativas de
[arquitectura §7](../../docs/ARCHITECTURE.md#7-consideraciones-multiplataforma).
No cambiar presets/renderers para aparentar aceptación. No usar scripts
personales/temporales de I2 como dependencia de 005 ni abrir navegador móvil.

Logs/muestras en temporales o CI; entregar a QA commit/entorno/comandos,
FPS/frame times/carga y límites, y resumirlo en PR sin evidencias nuevas Git.
Separar carga fría/caliente e inicio medido de carga completa; recorridos con
gestos distintos no son benchmark causal. Umbral global de carga pendiente:
no inventarlo ni declararlo aprobado. SC-007 y criterios obligatorios pendientes
impiden aprobar/entregar el incremento afectado y marcar feature completa o
cerrar Issue; todo borrador WIP declara alcance y límites. Emulación permite
avanzar funcionalmente, sin excepción implícita.
