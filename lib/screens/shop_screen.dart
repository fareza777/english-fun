import 'package:flutter/material.dart';

import '../data/shop.dart';
import '../services/progress.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/funky.dart';

/// Costume shop: spend coins (earned from stars) on hats for Funky.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        world: 4,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: Progress.I,
            builder: (context, _) {
              final p = Progress.I;
              return Column(
                children: [
                  KidAppBar(
                    title: 'Toko Kostum',
                    emoji: '🛍️',
                    colors: const [Color(0xFFFF9AE2), Color(0xFFFFF0F9)],
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 4),
                          Text('${p.coins}', style: AppText.heading(18)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const FunkyMascot(size: 110),
                  Text('Funky coba topinya! 😄', style: AppText.body(16, color: Colors.white)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.05,
                      ),
                      itemCount: kShopItems.length,
                      itemBuilder: (context, i) {
                        final item = kShopItems[i];
                        final owned = p.ownedItems.contains(item.id);
                        final equipped = p.equippedHat == item.id;
                        final affordable = p.coins >= item.price;
                        return BouncyButton(
                          onTap: () => _tapItem(context, item, owned, equipped),
                          child: Container(
                            decoration: BoxDecoration(
                              color: equipped ? const Color(0xFFFFF3D6) : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: equipped ? AppColors.star : Colors.transparent,
                                width: 4,
                              ),
                              boxShadow: const [
                                BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4))
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(item.id, style: const TextStyle(fontSize: 52)),
                                Text(item.name, style: AppText.heading(17)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: owned
                                        ? (equipped ? AppColors.star : AppColors.correct)
                                        : (affordable ? const Color(0xFF4361EE) : Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    owned
                                        ? (equipped ? 'Dipakai ✓' : 'Pakai')
                                        : '🪙 ${item.price}',
                                    style: AppText.display(15),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _tapItem(BuildContext context, ShopItem item, bool owned, bool equipped) {
    final p = Progress.I;
    if (equipped) {
      p.equipHat(''); // unequip
      Sfx.I.flip();
      return;
    }
    if (owned) {
      p.equipHat(item.id);
      Sfx.I.pop();
      Sfx.I.speak('Looking good!');
      return;
    }
    if (p.buyItem(item.id, item.price)) {
      p.equipHat(item.id);
      Sfx.I.win();
      Sfx.I.speak('Awesome! New hat!');
    } else {
      Sfx.I.wrong();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.wrong,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          'Koin belum cukup! Kumpulkan bintang untuk dapat koin. ⭐→🪙',
          style: AppText.body(16, color: Colors.white),
        ),
      ));
    }
  }
}
