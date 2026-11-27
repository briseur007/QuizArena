import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/segmented_switch.dart';
import '../../domain/entities/user.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_form_state.dart';
import '../bloc/register_cubit.dart';
import '../widgets/auth_widgets.dart';

/// Création de compte (lien « Créer un compte » de l'écran 01).
/// Pas de maquette dédiée : reprend les composants de l'écran de connexion.
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key, this.initialRole = UserRole.student});

  final UserRole initialRole;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RegisterCubit(getIt(), initialRole: initialRole),
      child: const RegisterView(),
    );
  }
}

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscured = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<RegisterCubit>().submit(name: _name.text, email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegisterCubit, AuthFormState>(
      listenWhen: (prev, curr) => curr.status == FormStatus.success && prev.status != curr.status,
      listener: (context, state) => context.read<AuthBloc>().add(AuthLoggedIn(state.user!)),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: BlocBuilder<RegisterCubit, AuthFormState>(
              builder: (context, state) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeader(
                    title: 'Créer un compte',
                    subtitle: 'Rejoins tes cours en quelques secondes.',
                    onBack: () => context.pop(),
                  ),
                  const SizedBox(height: 19),
                  SegmentedSwitch<UserRole>(
                    options: {for (final r in UserRole.values) r: r.label},
                    selected: state.role,
                    onChanged: context.read<RegisterCubit>().roleChanged,
                  ),
                  const SizedBox(height: 19),
                  if (state.message != null) ...[FormErrorBanner(state.message!), const SizedBox(height: 14)],
                  AutofillGroup(
                    child: Column(
                      children: [
                        LabeledField(
                          label: 'Nom complet',
                          hint: 'Amina Ouédraogo',
                          controller: _name,
                          errorText: state.fieldErrors['name'],
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                        ),
                        const SizedBox(height: 14),
                        LabeledField(
                          label: 'Adresse e-mail',
                          hint: 'prenom@universite.bf',
                          controller: _email,
                          errorText: state.fieldErrors['email'],
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                        ),
                        const SizedBox(height: 14),
                        LabeledField(
                          label: 'Mot de passe',
                          hint: '8 caractères minimum',
                          controller: _password,
                          errorText: state.fieldErrors['password'],
                          obscureText: _obscured,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onSubmitted: (_) => _submit(),
                          suffix: PasswordVisibilityButton(
                            obscured: _obscured,
                            onPressed: () => setState(() => _obscured = !_obscured),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Créer mon compte',
                    loading: state.status == FormStatus.submitting,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.role == UserRole.teacher
                        ? 'En tant qu’enseignant, tu pourras créer des cours et des quiz.'
                        : 'En tant qu’étudiant, tu rejoindras tes cours avec un code.',
                    style: AppText.regular(11, color: AppColors.muted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
