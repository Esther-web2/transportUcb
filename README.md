# SMART_PAY UCB

Flutter app prototype for UCB transport-card management, top-ups, and bus fare validation. The interface is in French. Authentication and payments are local/demo implementations; this is not connected to a production identity service or CinetPay account.

## Run locally

Requirements: Flutter 3.x (Dart 3), available in this workspace as Flutter 3.47.6. Android SDK and licenses are also installed.

```sh
flutter pub get
flutter devices
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 7357
```

Open `http://127.0.0.1:7357` in a browser. Stop the development server with `Ctrl+C`. Chromium is installed on this computer; to have Flutter launch it directly, use `CHROME_EXECUTABLE=/usr/bin/chromium flutter run -d chrome` instead.

To run on Android, create/start an emulator in Android Studio, then use `flutter devices` and `flutter run -d <device-id>`. No emulator is currently configured. For the Linux desktop target on CachyOS/Arch, install its missing build tools with `sudo pacman -S --needed base-devel cmake ninja pkgconf gtk3`, check `flutter doctor -v`, then run `flutter run -d linux`.


## Project map

- `lib/screens/`: login, student/admin/controller dashboards, card profile, recharge, and history screens.
- `lib/services/`: local authentication, Hive persistence, transport data, payment simulation, and theme state.
- `lib/models/`: card and transport/payment models, including the generated Hive adapter.
- `lib/widgets/` and `lib/theme/`: shared responsive layouts, UI components, and themes.
- `test/`: model, authentication, transport, and payment-service tests.

## Checks

```sh
flutter analyze
flutter test
```

If you change an annotated Hive model, regenerate its adapter with:

```sh
dart run build_runner build --delete-conflicting-outputs
```
