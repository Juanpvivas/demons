# Verificación prevista — 012-I1

Este documento prepara la comprobación del [spec](spec.md) y [contrato](contracts/trench-reload.md); no acredita pruebas ejecutadas. Rama `codex/012-recarga-trinchera`, [Issue #49](https://github.com/Juanpvivas/demons/issues/49). El tester registra comandos/resultados y variantes en temporales/PR, sin nuevos archivos de evidencias en Git.

## 1. Preparación y TDD

1. Confirmar checkout, base, tareas y aprobación de preparación; consultar GodotPrompter de testing/UI/input. No ejecutar `speckit-implement`.
2. Cargar interfaz neutral T002: getter `null`, petición `false`, registros vacíos y acción antigua intacta. Demostrar RED por requisitos ausentes con las firmas ya importables; QA revisa RED sin aprobar gameplay.
3. Tras desarrollo, repetir RED y regresión de HUD, selección, pickup, recarga/retorno y GameRoot. Ajustar sólo expectativas de la acción sustituida; conservar evidencia histórica. Suite completa/importación con `python3 tools/ci/run_gut.py` y CI exacto del PR.

## 2. Casos de aceptación

| Caso | Verificación |
|---|---|
| R01 · Aparición | Dueños cargados sin botón; al agotar carga, visible en su hogar sin selección. Repetir en filas 1/3/5 y cinco simultáneos. |
| R02 · Acción directa | Selección vacía y luego otro soldado seleccionado: pulsar botón ordena únicamente al dueño correcto, un cobro, carga repuesta y botón oculto. |
| R03 · Conservación | Herido/con moral, dentro y fuera: misma salud/moral, coste/carga desde stats, regreso físico por fila vulnerable y sin ofensiva; llegada HOME vigente. |
| R04 · Bloqueos | Sin fondos visible/deshabilitado; añadir fondos habilita. Pausa, terminal, aceptación/retorno y pulsación repetida/reentrante no agregan cobros. |
| R05 · Identidad | Capturar intención, matar/reemplazar dueño y procesarla: cero gasto/recarga del sucesor. Celda inválida y dueño inexistente rechazados. |
| R06 · Entrada | Ratón y toque con emulación: un gesto/una orden como máximo; sobre botones habilitados/deshabilitados no se recoge, selecciona ni despliega debajo. Fuera, pickup conserva prioridad. |
| R07 · Presentación | Cinco botones sobre hogares, mínimo 112×48, sin seguir actor; panel sólo fila/carga/moral/retorno, cero botón antiguo. Revisar barras, vecinos, HUD y bordes. |
| R08 · Ciclo y resize | Redimensionar antes/después de aparecer, pausar/reanudar, ganar/perder, menú/Retry: alineación/click correctos y ningún callback/control antiguo activo. |

## 3. Smoke real por destino disponible

- **Web, Chrome en computador**: exportar con `tools/web/export.sh` y el motor estándar oficial requerido; servir el ZIP extraído con las herramientas existentes. Observar inicio→Jugar, R01–R08 aplicables y captura antes/después de resize a 1152×648/960×540; identificar navegador/computador real. No usar navegador móvil.
- **Android, app instalada**: verificar APK y firma con las herramientas existentes, conservar datos y una app normal; observar ratón/toque disponibles, hogares, retorno, panel, pausa/terminal y geometría tras resize/orientación admitida. Registrar dispositivo/emulador, renderer real y límites de input; no modificar seguridad ni borrar datos para completar pruebas.
- **iOS, app instalada o `.app` nativa de Simulator**: mismos casos pertinentes, registrando dispositivo/simulador, renderer y tamaño; nunca convertir una comprobación del simulador en aceptación física o del IPA final.
- Los casos difíciles pueden usar un escenario reducido de prueba separado del smoke de producción; declarar qué recorrido/población se observó, sin atribuir victoria manual con 100 enemigos a un fixture. Input bloqueado, entorno no disponible o caso no observado queda pendiente explícito.

QA independiente revisa spec/código/pruebas, resultados exactos y documentación antes de `APROBADO PARA INTEGRACIÓN`. No incluye distribución, versión nueva, campaña FPS de 006 ni extensión de la excepción de beta 1.0.1; los gates físicos y de publicación anteriores permanecen pendientes.
