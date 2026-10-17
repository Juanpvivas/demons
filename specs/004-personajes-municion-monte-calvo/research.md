# Research: personajes y munición de Monte Calvo

Decisiones locales de preparación inicial, 2026-10-16. I1 conserva su aprobación
histórica sobre `87a39c6`; la corrección delimitada en T031 (§8) está aprobada
funcionalmente en T036. Las descripciones
de la línea base de las secciones 1–7 pertenecen a la preparación inicial.

## 1. Integración en escenas existentes

**Decisión**: mantener raíces/colliders y añadir presentación al AnimatedSprite2D.
Soldado y EnemigoBase actuales tienen un frame sólido 48×48; AmmoPickup 32×32,
círculo radio 20. No existen animaciones artísticas de actores.

**Rationale**: conserva física, input, alcances y economía aprobados.

**Alternativas**: reemplazar escenas, copiar cinco carriles/perspectiva.
Descartadas por alterar alcance. El concepto solo orienta estilo.

## 2. Presentación observacional

**Decisión**: script visual por actor; gameplay notifica ataques/daño ya
confirmados. Reutilizar mode_changed, ammo_depleted, moral_changed; nuevo evento
visual de derrota con snapshot previo a señales actuales.

**Rationale**: soldado.gd ya tiene enum/tinte/pulso; enemigo.gd flash/negro,
sin eventos de ataque o daño no letal. No presumir esas interfaces existentes.

**Alternativas**: daño desde Call Method/animation_finished. Rechazadas por
FR-006 y constitución, aunque sean recetas genéricas posibles en Godot.

## 3. Prioridades y contacto

**Decisión**: derrota cancela presentación viva; modo real interrumpe acción
incompatible al siguiente frame presentado. Última bala puede interrumpir su
reacción para pasar a machete. Daño/moral son overlays; callback consulta modo
vigente. Enemigo observa desplazamiento después de move_and_slide, no velocidad
deseada; bloqueado por soldado muestra contacto, sin ataque ficticio.

**Rationale**: evita fusil sin balas, caminar inmóvil o resurrección visual.

**Alternativas**: colas que retrasen modo o caminar por intención. Descartadas.
El daño enemigo sigue naciendo desde RangoMelee del soldado, arquitectura § 4.2.

## 4. Derrota visible sin retrasar retiro

**Decisión**: efecto Node2D + AnimatedSprite2D sin física/input, adquirido de
ObjectPool del nivel; snapshot por valor y final 0.40 s solo libera efecto.

**Rationale**: WaveSpawner devuelve enemigo al pool síncronamente durante
enemy_defeated. Soldado libera celda por señal y queue_free en el mismo ciclo.

**Alternativas**: esperar animación en actor, cuerpo cadáver o crear/destruir
efecto por baja. Rechazadas por timing, objetivos falsos o pooling constitucional.
Ausencia de listener/pool nunca impide muerte jugable.

## 5. Reset y callbacks

**Decisión**: reset frame, animación, transform, tinte, visibilidad, offset, flip,
colas y callbacks por activación. prepare_for_spawn conserva stats/posición;
hooks seguros en preinstanciación. Cancelar/invalidate activación anterior.

**Rationale**: ready no se repite; ObjectPool solo oculta/cambia process_mode.
is_instance_valid no distingue dos usos del mismo nodo válido.

**Alternativas**: confiar en ocultación/reset de tinte. Permiten residuos.
Diez ciclos y dos instancias deben discriminar el comportamiento.

## 6. Arte compartido de solo lectura

**Decisión**: PNG RGBA/frames por dominio; texturas importadas de ejecución hasta
1024² por actor, caja 256². El soldado conserva el PNG original de 1774×887;
la importación nativa limita su textura a 1024×512 y los recortes usan las
coordenadas importadas, según su `SOURCES.md`. El límite no exige reducir el
archivo original ni estimar la memoria de ejecución a partir de él.
Lossless, borde alfa, sin mipmaps/repetición, filtro lineal local. Reusar frames
de derrota. Máximo 8.25 MiB RGBA8 estimados, pendiente de memoria real.
SOURCES recoge original, autor/herramienta/fuente, transformaciones, permisos/
atribución; aplicar skill de imagen al producir. Medir regiones/alfa reales.

