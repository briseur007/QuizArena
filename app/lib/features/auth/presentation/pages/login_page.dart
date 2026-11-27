import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/segmented_switch.dart';
import '../../domain/entities/user.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_form_state.dart';
import '../bloc/login_cubit.dart';
import '../widgets/auth_widgets.dart';

/// Écran 01 · Connexion.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => getIt<LoginCubit>(), child: const LoginView());
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscured = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<LoginCubit>().submit(email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final sessionExpired = context.select((AuthBloc b) => b.state.sessionExpired);

    return BlocListener<LoginCubit, AuthFormState>(
      listenWhen: (prev, curr) => curr.status == FormStatus.success && prev.status != curr.status,
      listener: (context, state) => context.read<AuthBloc>().add(AuthLoggedIn(state.user!)),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: BlocBuilder<LoginCubit, AuthFormState>(
                    builder: (context, state) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const BrandHeader(),
                        const SizedBox(height: 19),
                        Text('Apprends. Joue.\nDépasse-toi.', style: AppText.bold(36)),
                        const SizedBox(height: 10),
                        Text(
                          'Tes cours deviennent un terrain de jeu.\nPrêt à relever le prochain défi ?',
                          style: AppText.regular(14, color: AppColors.muted),
                        ),
                        const SizedBox(height: 19),
                        SegmentedSwitch<UserRole>(
                          options: {for (final r in UserRole.values) r: r.label},
                          selected: state.role,
                          onChanged: context.read<LoginCubit>().roleChanged,
                        ),
                        const SizedBox(height: 19),
                        if (sessionExpired && state.message == null) ...[
                          const FormErrorBanner('Ta session a expiré. Reconnecte-toi.'),
                          const SizedBox(height: 14),
                        ],
                        if (state.message != null) ...[FormErrorBanner(state.message!), const SizedBox(height: 14)],
                        AutofillGroup(
                          child: Column(
                            children: [
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
                                hint: '••••••••••••',
                                controller: _password,
                                errorText: state.fieldErrors['password'],
                                obscureText: _obscured,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                onSubmitted: (_) => _submit(),
                                suffix: PasswordVisibilityButton(
                                  obscured: _obscured,
                                  onPressed: () => setState(() => _obscured = !_obscured),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 19),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Contacte ton établissement pour réinitialiser ton mot de passe.'),
                              ),
                            ),
                            child: Text('Mot de passe oublié ?', style: AppText.semibold(12, color: AppColors.primary)),
                          ),
                        ),
                        const SizedBox(height: 19),
                        PrimaryButton(
                          label: 'Se connecter',
                          loading: state.status == FormStatus.submitting,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 19),
                        const InfoBanner('Un compte, tous tes cours et tes résultats.'),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 72,
                child: Center(
                  child: InkWell(
                    onTap: () => context.push(Routes.register, extra: context.read<LoginCubit>().state.role),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Pas encore de compte ? Créer un compte',
                        style: AppText.semibold(12, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
