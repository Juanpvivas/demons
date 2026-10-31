# Validación017 — guía para tester y QA

**Estado**: I1 tiene pruebas aisladas y aprobación funcional del núcleo. Los
escenarios de integración jugable, equilibrio y destinos siguen pendientes para
I2 y publicación. [Plan](plan.md), [contrato](contracts/commander.md),
[modelo](data-model.md). Esta guía no es un registro de ejecución ni acredita
por sí sola GREEN, CI o publicación.

## Preparación antes de ejecutar

1. Generar/analizar `tasks.md`, revisar preparación y autorizar ejecución.
   Orquestador conserva pendientes016, crea/reutiliza un Issue único y prepara
   rama por incremento. I1 ya tiene su rama e Issue #65; I2 no se inicia
   automáticamente por quedar aprobado el núcleo.
2. Cada rol lee su definición en `.claude/agents/` y skills GodotPrompter
   pertinentes. Tester controla RED/GREEN; dev no escribe/ejecuta pruebas;
   QA valida en sólo lectura y sólo orquestador marca tareas tras APROBADO.
3. Confirmar Godot4.7.1, GUT9.7.1 y rutas reales. Si faltan APIs nuevas, preparar
   sólo firmas/campos neutrales mínimos antes de RED, sin implementar conducta.
4. Inyectar semilla, snapshots y almacén transitorio/rutas temporales. Nunca
   escribir o borrar memoria de usuario real, ni `intro_progress.cfg` en pruebas.
   No descargar modelos/SDKs ni ejecutar benchmark016 o campaña006.

## RED → GREEN y oráculos

El tester escribe RED por comportamiento ausente, con importación válida. Las
pruebas existentes de Timer, inicial, composición, terminales, economía y pool
se conservan. Ajustar sólo las aserciones de cursor1→5 cuando ejerciten el nuevo
comandante en I2; I1 no toca ese spawner y el juego conserva el cursor vigente.

| Grupo | Criterio y casos previstos | Spec |
|---|---|---|
| Calendario | aplanar diez Resources reales:99 WAVE,66 A/33 R, orden A,A,R, perfiles y todos los intervalos; primera aparición espera intervalo; inicial inmediato lane2 | SC001 |
| Bloques | semillas0–255,99 selecciones con snapshots fijados;19 permutaciones+4 distintos; continuidad entre oleadas e inicial fuera; nunca un carril ilegal | SC002 |
| Variedad | al menos dos secuencias distintas en ese conjunto; mismas entradas repiten secuencia; cambiar audio/RNG global no cambia selector; cancelar propuesta restaura RNG y no consume carril/ordinal | SC003 |
| Matemática | prior uniforme, m1 obligatorio; scores extremos mantienen p>0, suma≈1 y razón≤5/3; al repetirse señales favorables cambia preferencia y señales contrarias la revierten | SC004 |
| Aprendizaje | r0 y r1 analíticos; primera muestra r1 desde prior da q0.575,n1; muchas muestras de una misma celda en una partida actualizan una sola vez mediante su media; otras celdas sólo olvidan | SC004 |
| Sesión | sólo WON/LOST consolida; cero muestras→sin cambio; abandono/pausa no aprende; memoria de selección congelada; terminal/Retry duplicados son no-op | SC004/005 |
| Orden real | baja que dispara WON registrada antes de notify; cruce WAVE antes de LOST; INITIAL provoca LOST sin muestra propia; generación antigua o señal repetida no cuenta | SC001/005 |
| Censura | vivos al terminar no aportan0 ni1; cleanup no es baja; reward de cruce no depende de X del centro | SC004/005 |
| Disco | slots alternados, lectura de versión/tamaño/hash/rangos, write/flush/relectura fallidos preservan slot previo; conflicto y versión incompatible no se ocultan | SC005 |
| Borrado | cancelar no escribe; éxito persistente elimina ambos slots y neutraliza RAM/reinicio; TRANSIENT sólo neutraliza RAM sin I/O o promesa duradera; fallo explícito y datos de intro intactos; guardas MENU/intro/transición | SC005 |

Los casos analíticos se calculan independientemente del método bajo prueba;
no usar la propia implementación como oráculo. Pruebas de señal/pool y terminal
incluyen cuerpos/sistemas reales, no sólo dobles. Fakes de I/O no acreditan Web.
No crear suites enormes que repitan fórmulas sin comprobar límites o integración.

Comando vigente de regresión, **sólo durante ejecución por tester**:

```sh
python3 tools/ci/run_gut.py --godot /ruta/al/godot-4.7.1
```

El runner ya importa y ejecuta toda `tests/unit`; no sustituir un resumen vacío,
fallos de importación o una salida sin pruebas por GREEN. La CI de la base de I1
(`e8407ec`) añade el guard Python existente; no incluye aún el paso del benchmark016.
No incorporar ese benchmark ni modificar workflows por esta feature salvo
defecto independiente autorizado.

