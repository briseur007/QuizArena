import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/segmented_switch.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/surface_card.dart';
import '../../domain/entities/leaderboard.dart';
import '../bloc/leaderboard_cubit.dart';

/// Écran 05 · Classement (onglet de l'étudiant).
class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key, this.quizId, this.courseId});

  final String? quizId;
  final String? courseId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LeaderboardCubit>()..load(quizId: quizId, courseId: courseId),
      child: const LeaderboardView(),
    );
  }
}

class LeaderboardView extends StatelessWidget {
  const LeaderboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<LeaderboardCubit, LeaderboardState>(
        builder: (context, state) {
          final cubit = context.read<LeaderboardCubit>();
          final board = state.leaderboard;
          return ScreenBody(
            onRefresh: cubit.retry,
            children: [
              PageHeader(
                title: 'Le classement',
                subtitle: board == null
                    ? null
                    : '${board.title} · ${state.scope == LeaderboardScope.quiz ? 'Résultats du quiz' : 'Tous les quiz du cours'}',
                onBack: context.canPop() ? () => context.pop() : null,
              ),
              if (state.quizId != null)
                SegmentedSwitch<LeaderboardScope>(
                  options: const {LeaderboardScope.quiz: 'Ce quiz', LeaderboardScope.course: 'Mon cours'},
                  selected: state.scope,
                  onChanged: cubit.scopeChanged,
                  fontSize: 12,
                  itemPadding: 9,
                ),
              ...switch (state.status) {
                LeaderboardStatus.loading => [const LoadingView()],
                LeaderboardStatus.failure => [ErrorView(message: state.message ?? 'Erreur', onRetry: cubit.retry)],
                LeaderboardStatus.empty => [
                  const EmptyView(
                    title: 'Pas encore de classement',
                    message: 'Passe un quiz pour apparaître ici. Le classement est mis à jour après chaque remise.',
                  ),
                ],
                LeaderboardStatus.success => [
                  _Podium(entries: board!.podium),
                  Row(
                    children: [
                      Expanded(child: Text(Fmt.plural(board.participants, 'participant'), style: AppText.semibold(13))),
                      Text('Score, puis durée', style: AppText.medium(10, color: AppColors.muted)),
                    ],
                  ),
                  SurfaceCard(
                    padding: EdgeInsets.zero,
                    child: Column(children: [for (final e in board.entries) _RankRow(entry: e)]),
                  ),
                  Text(
                    'Classement mis à jour après chaque remise.',
                    style: AppText.regular(11, color: AppColors.muted),
                  ),
                ],
              },
            ],
          );
        },
      ),
    );
  }
}

/// Podium « LES CHAMPIONS DU JOUR » : 2e, 1er, 3e.
class _Podium extends StatelessWidget {
  const _Podium({required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    LeaderboardEntry? at(int i) => i < entries.length ? entries[i] : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Text('LES CHAMPIONS DU JOUR', style: AppText.bold(10, color: Colors.white)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _Step(entry: at(1), verticalPadding: 12)),
              const SizedBox(width: 8),
              Expanded(child: _Step(entry: at(0), verticalPadding: 23, highlighted: true)),
              const SizedBox(width: 8),
              Expanded(child: _Step(entry: at(2), verticalPadding: 8)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.entry, required this.verticalPadding, this.highlighted = false});

  final LeaderboardEntry? entry;
  final double verticalPadding;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    if (entry == null) return const SizedBox.shrink();
    final fg = highlighted ? AppColors.primary : Colors.white;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: highlighted ? Colors.white : AppColors.primaryMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('${entry!.rank}', style: AppText.bold(28, color: fg)),
          const SizedBox(height: 4),
          Text(
            Fmt.firstName(entry!.name),
            style: AppText.semibold(12, color: fg),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text('${entry!.score}/${entry!.total}', style: AppText.medium(11, color: fg)),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final me = entry.isMe;
    final strong = me ? AppColors.primary : AppColors.ink;
    return Container(
      color: me ? AppColors.primarySoft : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Text(Fmt.twoDigits(entry.rank), style: AppText.bold(12, color: me ? AppColors.primary : AppColors.muted)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  me ? '${Fmt.firstName(entry.name)} · toi' : entry.name,
                  style: AppText.semibold(12, color: strong),
                ),
                const SizedBox(height: 2),
                Text(Fmt.seconds(entry.durationSeconds), style: AppText.regular(10, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('${entry.score}/${entry.total}', style: AppText.bold(13, color: strong)),
        ],
      ),
    );
  }
}
