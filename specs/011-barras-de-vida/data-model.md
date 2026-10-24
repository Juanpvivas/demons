# Data Model — 011

| Entidad | Estado/dato existente | Presentación |
|---|---|---|
| Soldado | `_current_health`; `stats.max_health` (hoy 30) | HealthBar de su instancia |
| Enemigo | `_current_health`; `stats.max_health` (hoy 15); activación/pool actuales | HealthBar de su activación |
| WorldHealthBar | `value`, `max_value`, `visible`, estilo fill | Proporción limitada; oliva/ocre/rojo |

Vida >0 y máximo válido en actor activo → visible. Vida ≤0, retirada o máximo inválido → oculta; reactivación → máximo/valor/color actuales. Sin persistencia, nuevas estadísticas ni mutación de Resources; recarga no modifica vida.
