# Procedencia del preset

Los comandos y las plantillas de este paquete adaptan archivos de
[github/spec-kit](https://github.com/github/spec-kit), distribuidos bajo la
licencia MIT incluida en `LICENSE.spec-kit` (copyright GitHub, Inc.).

La base del proyecto estaba registrada como Spec Kit 0.16.2. Esta primera
versión del preset conserva las personalizaciones acordadas para preparación,
TDD y ejecución por agentes y se verificó con Specify CLI 1.0.1.

Los 10 comandos y 3 templates usan `replace` para conservar sus instrucciones
completas. Una actualización de Spec Kit no fusiona automáticamente novedades
del core en estas copias: revisar y versionar el preset al adoptarlas. Las
reglas compartidas siguen en `AGENTS.md` y `docs/DEVELOPMENT_WORKFLOW.md`, desde
la raíz del proyecto. El preset no instala agentes ni modifica el juego.

## Revisión 1.0.1 — compatibilidad con Spec Kit 1.2.0

`speckit.plan` consume `FEATURE_DIR` del script de planificación actualizado y
conserva `SPECS_DIR` como alternativa para scripts anteriores. No cambia las
reglas de preparación, ejecución por agentes ni TDD. La actualización del
proyecto y la resolución del preset se verificaron con Specify CLI 1.2.0.
