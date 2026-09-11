import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/seed_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    FirebaseDatabase.instance.setPersistenceEnabled(true);
  } catch (_) {}
  try {
    await SeedService().seedIfEmpty();
  } catch (_) {}
  runApp(const ProviderScope(child: BriskoApp()));
}
