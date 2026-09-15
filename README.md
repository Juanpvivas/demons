# Demonios de las Trincheras

[![CI](https://github.com/Juanpvivas/demons/actions/workflows/ci.yml/badge.svg)](https://github.com/Juanpvivas/demons/actions/workflows/ci.yml)

Tower defense / lane defense 2D en Godot 4.x, inspirado en la historia real
del Batallón Colombia en la Guerra de Corea (apodados "los demonios de las
trincheras" por su ferocidad en combate cuerpo a cuerpo tras quedarse sin
munición). Ver `docs/SPEC.md` para el diseño completo del juego y el
contexto histórico.

## Estado actual

La feature `001-soldado-defensor-oleadas` (`specs/001-soldado-defensor-oleadas/`)
está completa: un soldado defensor automático que dispara con fusil mientras
tiene munición y pasa a machete al quedarse sin ella (con daño escalado por
la moral acumulada), una economía de munición (los enemigos derrotados
sueltan munición recolectable, usable para recargar soldados existentes o
desplegar soldados nuevos), y un sistema de oleadas de enemigos crecientes en
dificultad con condiciones de victoria y derrota. Es el primer nivel jugable
de punta a punta del proyecto (`Nivel_MonteCalvo.tscn`).

## Requisitos

- Godot 4.7 (motor MIT, sin regalías).
- El proyecto se abre directamente con `project.godot` en la raíz del repo.

## Documentación del proyecto

| Documento | Contenido |
|---|---|
| `constitution.md` | Principios no negociables (calidad, testing, UX, rendimiento) |
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

## Pipeline de desarrollo

Este proyecto usa un pipeline de subagentes especializados de Claude Code
(`dev-godot` → `godot-tester` → `qa-validator` → `docs-writer`, coordinados
por `project-orchestrator`). Ver `CLAUDE.md` para el punto de entrada
(`/implementar-feature <feature-id>`) y el flujo completo.
