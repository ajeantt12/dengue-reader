import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/build_info.dart';

// Shows the app version and build identifier so a running app can be matched
// to its release and source commit.
class AppVersionLabel extends StatelessWidget {
  const AppVersionLabel({super.key, this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        final version = info == null
            ? 'v…'
            : 'v${info.version}+${info.buildNumber}';
        return Text(
          '$version · Build ${BuildInfo.commitHash}',
          style: style ?? const TextStyle(fontSize: 11, color: Colors.black54),
        );
      },
    );
  }
}
