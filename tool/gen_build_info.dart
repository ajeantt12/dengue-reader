// Regenerates lib/core/constants/build_info.dart from the current git state.
//
// Run before building for a device test, or via the pre-commit hook, so the
// running app can be matched back to the exact commit (and dirty-tree state)
// it was built from: `dart run tool/gen_build_info.dart`.
import 'dart:io';

void main() {
  final hash = _git(['rev-parse', '--short', 'HEAD']);
  final dirty = _git(['status', '--porcelain']).isNotEmpty;
  final generatedAt = DateTime.now().toUtc().toIso8601String();

  final content = '''
// GENERATED FILE — do not edit by hand.
// Regenerate with: dart run tool/gen_build_info.dart
//
// Captures the git commit checked out (and whether the tree had uncommitted
// changes) at generation time, so a running app build can be matched back to
// the source commit it came from.
class BuildInfo {
  static const String gitCommit = '$hash';
  static const bool isDirty = $dirty;
  static const String generatedAt = '$generatedAt';
}
''';

  final file = File('lib/core/constants/build_info.dart');
  file.writeAsStringSync(content);
  stdout.writeln(
    'Generated ${file.path}: $hash${dirty ? ' (dirty working tree)' : ''}',
  );
}

String _git(List<String> args) {
  final result = Process.runSync('git', args);
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    throw ProcessException('git', args, 'git command failed', result.exitCode);
  }
  return (result.stdout as String).trim();
}
