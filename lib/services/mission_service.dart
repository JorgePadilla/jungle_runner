import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mission.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

/// Manages 3 active missions at a time, persisted via SharedPreferences.
class MissionService {
  static MissionService? _instance;
  static SharedPreferences? _prefs;

  MissionService._internal();

  static Future<MissionService> getInstance() async {
    if (_instance == null) {
      _instance = MissionService._internal();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // ── Persistence ─────────────────────────────────────────────────

  Future<List<Mission>> getActiveMissions() async {
    final raw = _prefs?.getString(StorageKeys.activeMissions);
    if (raw == null || raw.isEmpty) {
      // First launch → generate 3 missions
      final missions = <Mission>[];
      for (var i = 0; i < 3; i++) {
        missions.add(_generateNewMission(missions));
      }
      await _saveMissions(missions);
      return missions;
    }
    final List decoded = jsonDecode(raw);
    return decoded.map((e) => Mission.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _saveMissions(List<Mission> missions) async {
    final json = jsonEncode(missions.map((m) => m.toJson()).toList());
    await _prefs?.setString(StorageKeys.activeMissions, json);
  }

  int _getCompletedCount() {
    return _prefs?.getInt(StorageKeys.completedMissionsCount) ?? 0;
  }

  Future<void> _incrementCompletedCount() async {
    final current = _getCompletedCount();
    await _prefs?.setInt(StorageKeys.completedMissionsCount, current + 1);
  }

  // ── Difficulty tier ────────────────────────────────────────────

  /// 0 = easy, 1 = medium, 2 = hard. Scales with total missions completed.
  int _difficultyTier() {
    final completed = _getCompletedCount();
    if (completed < 6) return 0;
    if (completed < 15) return 1;
    return 2;
  }

  // ── Mission templates ──────────────────────────────────────────

  static const _easyTemplates = <_MissionTemplate>[
    _MissionTemplate(MissionType.runDistance,  'Short Sprint',      'Run 100m total',                100,  25),
    _MissionTemplate(MissionType.collectCoins, 'Coin Collector',    'Collect 20 coins in one run',    20,  30),
    _MissionTemplate(MissionType.playGames,    'Getting Started',   'Play 3 games',                    3,  20),
    _MissionTemplate(MissionType.jumpTimes,    'Bouncy',            'Jump 10 times in one run',       10,  20),
    _MissionTemplate(MissionType.slideTimes,   'Slider',            'Slide 5 times in one run',        5,  20),
    _MissionTemplate(MissionType.reachScore,   'First Steps',       'Reach 50m in a single run',      50,  25),
    _MissionTemplate(MissionType.useShield,    'Shield Up',         'Use 1 shield',                    1,  25),
    _MissionTemplate(MissionType.useMagnet,    'Magnetic',          'Use 1 magnet',                    1,  25),
  ];

  static const _mediumTemplates = <_MissionTemplate>[
    _MissionTemplate(MissionType.runDistance,  'Distance Runner',   'Run 500m in one run',            500,  75),
    _MissionTemplate(MissionType.collectCoins, 'Gold Rush',         'Collect 50 coins in one run',     50,  60),
    _MissionTemplate(MissionType.useShield,    'Shield Master',     'Use 3 shields',                    3,  50),
    _MissionTemplate(MissionType.useMagnet,    'Magnet Mania',      'Use 3 magnets',                    3,  50),
    _MissionTemplate(MissionType.reachScore,   'Explorer',          'Reach 300m in a single run',     300,  60),
    _MissionTemplate(MissionType.playGames,    'Persistent',        'Play 5 games',                     5,  40),
    _MissionTemplate(MissionType.jumpTimes,    'Kangaroo',          'Jump 25 times in one run',        25,  50),
    _MissionTemplate(MissionType.slideTimes,   'Slip-n-Slide',      'Slide 10 times in one run',       10,  45),
  ];

  static const _hardTemplates = <_MissionTemplate>[
    _MissionTemplate(MissionType.runDistance,  'Marathon',          'Run 1000m in one run',          1000, 150),
    _MissionTemplate(MissionType.collectCoins, 'Treasure Hunter',   'Collect 100 coins in one run',  100, 120),
    _MissionTemplate(MissionType.slideTimes,   'Limbo King',        'Slide 20 times in one run',      20, 100),
    _MissionTemplate(MissionType.reachScore,   'Survivor',          'Reach 750m in a single run',    750, 130),
    _MissionTemplate(MissionType.jumpTimes,    'Sky High',          'Jump 50 times in one run',       50, 110),
    _MissionTemplate(MissionType.playGames,    'Veteran',           'Play 10 games',                   10,  80),
    _MissionTemplate(MissionType.useShield,    'Tank',              'Use 5 shields',                    5, 100),
    _MissionTemplate(MissionType.useMagnet,    'Magnetic Force',    'Use 5 magnets',                    5, 100),
  ];

  List<_MissionTemplate> _templatesForTier(int tier) {
    switch (tier) {
      case 0:  return _easyTemplates;
      case 1:  return _mediumTemplates;
      default: return _hardTemplates;
    }
  }

  // ── Generation ─────────────────────────────────────────────────

  Mission _generateNewMission([List<Mission>? existing]) {
    final rng = Random();
    final tier = _difficultyTier();

    // Mix in templates from the current tier, with a small chance of one tier up
    List<_MissionTemplate> pool;
    if (rng.nextDouble() < 0.3 && tier < 2) {
      pool = _templatesForTier(tier + 1);
    } else {
      pool = _templatesForTier(tier);
    }

    // Avoid duplicate mission types among active missions
    final existingTypes = existing?.map((m) => m.type).toSet() ?? <MissionType>{};
    final filtered = pool.where((t) => !existingTypes.contains(t.type)).toList();
    final candidates = filtered.isNotEmpty ? filtered : pool;

    final template = candidates[rng.nextInt(candidates.length)];

    return Mission(
      id: '${template.type.index}_${DateTime.now().millisecondsSinceEpoch}_${rng.nextInt(9999)}',
      type: template.type,
      title: template.title,
      description: template.description,
      target: template.target,
      coinReward: template.reward,
    );
  }

  // ── Public API ─────────────────────────────────────────────────

  /// Update progress for all active missions matching [type].
  /// [value] is the amount to add (e.g. distance run, coins collected).
  /// For "per-run" missions the caller should pass the run total, not a delta.
  Future<void> updateProgress(MissionType type, int value) async {
    final missions = await getActiveMissions();
    bool changed = false;

    for (final m in missions) {
      if (m.type == type && !m.completed) {
        // Cumulative missions (playGames, useShield, useMagnet) add to existing
        // Per-run missions (collectCoins, runDistance, reachScore, slideTimes, jumpTimes)
        // use the higher of existing progress and this run's value
        if (_isCumulative(type)) {
          m.updateProgress(m.progress + value);
        } else {
          // Per-run: take the max so re-playing can still raise progress
          if (value > m.progress) {
            m.updateProgress(value);
          }
        }
        changed = true;
      }
    }

    if (changed) await _saveMissions(missions);
  }

  bool _isCumulative(MissionType type) {
    return type == MissionType.playGames ||
        type == MissionType.useShield ||
        type == MissionType.useMagnet;
  }

  /// Claim a completed mission → award coins, replace with new mission.
  Future<int> claimMission(String id) async {
    final missions = await getActiveMissions();
    final idx = missions.indexWhere((m) => m.id == id);
    if (idx == -1) return 0;

    final mission = missions[idx];
    if (!mission.completed || mission.claimed) return 0;

    // Award coins
    final storageService = await StorageService.getInstance();
    await storageService.addCoins(mission.coinReward);
    await _incrementCompletedCount();

    // Replace with a new mission
    missions[idx] = _generateNewMission(
      missions.where((m) => m.id != id).toList(),
    );
    await _saveMissions(missions);

    return mission.coinReward;
  }

  /// True if any active mission is completed but unclaimed.
  Future<bool> hasClaimableMission() async {
    final missions = await getActiveMissions();
    return missions.any((m) => m.completed && !m.claimed);
  }
}

/// Internal helper for mission templates.
class _MissionTemplate {
  final MissionType type;
  final String title;
  final String description;
  final int target;
  final int reward;
  const _MissionTemplate(this.type, this.title, this.description, this.target, this.reward);
}
