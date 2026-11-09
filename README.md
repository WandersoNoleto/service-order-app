# service-order-app

Offline-first, white-label Android app to create service orders and export them as A4 PDF or image,
ready to share on WhatsApp or print. Built with Flutter.

## Features

- Service order form (customer, service call, parts with live totals, notes), stored locally (SQLite).
- History grouped by day, with search.
- A4 PDF following a paper template; parts table continues on the next page when needed.
- Share as PDF or image (WhatsApp), print.
- Company data and logo editable in the app; only what is filled in is printed on the PDF header.
- In-app updates from GitHub Releases.
- White-label: each client gets its own app id, name, colors, logo, icon and splash.

## Running

```bash
flutter run --flavor standard --dart-define-from-file=clients/default/config.json
```

`standard` is the generic app: green theme, no logo (the user can add one in Settings).

## White-label: adding a client

Client files never live in this repository. They go to `clients/private/<client>/`, a separate
private repository cloned into that folder (git-ignored here). Example for a client called `acme`:

1. **Config**: `clients/private/acme/config.json`, same keys as
   [`clients/default/config.json`](clients/default/config.json):
   `APP_CHANNEL` (`"acme"`), company data, `BRAND_COLOR` (`AARRGGBB`) and `LOGO_ASSET`
   (`"clients/private/acme/branding/logo.png"`, or `""` for no logo).
2. **Logo** (optional): `clients/private/acme/branding/logo.png`, plus the asset entry in
   `pubspec.yaml`:
   ```yaml
   - path: clients/private/acme/branding/
     flavors: [acme]
   ```
3. **Flavor**: add it to `android/app/build.gradle.kts` (see the commented example there), with
   `applicationIdSuffix = ".acme"`.
4. **Icon and splash** (optional): SVG/PNG sources and the generator configs
   (`flutter_launcher_icons-acme.yaml`, `flutter_native_splash-acme.yaml`) in
   `clients/private/acme/icon/`, symlinked into the project root. Generate with:
   ```bash
   dart run flutter_launcher_icons
   dart run flutter_native_splash:create --flavor acme
   ```
   Generated files go to `android/app/src/acme/` (git-ignored). Without them the client app uses the
   generic icon and splash. See [`assets/icon/README.md`](assets/icon/README.md).
5. **Run**:
   ```bash
   flutter run --flavor acme --dart-define-from-file=clients/private/acme/config.json
   ```

## Releases and updates

The version lives in `pubspec.yaml` (`x.y.z+<versionCode>`). Build signed APKs with:

```bash
tool/build_release.sh standard      # tag vX.Y.Z
tool/build_release.sh acme 1        # tag vX.Y.Z-acme.1
```

Publish the APK as a GitHub release with the printed tag. Each app only looks at the tags of its own
channel, so the generic app and each client update independently. Release signing reads
`android/key.properties` (see `android/key.properties.example`).
