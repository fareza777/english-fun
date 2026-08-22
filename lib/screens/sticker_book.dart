import 'package:flutter/material.dart';

import '../data/badges.dart';
import '../data/stickers.dart';
import '../services/progress.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';

/// Collection screen: sticker album + achievement badges.
class StickerBookScreen extends StatefulWidget {
  const StickerBookScreen({super.key});

  @override
  State<StickerBookScreen> createState() => _StickerBookScreenState();
}

class _StickerBookScreenState extends State<StickerBookScreen> {
  @override
  void initState() {
    super.initState();
    // Opening the collection re-checks achievement conditions.
    // Must run AFTER the first frame: unlockBadge() notifies listeners, and
    // doing that during build crashes the route (home still listens).
    WidgetsBinding.instance.addPostFrameCallback((_) => checkNewBadges());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: AnimatedBackground(
          child: Column(
            children: [
              const KidAppBar(title: 'Koleksiku', emoji: '🎒', colors: []),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TabBar(
                    labelStyle: AppText.heading(17),
                    unselectedLabelStyle: AppText.body(16),
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Stiker 🎒'),
                      Tab(text: 'Lencana 🏅'),
                    ],
                  ),
                ),
              ),
              Expanded(child: TabBarView(children: [_StickerTab(), _BadgeTab()])),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickerTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Progress.I,
      builder: (context, _) {
        final earned = Progress.I.stickers.length;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  Text(
                    '$earned dari ${kStickers.length} stiker terkumpul!',
                    style: AppText.heading(19),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: earned / kStickers.length,
                      minHeight: 12,
                      backgroundColor: Colors.white.withValues(alpha: 0.6),
                      valueColor: const AlwaysStoppedAnimation(AppColors.star),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: context.isTablet ? 7 : 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemCount: kStickers.length,
                itemBuilder: (context, i) {
                  final (emoji, name) = kStickers[i];
                  final has = Progress.I.stickers.contains(emoji);
                  return Container(
                    decoration: BoxDecoration(
                      color: has ? Colors.white : Colors.white.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: has ? AppColors.star : Colors.white.withValues(alpha: 0.6),
                        width: 3,
                      ),
                      boxShadow: has
                          ? const [BoxShadow(color: Color(0x33B26A00), offset: Offset(0, 4))]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          has ? emoji : '❓',
                          style: TextStyle(fontSize: 36, color: has ? null : Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            has ? name : '???',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(
                              12,
                              color: has ? AppColors.ink : Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BadgeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Progress.I,
      builder: (context, _) {
        final unlocked = Progress.I.badges.length;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                '$unlocked dari ${kBadges.length} lencana diraih!',
                style: AppText.heading(19),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: context.isTablet ? 5 : 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: kBadges.length,
                itemBuilder: (context, i) {
                  final b = kBadges[i];
                  final has = Progress.I.badges.contains(b.id);
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: has ? const Color(0xFFFFF3D6) : Colors.white.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: has ? AppColors.star : Colors.white.withValues(alpha: 0.6),
                        width: 3,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          has ? b.emoji : '🔒',
                          style: TextStyle(fontSize: 34, color: has ? null : Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          b.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.heading(
                            13,
                            color: has ? AppColors.ink : Colors.grey.shade500,
                          ),
                        ),
                        Text(
                          b.desc,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(
                            10,
                            color: has ? AppColors.inkSoft : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
