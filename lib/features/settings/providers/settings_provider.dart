import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/app_settings.dart';

part 'settings_provider.g.dart';

/// Untyped Hive box holding simple key/value preferences. Opened in main.dart
/// before runApp so reads in [Settings.build] are synchronous.
const settingsBoxName = 'settings';
const _kWellsPerRow = 'wellsPerRow';
const _kUseCountdown = 'useCountdown';

@riverpod
class Settings extends _$Settings {
  Box get _box => Hive.box(settingsBoxName);

  @override
  AppSettings build() {
    final box = _box;
    return AppSettings(
      wellsPerRow:
          (box.get(_kWellsPerRow) as int?) ?? AppSettings.defaultWellsPerRow,
      useCountdown: (box.get(_kUseCountdown) as bool?) ?? true,
    );
  }

  void setWellsPerRow(int value) {
    final clamped =
        value.clamp(AppSettings.minWellsPerRow, AppSettings.maxWellsPerRow);
    _box.put(_kWellsPerRow, clamped);
    state = state.copyWith(wellsPerRow: clamped);
  }

  void setUseCountdown(bool value) {
    _box.put(_kUseCountdown, value);
    state = state.copyWith(useCountdown: value);
  }
}
