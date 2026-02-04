class PokemonBasic {
  final int id;
  final String name;
  final String url;

  PokemonBasic({required this.id, required this.name, required this.url});

  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  String get spriteUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';

  String get displayName => name[0].toUpperCase() + name.substring(1);

  String get idString => '#${id.toString().padLeft(4, '0')}';

  factory PokemonBasic.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String;
    final segments = url.split('/').where((s) => s.isNotEmpty).toList();
    final id = int.parse(segments.last);
    return PokemonBasic(
      id: id,
      name: json['name'] as String,
      url: url,
    );
  }
}

class PokemonDetail {
  final int id;
  final String name;
  final List<PokemonType> types;
  final Map<String, int> stats;
  final int height; // decimetres
  final int weight; // hectograms
  final List<PokemonAbility> abilities;
  final List<PokemonMove> moves;
  final String? speciesUrl;
  final int baseExperience;

  PokemonDetail({
    required this.id,
    required this.name,
    required this.types,
    required this.stats,
    required this.height,
    required this.weight,
    required this.abilities,
    required this.moves,
    this.speciesUrl,
    required this.baseExperience,
  });

  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  String get displayName => name[0].toUpperCase() + name.substring(1);

  String get idString => '#${id.toString().padLeft(4, '0')}';

  double get heightInMeters => height / 10.0;
  double get weightInKg => weight / 10.0;

  factory PokemonDetail.fromJson(Map<String, dynamic> json) {
    final statsMap = <String, int>{};
    for (final s in json['stats'] as List) {
      statsMap[s['stat']['name']] = s['base_stat'];
    }

    final types = (json['types'] as List)
        .map((t) => PokemonType(
              name: t['type']['name'],
              slot: t['slot'],
            ))
        .toList();

    final abilities = (json['abilities'] as List)
        .map((a) => PokemonAbility(
              name: a['ability']['name'],
              isHidden: a['is_hidden'],
            ))
        .toList();

    final moves = (json['moves'] as List).map((m) {
      final versionDetails = m['version_group_details'] as List;
      final latestDetail = versionDetails.isNotEmpty ? versionDetails.last : null;
      return PokemonMove(
        name: m['move']['name'],
        learnMethod: latestDetail?['move_learn_method']?['name'] ?? 'unknown',
        levelLearnedAt: latestDetail?['level_learned_at'] ?? 0,
      );
    }).toList();

    return PokemonDetail(
      id: json['id'],
      name: json['name'],
      types: types,
      stats: statsMap,
      height: json['height'],
      weight: json['weight'],
      abilities: abilities,
      moves: moves,
      speciesUrl: json['species']?['url'],
      baseExperience: json['base_experience'] ?? 0,
    );
  }
}

class PokemonType {
  final String name;
  final int slot;

  PokemonType({required this.name, required this.slot});

  String get displayName => name[0].toUpperCase() + name.substring(1);
}

class PokemonAbility {
  final String name;
  final bool isHidden;

  PokemonAbility({required this.name, required this.isHidden});

  String get displayName =>
      name.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}

class PokemonMove {
  final String name;
  final String learnMethod;
  final int levelLearnedAt;

  PokemonMove({
    required this.name,
    required this.learnMethod,
    required this.levelLearnedAt,
  });

  String get displayName =>
      name.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}

class PokemonSpecies {
  final int id;
  final String name;
  final String? genus;
  final String? flavorText;
  final List<EvolutionInfo> evolutionChain;
  final int? evolutionChainId;

  PokemonSpecies({
    required this.id,
    required this.name,
    this.genus,
    this.flavorText,
    this.evolutionChain = const [],
    this.evolutionChainId,
  });

  factory PokemonSpecies.fromJson(Map<String, dynamic> json) {
    String? genus;
    for (final g in json['genera'] as List) {
      if (g['language']['name'] == 'en') {
        genus = g['genus'];
        break;
      }
    }

    String? flavorText;
    for (final f in json['flavor_text_entries'] as List) {
      if (f['language']['name'] == 'en') {
        flavorText = (f['flavor_text'] as String).replaceAll('\n', ' ').replaceAll('\f', ' ');
        break;
      }
    }

    int? chainId;
    final chainUrl = json['evolution_chain']?['url'];
    if (chainUrl != null) {
      final segments = (chainUrl as String).split('/').where((s) => s.isNotEmpty).toList();
      chainId = int.tryParse(segments.last);
    }

    return PokemonSpecies(
      id: json['id'],
      name: json['name'],
      genus: genus,
      flavorText: flavorText,
      evolutionChainId: chainId,
    );
  }
}

class EvolutionInfo {
  final String name;
  final int id;
  final String? trigger;
  final int? minLevel;

  EvolutionInfo({
    required this.name,
    required this.id,
    this.trigger,
    this.minLevel,
  });
}
