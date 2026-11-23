import 'package:flutter/material.dart';

import '../engine/models.dart';
import '../theme/usa94_theme.dart';

class Scoreboard extends StatelessWidget {
  const Scoreboard({super.key, required this.match});

  final MatchState match;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Usa94Colors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Usa94Colors.ink),
        boxShadow: const [
          BoxShadow(color: Color(0xFFD5DCEC), offset: Offset(4, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Usa94Colors.red, Usa94Colors.royal],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(child: _team(0)),
                Text(
                  '${match.scores[0]} : ${match.scores[1]}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Expanded(child: _team(1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _team(int i) {
    final team = match.config.teams[i];
    final color = i == 0 ? Usa94Colors.royal : Usa94Colors.red;
    return Column(
      crossAxisAlignment:
          i == 0 ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            team.name,
            style: const TextStyle(
              color: Usa94Colors.paper,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
