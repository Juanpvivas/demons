# Modelo de presentación — PREPARACIÓN de 004

Diseño previsto; no declara clases implementadas, arte producido o pruebas
ejecutadas. Complementa [plan](plan.md) y [contrato visual](contracts/visual-presentation.md).
Los nombres de estados siguientes son conceptuales, no nuevas APIs públicas.

## Límite con los datos jugables

`UnitStats`, `EnemyStats`, las oleadas y el estado mutable de cada actor siguen
siendo la fuente de verdad de salud, daño, munición, moral, modo y movimiento.
La presentación no escribe esos datos ni mantiene una segunda economía.
Las duraciones de clips son tiempos cosméticos, nunca cadencias de combate.

| Elemento existente | Presentación prevista | Invariante |
|---|---|---|
| `Soldado`, estacionario | Soldado colombiano oliva, casco y fusil/machete | Raíz, posición, cuerpo 48×48 y detectores actuales intactos |
| `Enemigo`, móvil/reciclado | Infantería gris/marrón, avance/contacto | Raíz, movimiento real, cuerpo 48×48 y pool actual intactos |
| `AmmoPickup` | Caja oliva con motivo de cartuchos | Sprite base 32×32; área circular de picking radio 20 intacta |

El tamaño de los cuerpos no impone el tamaño del lienzo del arte. Su encaje
visual se ajusta por separado, conservando el punto de apoyo y la correspondencia
con las zonas de interacción. No se modifican los detectores de combate.

## 1. Recurso artístico compartido

Un diseño base por bando y una caja; hojas/imágenes con transparencia, sus
recortes y secuencias de fotogramas constituyen datos visuales compartidos de
solo lectura. El progreso de reproducción pertenece a cada instancia.

| Actor | Cobertura mínima |
|---|---|
| Soldado | Espera fusil, disparo, espera machete, golpe machete, derrota |
| Enemigo | Avance, contacto detenido, derrota |
| Caja | Disponible; deja de mostrarse cuando se recoge |

El impacto se compone sobre la pose viva; no exige nuevas barras ni una hoja
de animación por cada valor de salud/moral. Cada recurso tiene procedencia,
permisos y transformaciones documentados junto al arte, según FR-011.

## 2. Presentación viva por instancia

El presenter dedicado se acopla al sprite del actor. Conserva únicamente:

- Modo real observado y pose base correspondiente.
- Acción cosmética activa y su tiempo de reproducción.
- Feedback de impacto activo y sus valores visuales originales para restaurar.
- Marcador de vida/reutilización y generación de callbacks, para invalidar
  trabajos pendientes de una aparición anterior.
- Fotograma, progreso, orientación, desplazamiento, escala y tinte propios.

| Suceso real | Estado visual | Tiempo cosmético previsto |
|---|---|---|
| Soldado vivo sin atacar | Espera del modo actual | Bucle/pose estable |
| Disparo realizado | Disparo de fusil | 0,16 s |
| Golpe de machete realizado | Golpe de machete | 0,24 s |
| Munición agotada/modo cambiado | Espera o acción válida del nuevo modo | Transición inmediata |
| Enemigo con desplazamiento real | Avance | Mientras se desplaza |
| Enemigo bloqueado y sin desplazamiento | Contacto detenido | Mientras permanece detenido |
| Daño no letal confirmado | Impacto superpuesto a la pose viva | 0,12 s |
| Moral ganada realmente | Pulso cosmético, sin cambiar el modo | 0,16 s; escala máxima 1,10 |
| Derrota confirmada | Retiro de presentación viva + efecto separado | Sin demora del retiro jugable |

La prioridad es **derrota → modo actual → acción válida → espera**. Un cambio
a machete interrumpe el clip de fusil aunque no haya terminado. Un callback de
disparo anterior no restaura después la pose de fusil. El impacto no cambia el
modo ni prolonga acciones; una derrota cancela todo feedback vivo.

El enemigo decide avance/contacto por desplazamiento real mayor de 0,01
unidades de mundo por paso tras física, no por su vector deseado: puede
intentar avanzar mientras una colisión lo mantiene detenido.
La pose de contacto no calcula, aplica ni promete un ataque independiente.

## 3. Snapshot de derrota y efecto separado

Antes del evento que puede liberar o reciclar al actor, la señal observacional
`defeat_visual_requested(snapshot: Dictionary)` entrega una copia por valor de
`world_position`, `sprite_frames`, `defeat_animation`, `visual_scale`,
`visual_offset`, `flip_h`, `flip_v` y `visual_z`, según el contrato. Usa valores
neutros autorados, sin pulso o tinte de impacto. Los datos mutables se copian;
los recursos de arte inmutables pueden compartirse. No retiene una referencia
al actor, su salud, modo o siguiente aparición ni callbacks de gameplay.

El nivel posee un pool de efectos visuales de derrota. Cada efecto es un
`Node2D` con `AnimatedSprite2D`, sin física, detección, input ni ocupación.
Permanece en la ubicación capturada, reproduce la derrota durante **0,40 s**
y vuelve a su pool. No es un cadáver persistente ni un objetivo atacable.
Puede sobrevivir visualmente al actor liberado sin retrasar daño, drop, baja,
liberación de celda, victoria/derrota o devolución del enemigo al pool.

## 4. Ciclo de vida y aislamiento

| Transición | Responsabilidad visual |
|---|---|
| Primera aparición | Inicializar pose desde el estado real y comenzar una generación limpia |
| Daño/acción | Reproducir solo el feedback del hecho confirmado para esa generación |
| Derrota | Capturar snapshot antes de liberar, solicitar un efecto y cancelar la presentación viva |
| Release/inactividad | Invalidar callbacks; detener clips/tweens; borrar colas y ocultar |
| Reutilización | Reiniciar frame/progreso, flip, offset, escala y tinte; observar el nuevo estado real |
| Fin del efecto | Devolver únicamente esa instancia/generación al pool de efectos |

Los valores base de restauración pertenecen a cada escena/presenter; no se
reemplaza indiscriminadamente la escala artística por un valor que la desajuste.
Una generación obsoleta no puede modificar ni liberar una instancia reutilizada.
El reseteo debe ser seguro también para una instancia nueva aún nunca usada.

No se añaden campos de gameplay, guardado, servicios externos o autoloads.
Las formas exactas de comunicación se fijan en el contrato; todo comportamiento
nuevo de sincronización/reset se guía por TDD, sin RED artificial para imágenes.
