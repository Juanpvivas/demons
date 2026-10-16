# Contrato interno: entorno visual y mecánicas existentes

**Estado**: contrato vigente para la implementación por agentes autorizada el 2026-10-15, en curso en `codex/002-monte-calvo-terreno-trincheras`. La integración y sus verificaciones requieren las aprobaciones de tareas. Vincula FR-004 a FR-011 y SC-002 a SC-006. No define una API externa.

**Adenda 2026-10-16**: preparación de la excepción I4 y método V4 aprobada por QA. No aprueba T019 ni el arreglo nativo; el [registro del orquestador en tasks.md](../tasks.md) es la fuente vigente de aprobaciones. Las reglas visuales permanecen vigentes; la excepción siguiente solo aplica al ciclo separado T019–T022, nunca a las tareas artísticas.

## Integración permitida

Añadir `scenes/levels/MonteCalvoVisual.tscn`, sus recursos gráficos y una instancia hija directa de `Nivel_MonteCalvo`. El root visual queda en (0,0), escala (1,1), rotación 0, `z_index=-10`; hijos con z relativo 0–3. Todas sus hojas se dibujan por debajo de los actores existentes, sin excepciones de z global.

No añadir scripts, señales, autoloads, `Control`, cuerpos/áreas, colisiones, navegación, cámaras, partículas, shaders, luces o parallax. No alterar procesos o estado de los nodos actuales. La decoración no captura input ni llama a gameplay.

## Invariantes de escena y coordenadas

| Elemento existente | Valor / comportamiento que se conserva |
|---|---|
| `Nivel_MonteCalvo` | Raíz `Node2D`, mismo script y transformación |
| `Tablero` | Hijo directo, tipo `TileMap`, transformación actual y TileSet de 96×96; sin migración a `TileMapLayer` |
| `Soldado` inicial | Hijo directo, posición (576,500), escena y geometrías actuales; no centrarlo ni ajustarlo al arte |
| `Enemigo` inicial | Hijo directo, posición (576,50), escena y geometrías actuales |
| Spawn de oleadas | `wave_spawn_position=(576,50)`; avance en +Y, sin rutas o carriles nuevos |
| `PosicionDefendida` | Hijo directo, posición (576,650), rectángulo 960×64 y configuración existente |
| Actores | Escalas y colisiones 48×48; detecciones, offsets, grupos y señales sin cambios |
| Entrada / celda | Inversa de `canvas_transform` → local de Tablero → `local_to_map`; despliegues nuevos en `map_to_local(cell)` |
| Ocupación | `BoardManager` mantiene solo ocupación/liberación; no existe filtro de región que esta feature deba añadir |
| Proyecto | Escena principal, autoloads, InputMap, `canvas_items`/`expand`, renderer y exportaciones sin cambios |

No confundir tamaño de celda con tamaño total del tablero: no hay límites finitos implementados. Los bordes de rocas, montañas y trincheras no deben prometer zonas inaccesibles. La posición inicial del soldado es distinta de la alineación de los despliegues nuevos y ambas se preservan.

## Invariantes de comportamiento

- Scripts de `scenes/`, `core/`, `autoloads/` y schemas de `resources/` sin cambios, salvo exclusivamente `scenes/levels/nivel_monte_calvo.gd` según la adenda T019–T022.
- Escenas de Soldado, EnemigoBase, AmmoPickup y HUD sin cambios.
- Los mismos recursos de unidades, enemigos y diez oleadas, en el mismo orden. Los costos, munición, daño, moral y recarga no cambian; los valores reales siempre proceden de sus Resources existentes.
- Mismos resultados de colocación, celda ocupada, fondos insuficientes, recolección, muerte/liberación, combate y fin de partida, con la única corrección de precedencia de I4 descrita abajo.
- Mantener pickup con su sprite, radio físico y recepción de entrada actuales. No compensar un fallo de picking modificando el controlador del nivel dentro de esta tarea artística.
- `HUD.tscn` no está instanciado en el nivel consultado y no se añade aquí. La recarga se conserva como método y se verifica mediante cobertura existente; no se inventa un botón de producción.

## Verificación del contrato al implementar

1. El tester registra hashes y propiedades de la línea base antes de cambios.
2. El desarrollador limita el diff a los recursos, la nueva escena y la instancia visual añadida a `Nivel_MonteCalvo.tscn`.
3. El tester confirma importación, regresión y matriz de clic/toque. La inspección de z no demuestra por sí sola el comportamiento de input.
4. QA compara el diff semántico y la evidencia antes/después, sin modificar el checkout ni marcar tareas.

