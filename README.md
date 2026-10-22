# Demonios de las Trincheras

[![CI](https://github.com/Juanpvivas/demons/actions/workflows/ci.yml/badge.svg)](https://github.com/Juanpvivas/demons/actions/workflows/ci.yml)

Tower defense / lane defense 2D en Godot 4.x, inspirado en la historia real
del Batallón Colombia en la Guerra de Corea (apodados "los demonios de las
trincheras" por su ferocidad en combate cuerpo a cuerpo tras quedarse sin
munición). Ver `docs/SPEC.md` para el diseño completo del juego y el
contexto histórico.

## Plataformas y publicación

El objetivo es publicar primero una versión **Web jugable en itch.io**,
desde el navegador de un computador, conservando **Android e iOS como
aplicaciones nativas instaladas (APK/IPA)**. Desde el 2026-10-19, por decisión
de la persona, las pruebas Web se limitan a computador; en Android/iOS se
prueban las apps instaladas, también en emulador/simulador cuando corresponda
(APK Android o `.app` nativa de iOS Simulator).
Se admiten ratón y toque según el destino.
No se prevén instaladores propios para Windows, macOS o Linux; el editor y
la ejecución nativa local en computador siguen siendo herramientas de desarrollo.

La feature [`003-web-itchio`](specs/003-web-itchio/spec.md) ya dispone de un
paquete Web revisado localmente, con entrega aceptada por QA en Chrome de
escritorio y Xiaomi horizontal bajo su alcance histórico: generación,
interacción y smoke observados, corroboración visual de producción móvil y
regreso sin recarga observada. Rendimiento sostenido,
carga fría y memoria exclusiva conservan sus límites. Los entornos históricos
no probados mantienen su registro; los navegadores móviles quedan fuera de
las nuevas verificaciones.
El juego no está publicado en el portal. Consulta la
[guía de exportación y estado de validación](docs/WEB_EXPORT.md).

## Estado actual

El incremento conjunto [004-I2](specs/004-personajes-municion-monte-calvo/tasks.md)
y [005-I1](specs/005-cinco-carriles/tasks.md), integrado en `main` mediante el
[PR #24](https://github.com/Juanpvivas/demons/pull/24) (`658dd7e`), incorpora el
enemigo pictórico y un tablero funcional de cinco filas horizontales. Empieza con cinco soldados
cargados en las plazas izquierdas, gratis y con reserva cero; disparan hacia
la derecha y los enemigos avanzan hacia la izquierda. Un inicial en fila 3 y
99 enemigos de oleadas comparten pool, con reparto 1→5 continuo para las oleadas.
La recogida manual conserva su precedencia sobre desplegar/cobrar.

005-I2 está integrado en `main` mediante el
[PR #25](https://github.com/Juanpvivas/demons/pull/25) (`c1f43d2`) y añade salida física con machete. Al agotar las balas, el mismo
soldado avanza a 40 unidades/s hacia un
enemigo frontal de su fila, se detiene para combatir y espera donde está si
no queda ninguno delante. Ambos cuerpos pueden recibir daño y morir; su plaza
sigue reservada mientras viva y queda libre al morir, aunque esté fuera.

005-I3 está integrado en `main` mediante el
[PR #26](https://github.com/Juanpvivas/demons/pull/26) (`8c4cab4`).
Seleccionar una trinchera muestra fila, carga y moral de su dueño vivo, aunque
esté fuera. «Recargar» exige carga cero, fondos y partida activa: cobra una vez,
conserva salud/moral y devuelve al soldado físicamente a 40 unidades/s,
vulnerable y sin atacar hasta llegar. El HUD muestra el regreso y bloquea
órdenes duplicadas.

005-I4 está integrado en `main` mediante el
[PR #27](https://github.com/Juanpvivas/demons/pull/27) (`cffb2ec`).
Añade cinco trincheras con parapetos y personajes laterales: fusil dentro,
marcha/espera con machete, golpe, regreso con fusil bajo y caída orientada.
Las poses observan acciones reales y conservan la geometría y las reglas.
La consolidación I5 está integrada mediante el
[PR #28](https://github.com/Juanpvivas/demons/pull/28); el estado de entrega se mantiene en las
[tareas de 005](specs/005-cinco-carriles/tasks.md).

004-I3, integrado mediante el
[PR #29](https://github.com/Juanpvivas/demons/pull/29), sustituye el bloque
amarillo por una caja oliva con cartuchos. La
última ampliación, aprobada para integración en T049, la aumenta otro 50 %
respecto a la versión con brillo. Conserva el pulso suave de 1,4 s, sin
desaparecer. La envolvente visual máxima es 60×60; conserva radio de recolección
20, valor y precedencia del gesto. Su
[seguimiento](specs/004-personajes-municion-monte-calvo/tasks.md) concentra entrega y PR.
Las features 004/005 y la publicación permanecen abiertas en T039/T071:
esta integración no acredita 60 FPS físicos, renderer
Mobile, hardware ni empaquetado final. Android software mostró una regresión;
iOS software conserva rendimiento muy limitado.
[Alcance y límites](docs/SPEC.md#8-arte-y-estilo-visual).

[006-I1](specs/006-diagnostico-rendimiento/spec.md) incorpora un instrumento
optativo de diagnóstico, aprobado para integración y sin activación en el
juego normal. Las mediciones nuevas no justifican modificar el shader:
Web no distingue una ganancia y Android conserva deriva y límites de
observación. Tres ventanas descriptivas de iPad Simulator con renderizado
software mantienen unos 150–151 ms por frame, sin causa confirmada. Las bases
nativas y la estabilización siguen pendientes en el
[seguimiento de 006](specs/006-diagnostico-rendimiento/tasks.md).

[007 — Menú de inicio y nueva partida](specs/007-menu-inicio-reinicio/spec.md)
implementa el ciclo completo en su rama funcional:

- Al abrir, el menú espera a que pulses «Jugar» para iniciar Monte Calvo.
- Tras ganar o perder, «Volver a jugar» empieza un intento nuevo sin refrescar.
- «Menú principal» permite esperar antes de iniciar otro intento con «Jugar».

Cada intento comienza limpio. El ciclo lógico está aprobado con escenarios de
prueba reducidos; la verificación final visual, por plataforma, de compilación,
rendimiento y CI sigue pendiente. Se conservan los pendientes de 006 y publicación.

La feature `001-soldado-defensor-oleadas` (`specs/001-soldado-defensor-oleadas/`)
está completa: un soldado defensor automático que dispara con fusil mientras
tiene munición y pasa a machete al quedarse sin ella (con daño escalado por
la moral acumulada), una economía de munición (los enemigos derrotados
sueltan munición recolectable, usable para recargar soldados existentes o
desplegar soldados nuevos), y un sistema de oleadas de enemigos crecientes en
dificultad con condiciones de victoria y derrota. Es el primer nivel jugable
de punta a punta del proyecto (`Nivel_MonteCalvo.tscn`).

La primera iteración visual de Monte Calvo está integrada en la feature
[`002-monte-calvo-terreno-trincheras`](specs/002-monte-calvo-terreno-trincheras/tasks.md),
aprobada con 22/22 tareas e integrada en `main` mediante el
[PR #16](https://github.com/Juanpvivas/demons/pull/16). Su
[matriz nativa](specs/002-monte-calvo-terreno-trincheras/evidence/native-validation-matrix.md)
distingue PC, Android e iPad Simulator; la excepción de rendimiento del Xiaomi
es exclusiva de 002 y no certifica Web. La rama 003 incorpora ese cierre sin
convertir las pruebas nativas en pruebas de navegador. Su
[seguimiento propio](specs/003-web-itchio/tasks.md) conserva el alcance aceptado;
el [informe de integración](specs/003-web-itchio/evidence/main-integration.md)
registra el nuevo paquete aprobado por QA desde `7309d8f`, su equivalencia con
la entrega anterior y los límites que se conservan.

## Requisitos

- Godot 4.7 (motor MIT, sin regalías).
- El proyecto se abre directamente con `project.godot` en la raíz del repo.
- Para exportar Web se usa Godot estándar oficial **4.7.1** y templates de
  igual versión. El gameplay compartido permanece en GDScript.
  Compatibility se aplica solo a Web y Mobile se conserva para las apps
  nativas. [Requisitos y procedimiento](docs/WEB_EXPORT.md).

## Documentación del proyecto

| Documento | Contenido |
|---|---|
| [AGENTS.md](AGENTS.md) | Instrucciones compartidas para asistentes de IA y flujo de trabajo |
| [CLAUDE.md](CLAUDE.md) | Punto de entrada de Claude; importa `AGENTS.md` |
| [docs/DEVELOPMENT_WORKFLOW.md](docs/DEVELOPMENT_WORKFLOW.md) | Preparación con Spec Kit, ejecución por agentes y ciclo TDD |
| [tools/speckit/README.md](tools/speckit/README.md) | Preset propio, workflow de preparación y verificación tras actualizar Spec Kit |
| [docs/WEB_EXPORT.md](docs/WEB_EXPORT.md) | Generación del ZIP Web, paquetes identificados, comprobaciones y futura carga manual en itch.io |
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

- **Web / itch.io**: `tools/web/export.sh` genera `build/demons-web.zip` y su
  manifiesto; exportación local, PCK y arranque del ZIP extraído verificados.
  El workflow `export-web.yml` adjunta artefactos sin publicar; la
  [exportación remota anterior](https://github.com/Juanpvivas/demons/actions/runs/38903800209)
  y el [CI anterior](https://github.com/Juanpvivas/demons/actions/runs/38903800369)
  terminaron correctamente antes de integrar el cierre de 002. El paquete
  integrado quedó verificado; consulta los
  [Checks del PR #15](https://github.com/Juanpvivas/demons/pull/15/checks)
  para el CI de cada revisión publicada. Entrada y smoke están aprobados en su
  alcance y QA aceptó la entrega 003; la demo sigue en desarrollo, con las
  mediciones y los entornos no certificados identificados explícitamente.
  [Guía y matriz real](docs/WEB_EXPORT.md).

La constitución [4.0.0](.specify/memory/constitution.md) separa integrar de
publicar: QA funcional, pruebas/build y CI permiten integrar a `main`; compartir
con testers o portales requiere además artefacto/renderer de destino,
certificaciones físicas aplicables y `APROBADO PARA PUBLICACIÓN`. Los guards de
versión se mantienen también en los despachos manuales, sin bypass.

- **Android**: la distribución a **Firebase App Distribution**
  (`.github/workflows/deploy-android-testers.yml`) requiere despacho manual
  desde `main`, confirmación explícita de QA de publicación y autorización
  humana para esa revisión. Un push/merge ya no la inicia. El APK debug se
  verificó históricamente en local con `apksigner verify`; cada artefacto de
  publicación requiere su propia verificación.
  Package: `com.juanpvivas.demons`. Los secrets `FIREBASE_ANDROID_APP_ID` y
  `FIREBASE_SERVICE_ACCOUNT` ya están configurados en el repo (Settings →
  Secrets and variables → Actions) — falta confirmar que un run real del
  workflow sube el APK a Firebase con éxito.
- **iOS**: el pipeline exporta el proyecto Xcode y archiva/firma para
  **TestFlight** (`.github/workflows/deploy-ios-testflight.yml`), con generación
  local y un run real históricos verificados. Su distribución requiere despacho
  manual desde `main`, confirmación de QA de publicación y autorización humana
  para esa revisión; un merge no la inicia. La **firma de código es Manual,
  no Automatic**: usa un certificado y un provisioning profile de
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

**Antes de una distribución autorizada, subí la versión**: ambos workflows
de arriba fallan a propósito (paso "Verificar que la versión ... cambió desde el
último deploy exitoso") si `export_presets.cfg` no tiene un bump de
`version/code`/`version/name` (Android) o
`application/version`/`application/short_version` (iOS) desde el último
deploy exitoso — no está permitido re-subir el mismo build sin cambiar la
versión. Un merge de integración no exige ese bump ni autoriza distribuir.
Ver `docs/ARCHITECTURE.md` §7 para el detalle de la política.

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
