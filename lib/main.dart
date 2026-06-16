import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'shared/models/dot_reading.dart';
import 'shared/models/test_result.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(DotReadingAdapter());
  Hive.registerAdapter(TestResultAdapter());

  runApp(
    const ProviderScope(
      child: DengueReaderApp(),
    ),
  );
}
