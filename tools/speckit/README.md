# Preset del proyecto: demons-agent-tdd

La fuente editable de las personalizaciones está en
[`presets/demons-agent-tdd/`](presets/demons-agent-tdd/), fuera de los archivos
que Spec Kit actualiza. El preset está instalado con prioridad 5 y proporciona
10 comandos y 3 plantillas. Mantiene **Spec Kit para preparación** y
**agentes para ejecución con TDD**, según
[DEVELOPMENT_WORKFLOW.md](../../docs/DEVELOPMENT_WORKFLOW.md).

El workflow complementario tiene un ID propio, `demons-preparation`, y su
fuente es [`workflows/demons-preparation/workflow.yml`](workflows/demons-preparation/workflow.yml).
Solo contiene Specify → Plan → Tasks y revisiones; nunca inicia implementación.
Los workflows son paquetes independientes del preset en la CLI utilizada.

## Fuente y archivos generados

| Fuente mantenida en el repositorio | Copia instalada o salida regenerable |
|---|---|
| `tools/speckit/presets/demons-agent-tdd/preset.yml`, `commands/`, `templates/` | `.specify/presets/demons-agent-tdd/` y `.claude/skills/speckit-*/SKILL.md` |
| `tools/speckit/workflows/demons-preparation/workflow.yml` | `.specify/workflows/demons-preparation/workflow.yml` |
| `AGENTS.md`, `CLAUDE.md`, `docs/DEVELOPMENT_WORKFLOW.md`, `.claude/agents/`, `.claude/commands/implementar-feature.md` y memorias | Archivos propios; no son comandos core generados por Spec Kit |

Edita las fuentes, no las skills generadas ni las copias instaladas. Los archivos
instalados se conservan en el repositorio para que la configuración esté disponible
al clonarlo; el verificador detecta diferencias respecto de la fuente editable.
La constitución redactada y `specs/` siguen siendo documentos propios del proyecto.

Las plantillas core en `.specify/templates/` y el workflow bundled `speckit`
se conservan sin nuestras modificaciones. Para el proceso del proyecto usa
**`demons-preparation`**, no el workflow bundled de implementación completa.
La implementación comienza por `/implementar-feature <feature-id>` o por el
orquestador equivalente de otra herramienta.

## Instalar y comprobar

La instalación inicial se verificó con Specify CLI 1.0.1. El **2026-10-15** se
actualizaron la CLI y la integración activa **Claude** a **1.2.0**. El preset
actual es **1.0.2**: conserva la adaptación de `FEATURE_DIR` y la alternativa
`SPECS_DIR` de 1.0.1; las tareas nuevas reportan resultados de validación en el
PR sin añadir archivos de evidencias a Git. El workflow
`demons-preparation` sigue en 1.0.0 y las reglas de agentes con TDD se conservan.
El manifiesto exige `>=1.0.1`; eso no certifica todas las versiones futuras.

Si aún no están instalados, desde la raíz del proyecto:

```bash
specify preset add --dev tools/speckit/presets/demons-agent-tdd --priority 5
specify workflow add tools/speckit/workflows/demons-preparation --dev
```

Comprueba la instalación sin ejecutar una feature:

```bash
python3 tools/speckit/verify.py
specify preset list
specify preset resolve tasks-template
specify workflow resolve demons-preparation
```

El verificador comprueba fuentes frente a copias instaladas, resolución efectiva,
skills materializadas de Claude y workflow. No ejecuta el juego, pruebas GUT,
agentes, workflows o actualizaciones. Por defecto solo lee; otras integraciones
requieren una verificación equivalente antes de considerarlas cubiertas.

## Actualizar Spec Kit

1. Guarda en Git o respalda la configuración actual, incluidas las fuentes de
   `tools/speckit/`, y ejecuta el verificador antes de actualizar.
2. Actualizar únicamente la CLI no modifica este preset del proyecto. Para
   refrescar archivos del proyecto, usa la actualización de integración
   recomendada por Spec Kit y revisa sus mensajes.
3. Al migrar desde la configuración anterior, la CLI puede detectar como cambios
   locales las skills generadas por un preset y detener `integration upgrade
   claude` sin `--force`. En 1.2.0, la actualización vuelve a registrar el preset
   y sincroniza esos hashes de forma nativa; la instalación actual informa cero
   archivos modificados o faltantes. No alteres los hashes de los manifests
   manualmente. Un refresh forzado debe hacerse
   con respaldo y después de comprobar que no hay cambios manuales sin trasladar
   a la fuente; primero puede ensayarse sobre una copia del proyecto.
4. Después del refresh, vuelve a ejecutar `python3 tools/speckit/verify.py`.
   Las plantillas se resuelven mediante el preset, pero las skills son archivos
   materializados. La CLI intenta reactivarlos al actualizar la integración
   activa; hay que confirmar el resultado, no asumir que ocurrió.
   Si cambian los scripts de preparación, contrasta también sus campos JSON
   con los comandos del preset en una copia temporal; la igualdad de las
   fuentes y su resolución no comprueba ese contrato por sí sola.

La actualización a 1.2.0 se ensayó primero en una copia de la configuración.
Además de comprobar las 10 skills, las 3 plantillas y el workflow, se revisaron
los contratos de los scripts de preparación en una copia temporal. No se
ejecutaron agentes de implementación, workflows, Godot ni pruebas del juego.
El verificador también se adaptó al cambio de módulo del resolver de workflows
de 1.2.0, conservando la comprobación con 1.0.1.

Si la fuente y la copia instalada coinciden pero se perdieron las skills
generadas, puedes reaplicar **la copia instalada** explícitamente:

```bash
python3 tools/speckit/verify.py --reapply
```

Esta operación no actualiza la CLI, no modifica el juego ni sincroniza cambios
nuevos de la fuente; vuelve a registrar los comandos del preset para Claude y
los comprueba. Si informa una divergencia o una API incompatible, detente y
revisa el diagnóstico antes de reemplazar archivos.

## Modificar el preset o el workflow

`preset add --dev` **copia** el directorio: editar la fuente no cambia la copia
instalada. Para publicar una nueva revisión local, modifica la fuente, aumenta
su versión y guarda un respaldo. En una copia temporal, valida la reinstalación
y el verificador antes de repetirla en el proyecto real:

```bash
specify preset remove demons-agent-tdd
specify preset add --dev tools/speckit/presets/demons-agent-tdd --priority 5
specify integration upgrade claude --force
specify workflow add tools/speckit/workflows/demons-preparation --dev
python3 tools/speckit/verify.py
```

La retirada/reinstalación es explícita y modifica la configuración activa; no
forma parte de la comprobación ni de `--reapply`. Si falla la instalación,
conserva la fuente y restaura la configuración desde el respaldo. El verificador
no borra ni reinstala presets automáticamente.

En 1.2.0, el refresh de integración después de instalar una nueva fuente vuelve
a registrar el preset y sincroniza nativamente su manifiesto. Evita que una
skill cambiada por la nueva revisión quede marcada como edición manual.

Los 10 comandos y 3 templates usan `replace`: conservarlos al actualizar no
significa incorporar automáticamente cambios nuevos de los comandos core.
Adopta esas novedades mediante una revisión de la fuente y una nueva versión.
Las reglas generales siguen centralizadas en `AGENTS.md` y el flujo compartido.

Referencias: [presets](https://github.github.io/spec-kit/reference/presets.html),
[workflows](https://github.github.io/spec-kit/reference/workflows.html) y
[actualizaciones](https://github.github.io/spec-kit/upgrade.html).
