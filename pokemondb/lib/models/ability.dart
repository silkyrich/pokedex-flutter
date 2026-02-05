class AbilityDetail {
  final int id;
  final String name;
  final String? effect;
  final String? shortEffect;
  final int generation;
  final List<PokemonRef> pokemon;

  AbilityDetail({
    required this.id,
    required this.name,
    this.effect,
    this.shortEffect,
    required this.generation,
    this.pokemon = const [],
  });

  String get displayName =>
      name.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

  factory AbilityDetail.fromJson(Map<String, dynamic> json) {
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

    // Extract Pokemon that have this ability
    final pokemonList = <PokemonRef>[];
    for (final p in json['pokemon'] as List? ?? []) {
      final pokemonData = p['pokemon'];
      final url = pokemonData['url'] as String;
      final segments = url.split('/').where((s) => s.isNotEmpty).toList();
      final id = int.parse(segments.last);
      pokemonList.add(PokemonRef(
        id: id,
        name: pokemonData['name'] as String,
        isHidden: p['is_hidden'] as bool? ?? false,
      ));
    }

    return AbilityDetail(
      id: json['id'],
      name: json['name'],
      effect: effect,
      shortEffect: shortEffect,
      generation: json['generation']?['name']?.toString().replaceAll('generation-', '').replaceAll('i', '1').replaceAll('v', '5').replaceAll('x', '10') != null
          ? int.tryParse(json['generation']['name'].toString().split('-').last) ?? 1
          : 1,
      pokemon: pokemonList,
    );
  }
}

class PokemonRef {
  final int id;
  final String name;
  final bool isHidden;

  PokemonRef({
    required this.id,
    required this.name,
    required this.isHidden,
  });

  String get displayName =>
      name.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}