**Rationale**: el arte 002 mostró que no se puede asumir grilla exacta generada.

**Alternativas**: fondo con actores horneados, escalar colliders o mutable
SpriteFrames compartido. Descartadas por separación/interacción/independencia.

## 7. Verificación y plataformas

**Decisión**: GUT para lógica nueva, revisión proporcional para arte. Variables
ocultas mediante inspector o copia temporal observadora solo lectura; partida
manual conserva Resources/oleadas y no invoca terminales artificialmente.
Recarga se verifica aparte por ruta reload existente, sin botón nuevo.
Corroborar visualmente producción sin observador declarando variables ocultas.
Sin terminal verificable, smoke permanece pendiente.

**Rationale**: nivel sin HUD/pantallas terminales. No inferir terminal por sprites.

**Alternativas**: overlay QA permanente o llamada terminal como partida completa.
Descartadas. Evidencias nuevas solo temporales/CI; resumen en PR.

Matriz Web escritorio/móvil, Android/iOS nativos separada; antes/después de carga,
frame times y memoria. Para 004, la decisión explícita del 2026-10-16 admite el
Xiaomi 11T Pro físico `2107113SG` de 2021 como referencia provisional exclusiva
(constitución 2.2.0), sin alterar la referencia nominal global ni los 60 FPS
estables. Su acceso, nuevas mediciones y QA siguen siendo requisitos; simulador
no acredita teléfono. Web y nativo se aceptan por separado también en el mismo
Xiaomi. Sin herencia de resultados 002/003, certificación iOS o de equipos menos
potentes, ni umbral de carga nuevo.
Skills consultadas: using-godot-prompter, 2d-essentials, assets-pipeline,
animation-system, scene-organization, gdscript-patterns, godot-code-review,
godot-testing y patrones de testing. No hizo falta investigación externa.

## 8. Enmienda T031: tamaño, contraste y encuadre

**Decisión**: reutilizar el atlas del soldado y ajustar solo su hijo
visual a altura opaca neutra aproximada de 72 unidades, pie raíz+y24 y pivote
estable ≤1. En CSS 794×305 exigir ≥32 CSS px opacos y reconocimiento sin overlay
y en grises, con luz/contorno mate discreto mediante material compartido
inmutable. Añadir visual_material al snapshot neutro y reset; conservar el estilo
en la caída y limpiar referencias entre usos, sin copiar tintes/pulsos transitorios.

Usar una cámara local sin zoom: mundo x=576 centrado (error ≤1 unidad lógica)
y origen vertical efectivo y=0 después de resize. Conservar iPad 1152×864,
equilibrar Xiaomi 1440×648 y Web aproximadamente 1684×648; ampliar únicamente
cielo/panorama/suelo hacia la izquierda con sus texturas actuales.

**Rationale**: el feedback identifica un soldado pequeño y confundido con suelo,
y espacio desequilibrado en Xiaomi, mientras la composición de iPad resulta
adecuada. Separar encaje visual y proyección conserva posiciones, física e input.

**Alternativas descartadas**: regenerar el PNG como requisito, escalar colliders,
mover trincheras/grid, aumentar zoom, añadir anillos/HUD o rediseñar terreno.
Fijar camera.position.y=0 desplazaría el origen efectivo; limit_left=0 impediría
el margen negativo que necesita un viewport ancho. Aplicar el contrato local,
con las guías camera-system y 2d-essentials consultadas para esta enmienda.
La corrección pasó QA documental T032 y su ciclo RED T033 → desarrollo T034 →
GREEN/visual T035 → QA funcional T036. Su consolidación y entrega se siguen en
las [tareas](tasks.md) y el PR, sin iniciar I2 ni rehacer evidencia histórica.
La autoría documental no ejecuta motor o pruebas ni sustituye esos gates.
