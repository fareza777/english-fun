import 'package:flutter/material.dart';

import '../data/adventures.dart';
import '../services/progress.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/funky.dart';

/// "Cerita Bercabang" — an interactive story where the kid's choices
/// (in English) decide what Funky does next.
class AdventureScreen extends StatefulWidget {
  final Adventure adventure;
  const AdventureScreen({super.key, required this.adventure});

  @override
  State<AdventureScreen> createState() => _AdventureScreenState();
}

class _AdventureScreenState extends State<AdventureScreen> {
  late String _nodeId;
  bool _rewarded = false;

  AdvNode get _node => widget.adventure.nodes[_nodeId]!;

  @override
  void initState() {
    super.initState();
    _nodeId = widget.adventure.startId;
    Future.delayed(const Duration(milliseconds: 500), _speakNode);
  }

  void _speakNode() {
    if (mounted) Sfx.I.speak(_node.en);
  }

  void _choose(AdvChoice c) {
    Sfx.I.pop();
    setState(() => _nodeId = c.next);
    _speakNode();
    if (_node.choices.isEmpty && _node.coins > 0 && !_rewarded) {
      _rewarded = true;
      Progress.I.addCoins(_node.coins);
      Sfx.I.win();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnd = _node.choices.isEmpty;
    return Scaffold(
      body: AnimatedBackground(
        world: 6,
        child: SafeArea(
          child: Column(
            children: [
              KidAppBar(
                title: widget.adventure.title,
                emoji: widget.adventure.emoji,
                colors: const [],
              ),
              const SizedBox(height: 8),
              const FunkyMascot(size: 90),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(_node.emoji, style: const TextStyle(fontSize: 72)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    _node.en,
                                    textAlign: TextAlign.center,
                                    style: AppText.heading(21),
                                  ),
                                ),
                                BouncyButton(
                                  onTap: _speakNode,
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.volume_up_rounded,
                                      color: Color(0xFF4361EE),
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _node.idn,
                              textAlign: TextAlign.center,
                              style: AppText.body(16, color: AppColors.inkSoft),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    if (isEnd) ...[
                      Text('🎉 +${_node.coins} koin! Tamat.', style: AppText.display(20)),
                      const SizedBox(height: 10),
                      PillButton(
                        label: 'Kembali',
                        emoji: '🔙',
                        color: AppColors.correct,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ] else ...[
                      Text('Apa yang Funky lakukan?', style: AppText.body(16, color: Colors.white)),
                      const SizedBox(height: 8),
                      for (final c in _node.choices)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PillButton(
                            label: c.text,
                            emoji: '👉',
                            color: const Color(0xFF7B61FF),
                            fontSize: 19,
                            onTap: () => _choose(c),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
