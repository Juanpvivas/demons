# Contrato visual: Corrida del soldado colombiano

- `melee_march`: ocho fases de salida hacia la derecha, machete en mano y fusil guardado; `returning`: ocho fases con fusil bajo, autoradas hacia la derecha y reflejadas por el comportamiento vigente de regreso.
- Cada recorrido combina las cuatro figuras superiores de su atlas base A y las cuatro de su hoja opuesta B en orden A0,A1,B2,B3,B0,B1,A2,A3 (IDs 0,1,6,7,4,5,2,3). A3→A0 y B3→B0 continúan el alcance/apoyo de la misma pierna.
- Cada clip conserva bucle de 0,60 s: ocho exposiciones de 75 ms. No cambiar velocidad de desplazamiento ni multiplicadores de reproducción del actor.
- Cada mitad enlaza contacto, compresión/paso, impulso y alcance de la pierna opuesta; el pie que alcanza continúa en su propio apoyo. Comprobar ambas transferencias y el cierre, sin suponer que el orden de una grilla ya es anatómicamente continuo.
- Mantener altura/proporciones, casco, rostro, uniforme oliva, botas, mochila y armas entre poses; sólo la oscilación natural acompaña los pasos.
- Las hojas base A definen el tono oliva y la luz mate de cada recorrido; sus hojas opuestas B conservan ese acabado durante los cambios A↔B, sin aclarado intermitente. La corrección de color sustituye sólo los dos PNG B y conserva poses, silueta perceptual, dimensiones, equipo y encaje; también cambian valores alfa, sin nuevo desvanecimiento o recorte observado en la composición real. No cambia recursos, importaciones, shader o material.
- Mantener lienzo lógico 384×288, apoyo (192,264), transformación y material de `Soldado.tscn`. Medir región/margen contra textura importada; ninguna figura vecina, arma cortada, halo o fondo.
- Conservar `rifle_idle`, `rifle_shot`, `melee_idle`, `melee_attack`, `returning_idle` y `defeat`, incluido el encaje de las poses antiguas.
- `SoldadoVisual` conserva selección por estado/desplazamiento real, espejo de regreso, reset e impacto. La animación no mueve el cuerpo, decide blancos ni causa ataques.
- Validación de ambos clips ampliados/a tamaño de juego y en las filas; comprobar detención, contacto, recarga, llegada, baja y nuevo intento según [quickstart](../quickstart.md).
- Cambiar comportamiento exige TDD antes de desarrollo. No modificar enemigo 008, performance 006, renderer, presets, versiones o publicación.
