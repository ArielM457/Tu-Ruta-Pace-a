import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (exception) {
      throw AuthFailure(_toSpanishMessage(exception));
    }
  }

  @override
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );
      return response.session != null;
    } on AuthException catch (exception) {
      throw AuthFailure(_toSpanishMessage(exception));
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  String _toSpanishMessage(AuthException exception) {
    switch (exception.code) {
      case 'invalid_credentials':
        return 'Correo o contraseña incorrectos';
      case 'email_address_invalid':
        return 'Ese correo no es válido para registrarse; usa un correo real (ej. tu Gmail)';
      case 'signup_disabled':
        return 'El registro de cuentas nuevas está desactivado en este proyecto';
      case 'email_exists':
      case 'user_already_exists':
        return 'Ya existe una cuenta con este correo';
      case 'weak_password':
        return 'La contraseña debe tener al menos 8 caracteres';
      case 'over_request_rate_limit':
        return 'Demasiados intentos; espera un momento y vuelve a intentar';
      default:
        return 'No se pudo completar la operación. Intenta de nuevo.';
    }
  }
}
