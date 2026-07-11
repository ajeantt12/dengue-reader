import 'package:flutter/material.dart';

import '../../core/constants/build_info.dart';

// Shows the GitHub commit hash so a running build can be matched to its source.
class AppVersionLabel extends StatelessWidget {
  const AppVersionLabel({super.key, this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Commit ${BuildInfo.commitHash}',
      style: style ?? const TextStyle(fontSize: 11, color: Colors.black54),
    );
  }
}
