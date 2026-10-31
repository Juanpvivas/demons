# Verificación de 015

I2 está aprobado funcionalmente en T021 (`b4fbaf8`), con CI/gate final pendientes. Verificar además la secuencia global 99 WAVE=66 A/33 R, inicial R1 independiente, tabla por ola/tiempos/carriles; cuerpos mixtos y reset R→A→R conservan avance A, parada/tiro R, contacto y limpieza. [Alcance y límites I2](research.md#i2-vigente-aprobado-funcionalmente).

## Recorrido I1 conservado

Comportamiento aprobado funcionalmente en T010; este recorrido conserva criterios repetibles. El [alcance ya observado y sus límites](research.md#alcance-funcional-aprobado-y-límites) distingue GUT, Web y apps. CI de `2351798` y QA de integración están aprobados; [PR #59 en borrador](https://github.com/Juanpvivas/demons/pull/59), sin merge. Publicación T015 pendiente.

1. Cuerpos reales: colombiano hogarx144/enemigo entradax1008 en mismo carril, con física: tiro/daño desde864. Controles detrás, fuera del borde físico y diagonal profunda; conservar diagonal inmediata y machete.
2. Enemigo entrada→colombiano vivo frontal mismo carril: detenerse, tiro inmediato y próximos a intervalos. Otro carril/detrás/muerto no es blanco; sin objetivo vuelve a marchar. Contacto melee no acumula fusil.
3. Perfiles de las diez olas iguales a tabla y monotónicos; inicial perfil1. Verificar por datos y spawn real sin alterar HP15/speed40/melee5/drop3 ni counts/spawn intervals.
4. Machete letal herido→+2moral/+3vida con cap, fullHP sólomoral, owner muerto sin heal, noletal/callback doble/reciclado sin crédito. Baja final+WON conserva premio válido. Fusil sigue1moral/noheal.
5. Tiro enemigo snapshot/destello/trazadora/audio una vez, daño una vez. Reciclar/cleanup/close y enviar evento viejo no afecta nueva activación; pausa/reanudar sin ráfagas o cooldown heredado.
6. Tester registra RED por aserción antes de dev; GREEN/regresión completa/import/build/CI aplicables. Playtesting de balance con actores/perfiles autorizados y UI legible; sin atribuir aprobación desde pruebas de callbacks únicamente.
7. Un export Web final para preview local8813; observar tiro desde entrada, parada/enemigo, contacto, premio y flujo menú/retry en computador. Apps nativas disponibles se declaran por app/renderer/gesto/audio, sin navegador móvil. Fixture no es producción completa.
8. Preservar introducción013, voces humanas/compañero definitivo, audio014 Stream/GameplaySFX/limiter9voces, recarga/barra/retorno. Comparar coste disponible sin campaña006, mediciones físicas o distribución no autorizadas. No nuevos logs/capturas/evidencias Git.
