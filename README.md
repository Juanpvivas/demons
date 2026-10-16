# Demonios de las Trincheras

[![CI](https://github.com/Juanpvivas/demons/actions/workflows/ci.yml/badge.svg)](https://github.com/Juanpvivas/demons/actions/workflows/ci.yml)

Tower defense / lane defense 2D en Godot 4.x, inspirado en la historia real
del Batallón Colombia en la Guerra de Corea (apodados "los demonios de las
trincheras" por su ferocidad en combate cuerpo a cuerpo tras quedarse sin
munición). Ver `docs/SPEC.md` para el diseño completo del juego y el
contexto histórico.

## Plataformas y publicación

El objetivo es publicar primero una versión **Web jugable en itch.io**,
desde el navegador de un computador o teléfono, conservando **Android e iOS
como aplicaciones nativas**. Se admiten ratón y toque según el dispositivo.
No se prevén instaladores propios para Windows, macOS o Linux; el editor y
la ejecución nativa local en computador siguen siendo herramientas de desarrollo.

La compatibilidad Web se prepara en
[`003-web-itchio`](specs/003-web-itchio/spec.md). Esta decisión de alcance
no significa que ya exista una versión exportada o publicada en el portal.

## Estado actual

La feature `001-soldado-defensor-oleadas` (`specs/001-soldado-defensor-oleadas/`)
está completa: un soldado defensor automático que dispara con fusil mientras
tiene munición y pasa a machete al quedarse sin ella (con daño escalado por
la moral acumulada), una economía de munición (los enemigos derrotados
sueltan munición recolectable, usable para recargar soldados existentes o
desplegar soldados nuevos), y un sistema de oleadas de enemigos crecientes en
dificultad con condiciones de victoria y derrota. Es el primer nivel jugable
de punta a punta del proyecto (`Nivel_MonteCalvo.tscn`).

La primera iteración visual de Monte Calvo está integrada en la feature
[`002-monte-calvo-terreno-trincheras`](specs/002-monte-calvo-terreno-trincheras/evidence/implementation-status.md),
que continúa abierta con validaciones pendientes. El cambio de destinos no
cierra esas tareas ni convierte sus pruebas nativas en pruebas Web.

## Requisitos

- Godot 4.7 (motor MIT, sin regalías).
- El proyecto se abre directamente con `project.godot` en la raíz del repo.
- Para preparar Web se prevé usar Godot estándar y plantillas de exportación
  de la misma versión. El gameplay compartido permanece en GDScript.
  La ruta propuesta usa Compatibility para Web y conserva Mobile para las
  aplicaciones nativas; su implementación y validación pertenecen a 003.

## Documentación del proyecto

| Documento | Contenido |
|---|---|
| [AGENTS.md](AGENTS.md) | Instrucciones compartidas para asistentes de IA y flujo de trabajo |
| [CLAUDE.md](CLAUDE.md) | Punto de entrada de Claude; importa `AGENTS.md` |
| [docs/DEVELOPMENT_WORKFLOW.md](docs/DEVELOPMENT_WORKFLOW.md) | Preparación con Spec Kit, ejecución por agentes y ciclo TDD |
| [tools/speckit/README.md](tools/speckit/README.md) | Preset propio, workflow de preparación y verificación tras actualizar Spec Kit |
| [.specify/memory/constitution.md](.specify/memory/constitution.md) | Principios no negociables (calidad, testing, UX, rendimiento) |
| `docs/SPEC.md` | Diseño del juego: mecánicas, economía, contexto histórico, alcance del MVP |
| `docs/ARCHITECTURE.md` | Convenciones técnicas: estructura de carpetas, nombres, patrones |
| `specs/<feature>/` | Requisitos, plan técnico y tareas de cada feature (Spec Kit) |

## Testing

Los tests automatizados usan **GUT** (Godot Unit Testing), instalado en
`res://addons/gut/` y habilitado en Project Settings → Plugins. Viven en
`res://tests/unit/`, organizados por dominio (`units/`, `enemies/`,
`systems/`, `levels/`) — ver `docs/ARCHITECTURE.md` §6 para la convención
completa y las limitaciones conocidas de correr tests bajo `--headless`.

## Integración continua

Cada push y cada Pull Request disparan `.github/workflows/ci.yml`: corre la
suite GUT completa y valida que el proyecto importa limpio en modo headless.
Un PR con tests rotos o errores de importación queda marcado en rojo, y se
comenta automáticamente en el PR si el pipeline falla. Los issues y PRs
nuevos se etiquetan automáticamente (`.github/workflows/label.yml`) y
reciben un mensaje de bienvenida en su primera contribución
(`.github/workflows/welcome.yml`).

## Builds de prueba

- **Web / itch.io**: preparación en la feature 003; exportación,
  comprobación en navegadores y paquete de publicación todavía pendientes.
  Los pipelines móviles existentes se conservan.
- **Android**: cada push a `main` exporta un APK debug (verificado en
  local: firma correctamente y pasa `apksigner verify`) y lo sube a
  **Firebase App Distribution** (`.github/workflows/deploy-android-testers.yml`).
  Package: `com.juanpvivas.demons`. Los secrets `FIREBASE_ANDROID_APP_ID` y
  `FIREBASE_SERVICE_ACCOUNT` ya están configurados en el repo (Settings →
  Secrets and variables → Actions) — falta confirmar que un run real del
  workflow sube el APK a Firebase con éxito.
- **iOS**: cada push a `main` exporta el proyecto Xcode (Godot;
  verificado en local que genera limpio con Xcode 27 y Team ID
  `XA43X2P8W2`), lo archiva/firma con `xcodebuild` y lo sube a
  **TestFlight** (`.github/workflows/deploy-ios-testflight.yml`) —
  verificado con un run real en CI. El pipeline en sí es 100% automático
  (un push a `main` dispara todo solo), pero la **firma de código es
  Manual, no Automatic**: usa un certificado y un provisioning profile de
  distribución ya creados de antemano (secrets `APPLE_DISTRIBUTION_CERT_P12`
  y `APPLE_DISTRIBUTION_PROVISIONING_PROFILE`), en vez de dejar que Xcode
  los gestione solo en cada corrida. Se eligió así porque la firma
  Automatic en xcodebuild headless insiste en pedir primero un perfil de
  Development (que requiere un dispositivo iOS/iPadOS registrado en la
  cuenta) antes de llegar a la firma de distribución real — ver
  [`deploy-ios-testflight.yml`](.github/workflows/deploy-ios-testflight.yml)
  para el detalle y las fuentes.
  **Mantenimiento pendiente**: el provisioning profile `CI TestFlight
  Distribution` expira el **15 de septiembre de 2027** (vigencia de 1 año,
  normal en Apple). Antes de esa fecha — o si se agrega alguna capability
  nueva a la app (push notifications, etc.) — hay que regenerarlo a mano en
  [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/profiles/list)
  y actualizar el secret `APPLE_DISTRIBUTION_PROVISIONING_PROFILE` (además
  de `PROVISIONING_PROFILE_SPECIFIER` en el workflow, si cambia el nombre
  del perfil).

**Antes de mergear a `main`, subí la versión**: ambos workflows de arriba
fallan a propósito (paso "Verificar que la versión ... cambió desde el
último deploy exitoso") si `export_presets.cfg` no tiene un bump de
`version/code`/`version/name` (Android) o
`application/version`/`application/short_version` (iOS) desde el último
deploy exitoso — no está permitido re-subir el mismo build sin cambiar la
versión. Ver `docs/ARCHITECTURE.md` §7 para el detalle de la política.

## Pipeline de desarrollo

**Spec Kit prepara la especificación, el plan y las tareas; los agentes
implementan, prueban y validan.** El workflow de Spec Kit termina al revisar
las tareas mediante el workflow **`demons-preparation`**. La ejecución pertenece
a `project-orchestrator`, que coordina
`godot-tester` (RED) → `dev-godot` → `godot-tester` (GREEN) → `qa-validator`
→ `docs-writer`. Solo el orquestador marca tareas después de la aprobación
independiente de QA. Para arte o documentación sin lógica nueva, la
verificación se adapta a sus criterios de aceptación.

[AGENTS.md](AGENTS.md) es la entrada compartida y
[docs/DEVELOPMENT_WORKFLOW.md](docs/DEVELOPMENT_WORKFLOW.md) detalla TDD,
dependencias, roles y cierre. Sus definiciones se mantienen en
`.claude/agents/`. En Claude Code se inicia la implementación con
`/implementar-feature <feature-id>`; `speckit-implement` es solo un aviso de
compatibilidad y no ejecuta trabajo. [CLAUDE.md](CLAUDE.md) importa la guía
común. En otras herramientas, usa delegación equivalente y carga `AGENTS.md`
explícitamente si no se descubre automáticamente.

Las personalizaciones de Spec Kit se mantienen como fuente en el preset local
`demons-agent-tdd`, bajo `tools/speckit/`. Sus copias instaladas y las skills
generadas se comprueban con `python3 tools/speckit/verify.py`. Consulta la
[guía de mantenimiento](tools/speckit/README.md) antes de actualizar archivos
del proyecto; los agentes y la guía común permanecen fuera de los archivos core.
