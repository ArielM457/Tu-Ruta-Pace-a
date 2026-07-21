class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class AuthRepository {
  Future<void> signIn({required String email, required String password});

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> signOut();
}
