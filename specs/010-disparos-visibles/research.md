# Decisiones de preparación — 010

## Hecho de disparo antes de sus consecuencias

**Decisión**: emitir `rifle_shot_visual_requested` con origen/destino por valor antes de `take_damage`. **Razón**: el daño actual es inmediato y sus callbacks pueden retirar o reutilizar al enemigo y resolver victoria en el mismo dispatch. **Alternativas**: seguir al actor o capturar después del daño pierde el contexto; un proyectil con física introduciría una mecánica no autorizada.

## Presentación 2D local

**Antecedente**: el perfil inicial aprobado en T001–T012 usó dibujo code-native cálido mate de 0,16 s, máximo 0,20 s, con ancla del cañón resuelta por `SoldadoVisual`. No se alteraron atlas ni color del soldado.

**Revisión autorizada del 2026-10-24, aprobada funcionalmente en T018**: duplicar destello y trazadora, conservar intensidad durante 0,30 s de avance hasta el destino capturado y desvanecer sólo durante los 0,10 s finales. **Razón**: la persona comprobó que el perfil inicial se percibía demasiado pequeño en Web, iOS y Android. Mantener paleta y dibujo local conserva el acabado pictórico sin luces sobre el actor ni recursos raster nuevos.

## Alcance frontal configurable

**Decisión autorizada**: pasar el extremo frontal de 264 a 396 (+50 %) en `UnitStats.rifle_range`/`.tres`, conservando inicio 24, altura 192 y diagonales directamente contiguas. **Razón**: comenzar a disparar antes deja más recorrido visible; es el único cambio de balance del ajuste. La forma debe ser propia de cada actor y el solape sigue siendo corporal, sin mutar datos compartidos. Una sesión manual de balance complementa RED/GREEN; no se compensan cadencia, daño, munición u oleadas.

## Pool y ciclo de partida

**Decisión**: segundo pool en `CombatVisualEffects`, con prewarm diez y crecimiento existente; activación identifica cada uso y reset limpia geometría/color/reloj. **Razón**: aplica constitución IV y el patrón de bajas sin cambiar sus conteos ni `ObjectPool`. **Alternativas**: crear/destruir cada tiro o reutilizar el pool de caídas mezclan vidas y estado.

**Decisión**: WON/LOST rechazan efectos nuevos y dejan completar los confirmados, incluido el ganador; cierre/MENU/Retry limpian síncronamente. **Razón**: el tiro ganador sigue siendo legible sin prolongar combate ni sobrevivir al intento. **Alternativa descartada**: limpiar al resolver victoria borraría el ganador antes del primer render. PAUSED y la pausa de árbol congelan el reloj; no se añade un control nuevo.

## Preparación de TDD y entrega

**Decisión**: esqueleto neutro explícito antes de RED; tests del tiro real, snapshot, vida/pool y ciclo, más revisión visual real. **Razón**: una clase o señal ausente produciría fallo de carga, no RED del requisito. **Alternativas**: conteos de frames o comparación textual no prueban el nuevo comportamiento. Las pruebas existentes cubren regresión sin inventar TDD histórico.

El esqueleto anterior pertenece al perfil inicial. La revisión usa las APIs existentes para RED de alcance ampliado y duración; recorrido y tamaño se validan visualmente, sin interfaces de introspección artificiales. El daño sigue siendo inmediato, aunque la trazadora cosmética tarde en alcanzar la posición capturada.

**Decisión**: un I1 funcional con QA/documentación/draft PR, sin publicación ni mediciones de rendimiento nuevas. **Razón**: alcance autorizado, gates separados y pausa explícita de #30. La falta de hardware final queda declarada, sin convertir simulación ni smoke en certificación física.

La revisión funcional de T018 acredita el recorrido completo y playtesting en Chrome; Android acredita destello/combate/derrota/Retry, e iPad sólo inicio por teclado/combate/machete, sin captura inequívoca del efecto ni Retry/recogida/retorno manuales. No se extrapola visibilidad entre destinos ni se atribuye a 010 la franja gris observada en iPad. Compatibility/software y la shell de simulador no certifican Mobile, hardware, IPA final ni 60 FPS. El cierre de integración y CI de la revisión exacta se verifica en el [PR #41](https://github.com/Juanpvivas/demons/pull/41); publicación pendiente.
