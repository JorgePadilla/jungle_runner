import 'dart:convert';

enum MissionType {
  runDistance,    // "Run X meters total"
  collectCoins,  // "Collect X coins in a single run"
  useShield,     // "Use X shields"
  useMagnet,     // "Use X magnets"
  reachScore,    // "Reach Xm in a single run"
  playGames,     // "Play X games"
  slideTimes,    // "Slide X times in a single run"
  jumpTimes,     // "Jump X times in a single run"
}

class Mission {
  final String id;
  final MissionType type;
  final String title;
  final String description;
  final int target;
  int progress;
  final int coinReward;
  bool completed;
  bool claimed;

  Mission({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.target,
    this.progress = 0,
    required this.coinReward,
    this.completed = false,
    this.claimed = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'title': title,
    'description': description,
    'target': target,
    'progress': progress,
    'coinReward': coinReward,
    'completed': completed,
    'claimed': claimed,
  };

  factory Mission.fromJson(Map<String, dynamic> json) => Mission(
    id: json['id'] as String,
    type: MissionType.values[json['type'] as int],
    title: json['title'] as String,
    description: json['description'] as String,
    target: json['target'] as int,
    progress: json['progress'] as int? ?? 0,
    coinReward: json['coinReward'] as int,
    completed: json['completed'] as bool? ?? false,
    claimed: json['claimed'] as bool? ?? false,
  );

  /// Check if progress meets target and mark completed
  void updateProgress(int value) {
    progress = value;
    if (progress >= target && !completed) {
      completed = true;
    }
  }

  /// Human-readable percentage for progress
  double get progressPercent => (progress / target).clamp(0.0, 1.0);
}
