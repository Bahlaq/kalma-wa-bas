import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/match_controller.dart';
import '../theme/usa94_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MatchController>();
    final active = ctrl.hasActiveMatch;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        const Text(
          'بروح مونديال أمريكا ٩٤',
          style: TextStyle(
            color: Usa94Colors.red,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        const Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              height: 1.5,
              color: Usa94Colors.ink,
            ),
            children: [
              TextSpan(text: 'كلمة '),
              TextSpan(
                text: 'واحدة.',
                style: TextStyle(color: Usa94Colors.royal),
              ),
              TextSpan(text: '\nوحماس '),
              TextSpan(
                text: 'مونديال.',
                style: TextStyle(color: Usa94Colors.royal),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'تعرف اللاعب من تلميح؟ جمّع أصحابك، كوّنوا فريقين، وخلّوا الحكم يدير الحماس. كل دور كلمة… والباقي على شطارتكم.',
          style: TextStyle(
            color: Color(0xFF5E6A83),
            height: 1.9,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: () {
            if (active) {
              ctrl.resumeMatch();
            } else {
              ctrl.goSetup();
            }
          },
          child: Text(active ? 'كمّلوا المباراة' : 'يلا نلعب'),
        ),
        if (active) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => ctrl.goSetup(fromExisting: true),
            child: const Text('مباراة جديدة'),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Usa94Colors.paper,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Usa94Colors.ink),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Usa94Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'مباراة محفوظة ${ctrl.match!.config.teams[0].name} ${ctrl.match!.scores[0]} — ${ctrl.match!.scores[1]} ${ctrl.match!.config.teams[1].name}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              'جهاز واحد.\nوالكل بالملعب.',
              style: TextStyle(color: Color(0xFF7D6B60)),
            ),
          ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Usa94Colors.royal,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Usa94Colors.ink, width: 2),
            boxShadow: const [
              BoxShadow(color: Usa94Colors.ink, offset: Offset(6, 6)),
            ],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'USA • 1994',
                style: TextStyle(
                  color: Usa94Colors.gold,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'THE ONE-WORD CUP',
                style: TextStyle(
                  color: Usa94Colors.paper,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'فريقان · ٤ لاعبين · حكم واحد',
                style: TextStyle(color: Color(0xFFD0DAF9)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        OutlinedButton(
          onPressed: () => _showRules(context),
          child: const Text('كيف نلعب؟'),
        ),
      ],
    );
  }

  void _showRules(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('كيف نلعب «كلمة وبس»؟'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('١) فريقين وحكم — كل فريق شخصين، الحكم يمسك الجهاز.'),
              SizedBox(height: 10),
              Text(
                '٢) نفس اللاعب سرّ واحد — شخص من كل فريق يكشف الصورة بالضغط المطوّل.',
              ),
              SizedBox(height: 10),
              Text(
                '٣) كلمة واحدة كل دور — المُلمّح يقول كلمة وزميله يخمّن.',
              ),
              SizedBox(height: 10),
              Text(
                '٤) أول إجابة صح تكسب — الحكم يسجّل النقطة للفريق الأسرع.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('تمام'),
          ),
        ],
      ),
    );
  }
}
