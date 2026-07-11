import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/build_info.dart';

// Shows "v<pubspec version>+<build number> · <git commit>" so a running
// build can be matched against a specific commit during development.
class AppVersionLabel extends StatelessWidget {
  const AppVersionLabel({super.key, this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        final version =
            info == null ? '…' : 'v${info.version}+${info.buildNumber}';
        const commit =
            BuildInfo.gitCommit + (BuildInfo.isDirty ? '-dirty' : '');
        return Text(
          '$version · $commit',
          style: style ??
              const TextStyle(fontSize: 11, color: Colors.black54),
        );
      },
    );
  }
}
