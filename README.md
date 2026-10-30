# Bloqueador Cobranza (Flutter · Android)

Bloquea llamadas entrantes de cobranza, spam y números ocultos. **Solo filtra llamadas.**
Nunca reemplaza tu app de Teléfono: usa el rol de Android `ROLE_CALL_SCREENING`
(filtro de llamadas), no `ROLE_DIALER`. Las llamadas permitidas suenan y se contestan
en tu app nativa de siempre.

## Requisitos
- Flutter 3.22 o superior (con Android SDK configurado: `flutter doctor`)
- Teléfono con **Android 10 o superior**

## Compilar e instalar
```bash
cd bloqueador_cobranza
flutter pub get
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```
O con el teléfono conectado por USB (depuración USB activa): `flutter run --release`

> No ejecutes `flutter create .` sobre este proyecto: ya trae todos los archivos.
> Si falta `gradlew`, Flutter lo genera solo en la primera compilación.

## Primer uso
1. Abre la app → **Activar filtro** → elige *Bloqueador Cobranza* como app de filtro
   de llamadas/spam. (Es un diálogo distinto al de "app de teléfono predeterminada").
2. **Dar permiso** de contactos (solo para no bloquear nunca a tus contactos).
3. Listo. Las opciones por defecto:
   - Bloquear desconocidos: **sí** (los despachos cambian de número todo el tiempo)
   - Dejar pasar si un desconocido llama 2 veces en 3 minutos: **sí** (emergencias)
   - Bloquear ocultos: **sí** · Bloquear falsificados: **sí**

## Cómo decide
1. Protección apagada → pasa
2. Número oculto → se bloquea (si está activado)
3. Lista "Siempre permitir" → pasa
4. Lista de bloqueo (exacto o prefijo con `*`, ej. `5588*`) → se bloquea
5. Contacto guardado → pasa siempre
6. Número falsificado según la red → se bloquea
7. Desconocido → se bloquea, salvo que insista 2 veces en 3 min

Una llamada bloqueada se cuelga sin sonar y sin notificación; queda en el registro del
teléfono y en el Historial de la app, desde donde puedes bloquear o permitir el número.

## Archivos clave
- `android/.../BlockerScreeningService.kt` – el servicio que Android llama en cada llamada
- `android/.../Rules.kt` – las reglas de bloqueo
- `android/.../BlockerStore.kt` – configuración, listas e historial (nativo)
- `android/.../MainActivity.kt` – puente con Flutter y solicitud del rol
- `lib/main.dart` – interfaz (Protección, Listas, Historial)

## Extra (México)
Para reducir también la publicidad, registra tu número en el REPEP de PROFECO
(repep.profeco.gob.mx). Si un despacho de cobranza te acosa, puedes quejarte ante
CONDUSEF (REDECO).
