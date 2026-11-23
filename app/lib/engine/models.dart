class Player {
  const Player({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.tags,
  });

  final String id;
  final String name;
  final String difficulty;
  final List<String> tags;

  Player copy() => Player(
        id: id,
        name: name,
        difficulty: difficulty,
        tags: List<String>.from(tags),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'difficulty': difficulty,
        'tags': tags,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        name: json['name'] as String,
        difficulty: json['difficulty'] as String,
        tags: (json['tags'] as List).map((e) => e as String).toList(),
      );
}

class TeamConfig {
  const TeamConfig({required this.name, required this.members});

  final String name;
  final List<String> members;

  TeamConfig copy() =>
      TeamConfig(name: name, members: List<String>.from(members));

  Map<String, dynamic> toJson() => {'name': name, 'members': members};

  factory TeamConfig.fromJson(Map<String, dynamic> json) => TeamConfig(
        name: json['name'] as String,
        members: (json['members'] as List).map((e) => e as String).toList(),
      );
}

class MatchConfig {
  const MatchConfig({
    required this.teams,
    required this.seconds,
    required this.target,
    required this.category,
    required this.difficulty,
    this.customNames = '',
  });

  final List<TeamConfig> teams;
  final int seconds;
  final int target;
  final String category;
  final String difficulty;
  final String customNames;

  MatchConfig copy() => MatchConfig(
        teams: teams.map((t) => t.copy()).toList(),
        seconds: seconds,
        target: target,
        category: category,
        difficulty: difficulty,
        customNames: customNames,
      );

  Map<String, dynamic> toJson() => {
        'teams': teams.map((t) => t.toJson()).toList(),
        'seconds': seconds,
        'target': target,
        'category': category,
        'difficulty': difficulty,
        'customNames': customNames,
      };

  factory MatchConfig.fromJson(Map<String, dynamic> json) => MatchConfig(
        teams: (json['teams'] as List)
            .map((e) => TeamConfig.fromJson(e as Map<String, dynamic>))
            .toList(),
        seconds: json['seconds'] as int,
        target: json['target'] as int,
        category: json['category'] as String,
        difficulty: json['difficulty'] as String,
        customNames: (json['customNames'] as String?) ?? '',
      );

  static MatchConfig defaults() => const MatchConfig(
        teams: [
          TeamConfig(name: 'الصقور', members: ['اللاعب ١', 'اللاعب ٢']),
          TeamConfig(name: 'النمور', members: ['اللاعب ٣', 'اللاعب ٤']),
        ],
        seconds: 90,
        target: 5,
        category: 'all',
        difficulty: 'all',
      );
}

class Hint {
  const Hint({required this.team, required this.word});

  final int team;
  final String word;

  Hint copy() => Hint(team: team, word: word);

  Map<String, dynamic> toJson() => {'team': team, 'word': word};

  factory Hint.fromJson(Map<String, dynamic> json) => Hint(
        team: json['team'] as int,
        word: json['word'] as String,
      );
}

class RoundOutcome {
  const RoundOutcome({required this.winner, required this.reason});

  final int? winner;
  final String reason;

  RoundOutcome copy() => RoundOutcome(winner: winner, reason: reason);

  Map<String, dynamic> toJson() => {'winner': winner, 'reason': reason};

  factory RoundOutcome.fromJson(Map<String, dynamic> json) => RoundOutcome(
        winner: json['winner'] as int?,
        reason: json['reason'] as String,
      );
}

class RoundState {
  RoundState({
    required this.number,
    required this.player,
    required this.revealStep,
    required this.seen,
    required this.turn,
    required this.clues,
    required this.hints,
    required this.remaining,
    required this.deadline,
    required this.paused,
    required this.outcome,
  });

  final int number;
  final Player player;
  int revealStep;
  List<bool> seen;
  int turn;
  List<int> clues;
  List<Hint> hints;
  double? remaining;
  int? deadline;
  bool paused;
  RoundOutcome? outcome;

  RoundState copy() => RoundState(
        number: number,
        player: player.copy(),
        revealStep: revealStep,
        seen: List<bool>.from(seen),
        turn: turn,
        clues: List<int>.from(clues),
        hints: hints.map((h) => h.copy()).toList(),
        remaining: remaining,
        deadline: deadline,
        paused: paused,
        outcome: outcome?.copy(),
      );

