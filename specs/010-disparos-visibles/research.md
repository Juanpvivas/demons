# Decisiones de preparación — 010

## Hecho de disparo antes de sus consecuencias

**Decisión**: emitir `rifle_shot_visual_requested` con origen/destino por valor antes de `take_damage`. **Razón**: el daño actual es inmediato y sus callbacks pueden retirar o reutilizar al enemigo y resolver victoria en el mismo dispatch. **Alternativas**: seguir al actor o capturar después del daño pierde el contexto; un proyectil con física introduciría una mecánica no autorizada.

## Presentación 2D local

**Decisión**: efecto code-native de destello y trazadora, cálido mate, duración inicial 0,16 s y máximo 0,20 s activo; ancla del cañón resuelta por `SoldadoVisual` contra la pose de fusil existente. **Razón**: un flash pequeño y un trazo suave pueden conservar la dirección pictórica sin alterar los atlas aprobados ni aclarar el soldado. **Alternativas**: raster nuevo, luces globales o partículas añaden recursos y variación innecesarios para esta indicación; sólo reconsiderarlos ante un defecto visual concreto.

## Pool y ciclo de partida

**Decisión**: segundo pool en `CombatVisualEffects`, con prewarm diez y crecimiento existente; activación identifica cada uso y reset limpia geometría/color/reloj. **Razón**: aplica constitución IV y el patrón de bajas sin cambiar sus conteos ni `ObjectPool`. **Alternativas**: crear/destruir cada tiro o reutilizar el pool de caídas mezclan vidas y estado.

**Decisión**: WON/LOST rechazan efectos nuevos y dejan completar los confirmados, incluido el ganador; cierre/MENU/Retry limpian síncronamente. **Razón**: el tiro ganador sigue siendo legible sin prolongar combate ni sobrevivir al intento. **Alternativa descartada**: limpiar al resolver victoria borraría el ganador antes del primer render. PAUSED y la pausa de árbol congelan el reloj; no se añade un control nuevo.

## Preparación de TDD y entrega

**Decisión**: esqueleto neutro explícito antes de RED; tests del tiro real, snapshot, vida/pool y ciclo, más revisión visual real. **Razón**: una clase o señal ausente produciría fallo de carga, no RED del requisito. **Alternativas**: conteos de frames o comparación textual no prueban el nuevo comportamiento. Las pruebas existentes cubren regresión sin inventar TDD histórico.

**Decisión**: un I1 funcional con QA/documentación/draft PR, sin publicación ni mediciones de rendimiento nuevas. **Razón**: alcance autorizado, gates separados y pausa explícita de #30. La falta de hardware final queda declarada, sin convertir simulación ni smoke en certificación física.
