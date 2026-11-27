import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../../../core/widgets/tag.dart';
import '../bloc/auth_bloc.dart';

/// Onglet Profil (pas de maquette dédiée).
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc b) => b.state.user);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      body: ScreenBody(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MON PROFIL', style: AppText.bold(10, color: AppColors.primary)),
              const SizedBox(height: 2),
              Text(user.name, style: AppText.bold(25)),
            ],
          ),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Adresse e-mail', Text(user.email, style: AppText.semibold(13))),
                const Divider(height: 24, color: AppColors.border),
                _row('Rôle', Tag(user.role.label)),
                if (!user.isTeacher) ...[
                  const Divider(height: 24, color: AppColors.border),
                  _row('Niveau', Tag('Niveau ${user.level}')),
                ],
              ],
            ),
          ),
          PrimaryButton(
            label: 'Se déconnecter',
            trailingIcon: null,
            onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
          Text(
            'Serveur : ${AppConfig.apiUrl}',
            style: AppText.regular(10, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, Widget value) => Row(
    children: [
      Expanded(
        child: Text(label, style: AppText.regular(12, color: AppColors.muted)),
      ),
      value,
    ],
  );
}
