# Demonios de las Trincheras — Spec del juego

> Documento vivo. Actualízalo a medida que el diseño evolucione; sirve como fuente única de verdad del proyecto.

**Nombre del juego (confirmado):** Demonios de las Trincheras

## 1. Resumen

Juego de defensa por carriles (estilo *Plants vs. Zombies*) inspirado en la historia real del Batallón Colombia en la Guerra de Corea, apodado **"los demonios de las trincheras"**. El jugador coloca soldados colombianos en distintas posiciones para detener el avance de oleadas enemigas y proteger una posición estratégica (ej. Monte Calvo / Old Baldy).

## 2. Contexto histórico e inspiración

- Colombia fue el único país latinoamericano que envió tropas a la Guerra de Corea (Batallón Colombia, ~4.300–5.100 soldados).
- El batallón se destacó especialmente en la **batalla de Monte Calvo (Old Baldy)**, donde llegó a perder cerca del 20% de su fuerza desplegada en un solo combate.
- El apodo "demonios de las trincheras" se lo dieron los propios enemigos, como reflejo del miedo y respeto que inspiraba su ferocidad en combate cuerpo a cuerpo.
- Nota de diseño: el juego usa la versión popular de la historia (soldados que se quedan sin munición y recurren al machete) como base narrativa y mecánica, priorizando jugabilidad sobre precisión documental estricta. Tratar el tema con respeto: es un homenaje, no glorificación gratuita de violencia.

## 3. Género y referencias

- **Género:** Tower defense / lane defense, 2D.
- **Referencia principal:** Plants vs. Zombies (colocación de unidades por costo de recurso, oleadas crecientes, carriles).
- **Diferenciador:** economía dual (ver sección 5) atada temáticamente a la historia real.

## 4. Plataformas objetivo

- Android
- iOS
- PC (Windows / macOS / Linux)

## 5. Motor y stack técnico

- **Motor:** Godot 4.x
- **Lenguaje:** por definir entre GDScript (más rápido para prototipar) o C# (más familiar viniendo de Kotlin). Recomendado: empezar en GDScript para el prototipo, migrar módulos críticos a C# solo si hay problemas de performance.
- **Licencia del motor:** MIT, sin regalías, sin costos.

## 6. Mecánicas core

### 6.1 Sistema de economía

**Recurso global: Munición**
- Se obtiene principalmente de enemigos derrotados (dropean munición al morir, el jugador la recoge/recolecta). *(Supuesto — confirmar si además debería acumularse pasiva y automáticamente con el tiempo, estilo sol en PvZ.)*
- Uso dual, a elección del jugador:
  1. **Recargar** a un soldado ya desplegado en el tablero (le da más disparos antes de quedarse sin balas).
  2. **Desplegar** un soldado nuevo en una casilla libre.

**Stat individual: Moral (por soldado, no es un recurso global)**
- Cada soldado acumula su propia moral mientras tiene munición y sigue eliminando enemigos (los impactos que no eliminan al enemigo no otorgan moral).
- Al quedarse sin munición, el soldado pasa automáticamente a combate cuerpo a cuerpo (machete).
- El **daño del machete depende de la moral acumulada por ese soldado en particular** antes de quedarse sin balas: un soldado que resistió más tiempo disparando y sumó más bajas será más letal cuerpo a cuerpo que uno que se quedó sin munición rápido.
- **Confirmado** (spec `001-soldado-defensor-oleadas`): si el soldado es recargado después de haber entrado en modo machete, vuelve a modo fusil conservando la moral acumulada — la moral no decae con el tiempo, y solo se pierde por completo si el soldado es derrotado.

Esta economía recrea la tensión histórica real: cada bala cuenta, y sobrevivir el tiempo suficiente disparando paga dividendos cuando llega el momento de pelear cuerpo a cuerpo.

### 6.2 Sistema de colocación

- Grid/carriles, similar a PvZ.
- Colocación restringida por casillas (snap a grid).
- Cada unidad ocupa una casilla; algunas pueden tener rango de ataque que cubre varias casillas adelante.

### 6.3 Tipos de unidad (borrador inicial — por refinar)

**Soldado base (única unidad inicial, dos modos):**
- **Modo fusil** (por defecto al desplegarlo): dispara a enemigos dentro de su cono de detección (carril frontal + diagonales adyacentes), con una cantidad limitada de disparos definida por su munición actual.
- **Modo machete** (automático al quedarse sin munición): combate cuerpo a cuerpo, rango de 1 casilla frontal, daño escalado según la moral acumulada en modo fusil.
- Stats a definir: disparos por carga, daño por disparo, cadencia de disparo, alcance del cono de detección, fórmula de daño machete según moral (ej. daño_base + moral × multiplicador).

**Futuras unidades (post-MVP, no bloquean el prototipo inicial):**
- [ ] Variantes con distinto alcance/cadencia (ej. mortero de área, francotirador de rango largo)
- [ ] (agregar más según playtesting)

### 6.4 Enemigos y oleadas

- Oleadas crecientes en dificultad, representando el avance de tropas chinas/norcoreanas.
- Definición de enemigos vía `Resource` personalizados (stats: vida, velocidad, daño, tipo).
- Sistema de spawn controlado por `Timer` + cola de oleadas.

## 7. Estructura técnica en Godot (borrador)

