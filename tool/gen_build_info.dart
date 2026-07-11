// Regenerates lib/core/constants/build_info.dart from the current Git commit.
//
// Run after committing and before building for a device test, so the running
// app can be matched to the commit it was built from:
// `dart run tool/gen_build_info.dart`.
import 'dart:io';

void main() {
  final hash = _git(['rev-parse', '--short', 'HEAD']);
  final generatedAt = DateTime.now().toUtc().toIso8601String();

  final content =
      '''
// GENERATED FILE — do not edit by hand.
// Regenerate with: dart run tool/gen_build_info.dart
//
// Captures the Git commit checked out at generation time, so a running app
// build can be matched back to the source commit it came from.
class BuildInfo {
  static const String commitHash = '$hash';
  static const String generatedAt = '$generatedAt';
}
''';

  final file = File('lib/core/constants/build_info.dart');
  file.writeAsStringSync(content);
  stdout.writeln('Generated ${file.path}: $hash');
}

String _git(List<String> args) {
  final result = Process.runSync('git', args);
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    throw ProcessException('git', args, 'git command failed', result.exitCode);
  }
  return (result.stdout as String).trim();
}
