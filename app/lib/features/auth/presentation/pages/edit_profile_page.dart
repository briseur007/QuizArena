import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../domain/entities/user.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_form_state.dart';
import '../bloc/edit_profile_cubit.dart';
import '../widgets/auth_widgets.dart';

/// Modifier ses informations (nom, e-mail) et son mot de passe.
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => getIt<EditProfileCubit>(), child: const EditProfileView());
  }
}

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late final User _initial = context.read<AuthBloc>().state.user!;
  late final _name = TextEditingController(text: _initial.name);
  late final _email = TextEditingController(text: _initial.email);
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscured = true;

  @override
  void dispose() {
    for (final c in [_name, _email, _current, _new, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _saveProfile() {
    FocusScope.of(context).unfocus();
    context.read<EditProfileCubit>().saveProfile(
      current: context.read<AuthBloc>().state.user!,
      name: _name.text,
      email: _email.text,
    );
  }

  void _changePassword() {
    FocusScope.of(context).unfocus();
    context.read<EditProfileCubit>().changePassword(
      currentPassword: _current.text,
      newPassword: _new.text,
      confirmPassword: _confirm.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<EditProfileCubit, EditProfileState>(
          listenWhen: (p, c) => c.message != null,
          listener: (context, state) =>
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!))),
        ),
        // Profil enregistré : toute l'app (en-têtes, profil) affiche le nouveau nom.
        BlocListener<EditProfileCubit, EditProfileState>(
          listenWhen: (p, c) => c.profileStatus == FormStatus.success && p.profileStatus != c.profileStatus,
          listener: (context, state) => context.read<AuthBloc>().add(AuthUserUpdated(state.user!)),
        ),
        // Mot de passe changé : on vide les champs.
        BlocListener<EditProfileCubit, EditProfileState>(
          listenWhen: (p, c) => c.passwordStatus == FormStatus.success && p.passwordStatus != c.passwordStatus,
          listener: (context, state) {
            for (final c in [_current, _new, _confirm]) {
              c.clear();
            }
          },
        ),
      ],
      child: Scaffold(
        body: BlocBuilder<EditProfileCubit, EditProfileState>(
          builder: (context, state) => ScreenBody(
            children: [
              PageHeader(
                title: 'Mon profil',
                subtitle: '${_initial.role.label} · le rôle ne peut pas être modifié',
                onBack: () => context.pop(),
              ),

              // Mes informations
              SurfaceCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Mes informations', style: AppText.bold(17)),
                    const SizedBox(height: 14),
                    LabeledField(
                      label: 'Nom complet',
                      controller: _name,
                      errorText: state.fieldErrors['name'],
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                    ),
                    const SizedBox(height: 14),
                    LabeledField(
                      label: 'Adresse e-mail',
                      controller: _email,
                      errorText: state.fieldErrors['email'],
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      onSubmitted: (_) => _saveProfile(),
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: 'Enregistrer',
                      trailingIcon: null,
                      fontSize: 14,
                      verticalPadding: 13,
                      loading: state.profileStatus == FormStatus.submitting,
                      onPressed: _saveProfile,
                    ),
                  ],
                ),
              ),

              // Mot de passe
              SurfaceCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Mot de passe', style: AppText.bold(17)),
                    const SizedBox(height: 4),
                    Text(
                      'Tes autres appareils seront déconnectés.',
                      style: AppText.regular(11, color: AppColors.muted),
                    ),
                    const SizedBox(height: 14),
                    LabeledField(
                      label: 'Mot de passe actuel',
                      controller: _current,
                      obscureText: _obscured,
                      errorText: state.fieldErrors['currentPassword'],
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.password],
                      suffix: PasswordVisibilityButton(
                        obscured: _obscured,
                        onPressed: () => setState(() => _obscured = !_obscured),
                      ),
                    ),
                    const SizedBox(height: 14),
                    LabeledField(
                      label: 'Nouveau mot de passe',
                      hint: '8 caractères minimum',
                      controller: _new,
                      obscureText: _obscured,
                      errorText: state.fieldErrors['newPassword'],
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                    ),
                    const SizedBox(height: 14),
                    LabeledField(
                      label: 'Confirmer le nouveau mot de passe',
                      controller: _confirm,
                      obscureText: _obscured,
                      errorText: state.fieldErrors['confirmPassword'],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _changePassword(),
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: 'Changer le mot de passe',
                      trailingIcon: null,
                      fontSize: 14,
                      verticalPadding: 13,
                      loading: state.passwordStatus == FormStatus.submitting,
                      onPressed: _changePassword,
                    ),
                  ],
                ),
              ),
              const InfoBanner('Ton nom apparaît dans les classements et sur les résultats.'),
            ],
          ),
        ),
      ),
    );
  }
}
