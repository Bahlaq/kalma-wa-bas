import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/player_photos.dart';
import '../data/players.dart';
import '../engine/engine.dart' as E;
import '../engine/models.dart';
import '../state/match_controller.dart';
import '../theme/usa94_theme.dart';
import '../widgets/pass_phone_banner.dart';
import '../widgets/scoreboard.dart';
import '../widgets/secret_card.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final _hintCtrl = TextEditingController();
  String? _hintError;

  /// After handoff card; before/during secret hold-to-reveal.
  bool _phoneReady = false;

  @override
  void dispose() {
    _hintCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MatchController>();
    final match = ctrl.match;
    if (match == null) {
      return const Center(child: Text('لا توجد مباراة'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: ctrl.goHome,
              icon: const Icon(Icons.chevron_right),
              label: const Text('الرئيسية'),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Usa94Colors.paper,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Usa94Colors.ink),
              ),
              child: Text(
                match.phase == 'finished'
                    ? 'النتيجة'
                    : 'الجولة ${match.current?.number ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () => _confirmEnd(context, ctrl),
              child: const Text('إنهاء'),
            ),
          ],
        ),
        if (match.phase != 'finished') ...[
          Scoreboard(match: match),
          const SizedBox(height: 8),
          Text(
            'الفوز بتجاوز ١٠ نقاط (أول من يوصل ${match.config.target})',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Usa94Colors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
        ],
        switch (match.phase) {
          'reveal' => _reveal(match, ctrl),
          'ready' => _ready(match, ctrl),
          'playing' => _playing(match, ctrl),
          'result' => _result(match, ctrl),
          'finished' => _finished(match, ctrl),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }

  Widget _reveal(MatchState match, MatchController ctrl) {
    final step = match.current!.revealStep;
    final clue = E.cluePerson(match, step);
    final guess = E.guessPerson(match, step);
    final team = match.config.teams[step];
    final seen = match.current!.seen[step];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _pill('١ ${E.cluePerson(match, 0)}', step == 0, step > 0),
            const SizedBox(width: 8),
            _pill('٢ ${E.cluePerson(match, 1)}', step == 1, false),
          ],
        ),
        const SizedBox(height: 16),
        if (!_phoneReady)
          PassPhoneBanner(
            holderName: clue,
            teamName: team.name,
            guesserName: guess,
            stepLabel: step == 0 ? 'كشف ١ من ٢' : 'كشف ٢ من ٢',
            onReady: () => setState(() => _phoneReady = true),
          )
        else ...[
          Text(
            'يا $clue — اضغط مطوّلًا لتشوف اللاعب',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'بعد ما تشوف، افلِت ثم اضغط التالي. خلي $guess بعيد.',
            style: const TextStyle(color: Usa94Colors.muted, height: 1.6),
          ),
          const SizedBox(height: 16),
          SecretCard(
            player: match.current!.player,
            onHeld: ctrl.markSeen,
            onReleased: () {},
          ),
          if (seen) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _phoneReady = false);
                  ctrl.acknowledge();
                },
                child: Text(
                  step == 0
                      ? 'التالي — مرّر التلفون'
                      : 'التالي — الحكم يمسك الجهاز',
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _pill(String label, bool active, bool done) {
    final bg = active
        ? Usa94Colors.royal
        : done
            ? const Color(0xFFF8E5B6)
            : Usa94Colors.paper;
    final fg = active ? Usa94Colors.paper : Usa94Colors.ink;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: active ? Usa94Colors.ink : const Color(0xFFC4CCDC),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _ready(MatchState match, MatchController ctrl) {
    final starter = match.config.teams[match.current!.turn].name;
    return Column(
      children: [
        const Icon(Icons.sports, color: Usa94Colors.royal, size: 48),
        const SizedBox(height: 12),
        const Text(
          'السر صار مع الاثنين',
          style: TextStyle(
            color: Usa94Colors.red,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'يا حكم… صفّر!',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'الجهاز مع الحكم. الأسماء مخبّأة. الفريقان يتناوبان كلمة بكلمة.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Usa94Colors.muted, height: 1.6),
        ),
        const SizedBox(height: 18),
        ...List.generate(2, (i) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: i == 0 ? const Color(0xFFE9EDFB) : const Color(0xFFF9E9E6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    i == 0 ? const Color(0xFFAABDE9) : const Color(0xFFE8B7BA),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.config.teams[i].name,
                  style: TextStyle(
                    color: i == 0 ? Usa94Colors.royal : Usa94Colors.red,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${E.cluePerson(match, i)} → يعطي التلميح'),
                Text('${E.guessPerson(match, i)} → يحزر'),
              ],
            ),
          );
        }),
        Text(
          match.config.seconds == 0
              ? 'بدون مؤقّت · $starter يبدأ'
              : '${match.config.seconds} ثانية · $starter يبدأ',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: ctrl.startRound,
            child: const Text('ابدأ الجولة'),
          ),
        ),
      ],
    );
  }

  Widget _playing(MatchState match, MatchController ctrl) {
    final c = match.current!;
    final left = E.remaining(match);
    final timeLabel = left == null
        ? '∞'
        : () {
            final total = left.ceil();
            final m = total ~/ 60;
            final s = total % 60;
            return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
          }();
    final teamColor = c.turn == 0 ? Usa94Colors.royal : Usa94Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Usa94Colors.paper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Usa94Colors.ink),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: ctrl.togglePause,
                icon: Icon(c.paused ? Icons.play_arrow : Icons.pause),
              ),
              Expanded(
                child: Text(
                  c.paused ? 'متوقّفة' : 'الوقت يمشي',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                timeLabel,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: (left != null && left <= 15)
                      ? Usa94Colors.red
                      : Usa94Colors.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (c.paused)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Usa94Colors.royal),
            ),
            child: Column(
              children: [
                const Text(
                  'خذوا نفس…',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: ctrl.togglePause,
                  child: const Text('متابعة الجولة'),
                ),
              ],
            ),
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.turn == 0
                  ? const Color(0xFFE7ECFB)
                  : const Color(0xFFF9E8E5),
              borderRadius: BorderRadius.circular(12),
              border: Border(
                top: BorderSide(color: teamColor, width: 5),
                left: const BorderSide(color: Usa94Colors.ink),
                right: const BorderSide(color: Usa94Colors.ink),
                bottom: const BorderSide(color: Usa94Colors.ink),
              ),
              boxShadow: const [
                BoxShadow(color: Color(0xFFCAD3EC), offset: Offset(4, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'دور فريق ${match.config.teams[c.turn].name}',
                  style: TextStyle(
                    color: teamColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${E.cluePerson(match, c.turn)} يقول كلمة واحدة',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${E.guessPerson(match, c.turn)} يحزر اللاعب',
                  style: const TextStyle(color: Usa94Colors.muted),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _hintCtrl,
                  decoration: InputDecoration(
                    labelText: 'سجّل الكلمة (اختياري) ثم بدّل الدور',
                    errorText: _hintError,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      final err = ctrl.addHint(_hintCtrl.text);
                      setState(() {
                        _hintError = err;
                        if (err == null) _hintCtrl.clear();
                      });
                    },
                    child: const Text('بدّل الدور للفريق الثاني'),
                  ),
                ),
              ],
            ),
          ),
          if (c.hints.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: c.hints
                  .map(
                    (h) => Chip(
                      label: Text(h.word.isEmpty ? '—' : h.word),
                      backgroundColor: h.team == 0
                          ? const Color(0xFFE3E9FA)
                          : const Color(0xFFF9DFDF),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'مين حزر؟',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Usa94Colors.royal,
              ),
              onPressed: () => ctrl.award(0),
              child: Text(
                'نقطة لـ ${match.config.teams[0].name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Usa94Colors.red,
              ),
              onPressed: () => ctrl.award(1),
              child: Text(
                'نقطة لـ ${match.config.teams[1].name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _confirmSkip(context, ctrl),
            child: const Text('تخطّي الجولة (بدون نقطة)'),
          ),
        ],
      ],
    );
  }

  Widget _result(MatchState match, MatchController ctrl) {
    final outcome = match.current!.outcome!;
    final won = outcome.winner != null;
    final photo = photoAssetFor(match.current!.player.id);
    final difficulty =
        difficultyLabels[match.current!.player.difficulty] ?? 'خاص';
    final targetHit = E.matchWinner(match) != -1;

    return Column(
      children: [
        Icon(
          won ? Icons.emoji_events : Icons.timer,
          size: 48,
          color: won ? Usa94Colors.gold : Usa94Colors.ink,
        ),
        const SizedBox(height: 10),
        Text(
          targetHit
              ? 'تجاوزوا ١٠… خلصت المباراة!'
              : won
                  ? 'قولوا جوووول!'
                  : outcome.reason == 'timeout'
                      ? 'خلص الوقت'
                      : 'بدون نقاط هالجولة',
          style: const TextStyle(
            color: Usa94Colors.red,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          won
              ? 'نقطة لـ ${match.config.teams[outcome.winner!].name}'
              : outcome.reason == 'timeout'
                  ? 'صفّر الجولة الجاية'
                  : 'نغيّر اللاعب ونكمّل',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Usa94Colors.paper,
            borderRadius: BorderRadius.circular(8),
            border: const Border(
              top: BorderSide(color: Usa94Colors.red, width: 5),
              left: BorderSide(color: Usa94Colors.ink),
              right: BorderSide(color: Usa94Colors.ink),
              bottom: BorderSide(color: Usa94Colors.ink),
            ),
          ),
          child: Column(
            children: [
              const Text('اللاعب كان'),
              if (photo != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(photo, height: 140, fit: BoxFit.cover),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                match.current!.player.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(difficulty),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() => _phoneReady = false);
              ctrl.continueMatch();
            },
            child: Text(
              targetHit ? 'عرض الأبطال' : 'لاعب جديد — الجولة التالية',
            ),
          ),
        ),
        if (won)
          TextButton(
            onPressed: ctrl.undoResult,
            child: const Text('تراجع عن النقطة'),
          ),
      ],
    );
  }

  Widget _finished(MatchState match, MatchController ctrl) {
    final scores = match.scores;
    final tie = scores[0] == scores[1];
    final winner = tie ? null : (scores[0] > scores[1] ? 0 : 1);
    final title = tie
        ? 'تعادل… بدها إعادة!'
        : match.endReason == 'target'
            ? 'فريق ${match.config.teams[winner!].name} تجاوز ١٠ — فاز!'
            : '${match.config.teams[winner!].name} في الصدارة';

    return Column(
      children: [
        const Icon(Icons.emoji_events, size: 64, color: Usa94Colors.gold),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        Text(
          '${match.config.teams[0].name}  ${scores[0]} — ${scores[1]}  ${match.config.teams[1].name}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text('${match.history.length} جولات'),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ctrl.clearFinishedAndHome();
              ctrl.goSetup();
            },
            child: const Text('مباراة جديدة'),
          ),
        ),
        TextButton(
          onPressed: ctrl.clearFinishedAndHome,
          child: const Text('الرئيسية'),
        ),
      ],
    );
  }

  void _confirmSkip(BuildContext context, MatchController ctrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('نتخطّى هذه الجولة؟'),
        content: const Text(
          'رح نكشف اسم اللاعب وتنتهي الجولة بدون نقطة لأي فريق.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('خلّينا نكمّل'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ctrl.skipRound();
            },
            child: const Text('تخطّي الجولة'),
          ),
        ],
      ),
    );
  }

  void _confirmEnd(BuildContext context, MatchController ctrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ننهي المباراة؟'),
        content: const Text('رح نعرض النتيجة الحالية.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('خلّينا نكمّل'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ctrl.endMatch();
            },
            child: const Text('إنهاء'),
          ),
        ],
      ),
    );
  }
}
