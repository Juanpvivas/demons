# Contrato017 — selector, aprendizaje e integración

API del núcleo I1 implementado y aprobado funcionalmente. Las secciones de
cableado de nodos, feedback y menú describen I2, todavía pendiente.
[Spec](../spec.md) · [Modelo](../data-model.md) · [Guía](../quickstart.md).

## 1. API local del núcleo I1

| Componente | Operación y resultado |
|---|---|
| CommanderSession (RefCounted) | `begin_match(match_id, seed, config, memory)` inicializa sesión y copia neutral/compatible |
| Session | `choose_lane(snapshot) -> decision` propone lane0–4 sólo entre pendientes |
| Session | `register_spawn(decision, actor_id, generation, spawn_x, defended_right) -> bool` confirma aparición WAVE y consume carril/ordinal una vez |
| Session | `cancel_proposal(token) -> bool` revoca propuesta pendiente y restaura RNG sin consumir bloque/ordinal |
| Session | `record_defeat(actor_id, generation, death_x)` cierra una muerte válida |
| Session | `record_breach(actor_id, generation)` cierra un cruce WAVE real |
| Session | `finish(result) -> commit_candidate` sólo WON/LOST, una vez; incluye changed y memoria candidata |
| Session | `abandon()` idempotente, descarta buffer y cierra selección |
| Session | `get_decision_snapshot()` copia de diagnóstico de sólo lectura para pruebas |
| CommanderMemoryStore (RefCounted) | `load_compatible(config) -> load_result` sin datos de otros juegos |
| Store | `save(candidate, expected_generation) -> save_result` valida y verifica antes de publicar |
| Store | `clear() -> clear_result` borra todas sus copias antes de comunicar éxito |

Los payloads públicos son `Dictionary`; `register_spawn` y `cancel_proposal`
devuelven `bool`, y los métodos de inicio/registro/abandono no devuelven valor.
`decision` contiene `ordinal`, `lane`, `context` (clave canónica) y `token` opaco.
No contiene stats, tiempo ni orden de spawn. Propuestas se consumen una vez,
sin reentrada. `finish` recibe los valores enteros públicos WON/LOST de
GameStateManager y devuelve `{changed, memory, match_id}`. No modifica el Manager.

El snapshot de entrada lleva `wave_number`, `role`, `defenders` y `lane_loads`.
Los dos arrays tienen cinco posiciones: cada defensor declara `lane_id`,
`alive`, `movement_state`, `ammo` y `mode`, procedentes del estado público del
actor. La sesión extrae sólo los campos permitidos. Diagnóstico devuelve copias
de pendientes, ordinal (`wave_index`), propuesta, estado, RNG y probabilidades;
no expone la memoria mutable interna.

`load_compatible(config)` con configuración válida prepara el almacén antes
de save o clear; sin esa carga previa ambas operaciones devuelven INVALID.
El almacén devuelve siempre `{status, memory}` y para save/clear añade
`applied`/`saved`. `storage_base_path` es un directorio inyectable, vacío para
`user://`; `transient` evita I/O de memoria. `compatibility_sources` acepta el
bundle confiable completo descrito en el modelo. Un `io_backend` opcional
implementa `exists(path)`/`size(path)` con `{error,value}`,
`read(path,max_bytes)` con `{error,text}`, y `write(path,text)`/`remove(path)`
con `{error}`. Write abarca apertura, escritura, flush y cierre; los dobles pueden
identificar la etapa del fallo. Los datos de usuario no eligen estos puertos.

## 2. Selección, límites y RNG

1. La sesión empieza con pendientes[0,1,2,3,4]. Tras cinco `register_spawn`
   vuelve a ese conjunto. Ningún callback de oleada reinicia el bloque.
2. Obtener en un único snapshot los cinco contextos; ordenar candidatos por lane.
   Sólo evaluar pendientes, aunque otro carril tenga mayor score.
3. Para cada candidato, recuperar q,n o prior0.5,0. Definir:

   `s = 0.5 + (q - 0.5) * min(n / confidence_visits, 1)`

   `w = 1 + weight_gain * (2*s - 1)`

   `p = exploration_share/m + (1-exploration_share)*w/sum(w)`

   con m=carriles pendientes, gain0.25, exploration0.25. Pesos∈[0.75,1.25],
   suma de p=1; todas las opciones tienen probabilidad positiva y la razón
   entre probabilidades máximas/mínimas no supera5/3. m=1 obliga al único carril.
   Este límite de preferencia no demuestra igual dificultad entre partidas.
