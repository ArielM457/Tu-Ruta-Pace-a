import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/supabase_auth_repository.dart';
import '../../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(ref.watch(supabaseClientProvider)),
);

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> signIn({required String email, required String password}) {
    return _run(
      () => ref.read(authRepositoryProvider).signIn(
            email: email,
            password: password,
          ),
    );
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _run(() async {
      final hasSession = await ref.read(authRepositoryProvider).register(
            email: email,
            password: password,
            displayName: displayName,
          );
      if (!hasSession) {
        throw const AuthFailure(
          'Tu cuenta fue creada; confirma tu correo antes de iniciar sesión',
        );
      }
      await ref
          .read(profileRepositoryProvider)
          .bootstrap(displayName: displayName);
    });
  }

  Future<bool> signOut() {
    return _run(() => ref.read(authRepositoryProvider).signOut());
  }

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }
}
