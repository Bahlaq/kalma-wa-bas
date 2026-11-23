import 'models.dart';

const int engineVersion = 1;

final RegExp _oneWordPattern = RegExp(r'^[\p{L}\p{M}\p{N}]+$', unicode: true);
final RegExp _tashkeelPattern = RegExp(r'[\u064B-\u065F\u0670\u0640]');
final RegExp _alefPattern = RegExp('[أإآ]');

String normalizeWord(String word) {
  return word
      .trim()
      .replaceAll(_tashkeelPattern, '')
      .replaceAll(_alefPattern, 'ا')
      .toLowerCase();
}

List<Player> makePool(List<Player> players, MatchConfig config) {
  final customLines = (config.customNames)
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet()
      .take(150)
      .toList();
  final custom = <Player>[
    for (var i = 0; i < customLines.length; i++)
      Player(
        id: 'custom-$i',
        name: customLines[i].length > 70
            ? customLines[i].substring(0, 70)
            : customLines[i],
        difficulty: 'custom',
        tags: const ['custom'],
      ),
  ];

  final filtered = config.category == 'custom'
      ? <Player>[]
      : players
          .where(
            (p) =>
                (config.category == 'all' ||
                    p.tags.contains(config.category)) &&
                (config.difficulty == 'all' ||
                    p.difficulty == config.difficulty),
          )
          .toList();

  final combined = [...filtered, ...custom];
  final seen = <String>{};
  return combined.where((p) {
    final key = normalizeWord(p.name);
    if (seen.contains(key)) return false;
    seen.add(key);
    return true;
  }).toList();
}

List<T> shuffled<T>(List<T> list, [double Function()? rng]) {
  final random = rng ?? () => (DateTime.now().microsecondsSinceEpoch % 10000) / 10000.0;
  final a = List<T>.from(list);
  for (var i = a.length - 1; i > 0; i--) {
    final j = (random() * (i + 1)).floor();
    final tmp = a[i];
    a[i] = a[j];
    a[j] = tmp;
  }
  return a;
}

MatchState createMatch(
  MatchConfig config,
  List<Player> players, [
  double Function()? rng,
]) {
  final deck = shuffled(makePool(players, config), rng);
  if (deck.length < 2) {
    throw StateError('اختاروا لاعبين اثنين على الأقل لبدء التحدّي.');
  }
  final state = MatchState(
    version: engineVersion,
    config: config.copy(),
    deck: deck,
    cursor: 0,
    scores: [0, 0],
    history: [],
    phase: 'reveal',
    current: null,
    endReason: null,
  );
  return nextRound(state);
}

MatchState nextRound(MatchState previous, {bool replace = false}) {
  final state = previous.copy();
  if (state.cursor >= state.deck.length) {
    state.phase = 'finished';
    state.endReason = 'exhausted';
    return state;
  }
  final number = replace ? state.current!.number : state.history.length + 1;
  final player = state.deck[state.cursor++];
  state.current = RoundState(
    number: number,
    player: player,
    revealStep: 0,
    seen: [false, false],
    turn: (number - 1) % 2,
    clues: [0, 0],
    hints: [],
    remaining: state.config.seconds == 0 ? null : state.config.seconds.toDouble(),
    deadline: null,
    paused: false,
    outcome: null,
  );
  state.phase = 'reveal';
  return state;
}

MatchState markSeen(MatchState previous) {
  final state = previous.copy();
  if (state.phase == 'reveal' && state.current != null) {
    state.current!.seen[state.current!.revealStep] = true;
  }
  return state;
}

MatchState acknowledge(MatchState previous) {
  final state = previous.copy();
  if (state.phase != 'reveal' || state.current == null) return state;
  if (!state.current!.seen[state.current!.revealStep]) return state;
  if (state.current!.revealStep == 0) {
    state.current!.revealStep = 1;
  } else {
    state.phase = 'ready';
  }
  return state;
}

MatchState startRound(MatchState previous, [int? now]) {
  final timestamp = now ?? DateTime.now().millisecondsSinceEpoch;
  final state = previous.copy();
  if (state.phase != 'ready' || state.current == null) return state;
  state.phase = 'playing';
  state.current!.paused = false;
  state.current!.deadline = state.config.seconds == 0
      ? null
      : timestamp + (state.current!.remaining! * 1000).round();
  return state;
}

double? remaining(MatchState state, [int? now]) {
  if (state.config.seconds == 0 || state.current == null) return null;
  final timestamp = now ?? DateTime.now().millisecondsSinceEpoch;
  if (state.current!.deadline == null) return state.current!.remaining;
  return ((state.current!.deadline! - timestamp) / 1000).clamp(0, double.infinity);
}

