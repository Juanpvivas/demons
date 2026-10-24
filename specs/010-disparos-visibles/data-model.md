# Modelo de presentación — 010

| Entidad | Datos | Invariantes |
|---------|-------|-------------|
| Snapshot de tiro | `origin_world: Vector2`, `target_world: Vector2` | Exactamente esas claves por valor; coordenadas de mundo finitas; sin Node, Callable, actor ni recurso mutable. Capturado antes de daño/callbacks. |
| Activación del efecto | snapshot copiado, identificador entero, tiempo activo, visibilidad/alpha | Estado por instancia; sin referencia posterior a actores; duración total ≤0,20 s; sólo una finalización válida. |
| Servicio local | pool de tiros, registro de actores, cierre irrevocable de ese intento | Conteos de tiros separados de bajas; registro idempotente; cierre devuelve todo efecto y rechaza peticiones posteriores. |

Transiciones del efecto: inactivo → adquirido limpio → presentación → finalización válida → devuelto limpio. Un callback de otra activación no altera esta transición; release es seguro incluso antes de `_ready()` y antes del primer acquire.

Pausa conserva el tiempo activo. WON/LOST no admiten activaciones nuevas y permiten terminar las existentes. MENU/cierre/Retry cancelan inmediatamente; el intento siguiente crea su propio servicio. Ningún estado persiste entre partidas ni cambia stats, daño, moral o munición.
