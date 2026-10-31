# Modelo de datos017

Diseño previsto; los archivos y tipos nuevos mencionados aquí aún no existen.
[Especificación](spec.md) · [Contrato](contracts/commander.md).

## CommanderConfig — Resource compartido de sólo lectura

Ruta prevista: `resources/schemas/commander_config.gd` e instancia
`resources/director/monte_calvo_commander.tres`. Sin estado aprendido.

| Campo | Valor inicial | Validación |
|---|---:|---|
| schema_version / policy_version | 1 / 1 | enteros positivos; no confundir con versión beta |
| phase_end_waves | [3,7,10] | exactamente3 enteros positivos estrictamente crecientes; último10 |
| prior_score | 0.5 | exactamente el prior de policy1 |
| learning_rate | 0.15 | finito, mayor que0 y como máximo0.15 |
| retention_per_match | 0.98 | finito en [0,1) |
| exploration_share | 0.25 | finito en [0.25,1) |
| weight_gain | 0.25 | finito, mayor que0 y como máximo0.25 |
| confidence_visits | 3.0 | finito, mayor que0 y como máximo max_effective_visits |
| max_effective_visits | 20.0 | finito, al menos confidence_visits y como máximo20 |

Los rangos limitan el diseño inicial; no acreditan equilibrio. Parámetros,
categorías y orden canónico entran en `compatibility_id`. Cambiarlos invalida
la memoria previa; no permitir que el guardado sobrescriba esta configuración.
Usar campos tipados/exportados con rangos en el futuro schema. Número de carriles,
bloque5 y secuencia WAVE son invariantes del spec, no controles del jugador.

## Contexto candidato

Clave canónica `phase/role/lane/defense/load`, con orden de categorías fijado:

- phase: `early`, `middle`, `late` según phase_end_waves del Resource. Con los
  valores iniciales: olas1–3,4–7,8–10 respectivamente.
- role: `A` o `R`, del perfil autorado del próximo WAVE. Adaptador identifica R
  por los campos de fusil activos del EnemyStats, sin modificar ese Resource.
- lane: entero0–4; la UI puede expresarlo como filas1–5.
- defense: `empty`, `armed`, `unarmed`, `returning`. Desde snapshot público:
  sin soldado vivo→empty; vivo y RETURNING→returning; vivo con ammo>0 y modo
  RIFLE→armed; cualquier otro vivo→unarmed. RETURNING tiene precedencia.
- load: `zero`, `one`, `two_plus`, contando enemigos activos/targetable del
  carril antes de la aparición; INITIAL también es carga observable.

5×3×2×4×3 =360 claves posibles. Las cinco opciones se evalúan con el mismo
snapshot de decisión. No almacenar Node, instance_id de soldado, su moral,
saldo económico, objetivos o comandos futuros. Se abstrae el fuego diagonal:
el modelo no pretende representar toda la fuerza efectiva de una defensa.

## Memoria persistente

| Campo | Significado y rango |
|---|---|
| schema_version | 1; versiones desconocidas no se migran automáticamente |
| policy_version | 1 |
| compatibility_id | SHA256 de contenido/configuración/geométrica canónica |
| generation | entero no negativo hasta2^53−1; no overflow ni wrap |
| last_match_id | string opaco de sesión, máximo64 caracteres |
| cells | mapa de hasta360 claves canónicas únicas |
| q, n por celda | números finitos, q∈[0,1], n∈[0,20] |

Una celda ausente equivale a q=0.5,n=0. `n` es evidencia efectiva y fraccionaria,
no un contador de enemigos ni un total histórico de partidas. Cada partida
aporta como máximo una visita efectiva por celda. La memoria sólo cambia en
un terminal con al menos una muestra WAVE cerrada; el borrado es otra operación
expresa del jugador, no una partida.

`compatibility_id` incluye política/config, orden de tipos y tiempos aplanados,
campos base de stats A/R y soldado que afectan combate, y LaneBoardConfig.
Excluir rutas absolutas, UID del editor y arte/audio; documentar la serialización
canónica de nombres/campos/valores en la prueba de compatibilidad. No usar sólo
versión de app, SHA de Git o una fecha como proxy de balance.

## Estado efímero de CommanderSession

- `match_id`, estado ACTIVE/FINALIZED/ABANDONED, semilla y RNG propios.
- Copia profunda de memoria inicial; nunca escribir en ella durante selección.
- Índice WAVE0–98, carriles pendientes del bloque, ordinal global y última decisión.
- Hasta99 registros de aparición, cada uno con clave de contexto, carril,
  ordinal, spawn_x, defended_right, actor_id y activation_generation.
- Registro OPEN, DEFEATED, BREACHED o CENSORED; resultado finito opcional.
  Actor/generación son identidades transitorias; no se guardan entre partidas.
- Agregados provisionales por celda: suma y número de recompensas cerradas.

Cada activación WAVE aparece una vez; muerte/cruce duplicados o de otra generación
no la cierran otra vez. CENSORED no equivale a recompensa0 y no entra en la media.
No quedan referencias fuertes a actores una vez cerrado el registro.

## Almacenamiento y errores

Dos rutas dedicadas: `user://commander_memory_a.json` y
`user://commander_memory_b.json`; base de ruta inyectable en pruebas.
Cada archivo es un sobre JSON con `payload` string y `sha256` del UTF-8 exacto
de ese string. El payload es el objeto anterior. Rechazar archivos mayores de
128KiB antes de leer todo, tipos extraños, campos extra, claves inválidas,
NaN/Infinity, bool usado como entero y estructuras fuera del esquema.
El hash detecta truncamientos/cambios accidentales, no es protección anti-cheat.

Resultados explícitos del almacén: OK, MISSING, INVALID, INCOMPATIBLE,
IO_ERROR, CONFLICT, TRANSIENT. Separar `saved` (verificación local de escritura)
de durabilidad Web entre recargas; nunca presentar un detector como certificación.
Conservar una sola instancia escritora por GameRoot; varias pestañas/procesos
no se sincronizan. Una generación inesperada detectada invalida ese commit y
obliga a recargar antes del próximo intento; no prometer bloqueo entre procesos.

## Transiciones

| Origen/evento | Destino | Efecto |
|---|---|---|
| inicio válido | ACTIVE | cargar copia compatible y reiniciar bloque/RNG |
| ACTIVE + pausa | ACTIVE | sin decisiones, aprendizaje o avance de RNG |
| ACTIVE + WON/LOST | FINALIZED | guard previo, censura OPEN y candidato de memoria |
| ACTIVE + menú/cierre | ABANDONED | descartar todo; cero guardado/olvido |
| FINALIZED + terminal/Retry | FINALIZED | sin nuevo cómputo; Retry crea otra sesión |
| menú + borrar persistente exitoso | memoria neutral | eliminar slots; no tocar datos ajenos |
| menú + borrar TRANSIENT | memoria neutral en RAM | sin I/O ni promesa de borrar datos persistidos inaccesibles |

El candidato sólo reemplaza la memoria del almacén si save devuelve OK. En modo
TRANSIENT esto valida y publica sólo en RAM, con saved=false: permite recordar
entre partidas de esa sesión sin fingir persistencia. Un error no bloquea el
resultado de partida; se informa y no se reintenta en background.
La terminación sin muestras cerradas no escribe ni envejece la memoria.
