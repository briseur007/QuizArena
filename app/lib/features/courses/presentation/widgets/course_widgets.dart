import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../domain/entities/course.dart';

/// Ligne de cours de l'écran 02 : « 01 · Développement mobile · Dr Nikiema… › ».
class CourseTile extends StatelessWidget {
  const CourseTile({super.key, required this.course, required this.position, this.onTap});

  final Course course;

  /// Position dans la liste (1, 2, …), affichée dans la pastille.
  final int position;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badgeColor = position.isOdd ? AppColors.primarySoft : AppColors.warningSoft;
    return SurfaceCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
            child: Text(Fmt.twoDigits(position), style: AppText.bold(16), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.name, style: AppText.semibold(14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  '${course.teacherName} · ${Fmt.plural(course.quizCount, 'quiz disponible', 'quiz disponibles')}',
                  style: AppText.regular(10, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const AppIcon(AppIcons.chevron, color: AppColors.muted),
        ],
      ),
    );
  }
}

/// Carte « + Rejoindre un cours » avec saisie du code.
class JoinCourseCard extends StatefulWidget {
  const JoinCourseCard({super.key, required this.onJoin, this.loading = false});

  final ValueChanged<String> onJoin;
  final bool loading;

  @override
  State<JoinCourseCard> createState() => _JoinCourseCardState();
}

class _JoinCourseCardState extends State<JoinCourseCard> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    widget.onJoin(_code.text);
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon(AppIcons.plus, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Rejoindre un cours', style: AppText.semibold(14)),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _submit(),
                  style: AppText.semibold(12),
                  decoration: InputDecoration(
                    hintText: 'Entrer le code du cours',
                    hintStyle: AppText.regular(12, color: AppColors.muted),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: widget.loading ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: widget.loading
                        ? const SizedBox.square(
                            dimension: 15,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text('Rejoindre', style: AppText.semibold(11, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Petite ligne d'information « ✓ Dernier quiz : 8/10… ».
class InfoLine extends StatelessWidget {
  const InfoLine({super.key, required this.icon, required this.text, this.color = AppColors.muted, this.iconColor});

  final AppIcons icon;
  final String text;
  final Color color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIcon(icon, color: iconColor ?? color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: AppText.regular(11, color: color)),
        ),
      ],
    );
  }
}
