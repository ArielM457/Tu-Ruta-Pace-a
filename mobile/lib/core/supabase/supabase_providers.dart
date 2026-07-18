import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider =
    Provider<SupabaseClient>((ref) => Supabase.instance.client);

final authStateChangesProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(supabaseClientProvider).auth.onAuthStateChange,
);

final currentSessionProvider = Provider<Session?>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(supabaseClientProvider).auth.currentSession;
});
