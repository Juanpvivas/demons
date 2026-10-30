# Implementation Plan: La carta

**Feature ID**: `013-introduccion-la-carta` | **Planned Branch**: `codex/013-introduccion-la-carta` | **Date**: 2026-10-30 | **Spec**: [spec.md](spec.md)

**Input**: Preparación `demons-preparation`; ejecución posterior por [roles](../../docs/DEVELOPMENT_WORKFLOW.md), sin `speckit-implement`.

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
