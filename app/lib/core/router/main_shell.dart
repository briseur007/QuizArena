import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_icon.dart';

/// Barre de navigation du bas de la maquette :
/// étudiant « Mes cours · Classement · Profil »,
/// enseignant « Mes cours · Résultats · Profil ».
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final isTeacher = context.select((AuthBloc b) => b.state.user?.isTeacher ?? false);
    final items = [
      (AppIcons.book, 'Mes cours'),
      (AppIcons.chart, isTeacher ? 'Résultats' : 'Classement'),
      (AppIcons.user, 'Profil'),
    ];

    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final (index, (icon, label)) in items.indexed)
                    _NavItem(
                      icon: icon,
                      label: label,
                      selected: shell.currentIndex == index,
                      // Re-taper l'onglet actif revient à sa racine.
                      onTap: () => shell.goBranch(index, initialLocation: index == shell.currentIndex),
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

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final AppIcons icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.muted;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(icon, size: 21, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: selected ? AppText.semibold(10, color: color) : AppText.medium(10, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
