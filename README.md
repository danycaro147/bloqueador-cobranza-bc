# Bloqueador Cobranza (Flutter · Android)

Una app de **BrainCode México Tech** — https://braincode.com.mx

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
flutter build apk --release        # o appbundle para Play Store
# APK: build/app/outputs/flutter-apk/app-release.apk
```
O con el teléfono conectado por USB (depuración USB activa): `flutter run --release`

> No ejecutes `flutter create .` sobre este proyecto: ya trae todos los archivos.
> Si falta `gradlew`, Flutter lo genera solo en la primera compilación.

## Primer uso
La app abre una guía de 3 pasos: activar el filtro de llamadas, permitir contactos y
elegir el nivel (Recomendado, Estricto o Solo mi lista).

## Play Store
- Cada push a `main` compila en GitHub Actions y publica en *Releases* el `.apk` y el `.aab`.
- Para firmar con la llave de Play, agrega estos secretos en GitHub (Settings → Secrets → Actions):
  `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`.
- Ficha, textos y gráficos: carpeta `store/`. Política de privacidad: `PRIVACIDAD.md`.

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
- `lib/onboarding.dart` – guía de configuración
- `lib/home.dart` – pantallas Protección, Listas e Historial
- `lib/braincode.dart` – Acerca de, tarjeta y firma de BrainCode

## Extra (México)
Para reducir también la publicidad, registra tu número en el REPEP de PROFECO
(repep.profeco.gob.mx). Si un despacho de cobranza te acosa, puedes quejarte ante
CONDUSEF (REDECO).
