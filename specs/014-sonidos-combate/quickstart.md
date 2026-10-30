# Verificación prevista — Sonidos de combate

1. Perfil/fixtures de audio aislados: soldado con munición/blanco válido dispara y se oye una petición; última bala incluida. Sin blanco/munición, recarga y animaciones no inventan tiros.
2. Herir sin matar a cada bando no produce baja; matar produce una, repetir daño/cleanup no otra. Reciclar enemigo y volver a matarlo sí produce una nueva. Registrar actor dos veces no duplica.
3. Provocar victoria/derrota reales por fixture declarado; una señal terminal por intento. Tiro letal final+baja+victoria una vez cada uno, sin que el resultado corte sonidos ya admitidos. Menú/retry nunca suenan como resultado.
4. Saturar peticiones: número de voces fijo, resultado reservado y sin cola ilimitada. Contrastar estado/RNG jugable con audio activado/desactivado sin alterar balance.
5. Pausa/foco silencian, recuperar no reproduce eventos viejos; menú y retry dejan cero voces y callbacks anteriores inofensivos.
6. Verificar nueve WAV de los cinco cues/procedencia/importación/carga offline, niveles/duración/no clipping y exclamación+caída breve; audición perceptual real si disponible, o declararla pendiente. No test artificial que replique bytes o percepción.
7. GREEN y suite completa GUT/import/build/export/CI aplicables. Preview/smoke Web de computador y apps nativas disponibles, declarando fixture/producción, gesto, audio y renderer observado; no navegador móvil.
8. Comparar carga/coste disponible proporcionalmente, no campaña nueva de rendimiento. Preservar007/013 entrada/retry/menú, voz definitiva/ambiente013, 006 pausada y pendientes004/005/013. Hardware/60FPS/paquete final/publicación separados.
