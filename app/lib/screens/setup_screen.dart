import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/players.dart';
import '../engine/models.dart';
import '../state/match_controller.dart';
import '../theme/usa94_theme.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late final TextEditingController _team0;
  late final TextEditingController _team1;
  late final TextEditingController _m00;
  late final TextEditingController _m01;
  late final TextEditingController _m10;
  late final TextEditingController _m11;
  late int _seconds;
  late int _target;
  late String _difficulty;

  @override
  void initState() {
    super.initState();
    final c = context.read<MatchController>().setupConfig;
    _team0 = TextEditingController(text: c.teams[0].name);
    _team1 = TextEditingController(text: c.teams[1].name);
    _m00 = TextEditingController(text: c.teams[0].members[0]);
    _m01 = TextEditingController(text: c.teams[0].members[1]);
    _m10 = TextEditingController(text: c.teams[1].members[0]);
    _m11 = TextEditingController(text: c.teams[1].members[1]);
    _seconds = c.seconds == 0 ? 60 : c.seconds;
    _target = [5, 7, 11].contains(c.target) ? c.target : 11;
    _difficulty = ['easy', 'medium', 'hard'].contains(c.difficulty)
        ? c.difficulty
        : 'easy';
  }

  @override
  void dispose() {
    _team0.dispose();
    _team1.dispose();
    _m00.dispose();
    _m01.dispose();
    _m10.dispose();
    _m11.dispose();
    super.dispose();
  }

  MatchConfig _buildConfig() => MatchConfig(
        teams: [
          TeamConfig(
            name: _team0.text.trim().isEmpty ? 'الصقور' : _team0.text.trim(),
            members: [
              _m00.text.trim().isEmpty ? 'عمر' : _m00.text.trim(),
              _m01.text.trim().isEmpty ? 'أحمد' : _m01.text.trim(),
            ],
          ),
          TeamConfig(
            name: _team1.text.trim().isEmpty ? 'النمور' : _team1.text.trim(),
            members: [
              _m10.text.trim().isEmpty ? 'محمد' : _m10.text.trim(),
              _m11.text.trim().isEmpty ? 'خالد' : _m11.text.trim(),
            ],
          ),
        ],
        seconds: _seconds,
        target: _target,
        category: 'all',
        difficulty: _difficulty,
      );

  void _sync() {
    context.read<MatchController>().updateSetup(_buildConfig());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MatchController>();
    final pool = ctrl.poolPreviewCount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        TextButton.icon(
          onPressed: ctrl.goHome,
          icon: const Icon(Icons.chevron_right),
          label: const Text('الرئيسية'),
        ),
        const Text(
          'قبل صافرة البداية',
          style: TextStyle(
            color: Usa94Colors.red,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'سجّلوا الفريقين',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'فريقان، أربعة أسماء، مستوى واحد، ووقت الجولة. الحكم يمسك الجهاز.',
          style: TextStyle(color: Usa94Colors.muted, height: 1.6),
        ),
        const SizedBox(height: 20),
        _teamCard(
          index: 0,
          teamCtrl: _team0,
          m0: _m00,
          m1: _m01,
          color: Usa94Colors.royal,
        ),
        const SizedBox(height: 14),
        _teamCard(
          index: 1,
          teamCtrl: _team1,
          m0: _m10,
          m1: _m11,
          color: Usa94Colors.red,
        ),
        const SizedBox(height: 18),
        _levelCard(),
        const SizedBox(height: 14),
        _timeAndTargetCard(),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Usa94Colors.paper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Usa94Colors.ink),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Usa94Colors.gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.groups, color: Usa94Colors.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$pool لاعب جاهز في المستوى المختار',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        if (ctrl.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            ctrl.errorMessage!,
            style: const TextStyle(color: Usa94Colors.red),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              ctrl.updateSetup(_buildConfig());
              ctrl.startNewMatch();
            },
            child: const Text('يلا نبدأ'),
          ),
        ),
      ],
    );
  }

  Widget _teamCard({
    required int index,
    required TextEditingController teamCtrl,
    required TextEditingController m0,
    required TextEditingController m1,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Usa94Colors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          top: BorderSide(color: color, width: 5),
          left: const BorderSide(color: Usa94Colors.ink),
          right: const BorderSide(color: Usa94Colors.ink),
          bottom: const BorderSide(color: Usa94Colors.ink),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0xFFD9DEEB), offset: Offset(4, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الفريق ${index == 0 ? 'الأول' : 'الثاني'}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: teamCtrl,
            decoration: InputDecoration(
              labelText: 'اسم الفريق',
              hintText: index == 0 ? 'مثال: الصقور' : 'مثال: النمور',
            ),
            onChanged: (_) => _sync(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: m0,
            decoration: InputDecoration(
              labelText: 'اللاعب الأول',
              hintText: index == 0 ? 'عمر' : 'محمد',
            ),
            onChanged: (_) => _sync(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: m1,
            decoration: InputDecoration(
              labelText: 'اللاعب الثاني',
              hintText: index == 0 ? 'أحمد' : 'خالد',
            ),
            onChanged: (_) => _sync(),
          ),
        ],
      ),
    );
  }

  Widget _levelCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Usa94Colors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Usa94Colors.ink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'المستوى (٣ خيارات)',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...difficultyLabels.entries.map((e) {
            final selected = _difficulty == e.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() => _difficulty = e.key);
                  _sync();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? Usa94Colors.royal : Usa94Colors.paper,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Usa94Colors.ink),
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                              color: Usa94Colors.ink,
                              offset: Offset(2, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    e.value,
                    style: TextStyle(
                      color: selected ? Usa94Colors.paper : Usa94Colors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _timeAndTargetCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Usa94Colors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Usa94Colors.ink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'وقت الجولة',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [30, 45, 60, 90].map((s) {
              final selected = _seconds == s;
              return ChoiceChip(
                label: Text('$s ث'),
                selected: selected,
                onSelected: (_) {
                  setState(() => _seconds = s);
                  _sync();
                },
                selectedColor: Usa94Colors.gold,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Usa94Colors.ink,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          const Text(
            'الفوز (تجاوز ١٠ = ١١ نقطة)',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [5, 7, 11].map((t) {
              final selected = _target == t;
              return ChoiceChip(
                label: Text(t == 11 ? 'أول من يتجاوز ١٠' : 'أول من يوصل $t'),
                selected: selected,
                onSelected: (_) {
                  setState(() => _target = t);
                  _sync();
                },
                selectedColor: Usa94Colors.gold,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Usa94Colors.ink,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