4. Usar una extracción uniforme del RNG privado y acumulación en orden de lane.
   Consumir exactamente una extracción por aparición WAVE confirmada, también
   si m=1. La propuesta conserva el estado RNG previo: cancel_proposal del token
   pendiente lo restaura, elimina esa propuesta y devuelve true. Token cancelado,
   consumido o ajeno devuelve false y no modifica estado. Un choose adicional
   con propuesta pendiente devuelve la misma decisión, sin otra extracción.
   register_spawn válido confirma y descarta el estado previo; duplicado/ajeno
   devuelve false sin efectos. El adaptador cancela explícitamente si no activa.
   No consumir ordinal/carril por una activación fallida o cancelada. Una
   activación real sin registro válido es un defecto de integración, no una
   razón para omitirla silenciosamente o aprender de ella con identidad inventada.
5. `choose_lane` no produce señales, I/O, creación de actores o cambios a timers.
   Sólo una propuesta pendiente; el token impide confirmación duplicada.
6. Seed explícita inyectable para pruebas; producción usa semilla independiente
   del RNG global/cosmético. Reproducibilidad exige mismo motor, config, memoria
   y secuencia de snapshots, sin prometer determinismo completo de física/input.
7. Nunca usar la memoria como una lista de carriles prohibidos. Un dato inválido
   de memoria se neutraliza al cargar. Configuración inválida es fallo de fuente
   o build que bloquea integración; no se oculta como una partida aprobada.

El adaptador de spawner sin comandante conserva su camino legado para pruebas
y usos sin tablero. El nivel de producción siempre instala el comandante;
la ausencia accidental de inyección en ese camino debe detectarse en integración.

## 3. Resultado observable y aprendizaje

En una muerte WAVE confirmada:

`r = clamp((spawn_x - death_x)/(spawn_x - defended_right), 0, 1)`.

La geometría procede del tablero, nunca un número912 hardcodeado. Exigir
spawn_x>defended_right. Para la configuración actual son1008 y96. Es avance
observado en el cierre del actor, no máximo por frame ni evaluación de daño.
Un cruce WAVE confirmado por el nivel asigna r=1 aunque su centro aún no haya
llegado a X96. Un INITIAL no genera muestra. Una baja válida no se filtra por
`is_targetable()` después de `_die()`.

Al terminal, marcar OPEN como CENSORED y excluirlo. No inventar el resultado
de los supervivientes, drops de cleanup o enemigos no emitidos. Por cada clave
con resultados cerrados, calcular r_media de la partida. Si no hay ninguna,
changed=false y conservar exactamente la memoria anterior, sin olvido o save.

Con muestras y sólo una vez por terminal:

- En todas las celdas existentes: `qd=0.5+retention*(q-0.5)`, `nd=retention*n`.
- Por celda observada: `q_new=qd+learning_rate*(r_media-qd)` y
  `n_new=min(max_effective_visits,nd+1)`; ausente parte del prior.
- No observadas: mantener qd,nd. No añadir celdas fuera de las360 posibles.
- learning_rate0.15, retention0.98, confidence_visits3 y max_visits20.
- No utilizar victoria/derrota como recompensa global; ambos habilitan cierre.
  Un terminal de INITIAL sólo aprende si antes hubo WAVE cerrados válidos.

La memoria congelada decide toda esa partida. El ajuste queda disponible para
la siguiente sólo tras save OK. A diferencia de un contador acumulativo de
victorias, n y pesos están acotados. Es aprendizaje correlacional con censura;
no hay garantía de estrategia óptima ni de que avance mida diversión.

## 4. Orden de integración y vida de las señales — I2 pendiente

- `GameRoot._ready()`: preparar Store independiente de IntroProgress y conectar
  intención del menú. `_start_match()` inyecta almacén/seed antes de add_child.
- Nivel `_ready()`: si es una escena directa de desarrollo sin raíz, usar
  almacén TRANSIENT sin rutas reales; esa ejecución no acredita persistencia.
  Configurar Session tras crear defensores y antes del primer WAVE. Conectar
  game_won/game_lost una vez por nivel y desconectar al cerrar.
- `_on_spawn_timer_timeout()`: conservar guard, pop de cola, stats, posiciónX,
  prepare_for_spawn y rearme actuales. Sustituir sólo la selección de lane;
  registrar token+actor/generación después de la activación exitosa. El contexto
  y elección se calculan antes de añadir ese nuevo enemigo a la carga observada.
- `_on_enemy_defeated()`: capturar origen/generación y la posición del argumento;
  comprobar muerte confirmada y registrar WAVE ANTES de notify_enemy_defeated.
  Después, notify y release conservan su orden y autoridad actuales. No añadir
  otra conexión que dependa del orden casual de listeners del pool.
- `_on_posicion_defendida_body_entered()`: registrar cruce WAVE válido ANTES de
  notify_reached_defended_position/report_reached_defended_position. INITIAL
  sigue causando LOST normalmente, sin resultado propio de aprendizaje.
- Handler terminal: cerrar con guard previo a cualquier escritura/callback,
  censurar abiertos y guardar candidato si changed. Guard de sesión y generación
  de nivel impide dobles commits o callbacks de un nivel retirado.
