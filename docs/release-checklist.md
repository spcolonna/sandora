# Checklist de release

Para cada subida a App Store y Google Play. Lo marcado como **(usuario)** lo hace una persona en las consolas o en
GitHub; no está automatizado.

## 1. Versión
- [ ] `pubspec.yaml` → `version: 1.0.0+1` en la primera subida. Después, subir siempre el número de build (`+2`,
      `+3`…): ninguna de las dos tiendas acepta repetirlo. El nombre (`1.0.1`) cambia cuando cambia lo que ve el jugador.
- [ ] `flutter analyze` limpio y `flutter test` en verde.

## 2. Marca y nombre (usuario)
- [ ] Búsqueda de "Sandora" en USPTO, EUIPO y MIEM, clases 9 y 41 (ver `docs/pendientes.md`).
- [ ] Reservar el nombre: crear la app en App Store Connect (bundle `com.oraki.sandora`, nombre "Sandora: jardín
      zen") y en Play Console (paquete `com.oraki.sandora`). El nombre de App Store queda tomado al crear la app.

## 3. Firma de Android
Una sola vez. La clave de subida no se pierde ni se commitea (`android/.gitignore` ignora `key.properties`, `*.jks`
y `*.keystore`); guardarla con sus contraseñas en un gestor y con copia fuera de la máquina.

```bash
keytool -genkey -v -keystore ~/keys/sandora-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Después, `android/key.properties` (rutas relativas a `android/app/`, o absolutas):

```properties
storeFile=/Users/<usuario>/keys/sandora-upload.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

`android/app/build.gradle.kts` firma el release con esa clave si el archivo existe; si no, con la de debug (sirve
para `flutter run --release`, pero Play lo rechaza). En Play Console, activar la firma de apps de Google Play: Google
guarda la clave de la app y esta queda como clave de subida.

- [ ] `android/key.properties` presente y apuntando al `.jks`.

## 4. Builds
- [ ] Android: `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`.
      Comprobar que no salió con la firma de debug:
      `keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab` (el dueño no debe ser "Android Debug").
- [ ] iOS: en Xcode, el equipo de firma de Oraki Games en Runner › Signing & Capabilities. Después
      `flutter build ipa --release` → `build/ios/ipa/` y subir con Transporter o
      `xcrun altool --upload-app` (o Xcode › Organizer).
- [ ] Probar el build de release en un teléfono real antes de mandarlo a revisión.

## 5. Capturas
- [ ] `tool/screenshots.sh` en el iPhone 17 Pro Max (6.9") y `DEVICE="iPad Pro 13-inch (M5)" tool/screenshots.sh`.
- [ ] `PLAY=1 tool/screenshots.sh` para las de Play (1080 × 1920).
- [ ] Gráfico de funciones de Play (1024 × 500) e ícono de 512 × 512.
- [ ] Tamaños y lista de pantallas: "Capturas" en `docs/store-listing.md`.

## 6. Política de privacidad (usuario)
- [ ] Publicar `docs/privacy/index.html`, por ejemplo con GitHub Pages del repo (Settings › Pages › rama `main`,
      carpeta `/docs`). Queda en `https://spcolonna.github.io/sandora/privacy/`.
- [ ] Abrir la URL y revisar que se vea y que el contacto sea `orakigames.uy@gmail.com`.
- [ ] Poner esa URL como política de privacidad y soporte en las dos consolas.

## 7. Fichas en las consolas (usuario)
- [ ] Textos en 5 idiomas, categoría y clasificación: `docs/store-listing.md`.
- [ ] Declaraciones de privacidad (App Store › Privacidad de la app, Play › Seguridad de los datos): mismo archivo.
- [ ] Contacto: `orakigames.uy@gmail.com`.

## 8. Venta de lotos desactivada
- [ ] `assets/balance/game_balance.json` → `shop.lotusPacks.enabled: false`. En la primera versión no se vende nada:
      las fichas dicen "sin compras" y no hay consumibles creados en las consolas.
- [ ] Ninguna captura muestra precios.
