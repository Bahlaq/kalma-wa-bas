import 'package:flutter/material.dart';

import '../theme/usa94_theme.dart';

/// Big handoff card: "أعطِ التلفون لـ [name]" then confirm before reveal.
class PassPhoneBanner extends StatelessWidget {
  const PassPhoneBanner({
    super.key,
    required this.holderName,
    required this.teamName,
    required this.guesserName,
    required this.stepLabel,
    required this.onReady,
  });

  final String holderName;
  final String teamName;
  final String guesserName;
  final String stepLabel;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        color: Usa94Colors.royal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Usa94Colors.ink, width: 2),
        boxShadow: const [
          BoxShadow(color: Usa94Colors.ink, offset: Offset(6, 6)),
        ],
      ),
      child: Column(
        children: [
          Text(
            stepLabel,
            style: const TextStyle(
              color: Usa94Colors.gold,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          const Icon(Icons.phone_android, color: Usa94Colors.paper, size: 52),
          const SizedBox(height: 16),
          const Text(
            'أعطِ التلفون لـ',
            style: TextStyle(color: Color(0xFFD0DAF9), fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            holderName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Usa94Colors.paper,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'من فريق $teamName',
            style: const TextStyle(
              color: Usa94Colors.gold,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'خلي $guesserName يبعد نظره عن الشاشة',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFD0DAF9), height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Usa94Colors.gold,
                foregroundColor: Usa94Colors.ink,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: onReady,
              child: Text(
                'التلفون مع $holderName — يلا',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
