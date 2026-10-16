# Contrato: presentación observacional de Monte Calvo

Diseño previsto; sin implementación o validación de entrega afirmadas.

## 1. Frontera protegida

Raíces y transform jugable, grid 96×96, cuerpos 48×48, detector 144×240 offset (0, -144),
melee 64×64 offset (0, -32), pickup CircleShape2D radio 20 y posiciones/spawn intactos.
Sin cambios de capas, máscaras, velocidad, input, cámara, renderer, balance, prioridades,
ocupación u oleadas. Ajustar escala/offset solo en el hijo visual.
Notificar hechos ya confirmados sin esperar. Daño, munición, moral y cooldowns
conservan valores/orden. Ningún clip/callback llama take_damage, reload, add_ammo,
free_cell, notify_enemy_defeated o métodos terminales.

## 2. Tiempos y prioridades

| Presentación | Duración | Regla |
|---|---|---|
| Espera fusil/machete | Continua | Arma/postura distintas sin depender del tinte |
| Disparo real | 0.16 s | Una reacción por ataque; interrumpible por modo/derrota |
| Golpe machete real | 0.24 s | Distinto del disparo; sin daño desde clip |
| Impacto | 0.12 s | Overlay, sin cambiar arma/movimiento |
| Moral ganada | 0.16 s, escala máxima 1.10 | Solo evento real, no stat global |
| Avance enemigo | Loop 0.60 s | Solo desplazamiento real tras física |
| Contacto enemigo | Pose/loop sobrio | No golpe ficticio ni daño generado |
| Derrota | 0.40 s, sin loop | Máxima prioridad; efecto independiente |

Cambio de modo visible como máximo al siguiente frame presentado; última bala
puede interrumpir reacción. Callback termina en modo vigente, nunca restaurando
uno capturado. Derrota cancela daño/moral/ataque vivos. Dos instancias no comparten
frame/tween/estado mutable. Tiempos visuales no modifican fire_rate/daño enemigo.
Avance significa desplazamiento real mayor de 0.01 unidades de mundo por paso
tras move_and_slide; contacto si es menor/igual. Test con cuerpo real bloqueado
por Soldado real; velocidad deseada +Y no acredita desplazamiento.

## 3. Snapshot y evento de derrota

Nueva señal observacional por actor:
`defeat_visual_requested(snapshot: Dictionary)`.

Campos por valor: world_position (Vector2), sprite_frames (SpriteFrames compartido
solo lectura), defeat_animation (StringName), visual_scale/visual_offset (Vector2),
flip_h/flip_v (bool), visual_z (int). Sin Node, objetivo, salud, moral, munición o
callback jugable. Usar transform neutro autorado, sin tinte/pulso de impacto.
No compartir diccionario mutable con otra activación.

Tras salud cero, capturar snapshot y emitir evento visual una vez ANTES de las
señales que retiran al actor. Conservar orden relativo jugable existente:
soldado moral 0 → soldier_defeated → queue_free; enemigo enemy_defeated → drop y retorno
síncrono al pool por su dueño. No introducir espera ni dependencia de
pool/listener disponible para completar muerte. Fallo visual se reporta sin
dejar un actor inmortal. Tests comprueban flujo también sin listener visual.

CombatVisualEffects, Node del nivel, registra una vez actores iniciales, nuevos
soldados y cada instancia física creada por el pool enemigo. Se cablea en
ready/creación, nunca por frame ni en cada acquire. El spawner recibe el servicio
en preparación de sus instancias; no se convierte en autoridad visual global.

## 4. Efecto y reciclado

DeathVisualEffect es Node2D + AnimatedSprite2D sin física, input, grupo enemies
ni escritura jugable. Servicio adquiere/configura/reproduce; final únicamente
devuelve ESA activación al pool. No instancia/destruye efectos por baja.
Actor puede reaparecer/celda ocuparse mientras termina su efecto anterior,
que permanece en su posición capturada y no bloquea recolección/despliegue.

prepare_for_spawn conserva stats/salud/posición y reset visual completo antes
del primer frame de aparición. Release cancela tweens, colas/callbacks.
Reset: frame, reproducción, escala, offset, tinte, flip, visibilidad y activación.
Hooks seguros también en preinstanciación. No modificar API genérica ObjectPool.
Efecto adquirido reinicia activación; callback viejo no altera/libera una nueva.
Probar diez ciclos y reacquire antes de terminar feedback anterior.

## 5. Arte, huella y procedencia

Actor neutro 48×48, apoyo en base del collider, centro sin desplazar; pivote estable
entre frames, sin salto mayor de 1 unidad salvo gesto intencional. En canvas 960×540,
arma principal visible aproximadamente ≥ 8 px de largo/2 px de espesor; revisión
manual sigue exigiendo reconocer fusil/machete sin tinte.
Caja opaca/motivo dentro de 32×32 centrados, radio 20 intacto; sin aureola/etiqueta
que prometa área interactiva extra. Bandos distintos por silueta/uniforme;
caja por forma/cartuchos/contraste sobre suelo y junto a trincheras.

Atlas actor ≤ 1024² por bando, caja ≤ 256²; alfa y regiones sin vecinos/halos.
Compartir texturas/frames; lossless, borde alfa, sin mipmaps/repetición, lineal local.
No hornear terreno/HUD. SOURCES para 100 % de recursos: original, origen/herramienta,
transformaciones, condiciones de uso/atribución.

## 6. Aceptación y límites

FR-001–003/011 y SC-001/008: arte/procedencia/huella.
FR-004/006/009 y SC-002/004: soldado/modo/daño/neutralidad.
FR-005–007 y SC-002/003: avance/contacto/derrota/reset.
FR-008–010 y SC-004/005: caja/input/redimensionamiento.
FR-009/010 y SC-006: partida terminal y regresión real de victoria/derrota.
SC-007: baseline/candidato con carga/frame times/memoria por entorno,
Xiaomi 11T Pro físico `2107113SG` de 2021 como referencia provisional exclusiva
de 004 (autorización del 2026-10-16, constitución 2.2.0) y 60 FPS estables sin
relajar por promedios. Exigir nuevas mediciones y QA; sin heredar resultados de
002/003 ni certificar equipos menos potentes o iOS. Web y nativo se miden y
aceptan por separado también sobre el mismo Xiaomi.
FR-012/SC-008: diff acotado y QA/resumen en PR, sin nuevas evidencias Git.

Quickstart define matriz y pasos: Web 1152×648/960×540 y móvil horizontal,
apps Android/iOS separadas. No probado queda pendiente y bloquea su cierre.
GUT verifica semántica/ciclo, no píxeles/tipo de textura. Arte se revisa
visualmente. Simulador/editor no acreditan navegador/hardware físico.
