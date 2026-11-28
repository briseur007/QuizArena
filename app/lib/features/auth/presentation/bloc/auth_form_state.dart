import 'package:equatable/equatable.dart';

import '../../domain/entities/user.dart';

enum FormStatus { idle, submitting, success, failure }

/// État commun aux formulaires de connexion et d'inscription.
final class AuthFormState extends Equatable {
  const AuthFormState({
    this.role = UserRole.student,
    this.status = FormStatus.idle,
    this.fieldErrors = const {},
    this.message,
    this.user,
  });

  final UserRole role;
  final FormStatus status;

  /// Erreurs par champ : validation locale ou 422 du serveur (F10).
  final Map<String, String> fieldErrors;

  /// Erreur générale (réseau, identifiants incorrects…).
  final String? message;

  /// Utilisateur connecté quand [status] == success.
  final User? user;

  AuthFormState copyWith({
    UserRole? role,
    FormStatus? status,
    Map<String, String>? fieldErrors,
    String? message,
    User? user,
  }) => AuthFormState(
    role: role ?? this.role,
    status: status ?? this.status,
    fieldErrors: fieldErrors ?? this.fieldErrors,
    message: message,
    user: user ?? this.user,
  );

  @override
  List<Object?> get props => [role, status, fieldErrors, message, user];
}

/// Règles de validation locales, partagées par les deux formulaires.
abstract final class AuthValidators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String value) {
    if (value.trim().isEmpty) return "L'adresse e-mail est obligatoire.";
    if (!_email.hasMatch(value.trim())) return 'Adresse e-mail invalide.';
    return null;
  }

  static String? password(String value, {bool strict = false}) {
    if (value.isEmpty) return 'Le mot de passe est obligatoire.';
    if (strict && value.length < 8) return 'Au moins 8 caractères.';
    return null;
  }

  /// Le mot de passe retapé doit être identique (inscription, changement).
  static String? confirmation(String password, String confirm) {
    if (confirm.isEmpty) return 'Retape ton mot de passe.';
    if (confirm != password) return 'Les deux mots de passe ne correspondent pas.';
    return null;
  }

  static String? name(String value) {
    if (value.trim().length < 2) return 'Indique ton nom complet.';
    return null;
  }
}