MatchState pause(MatchState previous, [int? now]) {
  final timestamp = now ?? DateTime.now().millisecondsSinceEpoch;
  final state = previous.copy();
  if (state.phase != 'playing' || state.current == null) return state;
  state.current!.remaining = remaining(state, timestamp);
  state.current!.deadline = null;
  state.current!.paused = true;
  return state;
}

MatchState resume(MatchState previous, [int? now]) {
  final timestamp = now ?? DateTime.now().millisecondsSinceEpoch;
  final state = previous.copy();
  if (state.phase != 'playing' ||
      state.current == null ||
      !state.current!.paused) {
    return state;
  }
  state.current!.paused = false;
  state.current!.deadline = state.config.seconds == 0
      ? null
      : timestamp + (state.current!.remaining! * 1000).round();
  return state;
}

MatchState addHint(MatchState previous, [String word = '', int? now]) {
  final timestamp = now ?? DateTime.now().millisecondsSinceEpoch;
  if (previous.phase != 'playing' || previous.current?.paused == true) {
    throw StateError('تابعوا المؤقّت أولًا.');
  }
  if (remaining(previous, timestamp) == 0) {
    throw StateError('انتهى الوقت.');
  }
  final clean = word.trim();
  final normalized = normalizeWord(clean);
  if (clean.isNotEmpty &&
      (!_oneWordPattern.hasMatch(clean) || clean.length > 30)) {
    throw StateError('كلمة واحدة فقط، بدون مسافات أو رموز.');
  }
  if (clean.isNotEmpty &&
      previous.current!.hints
          .any((h) => normalizeWord(h.word) == normalized)) {
    throw StateError('هذه الكلمة انقالت! جرّب كلمة جديدة.');
  }
  final state = previous.copy();
  final team = state.current!.turn;
  state.current!.hints.add(Hint(team: team, word: clean));
  state.current!.clues[team]++;
  state.current!.turn = 1 - team;
  return state;
}

MatchState resolveRound(
  MatchState previous, [
  int? winner,
  String reason = 'skip',
  int? now,
]) {
  final timestamp = now ?? DateTime.now().millisecondsSinceEpoch;
  final state = previous.copy();
  if (state.phase != 'playing' || state.current == null) return state;
  if (winner != null && winner != 0 && winner != 1) {
    throw StateError('فريق غير صالح.');
  }
  if (winner != null && state.current!.paused) {
    throw StateError('تابعوا الجولة قبل تسجيل النقطة.');
  }
  state.current!.remaining = remaining(state, timestamp);
  state.current!.deadline = null;
  state.current!.paused = false;
  state.current!.outcome = RoundOutcome(winner: winner, reason: reason);
  if (winner != null) state.scores[winner]++;
  state.history.add(
    HistoryEntry(
      number: state.current!.number,
      player: state.current!.player.copy(),
      winner: winner,
      reason: reason,
      clues: List<int>.from(state.current!.clues),
      hints: state.current!.hints.map((h) => h.copy()).toList(),
    ),
  );
  state.phase = 'result';
  return state;
}

MatchState undoResult(MatchState previous) {
  final state = previous.copy();
  if (state.phase != 'result' ||
      state.current?.outcome?.winner == null) {
    return state;
  }
  state.scores[state.current!.outcome!.winner!]--;
  state.history.removeLast();
  state.current!.outcome = null;
  state.current!.remaining = state.config.seconds == 0
      ? null
      : (state.current!.remaining ?? 1).clamp(1, double.infinity);
  state.phase = 'playing';
  state.current!.paused = true;
  return state;
}

int matchWinner(MatchState state) {
  return state.scores.indexWhere((score) => score >= state.config.target);
}

MatchState continueMatch(MatchState previous) {
  if (previous.phase != 'result') return previous.copy();
  if (matchWinner(previous) != -1) {
    final state = previous.copy();
    state.phase = 'finished';
    state.endReason = 'target';
    return state;
  }
  return nextRound(previous);
}

MatchState finishMatch(MatchState previous) {
  final state = pause(previous);
  state.phase = 'finished';
  state.endReason = 'manual';
  return state;
}

String cluePerson(MatchState state, int team) {
  return state.config.teams[team].members[(state.current!.number - 1) % 2];
}

String guessPerson(MatchState state, int team) {
  return state.config.teams[team].members[state.current!.number % 2];
}

bool validSavedState(dynamic raw) {
  if (raw is! Map) return false;
  try {
    final state = MatchState.fromJson(Map<String, dynamic>.from(raw));
    const phases = ['reveal', 'ready', 'playing', 'result', 'finished'];
    return state.version == engineVersion &&
        state.deck.isNotEmpty &&
        state.config.teams.length == 2 &&
        state.config.teams.every((t) => t.members.length == 2) &&
        state.scores.length == 2 &&
        state.current?.player.name.isNotEmpty == true &&
        phases.contains(state.phase) &&
        state.cursor >= 1 &&
        state.cursor <= state.deck.length;
  } catch (_) {
    return false;
  }
}