## Playtesting de equilibrio predefinido — I2 pendiente

Los parámetros iniciales del modelo son candidatos de balance, sin aprobación
actual. Con fuente estable y GREEN, aplicar este protocolo antes de integrar
el alcance jugable; no ajustar parámetros entre comparaciones para conseguir PASS.

1. En el entorno funcional elegido, fijar motor/config y semillas42,43,44.
   Mismos controles y contenido de producción; sin invulnerabilidad, economía
   extra, cambios de tiempos o eliminación artificial de enemigos.
2. Dos estilos manuales, con recogida normal de munición y uso normal de recarga:
   **S1** prioriza recargar al soldado agotado cuyo carril tiene el enemigo más
   avanzado, desempate por fila menor; **S2** recarga agotados en rotación1→5,
   saltando hogares no agotados y continuando desde la última recarga.
   El jugador puede recoger y reaccionar normalmente; registrar desviaciones
   sustanciales, no presentar input humano como repetición determinista.
3. Obtener un snapshot acumulado real mediante seis partidas WON/LOST: S1 y S2
   para cada semilla, en orden42/S1,42/S2,43/S1,43/S2,44/S1,44/S2, partiendo neutral.
   Conservar fuera de Git los estados y resultados necesarios para reproducir
   el contexto. Si la memoria no cambió por falta de WAVE cerrados, no fingir
   experiencia acumulada ni reemplazarla por una tabla extrema sintética.
4. Medir12 partidas:3 semillas×2 estilos×2 memorias (neutral/acumulada). Restaurar
   al inicio de cada partida una copia del snapshot correspondiente en un
   almacén de QA; las actualizaciones terminales no contaminan las siguientes.
   Alternar orden neutral/acumulada entre semillas para reducir efecto de práctica.
5. Por condición estilo×memoria exigir al menos una victoria completa entre sus
   tres intentos, sin vulneraciones funcionales ni concentración fuera de bloques.
   Exigir que no haya una respuesta del jugador anulada por cambio retroactivo
   de carril o por violación de tiempos; examinar especialmente la repetición
   permitida entre bloques y el orden de fusileros ante soldados a machete.
6. Si una condición no obtiene victoria, falla esta comprobación de balance:
   devolver a revisión del responsable y repetir el conjunto afectado sólo
   después de un cambio justificado. No cambiar tipos, cantidades o tiempos para
   salvarla. Si el alcance permitido no basta, escalar la decisión de diseño.
7. Documentar resultado, semilla, estilo, snapshot/config, causas de derrota,
   oportunidades de respuesta y anomalías. Es muestra descriptiva: no estima una
   tasa poblacional ni garantiza victoria para todo jugador o estrategia.

Comprobar aparte memoria extrema sintética para límites. No llamarla aprendizaje
real ni usar esas victorias como sustituto de las12 partidas comparables.
No existe un límite adicional de capacidad simultánea por carril autorizado:
si el playtest lo necesita, requiere revisión del diseño, no añadirlo en secreto.

## Matriz funcional y gate — integración jugable/publicación pendientes

En cada destino disponible: primera partida neutral, terminal→Retry con memoria,
abandono sin aprendizaje, cierre/reapertura, borrado confirmado/cancelado/fallido,
pausa y menú, foco/entrada y legibilidad del feedback.

- **Web computador**: identificar navegador/versión/computador/origen. Validar
  recarga real con IndexedDB habilitado y caso sin persistencia; si el destino
  futuro usa iframe, comprobar ese contexto antes de certificarlo. No publicar
  itch.io desde esta guía ni probar navegadores móviles.
- **Android nativo**: app instalada, dispositivo o emulador y renderer declarados.
- **iOS nativo**: app instalada en dispositivo o `.app` de Simulator, sin atribuir
  al IPA físico lo observado en simulador.
- **PC nativo**: desarrollo/regresión; no acredita los destinos anteriores.

Integración requiere GREEN/regresión, compilación/importación, validación
funcional y de equilibrio, CI y APROBADO PARA INTEGRACIÓN por SHA exacto.
QA declara entornos no disponibles y cualquier caída de rendimiento observada.
Simulación/software no certifica hardware, renderer final o60FPS.
Publicación conserva artefacto firmado/versionado, verificación física/60FPS,
APROBADO PARA PUBLICACIÓN y autorización humana; #61/#53 y006 no cambian.

Resultados y veredicto breves irán al PR borrador/CI, con temporales externos
durante ejecución. No crear archivos nuevos de evidencia en Git. El cierre de
I1 no autoriza ejecutar la integración, el playtesting de I2 o publicación.
