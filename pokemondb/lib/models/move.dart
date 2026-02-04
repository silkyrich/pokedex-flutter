class MoveDetail {
  final int id;
  final String name;
  final String? type;
  final int? power;
  final int? accuracy;
  final int? pp;
  final String? damageClass; // physical, special, status
  final String? effectText;
  final String? flavorText;
  final List<MovePokemonRef> learnedByPokemon;

  MoveDetail({
    required this.id,
    required this.name,
    this.type,
    this.power,
    this.accuracy,
    this.pp,
    this.damageClass,
    this.effectText,
    this.flavorText,
    this.learnedByPokemon = const [],
  });

  String get displayName =>
      name.split('-').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');

  factory MoveDetail.fromJson(Map<String, dynamic> json) {
    String? effectText;
    final effectEntries = json['effect_entries'] as List? ?? [];
    for (final e in effectEntries) {
      if (e['language']['name'] == 'en') {
        effectText = e['short_effect'];
        break;
      }
    }

    String? flavorText;
    final flavorEntries = json['flavor_text_entries'] as List? ?? [];
    for (final f in flavorEntries) {
      if (f['language']?['name'] == 'en') {
        flavorText = (f['flavor_text'] as String?)?.replaceAll('\n', ' ').replaceAll('\f', ' ');
        break;
      }
    }

    final learnedBy = <MovePokemonRef>[];
    final learnedByList = json['learned_by_pokemon'] as List? ?? [];
    for (final p in learnedByList) {
      final url = p['url'] as String;
      final segments = url.split('/').where((s) => s.isNotEmpty).toList();
      final id = int.tryParse(segments.last);
      if (id != null) {
        learnedBy.add(MovePokemonRef(id: id, name: p['name'] as String));
      }
    }

    return MoveDetail(
      id: json['id'],
      name: json['name'],
      type: json['type']?['name'],
      power: json['power'],
      accuracy: json['accuracy'],
      pp: json['pp'],
      damageClass: json['damage_class']?['name'],
      effectText: effectText,
      flavorText: flavorText,
      learnedByPokemon: learnedBy,
    );
  }
}

class MovePokemonRef {
  final int id;
  final String name;

  MovePokemonRef({required this.id, required this.name});

  String get displayName => name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
  String get idString => '#${id.toString().padLeft(4, '0')}';
  String get spriteUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';
}
