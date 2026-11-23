import 'package:flutter/material.dart';

import '../data/player_photos.dart';
import '../data/players.dart';
import '../engine/models.dart';
import '../theme/usa94_theme.dart';

class SecretCard extends StatefulWidget {
  const SecretCard({
    super.key,
    required this.player,
    required this.onHeld,
    required this.onReleased,
  });

  final Player player;
  final VoidCallback onHeld;
  final VoidCallback onReleased;

  @override
  State<SecretCard> createState() => _SecretCardState();
}

class _SecretCardState extends State<SecretCard> {
  bool _revealed = false;

  void _show() {
    if (_revealed) return;
    setState(() => _revealed = true);
    widget.onHeld();
  }

  void _hide() {
    if (!_revealed) return;
    setState(() => _revealed = false);
    widget.onReleased();
  }

  @override
  Widget build(BuildContext context) {
    final photo = photoAssetFor(widget.player.id);
    final difficulty = difficultyLabels[widget.player.difficulty] ??
        widget.player.difficulty;

    return Listener(
      onPointerDown: (_) => _show(),
      onPointerUp: (_) => _hide(),
      onPointerCancel: (_) => _hide(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _revealed ? Usa94Colors.paper : Usa94Colors.royal,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Usa94Colors.ink, width: 2),
          boxShadow: [
            BoxShadow(
              color: _revealed ? Usa94Colors.red : Usa94Colors.ink,
              offset: const Offset(6, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            if (!_revealed) ...[
              const Icon(Icons.lock, color: Usa94Colors.paper, size: 42),
              const SizedBox(height: 12),
              const Text(
                'اللاعب مخبّأ',
                style: TextStyle(
                  color: Usa94Colors.paper,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'شخص واحد فقط من كل فريق يشوف اللاعب',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFD0DAF9)),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Usa94Colors.gold,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Usa94Colors.ink),
                  boxShadow: const [
                    BoxShadow(color: Usa94Colors.ink, offset: Offset(3, 3)),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.visibility, color: Usa94Colors.ink),
                    SizedBox(width: 8),
                    Text(
                      'اضغط مطوّلًا للكشف',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Usa94Colors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Text(
                'السرّ معك فقط',
                style: TextStyle(
                  color: Usa94Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (photo != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    photo,
                    height: 180,
                    width: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                widget.player.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Usa94Colors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6ECFB),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  difficulty,
                  style: const TextStyle(
                    color: Usa94Colors.royal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'افلِت عشان تختفي الصورة',
                style: TextStyle(color: Usa94Colors.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
