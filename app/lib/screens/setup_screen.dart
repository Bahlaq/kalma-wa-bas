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
  late final TextEditingController _custom;
  late int _seconds;
  late int _target;
  late String _category;
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
    _custom = TextEditingController(text: c.customNames);
    _seconds = c.seconds;
    _target = c.target;
    _category = c.category;
    _difficulty = c.difficulty;
  }

  @override
  void dispose() {
    _team0.dispose();
    _team1.dispose();
    _m00.dispose();
    _m01.dispose();
    _m10.dispose();
    _m11.dispose();
    _custom.dispose();
    super.dispose();
  }

  MatchConfig _buildConfig() => MatchConfig(
        teams: [
          TeamConfig(
            name: _team0.text.trim().isEmpty ? 'الصقور' : _team0.text.trim(),
            members: [
              _m00.text.trim().isEmpty ? 'اللاعب ١' : _m00.text.trim(),
              _m01.text.trim().isEmpty ? 'اللاعب ٢' : _m01.text.trim(),
            ],
          ),
          TeamConfig(
            name: _team1.text.trim().isEmpty ? 'النمور' : _team1.text.trim(),
            members: [
              _m10.text.trim().isEmpty ? 'اللاعب ٣' : _m10.text.trim(),
              _m11.text.trim().isEmpty ? 'اللاعب ٤' : _m11.text.trim(),
            ],
          ),
        ],
        seconds: _seconds,
        target: _target,
        category: _category,
        difficulty: _difficulty,
        customNames: _custom.text,
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
          'مين نازل الملعب؟',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'سمّوا فريقكم، واختاروا شكل التحدّي. الحكم يمسك الجهاز.',
          style: TextStyle(color: Usa94Colors.muted),
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
        _settingsCard(),
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
                  'جاهز $pool لاعب في المجموعة',
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
        ElevatedButton(
          onPressed: () {
            ctrl.updateSetup(_buildConfig());
            ctrl.startNewMatch();
          },
          child: const Text('ابدأ التحدّي'),
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
            decoration: const InputDecoration(labelText: 'اسم الفريق'),
            onChanged: (_) => _sync(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: m0,
            decoration: const InputDecoration(labelText: 'اللاعب الأول'),
            onChanged: (_) => _sync(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: m1,
            decoration: const InputDecoration(labelText: 'اللاعب الثاني'),
            onChanged: (_) => _sync(),
          ),
        ],
      ),
    );
  }

  Widget _settingsCard() {
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
          const Text('إعدادات التحدّي', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _seconds,
            decoration: const InputDecoration(labelText: 'وقت الجولة'),
            items: const [
              DropdownMenuItem(value: 60, child: Text('60 ثانية')),
              DropdownMenuItem(value: 90, child: Text('90 ثانية')),
              DropdownMenuItem(value: 120, child: Text('120 ثانية')),
              DropdownMenuItem(value: 0, child: Text('بدون مؤقّت')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _seconds = v);
              _sync();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _target,
            decoration: const InputDecoration(labelText: 'هدف الفوز'),
            items: const [
              DropdownMenuItem(value: 3, child: Text('٣ نقاط')),
              DropdownMenuItem(value: 5, child: Text('٥ نقاط')),
              DropdownMenuItem(value: 7, child: Text('٧ نقاط')),
              DropdownMenuItem(value: 10, child: Text('١٠ نقاط')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _target = v);
              _sync();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'المجموعة'),
            items: categoryLabels.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _category = v);
              _sync();
            },
          ),
          if (_category != 'custom') ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _difficulty,
              decoration: const InputDecoration(labelText: 'الصعوبة'),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('الكل')),
                ...difficultyLabels.entries.map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _difficulty = v);
                _sync();
              },
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _custom,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'أسماء إضافية (سطر لكل اسم)',
            ),
            onChanged: (_) => _sync(),
          ),
        ],
      ),
    );
  }
}
