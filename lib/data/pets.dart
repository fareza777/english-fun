import 'dart:math' as math;

/// Collectible pets hatched from eggs. The emoji is the id.
class Pet {
  final String id; // emoji
  final String name;
  final int rarity; // 0 common, 1 rare, 2 legendary
  const Pet(this.id, this.name, this.rarity);
}

const kPets = <Pet>[
  Pet('🐱', 'Oyen si Kucing', 0),
  Pet('🐶', 'Bobo si Anjing', 0),
  Pet('🐰', 'Lulu si Kelinci', 0),
  Pet('🐥', 'Ciko si Anak Ayam', 0),
  Pet('🐢', 'Tito si Kura-kura', 0),
  Pet('🐹', 'Mochi si Hamster', 0),
  Pet('🐧', 'Ping si Penguin', 1),
  Pet('🐼', 'Pandi si Panda', 1),
  Pet('🦊', 'Foxy Junior', 1),
  Pet('🦖', 'Rex si Dino', 1),
  Pet('🦄', 'Sparkle si Unicorn', 2),
  Pet('🐉', 'Drago si Naga Mini', 2),
];

/// Roll a random pet, weighted by rarity (60% common, 30% rare, 10% legendary).
/// Prefers pets the player does not own yet.
Pet rollPet(List<String> ownedIds) {
  final rnd = math.Random();
  final roll = rnd.nextDouble();
  final rarity = roll < 0.6 ? 0 : (roll < 0.9 ? 1 : 2);
  var pool = kPets.where((p) => p.rarity == rarity && !ownedIds.contains(p.id)).toList();
  if (pool.isEmpty) pool = kPets.where((p) => !ownedIds.contains(p.id)).toList();
  if (pool.isEmpty) pool = kPets.where((p) => p.rarity == rarity).toList();
  return pool[rnd.nextInt(pool.length)];
}

Pet? petById(String id) {
  for (final p in kPets) {
    if (p.id == id) return p;
  }
  return null;
}
