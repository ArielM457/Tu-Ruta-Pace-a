import 'package:flutter/material.dart';

import 'theme.dart';

class MissingConfigurationApp extends StatelessWidget {
  const MissingConfigurationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chasqui',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings_suggest, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Falta configurar Supabase',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Ejecuta la app con:\n'
                  'flutter run --dart-define=SUPABASE_URL=... '
                  '--dart-define=SUPABASE_ANON_KEY=... '
                  '--dart-define=API_BASE_URL=...',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
