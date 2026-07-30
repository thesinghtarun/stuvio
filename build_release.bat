# Build release APK (always disables icon tree-shaking since the app uses
# dynamic IconData codepoints stored in the Isar database).
flutter build apk --release --no-tree-shake-icons
