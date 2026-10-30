# Feature Specification: La carta — introducción narrativa

**Feature ID**: `013-introduccion-la-carta`  
**Planned Branch**: `codex/013-introduccion-la-carta`  
**Created**: 2026-10-30  
**Status**: Preparación para revisión independiente  
**Input**: Integrar el guion y las siete imágenes de La carta. La persona confirmó mostrarla automáticamente sólo la primera vez al pulsar Jugar, repetirla desde el menú e incluir voz provisional en la primera entrega.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Escuchar la carta (Priority: P1)

Como jugador quiero conocer al soldado y sus compañeros mediante imágenes, narración y subtítulos antes de combatir.

**Why this priority**: Hace visible la inspiración humana del juego.

**Independent Test**: Reproducir las siete escenas en orden, pausar/continuar y omitir sin combate simultáneo.

**Acceptance Scenarios**:

1. **Given** una introducción abierta, **When** avanza normalmente, **Then** presenta las siete escenas de [guion.md](guion.md), con imágenes, voz provisional y subtítulos concordantes.
2. **Given** una frase en curso, **When** se pausa o la app pierde actividad, **Then** voz, movimiento y avance se detienen; recuperar actividad no reanuda hasta Continuar.
3. **Given** cualquier escena, **When** se omite, **Then** se detiene audio/animación y se acepta una sola salida hacia el destino de apertura.

### User Story 2 - Primera partida y siguientes (Priority: P1)

Como jugador quiero escuchar la carta la primera vez y acceder directamente a partidas posteriores.

**Why this priority**: Presenta la historia sin retrasar cada intento.

**Independent Test**: Con recuerdo temporal aislado, Jugar→intro→final/omisión→Comenzar→partida; reiniciar y volver a Jugar.

**Acceptance Scenarios**:

1. **Given** que esta versión no fue vista/omitida localmente, **When** se pulsa Jugar, **Then** aparece la introducción sin nivel ni oleadas activos.
2. **Given** esa introducción, **When** finaliza o se omite, **Then** aparece Comenzar y sólo un gesto nuevo inicia exactamente una partida.
3. **Given** recuerdo válido de finalización/omisión, **When** se vuelve a Jugar incluso tras reiniciar, **Then** se entra directamente a la partida.
4. **Given** resultado de partida, **When** se pulsa Reintentar, **Then** se inicia directamente otra partida.
5. **Given** error al guardar, **When** termina/omite la carta, **Then** se permite Comenzar sin afirmar guardado exitoso; otra apertura puede ofrecerla de nuevo.

### User Story 3 - Volver a verla (Priority: P2)

Como jugador quiero volver a escuchar la carta voluntariamente desde el menú sin iniciar combate.

**Why this priority**: Mantiene disponible la historia después de la primera vez.

**Independent Test**: Ver introducción→final/omisión→menú, sin crear nivel.

**Acceptance Scenarios**:

1. **Given** el menú, **When** se pulsa Ver introducción, **Then** se reproduce desde la primera escena con independencia del recuerdo.
2. **Given** esa repetición, **When** termina o se omite, **Then** vuelve al menú con controles/foco restaurados, sin comenzar partida.

### Edge Cases

- Doble toque, emulación touch/mouse y final simultáneo con Omitir no duplican salida ni partidas.
- Callbacks/audio de reproducciones cerradas no afectan otras reproducciones o niveles.
- Cierre a mitad de carta no registra finalización. Recuerdo ausente, corrupto o de otra versión equivale a no visto sin borrar progreso ajeno.
- El gesto de Comenzar/Omitir no llega al tablero recién creado.
- Resize y áreas seguras mantienen subtítulos completos y controles alcanzables.
- Si el audio no puede reproducirse, los subtítulos/controles permiten continuar u omitir sin bloqueo.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Presentar siete imágenes en el orden y con el texto exacto de [guion.md](guion.md), conservando identidad del protagonista y estilo del storyboard.
- **FR-002**: Incluir voz provisional en español, incluida intervención del compañero en escena6; archivos locales disponibles offline y reemplazables, sin atribuir voz/carta a veterano real.
- **FR-003**: Usar fundidos y movimientos lentos de encuadre con subtítulos legibles y rótulos del guion; cada duración permite escuchar clips completos y leer el texto. El minuto del guion es orientativo.
- **FR-004**: Ofrecer Pausar, Continuar y Omitir con ratón/teclado/toque según destino; pausa manual o pérdida de actividad detiene tiempo, audio y movimiento hasta Continuar explícito.
- **FR-005**: Después de Jugar, ofrecer automáticamente la carta sólo si esta versión no está registrada como completada u omitida.
- **FR-006**: Tras final/omisión desde Jugar, mostrar Comenzar sin nivel/oleadas hasta un nuevo gesto explícito.
- **FR-007**: Recordar finalización u omisión local por versión narrativa; lectura inválida se trata como no visto y escritura fallida no bloquea jugar ni falsea guardado.
- **FR-008**: Añadir Ver introducción al menú; desde esa ruta terminar/omitir vuelve al menú, sin iniciar partida.
- **FR-009**: Conservar Jugar directo tras recuerdo y Reintentar directo, con exactamente un nivel por inicio aceptado.
- **FR-010**: Consumir gestos, proteger reentrada y cancelar audio/tweens/callbacks de una reproducción al cerrarla.
- **FR-011**: Adaptar imágenes, texto y controles a tamaños/áreas seguras y conservar foco visible y subtítulos completos.
- **FR-012**: Mantener balance, cinco carriles, renderer y releases; 006 sigue pausada y publicación004/005 pendiente.
- **FR-013**: Identificar carta/personajes como ficción inspirada en el contexto histórico y registrar procedencia/licencia de imágenes y audio, sin citas históricas inventadas.

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
- **SC-004**: Ver introducción empieza en escena1 y vuelve al menú tras final/omisión sin crear nivel; Reintentar conserva inicio directo.
- **SC-005**: Pausa manual y pérdida de actividad detienen voz/tiempo/movimiento; Continuar retoma sin saltos ni voces solapadas y salir silencia la reproducción anterior.
- **SC-006**: Controles/subtítulos son utilizables y legibles en las relaciones de pantalla verificadas para Web de computador y apps Android/iOS; destinos no disponibles se declaran separados.
- **SC-007**: Pruebas de comportamiento/regresión, importación/exportación y CI no tienen fallos atribuibles al alcance; QA independiente emite el gate de integración con límites explícitos.
- **SC-008**: Antes de distribuir se verifican paquete/renderer/versión/firma, instalación/smoke y 60FPS físicos aplicables, QA de publicación y autorización explícita. Integración no acredita este criterio.

## Assumptions

- Guion e imágenes son entradas aceptadas. Primera entrega incluye voz sintética provisional sin prometer interpretación definitiva ni música nueva.
- La apertura automática ocurre tras Jugar, como se confirmó, para iniciar audio desde un gesto.
- La repetición voluntaria es acceso narrativo desde menú, separado de Jugar.
- Recuerdo por instalación/almacenamiento del navegador; no cuenta, backend, sincronización ni permisos nuevos.
- Conservar originales `output/`; copiar sólo recursos finales a producción. No consumir excepciones beta anteriores ni certificar hardware desde simulación.
