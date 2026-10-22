# Quickstart de validación

Fuente normativa: [protocolo](contracts/profiling-protocol.md); requisitos en [spec](spec.md). Ejecutan los agentes asignados, nunca Spec Kit.

El T009 de I1 aprobó para integración el instrumento y diagnóstico limitado, sin parche. Esta guía conserva el recorrido pendiente: las bases nativas de T008/SC-001 y US2 no se completaron. El detalle de ejecución y límites queda en el PR; no se exige repetir evidencia vigente por cambios sólo documentales.

Para I2, B=`2272aa2` y C es la misma fuente con una intervención. Antes del lote,
el tester verifica el [preflight GPU Web](contracts/profiling-protocol.md#adenda-i2-componente-gpu-web):
contexto real, bracket single-thread de dibujo, queries asíncronas disponibles
y sin disjoint, con control de perturbación. Un fallo invalida ese carril.
Sólo tras revisión QA y confirmación del orquestador se ejecuta B,C,C,B,B,C,
10 s de calentamiento y 30 s de reloj monotónico por ventana. DOM/RAF no acreditan
VSync físico; el probe mantiene sus ocho condiciones y nunca se fuerza válido.
El nuevo T009-I2 decide sobre señal repetible antes de T010; material-off no
prueba ahorro de cuatro lecturas ni neutralidad. I1/PR #31 es antecedente integrado.

1. Confirmar rama/base y SHA, entorno nativo/Web y fuentes disponibles. Antes de tests, importación aislada con Godot4.7.1; no tratar fallos de parser/import como RED.
2. T003 ejecuta RED dirigido: `godot --headless --path <copia-aislada> -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/systems/test_performance_probe.gd -gexit`. QA revisa fallo semántico; tras T005 se repite el mismo comando para GREEN.
3. Montar collectors/fixtures y resultados en temporales. Completar las condiciones observadas desde lecturas reales con procedencia/instantes según protocolo, sin copiar expected; verificar inventario frente al manifiesto independiente antes de cronometrar; invalidar diferencias de geometría, población o reloj. Verificar que foco/vsync observan el estado efectivo: un getter de fallback y `valid=true` no bastan para acreditar comparabilidad causal.
4. Ejecutar escenarios/repeticiones del protocolo, incluyendo control del coste del observador. Web sólo en computador; Android/iOS mediante APK/`.app` instaladas, con renderer/variantes identificados. Excluir escenas GUT malformadas sólo en copias QA si se necesita, idéntico en B/C y declarado.
5. Revisar hipótesis antes de aplicar el parche. La ablación del material/pacing es diagnóstica; no demuestra equivalencia visual ni es candidata de entrega. Reportar ausencia de datos GPU/Self como tal.
6. Tras el parche autorizado, repetir comparación pertinente y revisar poses/ataques/impacto/moral, marcha/espera/retorno/flips y caída. Verificar recogida (incluidas cajas anidadas/solapadas), selección/recarga/despliegue y terminales según código afectado; reutilizar alcance no invalidado con comprobación de vigencia.
7. Ejecutar suite completa con `python3 tools/ci/run_gut.py` o reutilizar la CI automática de la revisión exacta ya ejecutada; comprobar import/build y exportación Web. Si se actualiza fuente, repetir sólo verificaciones invalidadas.
8. Restaurar las apps normales y sus datos tras usar variantes QA; dejar sólo «Monte Calvo» normal en iPad, sin fixtures/controles. Si no se pudo ejecutar o instalar una variante, informar conservación y límites de la comprobación, sin inventar hashes anteriores. Detener servidores/AVD propios y restaurar geometría. No distribuir ni modificar versiones/presets de producción.
9. QA evalúa SC-001–006 y FR-001–010, explica caídas y límites; docs documenta sólo lo aprobado. El orquestador registra casillas, deja el PR en borrador `Refs #30` y conserva T039/T071 abiertos.

El binario real se localiza por entorno; `godot` representa ese ejecutable verificado. No se instala ni actualiza el motor como parte de esta guía. La app nativa Compatibility/software del simulador no equivale a IPA/hardware o renderer Mobile final.
