import 'package:flutter/material.dart';

class AuthFormError extends StatelessWidget {
  const AuthFormError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: colorScheme.onErrorContainer),
      ),
    );
  }
}

abstract final class AuthFieldValidators {
  static const int minimumPasswordLength = 8;

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    final isValidFormat = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!isValidFormat) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  static String? password(String? value) {
    if ((value ?? '').length < minimumPasswordLength) {
      return 'La contraseña debe tener al menos $minimumPasswordLength caracteres';
    }
    return null;
  }

  static String? displayName(String? value) {
    final name = value?.trim() ?? '';
    if (name.length < 2) {
      return 'Ingresa tu nombre (mínimo 2 caracteres)';
    }
    return null;
  }
}
