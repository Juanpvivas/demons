# PC FINAL/Arte — sesión humana con ratón

**I1/I2/I4/I9 aprobados por QA el 2026-10-16.** La persona confirmó que completó la secuencia y que B con el soldado vivo no creó otro. Los PRE/POST acreditan los casos; la declaración no sustituye saldo, ocupación ni estado real.

[Raw](native-pc-arte-cd-human.log), [derivado](native-pc-arte-cd-human-derived.json), [proof](native-pc-arte-cd-human-proof.json), [captura exclusiva de nuestra app](native-pc-arte-cd-human-current.png)/[metadatos](native-pc-arte-cd-human-capture.json). Raw88.452bytes, SHA`94ea47079fcd9c7db525cce0a9963afffab131a847a108f8401cad1e12d0d1c1`; una INITIAL310ms,16PRE/16POST, canal realmente recibido mouse. Recuperación/congelación antes de cerrar, relanzar o cambiar foco.

| Caso | PRE → POST | Resultado aprobado |
|---|---|---|
| I2 B,seq5,t15602→15611 | `(632,534)`/celda6,5 ocupada, sinpickup. Reserva12→12, soldados1→1 y ocupaciónidéntica; PLAYINGambos | No duplica ni gasta. Seq6/7 corroboran el rechazo |
| I4,seq8,t27236→27244 | `(581,455)`/celda6,4 libre. UNpickup3en576,451.95, reserva12→15/soldados1→1/ocupaciónidéntica; PLAYINGambos | +3 sin gasto10 ni unidadadicional |
| I1 C,seq9,t27827→27835 | `(543,607)`/celda5,6 libre, sinpickup. Reserva15→5/soldados1→2, nuevo centro528,624; PLAYINGambos | Costo10/unaunidad y centrocorrecto sobre decoración |
| I9 D,seq13,t40536→40543 | `(56,158)`/celda0,1 libre, sinpickup. Reserva14→4/soldados1→2, nuevo centro48,144; PLAYINGambos | Entrada fuera del centro ilustrado conservada, sin límite nuevo |

Seq12 también recoge un depósito único3 con pre11→14 y1→1soldados enPLAYING, aunque el gesto cae en5,4 y el centro del pickup en6,4; se distinguen ambas celdas. La colección junto al frente seq16 pre10→13 ocurrióLOST y **no** se utiliza como PASS activo. Seq15 junto al frente estabaPLAYING pero pre7<10; no se convierte en el caso discriminante. El I4válido es seq8 (y adicional12). El soldado inicial murió entre gestos; esa variación se conserva sin atribuirla al arte o al clic.

Fuentea473585/script4e89dce… idéntico aBASE; observerbasec628… y extensiónpasivaCDlegible123c0a98… conforme a [proveniencia aprobada](native-pc-cd-readable-provenance.json)/[diff](native-pc-cd-readable-instrument.diff). Los siete archivos de app coinciden con manifest91847b7c…. El subárbolartístico y la composición no contienen controles de entrada. Los labelsC/Dtemporales tienenIGNORE/FOCUSNONE y no cambian mecánicas ni recursos.

Godot4.7.1standard, Mobile/Metal, AppleM5Pro. Render1152×648/lógico1152×648, stretch1/canvasidentidad. Celda=floor(posición/96). Ventana capturada576×356puntos aorigen224,152, imagen1152×712incluyebarra32puntos: clicI4 equivale aproximadamente a host514.5,411.5puntos; es conversión geométrica, no posición global registrada por el observer. Captura pública por bundleIDyappURLúnicos, sin escritorio, AX, cambio de foco ni eventos sintéticos. Está enLOST al recuperarse y no se presenta como frame contemporáneo de los gestosPLAYING.

[BASEsesión1](native-pc-base-cd-human.md) aporta I2; [BASEsesión2](native-pc-base-cd-human-run2.md) aporta I1/I4/I9 y colección activa con fondos suficientes junto al frente. QA aprobó el mínimo de ratón antes/después; I3 se reutiliza de la sesión PCprevia y regresión, sin otra sesión rutinaria. No se extrapola a Web ni se marcan tareas. No hay más prueba humana o automática requerida por este informe.
