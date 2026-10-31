# Feature Specification: La carta — introducción narrativa

**Feature ID**: `013-introduccion-la-carta`  
**Planned Branch**: `codex/013-introduccion-la-carta`  
**Created**: 2026-10-30  
**Status**: Implementación integrada en `main` por PR #54 (`77be629`), con sus aprobaciones de integración conservadas. Narrador humano toma3 y compañero sintético definitivo aceptados por la persona; publicación T014 pendiente

**Tracking**: [PR #54 fusionado](https://github.com/Juanpvivas/demons/pull/54); [Issue #53](https://github.com/Juanpvivas/demons/issues/53) abierto por publicación
**Input**: Integrar el guion y las siete imágenes de La carta. La persona confirmó mostrarla automáticamente sólo la primera vez al pulsar Jugar, repetirla desde el menú e incluir voz provisional en la primera entrega.

**Revisión autorizada 013-I1-R2**: voz claramente masculina, final/omisión de
ambas rutas hacia Comenzar y después partida, imágenes sin textos superiores,
ambiente original de fondo y botón Menú principal durante combate. La persona
confirmó conservar Comenzar: nunca hay inicio automático al acabar la carta.
Los requisitos siguientes describen esta revisión; no atribuyen su cumplimiento
a los veredictos de I1 ni alteran los estados históricos T001–T014.

**Actualización de voz confirmada**: la persona acepta el timbre de Ald pero
lo percibe robotizado y ha elegido leer el guion. Se avanza con las otras
cuatro correcciones y Ald sólo como preview provisional. La grabación humana
del narrador y su incorporación/escucha final quedan en T026/SC-009, pendientes
del archivo externo; no es una ambigüedad de diseño ni bloquea esa entrega parcial.
La frase del compañero puede grabarse si la persona la incluye; su toma humana
no es requisito para aceptar la narración humana de los siete párrafos.

**Actualización R3 vigente**: la persona entregó y eligió explícitamente
`toma-3.wav`, autorizando usar su grabación para las siete narraciones. La
aceptación perceptual de esa toma corresponde a la persona: no se pide una
nueva aprobación del timbre ni se atribuye escucha propia al agente. T026 pasa
a incorporación y verificación técnica proporcional. No hay toma humana del
compañero: su único clip Ald se conserva como provisional y no se atribuye a la
persona. El único comportamiento nuevo es el prompt final: sólo Comenzar,
centrado abajo en la franja segura de controles, sin panel/banda de fondo,
títulos, ficción, subtítulos ni otros controles; última imagen limpia visible.
Las notas de espera de archivo en R2 son históricas y no son un bloqueo actual.

R3 implementado y aprobado funcionalmente en T032: siete WAV humanos locales,
compañero provisional separado y prompt inferior limpio. La imagen conserva
opacidad/encuadre durante la espera y resize; no se reactiva la reproducción.
T026/SC-009 quedan aprobados en ese alcance técnico y de elección humana, sin
atribuir escucha propia a los agentes ni certificar plataformas/publicación.

**Enmienda vigente R4**: sustituir únicamente `companero_06.wav` por el candidato
sintético masculino expresivo que prepara root, con la misma frase «Compañero.
Ya es hora.». Es trabajo de medio/arte sin lógica nueva: no cambia las siete
narraciones humanas, guion, montaje, controles, ambiente o recuerdo. Se verifica
recurso/procedencia/importación/reproducción/tiempo e integridad; la naturalidad
de la candidata queda pendiente de escucha humana y no se aprueba desde
metadatos o una escucha fingida del agente. El compañero sigue sintético y no
se atribuye a quien grabó toma3. Las descripciones Ald anteriores son historia.

El clip incorporado se generó con Qwen3-TTS VoiceDesign sin referencia
de audio ni clonación; su procedencia/licencia consta en
[SOURCES](../../assets/audio/narrative/la_carta/SOURCES.md). T040 aprueba su
integración técnica. Posteriormente, la persona aceptó ese mismo archivo como
voz definitiva del compañero; la aceptación perceptual queda registrada en
SOURCES para su SHA256, sin atribuir audición al agente. Las frases anteriores
de candidata/espera describen la preparación histórica, no el estado vigente.

### Historia conservada de I1

I1 usaba voz Piper es_MX-claude-high, contadores/rótulos/aviso superior y replay
que volvía al menú. Tenía acceso al menú desde resultado y no ambiente de fondo.
Las aprobaciones previas se limitan a ese alcance y sus límites. La corrección
de la voz responde a la percepción de la persona de que sonaba femenina;
la nueva revisión requiere escucha perceptual, no basta la etiqueta del modelo.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Escuchar la carta (Priority: P1)

Como jugador quiero conocer al soldado y sus compañeros mediante imágenes, narración y subtítulos antes de combatir.

**Why this priority**: Hace visible la inspiración humana del juego.

**Independent Test**: Reproducir las siete escenas en orden, pausar/continuar y omitir sin combate simultáneo.

**Acceptance Scenarios**:

1. **Given** una introducción abierta, **When** avanza normalmente, **Then** presenta las siete escenas de [guion.md](guion.md), con imágenes, voz provisional y subtítulos concordantes.
2. **Given** una frase en curso, **When** se pausa o la app pierde actividad, **Then** voz, movimiento y avance se detienen; recuperar actividad no reanuda hasta Continuar.
3. **Given** cualquier escena, **When** se omite, **Then** se detiene audio/animación y se acepta una sola salida hacia el destino de apertura.
4. **Given** la entrega parcial R2, **When** se reproduce la carta, **Then** admite voz Ald provisional con ambiente discreto, sin declararla voz definitiva, natural o de fluidez aprobada; al recibirse la grabación humana se sustituye y verifica en T026.
5. **Given** cualquiera de las siete imágenes, **When** se observa la interfaz, **Then** sólo aparecen subtítulos de voz y controles; no hay contador, aviso de ficción ni rótulos superiores.

### User Story 2 - Primera partida y siguientes (Priority: P1)

Como jugador quiero escuchar la carta la primera vez y acceder directamente a partidas posteriores.

**Why this priority**: Presenta la historia sin retrasar cada intento.

**Independent Test**: Con recuerdo temporal aislado, Jugar→intro→final/omisión→Comenzar→partida; reiniciar y volver a Jugar.

**Acceptance Scenarios**:

1. **Given** que esta versión no fue vista/omitida localmente, **When** se pulsa Jugar, **Then** aparece la introducción sin nivel ni oleadas activos.
2. **Given** esa introducción, **When** finaliza o se omite, **Then** aparece Comenzar y sólo un gesto nuevo inicia exactamente una partida.
   En R3 ese botón es el único control/texto visible, centrado abajo en la franja
   segura, con estilo de Pausar/Omitir y alto mínimo de 52 px; no hay panel
   central, banda de fondo, subtítulo o audio residual.
3. **Given** recuerdo válido de finalización/omisión, **When** se vuelve a Jugar incluso tras reiniciar, **Then** se entra directamente a la partida.
4. **Given** resultado de partida, **When** se pulsa Reintentar, **Then** se inicia directamente otra partida.
5. **Given** error al guardar, **When** termina/omite la carta, **Then** se permite Comenzar sin afirmar guardado exitoso; otra apertura puede ofrecerla de nuevo.

### User Story 3 - Volver a verla (Priority: P2)

Como jugador quiero volver a escuchar la carta voluntariamente y poder comenzar una partida al terminar.

**Why this priority**: Mantiene disponible la historia después de la primera vez.

**Independent Test**: Ver introducción→final/omisión→Comenzar→partida, sin nivel antes de ese gesto nuevo.

**Acceptance Scenarios**:

1. **Given** el menú, **When** se pulsa Ver introducción, **Then** se reproduce desde la primera escena con independencia del recuerdo.
2. **Given** esa repetición, **When** termina o se omite, **Then** muestra Comenzar sin volver al menú ni crear nivel automáticamente; un gesto nuevo inicia una partida.

### User Story 4 - Volver al menú durante la partida (Priority: P1)

Como jugador quiero un botón visible para salir al menú mientras juego, sin tener que esperar a ganar o perder.

**Why this priority**: Permite abandonar el intento actual con una salida clara y reutilizar el menú.

**Independent Test**: Durante PLAYING y PAUSED, pulsar Menú principal: la partida se retira, vuelve el menú y no quedan oleadas/audio/controles activos del intento.

**Acceptance Scenarios**:

1. **Given** una partida activa o pausada, **When** se pulsa Menú principal, **Then** el intento se cierra una sola vez y vuelve el menú, sin modal ni guardado de partida.
2. **Given** el regreso al menú, **When** se pulsa Jugar, **Then** comienza un intento limpio respetando el recuerdo de la carta; resultado y Reintentar conservan sus rutas actuales.

### Edge Cases

- Doble toque, emulación touch/mouse y final simultáneo con Omitir no duplican salida ni partidas.
- Callbacks/audio de reproducciones cerradas no afectan otras reproducciones o niveles.
- Cierre a mitad de carta no registra finalización. Recuerdo ausente, corrupto o de otra versión equivale a no visto sin borrar progreso ajeno.
- El gesto de Comenzar/Omitir no llega al tablero recién creado.
- Resize y áreas seguras mantienen subtítulos completos y controles alcanzables.
- Si el audio no puede reproducirse, los subtítulos/controles permiten continuar u omitir sin bloqueo.
- Salir al menú durante combate invalida callbacks del intento y cancela oleadas, entradas, audio y pools antes de crear otro nivel.
- Ambiente y voz no se acumulan al repetir la carta; ambos pausan y cesan al omitir, terminar o cerrar.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Presentar siete imágenes en el orden y con el texto exacto de [guion.md](guion.md), conservando identidad del protagonista y estilo del storyboard.
- **FR-002**: Incorporar las siete narraciones de `toma-3.wav`, recibida y elegida por la persona, con texto completo, duraciones y reproducción/mezcla técnicamente comprobadas. La aceptación perceptual procede de esa elección humana, sin pedirla de nuevo ni atribuir audición al agente. El compañero es un clip sintético identificado como tal, separado de la persona; todos son recursos offline reemplazables, no testimonios históricos.
- **FR-003**: Usar fundidos y movimientos lentos de encuadre con subtítulos de voz legibles; cada duración permite escuchar clips completos y leer el texto. El minuto del guion es orientativo. Rótulos del guion original no se muestran en R2.
- **FR-004**: Ofrecer Pausar, Continuar y Omitir con ratón/teclado/toque según destino; pausa manual o pérdida de actividad detiene tiempo, audio y movimiento hasta Continuar explícito.
- **FR-005**: Después de Jugar, ofrecer automáticamente la carta sólo si esta versión no está registrada como completada u omitida.
- **FR-006**: Tras final/omisión desde Jugar o Ver introducción, mostrar Comenzar sin nivel/oleadas hasta un nuevo gesto explícito, sin retorno automático al menú.
- **FR-007**: Recordar finalización u omisión local por versión narrativa; lectura inválida se trata como no visto y escritura fallida no bloquea jugar ni falsea guardado.
- **FR-008**: Ver introducción reproduce desde escena1 independientemente del recuerdo y, al terminar/omitir, enlaza con partida únicamente mediante Comenzar.
- **FR-009**: Conservar Jugar directo tras recuerdo y Reintentar directo, con exactamente un nivel por inicio aceptado.
- **FR-010**: Consumir gestos, proteger reentrada y cancelar audio, avance, animación y callbacks de una reproducción al cerrarla.
- **FR-011**: Adaptar imágenes, texto y controles a tamaños/áreas seguras y conservar foco visible y subtítulos completos.
- **FR-012**: Mantener balance, cinco carriles, renderer y releases; 006 sigue pausada y publicación004/005 pendiente.
- **FR-013**: Identificar carta/personajes como ficción inspirada en el contexto histórico y registrar procedencia/licencia de imágenes y audio, sin citas históricas inventadas.
- **FR-014**: Añadir ambiente original discreto offline, separado de la voz, que pause/continúe con la introducción y se detenga al terminar, omitir o cerrar, sin solaparse en aperturas posteriores ni tapar la narración.
- **FR-015**: Mostrar Menú principal durante PLAYING y PAUSED, con salida directa segura al menú que cierre el intento/oleadas/audio/entradas/pools una vez; conservar resultado y Reintentar, sin modal, persistencia de partida ni cambios de balance.
- **FR-016**: Durante las siete imágenes mostrar únicamente subtítulos de voz y controles, sin contador La carta/índice, captions de lugar/época ni aviso de ficción superior. La identificación de ficción y procedencia permanece en documentación/créditos fuera de las imágenes.
- **FR-017**: Al terminar u omitir desde cualquiera de las dos entradas, mostrar sólo Comenzar centrado abajo, en la misma franja segura/estilo de Pausar/Omitir y mínimo 52 px de alto. Mantener última imagen visible limpia, sin panel central, banda de fondo, títulos/ficción/rótulos, subtítulo, Pausar/Omitir ni audio de voz/ambiente residual. Conservar foco/resize y exigir un gesto nuevo para iniciar exactamente un nivel.
- **FR-018**: R4 reemplaza sólo el archivo del compañero por el clip sintético masculino expresivo preparado/autorizado para esa frase, con procedencia portable y verificación proporcional de importación/carga, hash, duración, ausencia de saturación y reproducción completa. La persona aceptó ese mismo archivo como voz definitiva; registrar la aceptación humana sin atribuir escucha al agente ni modificar runtime, guion/montaje o narrador humano.

### Key Entities

- **Escena**: imagen, narración, texto y encuadre; siete ordenadas.
- **Versión narrativa**: contenido cuya lectura se recuerda.
- **Reproducción**: índice/tiempo/pausa y salida de una apertura concreta.
- **Recuerdo local**: finalización u omisión de una versión, sin sincronización ni progreso jugable.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Se ven siete escenas y se escuchan completas siete narraciones y la intervención del compañero, con subtítulos concordantes y sin combate simultáneo.
- **SC-002**: Final y omisión del primer Jugar llevan una sola vez a Comenzar; únicamente otro gesto inicia exactamente una partida.
- **SC-003**: Tras final/omisión y reinicio con almacenamiento disponible, Jugar entra directamente; recuerdo nuevo/corrupto/de otra versión vuelve a ofrecer la carta.
- **SC-004**: Ver introducción empieza en escena1 y tras final/omisión muestra Comenzar; sólo otro gesto inicia exactamente un nivel. No vuelve al menú al finalizar y Reintentar conserva inicio directo.
- **SC-005**: Pausa manual y pérdida de actividad detienen voz/tiempo/movimiento; Continuar retoma sin saltos ni voces solapadas y salir silencia la reproducción anterior.
- **SC-006**: Controles/subtítulos son utilizables y legibles en las relaciones de pantalla verificadas para Web de computador y apps Android/iOS; destinos no disponibles se declaran separados.
- **SC-007**: Pruebas de comportamiento/regresión, importación/exportación y CI no tienen fallos atribuibles al alcance; QA independiente emite el gate de integración con límites explícitos.
- **SC-008**: Antes de distribuir se verifican paquete/renderer/versión/firma, instalación/smoke y 60FPS físicos aplicables, QA de publicación y autorización explícita. Integración no acredita este criterio.
- **SC-009**: Las siete narraciones proceden de la `toma-3.wav` autorizada y elegida por la persona, con texto íntegro, duración sin cortes y reproducción/mezcla técnicamente comprobadas. Timbre/fluidez se sustentan en la elección perceptual humana ya dada, no en una audición propia del agente. T026 conserva su aprobación R3; el único compañero sintético identificado permanece separado y su sustitución R4 no reabre la aceptación del narrador.
- **SC-010**: En las siete imágenes no hay ningún contador, caption o aviso superior; permanecen completos los subtítulos de voz y los controles.
- **SC-011**: Menú principal es visible durante partida activa/pausada y vuelve al menú con cero niveles/oleadas/audio/controles del intento anterior; pulsaciones repetidas no duplican cierre o nuevos niveles.
- **SC-012**: En final natural y omisión de ambas entradas sólo se ve Comenzar centrado abajo, alto mínimo 52 px y estilo/franja segura de los controles previos, con última imagen visible y sin panel/banda central o inferior, textos/controles extra ni audio residual. Resize conserva su alcance/foco; sin gesto nuevo no se crea nivel y varias pulsaciones crean sólo uno.
- **SC-013**: El compañero de escena6 usa el archivo R4 con hash/procedencia concordantes, frase completa, carga/importación sin errores, duración compatible con el montaje vigente y sin saturación del PCM. Las siete narraciones, texto/montaje, UI, ambiente y recuerdo permanecen idénticos; la aceptación perceptual definitiva de ese clip es la decisión humana explícita registrada en SOURCES, no una audición del agente.

## Assumptions

- Guion hablado e imágenes son entradas aceptadas. R3 incorpora toma humana recibida/elegida para siete narraciones y mantiene un compañero Ald provisional y ambiente original, sin música nueva ni cambio de versión narrativa.
- La apertura automática ocurre tras Jugar, como se confirmó, para iniciar audio desde un gesto.
- La repetición voluntaria es acceso narrativo desde menú, separado de Jugar.
- Recuerdo por instalación/almacenamiento del navegador; no cuenta, backend, sincronización ni permisos nuevos.
- Conservar originales `output/`; copiar sólo recursos finales a producción. No consumir excepciones beta anteriores ni certificar hardware desde simulación.
