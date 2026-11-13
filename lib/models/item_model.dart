class ItemModel {
  final String id;
  final String name;
  final String description;
  final String category; // 'agua', 'comida', 'medicamentos', 'ferramentas', 'combustivel'
  final String iconName;
  final bool isStarterItem;
  final int starterQuantity;

  const ItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.iconName,
    required this.isStarterItem,
    required this.starterQuantity,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'ferramentas',
      iconName: json['icon_name']?.toString() ?? 'inventory_2',
      isStarterItem: json['is_starter_item'] == true,
      starterQuantity: (json['starter_quantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'icon_name': iconName,
      'is_starter_item': isStarterItem,
      'starter_quantity': starterQuantity,
    };
  }

  static const List<ItemModel> defaultCatalog = [
    ItemModel(
      id: 'aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      name: 'Água Purificada',
      description: 'Garrafa de 1L livre de contaminação biológica.',
      category: 'agua',
      iconName: 'water_drop',
      isStarterItem: true,
      starterQuantity: 3,
    ),
    ItemModel(
      id: 'aaaaaaa2-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      name: 'Ração Enlatada',
      description: 'Alimento militar não perecível rico em calorias.',
      category: 'comida',
      iconName: 'restaurant',
      isStarterItem: true,
      starterQuantity: 2,
    ),
    ItemModel(
      id: 'aaaaaaa3-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      name: 'Bandagem Estéril',
      description: 'Estanca sangramentos leves rapidamente em campo.',
      category: 'medicamentos',
      iconName: 'healing',
      isStarterItem: true,
      starterQuantity: 2,
    ),
    ItemModel(
      id: 'aaaaaaa4-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      name: 'Antibiótico',
      description: 'Combate infecções severas e retarda contaminação.',
      category: 'medicamentos',
      iconName: 'medication',
      isStarterItem: false,
      starterQuantity: 0,
    ),
    ItemModel(
      id: 'aaaaaaa5-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      name: 'Pé de Cabra',
      description: 'Ferramenta essencial para arrombar portas e caixas.',
      category: 'ferramentas',
      iconName: 'build',
      isStarterItem: true,
      starterQuantity: 1,
    ),
    ItemModel(
      id: 'aaaaaaa6-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      name: 'Sucata Metálica',
      description: 'Material base para reforçar estruturas.',
      category: 'ferramentas',
      iconName: 'hardware',
      isStarterItem: false,
      starterQuantity: 0,
    ),
    ItemModel(
      id: 'aaaaaaa7-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      name: 'Galão de Gasolina',
      description: 'Combustível para geradores e veículos.',
      category: 'combustivel',
      iconName: 'local_gas_station',
      isStarterItem: false,
      starterQuantity: 0,
    ),
    ItemModel(
      id: 'aaaaaaa8-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      name: 'Bateria Automotiva',
      description: 'Fonte de energia portátil para rádios e luzes.',
      category: 'combustivel',
      iconName: 'battery_charging_full',
      isStarterItem: false,
      starterQuantity: 0,
    ),
  ];
}
