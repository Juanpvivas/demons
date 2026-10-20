# Contrato: Tablero, combate e interacción horizontal

Contrato de la feature para agentes/tester; sin API remota nueva. I1 está
integrado en `main`; salida/espera/contacto I2 tiene aprobación funcional para
integración en `codex/005-i2-machete`, aún sin integrar. Recarga/selección/regreso
siguen pendientes de I3 y la presentación lateral de I4. Las firmas concretas
se definen mediante setup/RED sin cambiar estas invariantes.
[Spec](../spec.md) · [Modelo](../data-model.md).

## Tablero, spawns y terminal

- Nivel acepta solo cinco plazas del modelo, antes de cobrar/instanciar.
  Inicializa cinco soldados completos sin costo y reserva global cero.
- Plaza ocupada selecciona a su dueño aunque esté fuera, nunca despliega/cobra.
  Reserva dura hasta morir el dueño, no hasta terminar caída visual.
- Inicial t0/fila 3 +99 de diez oleadas =100. Inicial no consume cursor ni
  notifica baja a WaveManager; conserva combate/drop 3/moral/visual/derrota.
- Spawn WAVE número n usa fila `1+(n−1)%5`; no reiniciar cursor en nueva oleada.
  Mantener orden/intervalos/espera inicial autorados. Primera oleada 1,2,3;
  segunda 4,5,1,2. Reinicio de partida vuelve a fila 1.
- Adquirir pool→preparar stats/fila/origen/generación/posición→combatir.
  Prewarm/crecimiento registran conexiones/visual una vez por nodo físico.
  Baja captura contexto antes de callbacks síncronos y produce recompensa
  una vez; solo origen WAVE notifica contador y ambos regresan al pool.
- Entrada de cuerpo enemigo activo en zona izquierda reporta LOST único.
  WON conserva el contador histórico de 99 bajas de oleadas;100 es población,
  no requisito nuevo de matar inicial para ganar. Inicial sí puede causar LOST.
  Tras terminal no se aceptan órdenes, gasto, recogidas o combate tardíos.

## Objetivos y física

- Frente colombiano +X, avance enemigo −X a velocidad existente; fila estable.
  Progreso mayor=`−global_position.x`; un único objetivo elegible activo, sin
  robar foco o dividir fuego. Al perderlo, reelegir el más avanzado elegible.
- Fusil solo HOME/carga>0: frente en fila propia o celda diagonal directamente
  contigua `(home_cell.x+1, home_cell.y±1)` de filas existentes. Excluir detrás,
  dos filas de distancia y diagonales más profundas.
- Conservar alcance longitudinal por solape de forma actual orientada+X:
  intervalo local[24,264], contra cuerpo enemigo 48×48. No convertir 264 en
  alcance hasta su centro ni ampliar daño por ensanchar broadphase transversal.
- Broadphase físico puede cubrir filas vecinas para evitar perder tangencias;
  después filtra fila/celda/frente/alcance. No truncar consulta de forma que
  orden interno omita candidatos elegibles.
- Machete busca frontal de fila propia para acercarse, incluso lejano;
  golpe solo dentro de rango 64×64 a offset(+32,0), más filtro frontal.
  Cadencia/daño vigentes; sin enemigos delante espera, nunca persigue detrás.
- Cuerpos reales móviles y colisión: aproximación se detiene sin atravesar ni
  desviar a otra fila. Contacto por consultas puntuales de tick físico, no
  overlaps estáticos heredados. Daño entrante mantiene cada atacante válido
  y cooldown 1s existente; un mismo ataque no daña dos veces por doble ruta.
- Regreso físico a 40 cancela blancos/ofensiva, conserva contacto/daño entrante.
  Muerte cancela orden y libera origen lejano. Alcanzar origen no se decide
  por animación, espera arbitraria o teletransporte.
- Validar la instancia antes de operaciones tipadas; después vivo/activo,
  elegibilidad y generación de blancos. Nodo reciclado no recibe ataque
  destinado a su uso anterior. Reinicio/terminal limpian órdenes, candidatos,
  intenciones de movimiento y callbacks visuales.

## Recarga, selección e input

Las reglas de selección/transacción/regreso siguientes pertenecen a I3.
Durante I2, `reload()` sólo conserva su operación heredada para actor vivo,
PLAYING, fondos y posición de hogar (distancia ≤0,01), sin exigir enum `HOME`
ni carga cero; fuera rechaza sin gasto. `return_speed=40` queda preparado sin
ruta activa. La precedencia de picking vigente se conserva.

1. Resolver selección contra dueño vivo actual y PLAYING. Habilitar solo
   carga 0, sin orden aceptada/RETURNING, con fondos≥costo. Panel muestra fila,
   carga/capacidad, moral y retorno. Plaza vacía/muerto/parcial/lleno/sin fondos
   deshabilita botón; la operación revalida aunque alguien la invoque directamente.
2. Aceptar/bloquear reentrada antes de notificar gasto. Cobrar exactamente
   `stats.deploy_ammo_cost` una vez, rellenar carga y conservar vida/moral.
   Fuera→RETURNING sin arma ofensiva y vulnerable; dentro→HOME/fusil sin viaje.
3. Al llegar, HOME; carga llena sigue haciendo inelegible otra recarga.
   Muerte invalida selección/orden: una acción antigua capturada antes de
   reemplazo no cobra ni recarga al nuevo dueño.
4. Widgets consumen gesto sin propagar al tablero; decoración no lo bloquea.
   En tablero: pickup pickable→ceder picking vigente; si no, plaza ocupada→
   selección, libre→despliegue, inválida→nada. Un gesto no recoge y además
   selecciona/despliega/recarga. Cajas solapadas conservan regla y radio vigentes.
5. Conservar mouse emulado de toque y ruta nativa sin doble despacho; convertir
   evento viewport→canvas inverso→TileMap, sin posición de mouse global para
   interpretar toque. Verificar mapping tras resize con entrada de SO.

## Presentación observadora

HUD emite intención al nivel y observa cambios, sin autoridad de economía.
Conectar al crear/registrar una vez; no polling de UI que decida la orden.
Presentador observa ataques/daño y desplazamiento confirmados: fusil dentro,
última bala, marcha/espera/golpe de machete, regreso y muerte. No causa daño,
gasto o llegada desde frames. Caída independiente captura posición/orientación
reales y libera actor/plaza inmediatamente. Reset limpia material, flips,
frames, tweens y generación. Imagen orienta materiales/siluetas, no HUD/stats.