La estructura estática puede verificarse con inspección; la lectura, el picking con stretch, el encuadre y el rendimiento requieren ejecución futura real. Si para cumplir el requisito se necesita lógica nueva, se detiene esa ampliación y se prepara un alcance con TDD; no se añade silenciosamente al subárbol visual.

## Excepción acotada — I4 (2026-10-16)

I4 exige que recoger no despliegue además un soldado. El diagnóstico actual reproduce el incumplimiento con/sin arte antes del arreglo; ambos scripts son idénticos. Esta excepción no conserva ese fallo como regla ni lo atribuye al entorno. Proviene del defecto corregido y aprobado con TDD en 003, no de una autorización humana explícita del backport. Su preparación está aprobada; aceptar el arreglo en 002 requiere T019–T022 nativas y su QA.

| Archivo / referencia | Límite verificable |
|---|---|
| Script histórico en `e7f2ca9` y `b670d86` | SHA-256 `2420d7100eb852b6dee0521df56015784a5ac0a0b2af0274b3fa6d2b3fe27e6b`; conservar manifests originales |
| Único script productivo permitido, `scenes/levels/nivel_monte_calvo.gd` | Copia exacta aprobada en `4a2915c5ceb075fbaa3ec7ce1e129a4c34aa497a`, SHA-256 `4e89dce236868c4203079e06937b5c8dbcbbd564382f373d2216d4aa8c700d7f` |
| Único archivo de pruebas nuevo, `tests/unit/levels/test_pickup_input_routing.gd` | Seis casos de la misma revisión, SHA-256 `ac55c141e87f74939d3432dccf89caa62a888b149e0db69df4f8ae1ef9e34dbd`; sin modificar pruebas existentes |
| UID nuevo de esa prueba | SHA-256 `d04d09db66592adb6ca9699779850af4a071aed17a727c10544548aabf3ca56d` |

La corrección da prioridad al pickup real visible/pickable bajo el punto, deja la recolección a su picking y evita el intento de despliegue de ese mismo gesto. Conserva el despliegue explícito por mouse normal y emulado cuando no hay pickup. No cambia InputMap, conversión de coordenadas, radio/escena/script de pickup, costos, recompensas —incluidos pickups superpuestos—, Resources, ocupación, geometría, renderer o presets; no importa código/configuración Web. El estado actual de física 2D en hilo principal debe verificarse sin cambiar configuración; no ampliar aquí a otra arquitectura de input.

El tester conserva la evidencia original, añade manifests nuevos y compara por separado: (a) diff exclusivo del arreglo y pruebas, (b) arte sin/con decoración usando el mismo script corregido. La diferencia visual ya permitida de `Nivel_MonteCalvo.tscn` sigue limitada a la instancia del entorno y `load_steps`, con nodos anteriores intactos. T019 RED aprobado precede T020; T021 confirma GREEN/regresión; T022 revisa el ciclo antes de aceptar T008/T009. Las pruebas de 003 y su aceptación Web son procedencia, no sustituyen evidencia nativa de 002 ni prueban toque físico.

V4 permite iOS Simulator autorizado, con interacción sobre su UI y método/estado registrados según [quickstart](../quickstart.md); hardware iOS queda no probado. El rendimiento SC-007 sigue requiriendo medición física y revisión QA. El 2026-10-16, tras registrar que el Xiaomi 11T Pro (`2107113SG`, 2021) queda fuera de la referencia nominal global, la persona lo designó como referencia provisional exclusivamente para aceptar 002. La enmienda 1.2.0 de la [constitución](../../../.specify/memory/constitution.md) mantiene 60 FPS estables durante gameplay típico y la referencia nominal global; no aprueba el rendimiento por esta decisión ni exime estabilidad. No se extrapola a otros teléfonos, 003 o iOS. Esta sincronización documental se entrega para QA; admitir simulación en V4 tampoco declara cumplido SC-007.

**Aclaración de método Android, aprobada por QA (2026-10-16)**: V3 conserva el Xiaomi físico para interacción humana y medición. Como subcobertura complementaria autorizada, I1–I4/I9 pueden comprobarse de forma controlada en Android Emulator mediante gestos entregados por el SO a la app visible; ADB solo se dirige al serial verificado del emulador. Se comparan ambas composiciones con el mismo arreglo I4 y se registran método, entorno, coordenadas y estado PRE/POST según [quickstart](../quickstart.md). No invocar gameplay ni inyección interna de Godot como sustituto del gesto. Los resultados AVD se separan de GUT, ratón PC, toque humano Xiaomi y gesto iOS Simulator; no sustituyen cobertura física ni certifican SC-007. Esta aclaración no declara ningún caso superado ni cambia fuentes, mecánicas, los 18 IDs originales o la adenda T019–T022.
