import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/missing_configuration_app.dart';
import 'core/config/app_environment.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!AppEnvironment.isSupabaseConfigured) {
    runApp(const MissingConfigurationApp());
    return;
  }
  await Supabase.initialize(
    url: AppEnvironment.supabaseUrl,
    anonKey: AppEnvironment.supabaseAnonKey,
  );
  runApp(const ProviderScope(child: AyniRutaApp()));
}
