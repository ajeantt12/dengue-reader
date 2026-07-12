import 'dart:io';

/// Builds a release APK and copies the shareable artifact to:
/// apks/dengue-reader-<version>-<short-commit>.apk
///
/// Use --reuse-existing to name the most recently built release APK without
/// rebuilding it.
void main(List<String> args) {
  if (args.contains('--help')) {
    stdout.writeln(
      'Usage: dart run tool/build_release_apk.dart [--reuse-existing]',
    );
    return;
  }

  final reuseExisting = args.contains('--reuse-existing');
  final unsupported = args.where((arg) => arg != '--reuse-existing').toList();
  if (unsupported.isNotEmpty) {
    stderr.writeln('Unknown argument: ${unsupported.join(', ')}');
    exitCode = 64;
    return;
  }

  final version = _appVersion();
  final commit = _git(['rev-parse', '--short', 'HEAD']);

  if (!reuseExisting) {
    final result = Process.runSync(
      Platform.isWindows ? 'flutter.bat' : 'flutter',
      ['build', 'apk', '--release', '--dart-define=GIT_COMMIT=$commit'],
    );
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    if (result.exitCode != 0) {
      exitCode = result.exitCode;
      return;
    }
  }

  final source = _findReleaseApk(version, commit);
  if (source == null) {
    stderr.writeln(
      'Release APK not found. Run without --reuse-existing first.',
    );
    exitCode = 1;
    return;
  }

  final outputDirectory = Directory('apks')..createSync(recursive: true);
  final destination = File(
    '${outputDirectory.path}${Platform.pathSeparator}'
    'dengue-reader-$version-$commit.apk',
  );
  source.copySync(destination.path);
  stdout.writeln('Release APK: ${destination.path}');
}

File? _findReleaseApk(String version, String commit) {
  final candidates = [
    'build/app/outputs/flutter-apk/app-release.apk',
    'build/app/outputs/apk/release/app-release.apk',
    'build/app/outputs/flutter-apk/dengue-reader-$version-$commit.apk',
  ];
  for (final path in candidates) {
    final file = File(path);
    if (file.existsSync()) return file;
  }
  return null;
}

String _appVersion() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final match = RegExp(
    r'^version:\s*([^\s#]+)',
    multiLine: true,
  ).firstMatch(pubspec);
  if (match == null) {
    throw StateError('Could not find the app version in pubspec.yaml.');
  }
  return match.group(1)!.split('+').first;
}

String _git(List<String> args) {
  final result = Process.runSync('git', args);
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    throw ProcessException('git', args, 'git command failed', result.exitCode);
  }
  return (result.stdout as String).trim();
}
