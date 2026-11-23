import 'package:flutter_test/flutter_test.dart';
import 'package:kalma_wa_bas/data/players.dart';
import 'package:kalma_wa_bas/engine/engine.dart' as E;
import 'package:kalma_wa_bas/engine/models.dart';

MatchConfig baseConfig({
  String category = 'all',
  String difficulty = 'all',
  String customNames = '',
  int seconds = 90,
  int target = 5,
}) {
  return MatchConfig(
    teams: const [
      TeamConfig(name: 'الصقور', members: ['أحمد', 'عمر']),
      TeamConfig(name: 'النمور', members: ['محمد', 'ليث']),
    ],
    seconds: seconds,
    target: target,
    category: category,
    difficulty: difficulty,
    customNames: customNames,
  );
}

MatchState newMatch([MatchConfig? overrides]) {
  return E.createMatch(overrides ?? baseConfig(), builtinPlayers, () => 0.43);
}

MatchState reveal(MatchState state) {
  return E.acknowledge(E.markSeen(E.acknowledge(E.markSeen(state))));
}

MatchState playing([MatchConfig? overrides, int now = 1000]) {
  return E.startRound(reveal(newMatch(overrides)), now);
}

void main() {
  test('both clue-givers must privately see the same name before start', () {
    var s = newMatch();
    final name = s.current!.player.name;
    expect(E.acknowledge(s).current!.revealStep, 0);
    expect(E.startRound(s, 1000).phase, 'reveal');
    s = E.acknowledge(E.markSeen(s));
    expect(s.current!.revealStep, 1);
    expect(s.current!.player.name, name);
    expect(E.acknowledge(s).phase, 'reveal');
    s = E.acknowledge(E.markSeen(s));
    expect(s.phase, 'ready');
    s = E.startRound(s, 1000);
    expect(s.phase, 'playing');
    expect(s.current!.deadline, 91000);
  });

  test('hints alternate and reject sentences / repeated Arabic words', () {
    var s = playing();
    s = E.addHint(s, 'أرجنتيني', 2000);
    expect(s.current!.turn, 1);
    expect(s.current!.clues, [1, 0]);
    expect(() => E.addHint(s, 'القدم اليسرى', 3000), throwsA(isA<StateError>()));
    expect(() => E.addHint(s, 'ارجنتيني', 3000), throwsA(isA<StateError>()));
    expect(() => E.addHint(s, 'القدم-اليسرى', 3000), throwsA(isA<StateError>()));
    s = E.addHint(s, 'يسار', 3000);
    expect(s.current!.turn, 0);
    expect(s.current!.clues, [1, 1]);
    s = E.addHint(s, '', 4000);
    expect(s.current!.hints.length, 3);
    expect(s.current!.turn, 1);
  });

  test('elapsed time and pause freeze remaining', () {
    var s = playing();
    expect(E.remaining(s, 21500), 69.5);
    s = E.pause(s, 21500);
    expect(E.remaining(s, 9999999), 69.5);
    expect(() => E.addHint(s, 'كلمة', 9999999), throwsA(isA<StateError>()));
    s = E.resume(s, 100000);
    expect(s.current!.deadline, 169500);
    expect(E.remaining(s, 169500), 0);
    expect(() => E.addHint(s, 'كلمة', 170000), throwsA(isA<StateError>()));
  });

  test('untimed rounds have no deadline', () {
    var s = playing(baseConfig(seconds: 0));
    expect(E.remaining(s, 1000000000000), isNull);
    s = E.pause(s, 1000000000000);
    s = E.resume(s, 2000000000000);
    expect(s.current!.deadline, isNull);
    expect(E.addHint(s, 'عربي', 3000000000000).current!.turn, 1);
  });

  test('scored answer awards one point and undo restores paused round', () {
    var s = playing();
    s = E.resolveRound(s, 1, 'correct', 17000);
    expect(s.scores, [0, 1]);
    expect(s.history.length, 1);
    expect(s.phase, 'result');
    final player = s.current!.player.name;
    s = E.resolveRound(s, 1, 'correct', 17001);
    expect(s.scores, [0, 1]);
    expect(s.history.length, 1);
    s = E.undoResult(s);
    expect(s.scores, [0, 0]);
    expect(s.history.length, 0);
    expect(s.current!.player.name, player);
    expect(s.current!.paused, true);
    expect(s.current!.remaining, 74);
  });

  test('timeout and skip award no points then swap roles', () {
    var s = playing();
    expect(E.cluePerson(s, 0), 'أحمد');
    expect(E.guessPerson(s, 1), 'ليث');
    s = E.resolveRound(s, null, 'timeout', 91000);
    expect(s.scores, [0, 0]);
    s = E.continueMatch(s);
    expect(s.current!.number, 2);
    expect(s.current!.turn, 1);
    expect(E.cluePerson(s, 0), 'عمر');
    expect(E.guessPerson(s, 1), 'محمد');
    s = E.startRound(reveal(s), 100000);
    s = E.pause(s, 101000);
    s = E.resolveRound(s, null, 'skip', 101000);
    expect(s.scores, [0, 0]);
    expect(s.history.length, 2);
  });

  test('match finishes at target', () {
    var s = newMatch(baseConfig(target: 2));
    for (var i = 0; i < 2; i++) {
      s = E.startRound(reveal(s), 1000);
      s = E.resolveRound(s, 0, 'correct', 2000);
      s = E.continueMatch(s);
    }
    expect(s.phase, 'finished');
    expect(s.endReason, 'target');
    expect(s.cursor, 2);
    expect(s.scores, [2, 0]);
  });

  test('every card unique and replacements consume deck', () {
    var s = newMatch(baseConfig(category: 'arab', difficulty: 'easy'));
    final seen = <String>{};
    final count = s.deck.length;
    while (s.phase != 'finished') {
      expect(seen.contains(s.current!.player.id), isFalse);
      seen.add(s.current!.player.id);
      s = E.nextRound(s, replace: true);
    }
    expect(seen.length, count);
    expect(s.current!.number, 1);
    expect(s.endReason, 'exhausted');
  });

  test('custom-only pool deduplicates Arabic aliases', () {
    final custom = baseConfig(
      category: 'custom',
      difficulty: 'hard',
      customNames: 'أحمد\nاحمد\nعمر\n\nمحمد',
    );
    final pool = E.makePool(builtinPlayers, custom);
    expect(pool.length, 3);
    expect(pool.every((p) => p.tags.contains('custom')), isTrue);
    expect(
      () => newMatch(baseConfig(category: 'custom', customNames: 'أحمد')),
      throwsA(isA<StateError>()),
    );
  });

  test('all category/difficulty pairs have a playable pool', () {
    for (final category in ['all', 'arab', 'world', 'legends']) {
      for (final difficulty in ['all', 'easy', 'medium', 'hard']) {
        final pool = E.makePool(
          builtinPlayers,
          baseConfig(category: category, difficulty: difficulty),
        );
        expect(pool.length >= 2, isTrue, reason: '$category/$difficulty');
      }
    }
    expect(
      builtinPlayers.map((p) => E.normalizeWord(p.name)).toSet().length,
      builtinPlayers.length,
    );
  });

  test('state round-trips through JSON persistence', () {
    final s = E.pause(playing(), 2000);
    final saved = s.toJson();
    expect(E.validSavedState(saved), isTrue);
    expect(MatchState.fromJson(saved).scores, s.scores);
    expect(E.validSavedState(null), isFalse);
    expect(E.validSavedState(<String, dynamic>{}), isFalse);
  });
}
