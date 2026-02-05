class EggGroup {
  final String name;

  EggGroup({required this.name});

  String get displayName =>
      name.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

  factory EggGroup.fromJson(Map<String, dynamic> json) {
    return EggGroup(name: json['name']);
  }
}

class EggGroupDetail {
  final int id;
  final String name;
  final List<PokemonSpeciesRef> pokemonSpecies;

  EggGroupDetail({
    required this.id,
    required this.name,
    this.pokemonSpecies = const [],
  });

  String get displayName =>
      name.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

  factory EggGroupDetail.fromJson(Map<String, dynamic> json) {
    final speciesList = <PokemonSpeciesRef>[];
    for (final s in json['pokemon_species'] as List? ?? []) {
      final url = s['url'] as String;
      final segments = url.split('/').where((s) => s.isNotEmpty).toList();
      final id = int.parse(segments.last);
      speciesList.add(PokemonSpeciesRef(
        id: id,
        name: s['name'] as String,
      ));
    }

    return EggGroupDetail(
      id: json['id'],
      name: json['name'],
      pokemonSpecies: speciesList,
    );
  }
}

class PokemonSpeciesRef {
  final int id;
  final String name;

  PokemonSpeciesRef({
    required this.id,
    required this.name,
  });

  String get displayName =>
      name.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}
