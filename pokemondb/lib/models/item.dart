class ItemBasic {
  final int id;
  final String name;
  final String url;

  ItemBasic({required this.id, required this.name, required this.url});

  String get displayName =>
      name.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

  String get spriteUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/$name.png';

  factory ItemBasic.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String;
    final segments = url.split('/').where((s) => s.isNotEmpty).toList();
    final id = int.parse(segments.last);
    return ItemBasic(
      id: id,
      name: json['name'] as String,
      url: url,
    );
  }
}

class ItemDetail {
  final int id;
  final String name;
  final int cost;
  final String? category;
  final String? effect;
  final String? shortEffect;
  final List<String> attributes;
  final String? spriteUrl;

  ItemDetail({
    required this.id,
    required this.name,
    required this.cost,
    this.category,
    this.effect,
    this.shortEffect,
    this.attributes = const [],
    this.spriteUrl,
  });

  String get displayName =>
      name.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

  String get imageUrl =>
      spriteUrl ??
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/$name.png';

  factory ItemDetail.fromJson(Map<String, dynamic> json) {
    String? effect;
    String? shortEffect;

    // Extract English effect text
    for (final entry in json['effect_entries'] as List? ?? []) {
      if (entry['language']['name'] == 'en') {
        effect = entry['effect'] as String?;
        shortEffect = entry['short_effect'] as String?;
        break;
      }
    }

    // Extract attributes
    final attributes = <String>[];
    for (final attr in json['attributes'] as List? ?? []) {
      attributes.add(attr['name'] as String);
    }

    return ItemDetail(
      id: json['id'],
      name: json['name'],
      cost: json['cost'] as int? ?? 0,
      category: json['category']?['name'] as String?,
      effect: effect,
      shortEffect: shortEffect,
      attributes: attributes,
      spriteUrl: json['sprites']?['default'] as String?,
    );
  }
}

// Item category constants for filtering
class ItemCategory {
  static const String evolutionStones = 'evolution-stone';
  static const String berries = 'berry';
  static const String machines = 'tm';
  static const String heldItems = 'held-items';
  static const String pokeballs = 'pokeballs';
  static const String healing = 'healing';
  static const String statusCures = 'status-cures';
  static const String vitamins = 'vitamins';

  static const List<String> all = [
    evolutionStones,
    berries,
    machines,
    heldItems,
    pokeballs,
    healing,
    statusCures,
    vitamins,
  ];

  static String displayName(String category) {
    switch (category) {
      case evolutionStones:
        return 'Evolution Stones';
      case berries:
        return 'Berries';
      case machines:
        return 'TMs & HMs';
      case heldItems:
        return 'Held Items';
      case pokeballs:
        return 'Poké Balls';
      case healing:
        return 'Healing';
      case statusCures:
        return 'Status Cures';
      case vitamins:
        return 'Vitamins';
      default:
        return category
            .split('-')
            .map((w) => w[0].toUpperCase() + w.substring(1))
            .join(' ');
    }
  }
}

class BerryDetail {
  final int id;
  final String name;
  final int growthTime;
  final int maxHarvest;
  final int size;
  final int smoothness;
  final int soilDryness;
  final String firmness;

  BerryDetail({
    required this.id,
    required this.name,
    required this.growthTime,
    required this.maxHarvest,
    required this.size,
    required this.smoothness,
    required this.soilDryness,
    required this.firmness,
  });

  String get displayName =>
      name.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

  factory BerryDetail.fromJson(Map<String, dynamic> json) {
    return BerryDetail(
      id: json['id'],
      name: json['name'],
      growthTime: json['growth_time'] as int? ?? 0,
      maxHarvest: json['max_harvest'] as int? ?? 0,
      size: json['size'] as int? ?? 0,
      smoothness: json['smoothness'] as int? ?? 0,
      soilDryness: json['soil_dryness'] as int? ?? 0,
      firmness: json['firmness']?['name'] as String? ?? 'unknown',
    );
  }
}
