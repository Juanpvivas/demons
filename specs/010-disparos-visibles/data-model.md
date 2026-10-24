# Modelo de presentación — 010

| Entidad | Datos | Invariantes |
|---------|-------|-------------|
| Snapshot de tiro | `origin_world: Vector2`, `target_world: Vector2` | Exactamente esas claves por valor; coordenadas de mundo finitas; sin Node, Callable, actor ni recurso mutable. Capturado antes de daño/callbacks. |
| Activación del efecto | snapshot copiado, identificador entero, tiempo activo, visibilidad/alpha | Estado por instancia; cabeza del trazo del cañón al destino en 0,30 s e intensidad conservada durante el recorrido; fade final 0,10 s, duración total 0,40 s; sólo una finalización válida. |
| Servicio local | pool de tiros, registro de actores, cierre irrevocable de ese intento | Conteos de tiros separados de bajas; registro idempotente; cierre devuelve todo efecto y rechaza peticiones posteriores. |
| `UnitStats` | `rifle_range: float` | Dato base de sólo lectura: extremo frontal 396 en `soldado_base_stats.tres`, default legado 264 en el esquema; el límite cercano 24 y altura 192 se conservan. No es distancia al centro enemigo. |
| Geometría de alcance | forma y transformación propias del actor, derivadas de stats | No muta formas o stats compartidos; consulta y filtro conservan solape real, misma fila y diagonales contiguas. |

Transiciones del efecto: inactivo → adquirido limpio → presentación → finalización válida → devuelto limpio. Un callback de otra activación no altera esta transición; release es seguro incluso antes de `_ready()` y antes del primer acquire.

Pausa conserva el tiempo activo. WON/LOST no admiten activaciones nuevas y permiten terminar las existentes. MENU/cierre/Retry cancelan inmediatamente; el intento siguiente crea su propio servicio. Ningún estado persiste entre partidas ni escribe en stats, daño, moral o munición. El alcance base ampliado es configuración autorizada, no estado del efecto. Perfil revisado del 2026-10-24 aprobado funcionalmente en T018; T001–T012 conservan el perfil inicial aprobado. El cierre de integración/CI y los límites de publicación se registran en el PR #41.
