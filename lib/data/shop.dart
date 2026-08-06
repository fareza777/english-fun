/// Costume shop items: hats Funky can wear, bought with coins earned from stars.
class ShopItem {
  final String id; // the emoji itself is the id (rendered on Funky's head)
  final String name;
  final int price;
  const ShopItem(this.id, this.name, this.price);
}

const kShopItems = <ShopItem>[
  ShopItem('🧢', 'Topi Keren', 50),
  ShopItem('🌸', 'Mahkota Bunga', 80),
  ShopItem('🎀', 'Pita Cantik', 100),
  ShopItem('🤠', 'Topi Koboi', 120),
  ShopItem('🎩', 'Topi Pesulap', 150),
  ShopItem('⛑️', 'Helm Penjaga', 180),
  ShopItem('🎓', 'Topi Wisuda', 200),
  ShopItem('👑', 'Mahkota Raja', 300),
];
