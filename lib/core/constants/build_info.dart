// Build metadata supplied when Flutter compiles the app.
//
// For a release build, pass the checked-out commit explicitly:
// flutter build apk --release --dart-define=GIT_COMMIT=<short-hash>
class BuildInfo {
  static const String commitHash = String.fromEnvironment(
    'GIT_COMMIT',
    defaultValue: 'development',
  );
}
