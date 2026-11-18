# بدلاتي | Badalaty

An offline allowance tracker for Android. The Flutter application includes Arabic and English, shared transportation, personal travel, internal rides, assignments, a history calendar, XLSX reporting and local backup.

## Setup

Use Flutter 3.50 stable (Dart 3.14), JDK 17 or newer, Android SDK Platform 36 and NDK 28.2.13676358. Run `flutter doctor -v` to check your setup.

```sh
flutter pub get
flutter gen-l10n
flutter run
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Android releases and updates

The application ID is `com.amwolfstein.badalaty`. Android treats versions with the previous ID as a separate app. Export a backup from the previous app and restore it in the new app to transfer records.

Use the Badalaty release PKCS#12 keystore for every published build. Keep the keystore and password file outside Git. The key alias is `badalaty` and the password applies to both the store and the key.

```sh
export BADALATY_KEYSTORE_PATH=/absolute/path/to/badalaty-release.p12
export BADALATY_KEYSTORE_PASSWORD_FILE=/absolute/path/to/store-password
flutter build apk --release --target-platform android-arm64
```

Use `apksigner verify --print-certs` to verify the build at `build/app/outputs/flutter-apk/app-release.apk`. Publish `Badalaty-<version>-arm64.apk` to GitHub Releases and to `android-preview/artifacts`. Update `artifacts/latest.json` in the same Git commit as the new APK. Set the package, version, incremented Android build number, and APK SHA-256. The settings screen checks this feed on request, downloads the verified APK, and hands it to the Android package installer. Allow installation from Badalaty if Android prompts.

## Allowances and data

Set the owner’s name and Employee ID in Settings before recording shared transportation. The owner is included automatically. A shared entry snapshots the participants and their allocated whole pounds. Travel defaults to EGP 100 for meals plus EGP 49 for accommodation. Accommodation rounds to the nearest whole pound, with halves rounded up. Each travel day requires saving an entry. Internal rides count in full toward the owner’s entitlement.

Reports export six sheets, including an owner-only summary. Choose the workbook language on the Reports screen. Backup creates a versioned JSON snapshot of the Drift database records and audit log. Restore checks the checksum and applies the replacement in one SQLite transaction. Keep the exported backup locally where you can access it after uninstalling.

## Android widgets and reminders

Add either Badalaty widget from the launcher’s widget picker. Add Allowance opens a category chooser. The expanded widget also opens History. Widgets display committed totals. Settings includes Android notification permission and a configurable reminder time. Android can defer notification delivery during idle modes. Native reminders use a 90-day snapshot refreshed when the app is opened or records are changed.

## iOS

The Flutter iOS runner is included. Build on macOS with Xcode using `flutter build ios --no-codesign`. A future WidgetKit extension can read the committed display snapshot from an App Group shared container and open the same Flutter routes. iOS widget and reminder implementations are pending.

## Design asset

The original artwork is in `assets/branding/badalaty-icon.png`. Android uses the artwork for legacy and adaptive color icons and a matching calendar and wallet glyph for themed icons. The iOS icon catalog uses opaque variants of the original artwork.

See [architecture](docs/ARCHITECTURE.md), [requirements](docs/REQUIREMENTS.md) and [implementation plan](docs/IMPLEMENTATION_PLAN.md).