- `close_match()`/`_exit_tree()`: abandonar sólo si aún ACTIVE; nunca consolidar.
  Si ya FINALIZED, sólo limpiar. MENU no se interpreta como resultado terminal.
  La raíz actualmente entra MENU y cancela waves antes de close_match: no
  intentar reconstruir un WON/LOST desde ese cierre.

El registro OPEN guarda IDs/generaciones, no referencias persistentes al Node.
Las consultas de carga excluyen actores desactivados; los registros de muerte
conservan el contexto de la activación original aunque el cuerpo se recicle.
No se necesitan modificaciones de Enemigo, Soldado, GameStateManager o
WaveManager para añadir decisiones o aprendizaje; si aparece un defecto real,
tratarlo explícitamente y no ampliar alcance desde esta planificación.

## 5. Guardado, recuperación y borrado

1. Validar tamaño, sobre, hash y esquema de ambos slots. Elegir mayor generación
   válida; a igual generación con distinto contenido, CONFLICT y memoria neutral.
   Comprobar compatibilidad sobre la versión más reciente, sin resucitar un
   slot viejo por ser compatible. Desconocida/incompatible→neutral con motivo.
2. Save exige candidato válido, match_id no consolidado y generación esperada.
   Releer cabecera actual antes de escribir; cambio detectado→CONFLICT.
   Sobrescribir únicamente el slot inactivo con generation+1; comprobar errores
   observables de apertura/escritura/flush y volver a leer/validar el archivo
   entero. Godot no devuelve Error desde `flush()` o `close()`: el backend nativo
   comprueba `get_error()`, cierre efectivo y relectura, sin inventar un código
   de fclose o una garantía de fsync. Publicar en RAM sólo al verificarlo.
   Mantener intacto el slot anterior.
   En modo TRANSIENT no hay I/O: validar/publicar en RAM devuelve status=OK,
   applied=true,saved=false. El modo persistente verificado devuelve saved=true,
   que sólo describe la verificación local, no una promesa de durabilidad Web.
3. No prometer atomicidad frente a dos procesos: una raíz es el único escritor
   soportado. Un conflicto no altera gameplay ni se arregla mezclando recuerdos.
4. Clear sólo fuera de partida: borrar primero el slot inactivo y luego el
   activo; comprobar ambos resultados y su ausencia. No existe un tercer
   backup/temp recuperable. Sólo entonces vaciar RAM y comunicar éxito.
   Un fallo conserva RAM y comunica fallo; el disco puede haber quedado
   parcialmente modificado, por lo que save queda bloqueado con IO_ERROR hasta
   recargar; un nuevo clear también revalida ambos slots antes de actuar.
   Rama TRANSIENT: neutralizar exclusivamente RAM, applied=true,saved=false,
   sin inspeccionar rutas reales. No prometer eliminación de datos persistentes
   que el backend actual no puede acceder.
5. Sin reintentos automáticos ni guardados en segundo plano que puedan repoblar
   un borrado. En Web, verificar ciclo de recarga real en el mismo origen;
   OK local no certifica sincronización duradera de IndexedDB. Si el navegador
   informa almacenamiento no persistente, usar memoria TRANSIENT, avisar y
   permitir jugar. Un detector positivo sigue requiriendo prueba de recarga.

## 6. Contrato del menú — I2 pendiente

Añadir a la VBox existente un botón «Borrar memoria del comandante», altura
mínima64px, Theme y safe area vigentes. Emite `commander_reset_requested`;
no consulta disco o Managers. Raíz exige MENU, sin nivel, intro ni transición.
`set_start_enabled(false)` también bloquea el borrado y la confirmación.

Confirmación local: «¿Borrar lo aprendido por el comandante? La próxima partida
empezará sin memoria. Tu progreso no cambia». Acciones «Cancelar» / «Borrar».
Cancelar no escribe. Confirmar sólo se acepta una vez y devuelve foco al botón.
Éxito persistente: «Memoria del comandante borrada». En TRANSIENT: «Memoria de
esta sesión borrada»; si el almacenamiento está bloqueado, aclarar «No se han
podido borrar datos guardados anteriormente en este navegador». Fallo: «No se pudo borrar la memoria.
Puedes seguir jugando e intentarlo de nuevo». No usar sólo color para el estado.
Si no hay datos válidos, borrar copias inválidas o indicar neutral tras verificar;
no deshabilitar el botón por una suposición sobre ausencia de archivos.

El texto es diseño previsto revisable en preparación; no añade cuentas o ajustes
de dificultad. Integrar foco circular Jugar→Introducción→Borrar y cerrar modal
antes de otra navegación. Touch y teclado/ratón tienen la misma semántica.
Un fallo de guardado terminal se muestra en resultado o, si se sale enseguida,
como aviso de menú: «No se pudo guardar lo aprendido. Puedes seguir jugando».
Aviso TRANSIENT: «Lo aprendido se conservará sólo mientras esta sesión esté abierta».
