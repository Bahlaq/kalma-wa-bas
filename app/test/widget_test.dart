import 'package:flutter_test/flutter_test.dart';
import 'package:kalma_wa_bas/data/players.dart';
import 'package:kalma_wa_bas/engine/engine.dart';

void main() {
  test('builtin deck is loaded', () {
    expect(builtinPlayers.length, greaterThanOrEqualTo(300));
    expect(normalizeWord('أحمد'), normalizeWord('احمد'));
  });
}
