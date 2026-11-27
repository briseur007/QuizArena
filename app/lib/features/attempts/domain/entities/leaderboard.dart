import 'package:equatable/equatable.dart';

enum LeaderboardScope { quiz, course }

/// Écran 05 · Classement, trié par le serveur : score, puis durée.
class Leaderboard extends Equatable {
  const Leaderboard({required this.title, required this.participants, required this.entries});

  final String title;
  final int participants;
  final List<LeaderboardEntry> entries;

  List<LeaderboardEntry> get podium => entries.take(3).toList();

  @override
  List<Object?> get props => [title, participants, entries];
}

class LeaderboardEntry extends Equatable {
  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.score,
    required this.total,
    required this.durationSeconds,
    this.isMe = false,
  });

  final int rank;
  final String name;
  final int score;
  final int total;
  final int durationSeconds;
  final bool isMe;

  @override
  List<Object?> get props => [rank, name, score, total, durationSeconds, isMe];
}
