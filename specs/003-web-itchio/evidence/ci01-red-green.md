# CI-01 — RED y GREEN del guard de GUT

2026-10-16. Base `274480363c9165111803f97299251490f62ea3b4`, rama `codex/003-web-itchio`.
Sin cambios de gameplay; QA aprueba RED antes de autorizar desarrollo.

## RED conservado

- Comando: `python3 -B -m unittest discover -s tests/ci -p 'test_*.py' -v`.
- Scaffold ejecutable: **exit 1, 3 métodos/16 escenarios, 15 fallos de aserción**;
  el control de exit no cero pasa. Ningún fallo de archivo/sintaxis/entorno.
- Se reproduce el falso verde job117134049321/run38948627481: error de clases
  GUT sin importar + exit 0 aceptado. Los otros casos cubren importación previa,
  freno por fallo/ERROR, resumen ausente/cero/descuadre, fallos y ANSI/reenvío.
- Fixture positivo: [T017 histórico](t017-green-full.log), sin fijar 189 en el guard.
- Scaffold SHA256: `789b7882f3742bb8af84dfa5e287d73f363143bbf17ba93ddf19c2a16a3a69e3`.
- Tests RED/GREEN idénticos, SHA256: `348eebf26fbfb2e714f7d07074649acf683c6eee12dd8f155b1daea3b8d4245a`.
- Log RED: `/private/tmp/demons-ci01-red-20261016/unittest-red.log`, SHA256
  `b49ecc4629c96b15601346031c9b99f08ae19873e9c52a58ffb132eaea66b1c7`; scaffold/tests/metadatos congelados junto al log.

## GREEN local real

- Mismo comando de contratos: **3 métodos/16 escenarios pasan, exit 0**.
- Runner SHA256: `90f8bceffa21bef0121f569a0aee60e5a6f0c2b62039a4f43eb9ce921da30d6d`.
- Clon aislado de la base anterior, sin `.godot` inicial; overlay del runner,
  tests y YAML identificado por hash en metadatos locales. Producto intacto.
- Comando: `python3 -B tools/ci/run_gut.py --godot /ruta/Godot --project /ruta/copia`.
- Godot estándar **4.7.1.stable.official.a13da4feb**: importación completa antes
  de GUT, **189/189**, **532 aserciones**, 16 scripts, 38,186 s; 3 avisos históricos,
  cero ERROR/SCRIPT ERROR, **exit 0**. Sin UI ni exportación nueva.
- Logs y metadatos completos en `/private/tmp/demons-ci01-green-20261016/`.
  `unittest-green.log` SHA256 `c07975eecf03cc255987755495f531dc3b449101ff1ae23bd432cb7d0094f22f`;
  `real-runner-green.log` SHA256 `b7742f8531b3ef4cc52ed6e63011df7275964b76ec4277c0f6f4c08a2267dc68`.

**CI remoto de esta revisión pendiente al redactar**; el run real se enlazará en el PR.