  Map<String, dynamic> toJson() => {
        'number': number,
        'player': player.toJson(),
        'revealStep': revealStep,
        'seen': seen,
        'turn': turn,
        'clues': clues,
        'hints': hints.map((h) => h.toJson()).toList(),
        'remaining': remaining,
        'deadline': deadline,
        'paused': paused,
        'outcome': outcome?.toJson(),
      };

  factory RoundState.fromJson(Map<String, dynamic> json) => RoundState(
        number: json['number'] as int,
        player: Player.fromJson(json['player'] as Map<String, dynamic>),
        revealStep: json['revealStep'] as int,
        seen: (json['seen'] as List).map((e) => e as bool).toList(),
        turn: json['turn'] as int,
        clues: (json['clues'] as List).map((e) => (e as num).toInt()).toList(),
        hints: (json['hints'] as List)
            .map((e) => Hint.fromJson(e as Map<String, dynamic>))
            .toList(),
        remaining: (json['remaining'] as num?)?.toDouble(),
        deadline: json['deadline'] as int?,
        paused: json['paused'] as bool,
        outcome: json['outcome'] == null
            ? null
            : RoundOutcome.fromJson(json['outcome'] as Map<String, dynamic>),
      );
}

class HistoryEntry {
  const HistoryEntry({
    required this.number,
    required this.player,
    required this.winner,
    required this.reason,
    required this.clues,
    required this.hints,
  });

  final int number;
  final Player player;
  final int? winner;
  final String reason;
  final List<int> clues;
  final List<Hint> hints;

  HistoryEntry copy() => HistoryEntry(
        number: number,
        player: player.copy(),
        winner: winner,
        reason: reason,
        clues: List<int>.from(clues),
        hints: hints.map((h) => h.copy()).toList(),
      );

  Map<String, dynamic> toJson() => {
        'number': number,
        'player': player.toJson(),
        'winner': winner,
        'reason': reason,
        'clues': clues,
        'hints': hints.map((h) => h.toJson()).toList(),
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        number: json['number'] as int,
        player: Player.fromJson(json['player'] as Map<String, dynamic>),
        winner: json['winner'] as int?,
        reason: json['reason'] as String,
        clues: (json['clues'] as List).map((e) => (e as num).toInt()).toList(),
        hints: (json['hints'] as List)
            .map((e) => Hint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class MatchState {
  MatchState({
    required this.version,
    required this.config,
    required this.deck,
    required this.cursor,
    required this.scores,
    required this.history,
    required this.phase,
    required this.current,
    required this.endReason,
  });

  final int version;
  final MatchConfig config;
  final List<Player> deck;
  int cursor;
  List<int> scores;
  List<HistoryEntry> history;
  String phase;
  RoundState? current;
  String? endReason;

  MatchState copy() => MatchState(
        version: version,
        config: config.copy(),
        deck: deck.map((p) => p.copy()).toList(),
        cursor: cursor,
        scores: List<int>.from(scores),
        history: history.map((h) => h.copy()).toList(),
        phase: phase,
        current: current?.copy(),
        endReason: endReason,
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'config': config.toJson(),
        'deck': deck.map((p) => p.toJson()).toList(),
        'cursor': cursor,
        'scores': scores,
        'history': history.map((h) => h.toJson()).toList(),
        'phase': phase,
        'current': current?.toJson(),
        'endReason': endReason,
      };

  factory MatchState.fromJson(Map<String, dynamic> json) => MatchState(
        version: json['version'] as int,
        config: MatchConfig.fromJson(json['config'] as Map<String, dynamic>),
        deck: (json['deck'] as List)
            .map((e) => Player.fromJson(e as Map<String, dynamic>))
            .toList(),
        cursor: json['cursor'] as int,
        scores:
            (json['scores'] as List).map((e) => (e as num).toInt()).toList(),
        history: (json['history'] as List)
            .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        phase: json['phase'] as String,
        current: json['current'] == null
            ? null
            : RoundState.fromJson(json['current'] as Map<String, dynamic>),
        endReason: json['endReason'] as String?,
      );
}
