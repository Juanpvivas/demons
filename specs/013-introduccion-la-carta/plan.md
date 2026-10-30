# Implementation Plan: La carta

**Feature ID**: `013-introduccion-la-carta` | **Planned Branch**: `codex/013-introduccion-la-carta` | **Date**: 2026-10-30 | **Spec**: [spec.md](spec.md)

**Input**: Preparación `demons-preparation`; ejecución posterior por [roles](../../docs/DEVELOPMENT_WORKFLOW.md), sin `speckit-implement`.

**Seguimiento**: [Issue #53](https://github.com/Juanpvivas/demons/issues/53).
I1/R2 conservan sus aprobaciones históricas. R3 prepara el único cambio de
comportamiento del prompt final y la incorporación de la toma humana elegida
en T026, con gate propio T027–T036. Publicación T014 sigue pendiente.

**Revisión actual 013-I1-R2**: I1 ya tiene T012 aprobado y PR #54 en borrador.
T015–T025 preparan y entregan cuatro correcciones con voz preview provisional;
T026 incorpora la grabación humana al recibirla. No reabren ni
reinician T001–T014. La nueva revisión necesita su propio RED/GREEN/QA/CI.

La sección R2 conserva su planificación histórica; para el alcance actual
prevalece la enmienda R3 siguiente. No reiniciar tareas aprobadas ni la
preferencia narrativa `la_carta_v1`.

## Enmienda vigente R3

- Medio recibido/elegido: `toma-3.wav`. Root segmenta siete clips conservando
  frases completas y proporciona metadatos técnicos temporales; dev incorpora
  sólo WAVs y SOURCES portable. El compañero no está en la grabación: conservar
  su único clip Ald provisional con atribución distinta. La aprobación perceptual
  ya es humana; no exigir otra ni simular escucha del agente. T026 se verifica
  proporcionalmente por integridad/texto/duración/reproducción/mezcla técnica,
  sin RED artificial sobre medios.
- Único comportamiento UI: show_start_prompt usa la franja inferior segura
  de controles para un solo botón Comenzar de estilo equivalente y mínimo 52 px
  de alto, sin panel/banda de fondo. Ocultar subtítulo, Pausar/Omitir y todo
  texto extra; última imagen visible limpia. Ambas rutas esperan gesto nuevo,
  sin audio residual. GameRoot usa sólo la API/señal pública, sin conocer nodos
  privados del layout.
- Reutilizar interfaces actuales, sin setup nuevo. Tester demuestra RED de
  posición/visibilidad/limpieza/gesto antes de dev; GREEN/regresión y export Web
  de una única revisión de QA, luego QA funcional, docs, CI exacto, QA integración
  y actualización del mismo PR #54 borrador con Refs #53. No cambiar releases,
  balance, destinos o gates de publicación; mantener ambiente y menú activo.

## Summary

IntroPlayer reproduce siete cuadros/voz/textos sin partida activa. GameRoot elige primera introducción, partida directa o replay; sólo crea nivel al aceptar el inicio correspondiente.

## Technical Context

**Language/Version**: GDScript / Godot4.x vigente (local4.7.1).  
**Primary Dependencies**: Control/TextureRect, AudioStreamPlayer, Tween, señales, Theme existentes; sin plugin runtime nuevo.  
**Storage**: ConfigFile bajo `user://`, con versión narrativa y escritura comprobada.  
**Testing**: GUT/`tools/ci/run_gut.py`, visual/input/escucha, import/export y CI vigentes.  
**Target Platform**: Web sólo navegador de computador; apps Android/iOS instaladas, simulador nativo cuando proceda.  
**Project Type**: Juego2D compartido; PC nativo sólo desarrollo/pruebas.  
**Performance Goals**: Conservar objetivo60FPS constitucional; comparar carga/coste disponible sin certificar físicos desde software.  
**Constraints**: Recursos offline, sin combate durante intro, sin nueva música ni cambios de renderer/presets/releases.  
**Scale/Scope**: 013-I1: siete imágenes, siete narraciones y un clip de compañero, recuerdo local, dos rutas.

## Constitution Check

- I: Resources de presentación inmutables separados del reproductor; sin balance ni autoload nuevo; señales a GameRoot.
- II: Setup neutral→tester RED→QA RED→dev→tester GREEN→QA→documentación. Arte/voz con revisión proporcional.
- III: Semántica mouse/teclado/toque coherente, texto/controles adaptables y ficción respetuosa.
- IV: Sin efectos costosos; comparar importación/carga y conservar límites físicos.
- V: Integración y publicación separados; PR borrador sin promoción/merge/distribución automática. Pendientes004/005 y pausa006 intactos.

**Resultado de diseño**: No requiere excepción constitucional. Check revisado antes y después de diseño; no es veredicto QA.

## Project Structure

```text
specs/013-introduccion-la-carta/
  spec.md plan.md tasks.md research.md data-model.md quickstart.md guion.md
  contracts/intro-flow.md checklists/requirements.md
scenes/ui/IntroPlayer.tscn intro_player.gd
scenes/ui/MainMenu.tscn main_menu.gd
scenes/game/game_root.gd
core/intro_progress.gd
resources/schemas/intro_slide.gd intro_sequence.gd
resources/narrative/la_carta.tres
assets/narrative/la_carta/                    # imágenes, SOURCES
assets/audio/narrative/la_carta/              # WAVs y licencias
tests/unit/ui/test_intro_player.gd
tests/unit/game/test_game_root.gd
tests/unit/systems/test_intro_progress.gd
```

**Structure Decision**: Mantener composición padre/hijo de arquitectura§4.8: IntroPlayer anuncia salida y GameRoot decide destino. Recuerdo inyectable con ruta temporal, sin singleton nuevo. Verificar nombres de escenas existentes antes de editar.

## Diseño y ejecución

1. Contrato neutral importable con firmas/Resources sin reproducción/guardado/conexiones nuevas.
2. RED por comportamiento ausente de reproducción, recuerdo y composición; QA del RED.
3. Dev incorpora los siete PNG originales y WAVs provisionales preparados en temporal, datos y reproductor/menú/raíz. No versionar output/ completo ni prompts con rutas personales.
4. Duración=max(mínimo nominal legible, narrador+compañero+respiración); no recortar audio para alcanzar60s. Fundidos no ocultan subtítulos ni truncan voz.
5. GREEN, regresión y visual/input/escucha/export disponibles→QA funcional→docs→CI→QA integración→PR borrador.

## Complexity Tracking

Sin arquitectura global, motor de diálogo, vídeo prerenderizado o backend. Resource de secuencia/escena y un reproductor bastan.

## Plan de corrección 013-I1-R2

1. Mantener siete PNG/guion hablado e integrar Ald sólo como preview provisional
   mientras se espera la grabación del narrador elegida por la persona.
   Su timbre le gusta, pero lo percibe robotizado: no aprobar voz final/natural
   ni fluidez. T026 sustituye siete narraciones al llegar el archivo humano y,
   si incluye la frase del compañero, también ese clip. Verificar medios/mezcla
   y escucha proporcional sin RED artificial ni exigir ocho tomas humanas.
2. Ambas entradas de intro terminan/omiten en el mismo prompt Comenzar. GameRoot
   acepta un gesto nuevo para crear un nivel; conserva reentrada/generación,
   persistencia por versión y Retry directo. No autoarranque ni retorno al menú.
3. Retirar de las imágenes contador, aviso de ficción y captions. Mantener
   subtítulos hablados/controles; identidad ficticia/procedencia queda fuera de
   las imágenes. Conservar cuadros y encuadres, sin repintarlos.
4. Añadir `ambience: AudioStream` y `ambience_volume_db: float` a IntroSequence,
   con reproductor no posicional independiente de Voice. El loop/volumen se
   autoran con el ambiente original entregado por root; ambos canales comparten
   pausa/foco/cierre y ninguno persiste tras fin/omisión. No motor de síntesis,
   streaming o música nuevos.
5. HUD añade botón visible Menú principal durante PLAYING/PAUSED. Reutilizar
   `menu_requested`→nivel→GameRoot y extender sólo destino menú a estados activos;
   Retry sigue restringido a terminal. Cierre común cancela oleadas, audio,
   inputs, pools y generación antes de retirar nivel y restaurar menú. Evitar
   click-through/doble cierre; sin modal ni guardado de partida.

Rutas adicionales: `scenes/ui/HUD.tscn`, `scenes/ui/hud.gd`,
`scenes/levels/nivel_monte_calvo.gd`, fixtures pertinentes de HUD/nivel/raíz y
assets de ambiente/licencia. Las APIs existentes y observación segura de nodos
permiten RED por aserción sin setup neutral nuevo. RED de layout, destino,
ambiente y retorno activo precede implementación. Comprobar escucha/mezcla y las
siete imágenes en los entornos disponibles; no heredar aprobación perceptual
de I1 ni ampliar campaña de rendimiento/publicación. El archivo humano es
dependencia externa de T026/SC-009; su ausencia permite entregar las cuatro
correcciones y la integración técnica provisional con ese límite explícito.