- **Autoload `EconomyManager`:** controla el contador global de Munición recolectada, expone señal `ammo_pool_changed`.
- **`TileMap`:** define el grid de carriles y posiciones válidas de colocación.
- **Detección multidireccional por soldado:** en vez de un único `Area2D` en línea recta, se evalúan varias celdas/carriles (frontal + diagonal superior + diagonal inferior) dentro del alcance del arma, para elegir el enemigo válido más cercano. Puede implementarse como una `Area2D` con forma de cono/trapecio, o revisando explícitamente las celdas de los carriles adyacentes vía el `TileMap`. **Confirmado** (spec `001-soldado-defensor-oleadas`): las "diagonales adyacentes" son únicamente las celdas diagonalmente contiguas a la posición del soldado (adyacencia directa), no un cono más amplio de varias celdas de profundidad. Cuando hay varios enemigos elegibles a la vez, el objetivo prioritario por defecto es el más avanzado (más cercano a la posición defendida); el soldado no divide su fuego entre objetivos.
- **Stats por instancia de soldado:** cada soldado en escena mantiene su propio estado local (munición actual, moral acumulada, modo activo: fusil/machete) — no vive en el `EconomyManager` global, solo el pool de munición recolectada es global.
- **`AnimatedSprite2D` / `AnimationPlayer`:** animaciones de disparo, cambio a modo machete, ataque cuerpo a cuerpo y muerte.
- **Unidades y enemigos como `Resource` (.tres):** stats base (daño, cadencia, alcance, fórmula de daño machete) desacoplados del código, para poder balancear sin tocar scripts.
- **Señal `enemy_defeated`:** emitida por cada enemigo al morir, con la cantidad de munición que suelta; conectada a `EconomyManager` para sumar al pool global, y al soldado que dio el golpe final para sumar moral individual.

## 8. Arte y estilo visual

**Estado: por definir.** Opciones consideradas:
- Pixel art retro
- Ilustrado / cartoon (estilo PvZ)
- Más serio y realista

## 9. Alcance del MVP (primera versión jugable)

- [ ] 1 nivel (ej. defensa de Monte Calvo)
- [ ] 2–3 unidades de munición
- [ ] 1–2 unidades de refuerzo/machete
- [ ] 1 tipo de enemigo base + 1 variante
- [ ] Sistema de oleadas funcional (3–5 oleadas)
- [ ] HUD con ambos contadores de recurso
- [ ] Condición de victoria/derrota

## 10. Preguntas abiertas / decisiones pendientes

- Estilo visual definitivo.
- ¿Habrá progresión entre niveles (más batallas históricas) o es un solo escenario?
- ¿Narrativa/contexto histórico se presenta dentro del juego (cutscenes, texto) o queda solo como inspiración temática?
- Balance de costos exactos de cada unidad (se define con playtesting).
- ¿La munición cae solo de enemigos derrotados, o también se acumula pasivamente con el tiempo? (supuesto actual: solo de enemigos)

### Resueltas (graduadas desde specs de feature)

- ✅ Moral tras recarga: se conserva, no decae con el tiempo, se pierde solo si el soldado es derrotado. (spec `001-soldado-defensor-oleadas`)
- ✅ Alcance de diagonales: celdas diagonalmente contiguas a la posición del soldado, no un cono más amplio. (spec `001-soldado-defensor-oleadas`)
- ✅ Disparador de moral: solo al eliminar enemigos, no por impactos sin eliminación. Se corrigió el FR-006 del spec `001-soldado-defensor-oleadas`, que decía "impacta o elimina", para alinearlo con esta definición. (spec `001-soldado-defensor-oleadas`)
- ✅ Fórmula exacta de daño en modo machete según moral acumulada: `machete_damage = machete_base_damage + current_morale * machete_moral_multiplier` (lineal), con `machete_base_damage` y `machete_moral_multiplier` como campos `@export_range` de `UnitStats` (balanceables sin tocar código). Con moral en cero, `machete_base_damage > 0` garantiza el daño mínimo del Edge Case de `spec.md`. Implementada y validada en `soldado.gd` (T017-T024) y cubierta por `tests/unit/units/test_soldado.gd` (T015); decisión de diseño en `research.md` §2 de esa feature. (spec `001-soldado-defensor-oleadas`)

## 11. Historial de cambios

| Fecha | Cambio |
|---|---|
| 2026-08-12 | Versión inicial del spec a partir de la conversación de diseño |
| 2026-08-12 | Refinado el sistema de economía: munición como recurso único de doble uso, moral como stat individual por soldado que escala el daño cuerpo a cuerpo, y detección de disparo multidireccional (frontal + diagonales) |
| 2026-08-13 | Nombre del juego confirmado: "Demonios de las Trincheras" |
| 2026-09-11 | Graduadas tres decisiones desde el spec de feature `001-soldado-defensor-oleadas`: persistencia de moral tras recarga, alcance exacto de las diagonales, y disparador de acumulación de moral (solo eliminaciones, no impactos). Se corrigió el FR-006 de esa feature, que decía "impacta o elimina", para alinearlo. |
| 2026-09-11 | Reparado el archivo: contenía contenido duplicado/entreverado (versión vieja sin resolver + versión nueva, pegadas sin salto de línea entre ellas). Se recuperó la versión correcta sin pérdida de contenido. |
| 2026-09-12 | Graduada la fórmula de daño de machete según moral desde el spec de feature `001-soldado-defensor-oleadas` (T017-T024, validado por `qa-validator`): `machete_base_damage + moral * machete_moral_multiplier`, lineal, con daño mínimo garantizado en moral=0. Se retira de "pendientes" en §10. |