# iPad Simulator 002 — preparación y registro persistente

**Runtime/render y mínimo de entrada V4 aprobados por QA el 2026-10-16.** iPad Pro13-inch(M5), iPadOS27.0, simulador ARM64 ya disponible; arrancó desdeShutdown. No se prueba hardware iOS ni rendererMobile. La copia usa Compatibility/OpenGL3/AppleSoftwareRenderer, requerido por simulador. Resolución de app2752×2064, viewport1152×864, stretch2.388889, canvas identidad: proporción4:3 distinta aPC/Android. [Captura de render de preparación](native-ipad-render-setup.png), guardada porSDK sin rotación/edición: framebuffer2064×2752 con contenidoLandscapeRight girado90, yaLOST; no acredita gesto ni rendimiento iOS. El frontend permite girar el dispositivo antes del inicio humano.

## Procedencia y resolución del bloqueo

El primer intento con las plantillas distribuidas fallóarm64/EXIT65, conservado en [antecedente](ios-simulator-build-summary.json). Se resolvió con bibliotecaSimulatorarm64 compilada **sin parches** desde Godot tag4.7.1-stable/commit`a13da4feb8d8aefc283c3763d33a2f170a18d541`, conforme al defecto de empaquetado [upstream122379](https://github.com/godotengine/godot/issues/122379). [Proveniencia de plantilla local](native-ipad-arm64-template-provenance.json), [dos apps y hashes](native-ipad-arm64-build-summary.json). BuildDebug de ambascomposicionesEXIT0, sin firma/provisioning/publicación ni instalación global deherramientas. ProducciónMobile intacta. Los22destinos concretos arm64 y2placeholders no se confunden con24destinos ejecutables.

Las composiciones anterior/final contienen el mismo scriptI4`4e89dce…`, observer003`c628c721…` y telemetría002`2fbdb3c0…`. No se cambian economía, controles, geometría o comportamiento. Éxito de build no se presenta como éxito de interacción.

## Control de interfaz

El frontend real de Xcode27 es **Device Hub**, `/Applications/Xcode.app/Contents/Applications/DeviceHub.app`, bundle`com.apple.dt.Devices`. La ruta históricaSimulator.app no existe. Una consultaCUA aDeviceHub quedó bloqueada186.4s pese al timeout30s y fue interrumpida; no se repitióAX. [Preflight público](native-ui-permission-preflight.json): captura ya concedida, `CGPreflightPostEventAccess=false` y `AXIsProcessTrusted=false`; no se solicitó/cambióTCC ni se enviaron eventosCoreGraphics. Esa vía de gesto esNOTRUN por permisos existentes, sin fallo atribuido al juego. `simctl help io/ui` no ofrece gestos públicos; no se usaron API privadas ni handlers deGodot.

Se abrió DeviceHub por lanzador local y **la persona seleccionó el iPad**. [Home del objetivo con icono«demons»](native-ipad-home.png), [metadatos de captura](native-ipad-home-metadata.json): PID69400/window7888, bounds1024×638puntos, imagen2048×1276(2×). La captura usa ScreenCaptureKit público **solo para esa ventana**, sin escritorio u otrasaplicaciones. Un preflight anterior mostraba otraapp en otro simulador seleccionado: esa imagen se conserva solo temporalmente y no se versiona ni publica como evidencia.

## Registro persistente confirmado antes de pedir gestos

EniOS, el [registro de archivos estándar](https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html#class-projectsettings-property-debug-file-logging-enable-file-logging) está deshabilitado por defecto. Ni consolaPTY ni lectura deunifiedlogs recuperaron los prints del observer de la primera preparación; no se pidió una prueba humana basándose en un buffer inexistente.

Autorizado por el orquestador: dos NUEVAScopias añaden únicamente `[debug] file_logging/enable_file_logging=true` y `file_logging/log_path="user://logs/godot.log"`. [Diff anterior](native-ipad-filelog-baseline.diff), [diff final](native-ipad-filelog-final.diff), [manifiesto](native-ipad-filelog-provenance.json). Import/exportdebugretorno0 ambos. Solo cambia`demons.pck` en COPIAS de las appsarm64 ya compiladas; motorbinario, Info.plist, firma/configproductiva y todos los scripts permanecen idénticos. No hay nuevohook/framework o estado dejuego.

Se instaló la final y ejecutó un preflightSDK **5s sininput**, se terminó solo nuestra app y se guardó el [log de2353bytes](native-ipad-filelog-preflight.log). Contiene `WEB_OBSERVER INITIAL` con reserva0/unSoldado576,500/celda6,5 y `NATIVE_GEOMETRY` con las dimensiones anteriores. [Verificación/códigos](native-ipad-filelog-verified.json). Se archivó y eliminó exclusivamente ese`godot.log` diagnóstico para que la siguiente sesión humana sea nueva; no se borraron logsdel sistema. Appfinal cerrada/iconoHome visible. La persona iniciará cuando termine de leer; no hay autostart ni grabación/bucle de espera.

Aviso de runtime preservado: el preflight contiene «Mouse is not supported by this display server». No se afirma ejecución sin errores/avisos; esta presencia aislada no demuestra fallo de touch. La ruta realmente recibida quedó registrada como pares mouse/touch de un mismo gesto humano, según los reportes de sesión enlazados abajo. Las lecturas aproximadas5–8FPS del AppleSoftwareRenderer simulado no se usan paraSC-007.

## Resultado humano recuperado y aceptado

[FINAL I1/I3](native-ipad-final-human.md) demuestra rechazo libre sin fondos y despliegue12→2/+1 durante PLAYING. Las recogidas focalizadas [BASE](native-ipad-baseline-human.md) y [FINAL](native-ipad-final-i4-human.md) demuestran I4 con el mismo arreglo: un pickup3, celda6,4 libre, reserva12→15 y un soldado antes/después, sin gasto ni unidad adicional. Las tres sesiones se recuperaron sin recargar, se congelaron con app/PCK reales y se revisaron de forma independiente. QA aprobó el mínimo V4 iPadSimulator/Compatibility el 2026-10-16.

I2/I9 de este iPad no quedaron demostrados y se conservan como tales; su cobertura controlada de toque corresponde a AVD, sin atribuirla al simulador iOS. No se requiere repetir cada rama por cada SO para esta distribución aprobada. El renderer Compatibility temporal, AppleSoftwareRenderer, la compilación arm64 local y los avisos de display server no se extrapolan a iOS físico/Mobile ni a rendimiento.
