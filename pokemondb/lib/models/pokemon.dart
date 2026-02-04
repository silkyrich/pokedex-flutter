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
  final String? _artworkUrl;
  final String? _spriteUrlFromApi;

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
    String? artworkUrl,
    String? spriteUrlFromApi,
  }) : _artworkUrl = artworkUrl, _spriteUrlFromApi = spriteUrlFromApi;

  String get imageUrl =>
      _artworkUrl ??
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  String get spriteUrl =>
      _spriteUrlFromApi ??
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';

  String get displayName {
    // For forms, show a nicer name: "charizard-mega-x" → "Charizard (Mega X)"
    final parts = name.split('-');
    if (parts.length == 1) return name[0].toUpperCase() + name.substring(1);
    final baseName = parts.first[0].toUpperCase() + parts.first.substring(1);
    // Check if this is a form (ID > 10000 usually indicates alternate form)
    if (id > 10000) {
      final suffix = parts.sublist(1).join('-');
      final formLabel = suffix
          .replaceAll('mega-x', 'Mega X')
          .replaceAll('mega-y', 'Mega Y')
          .replaceAll('mega', 'Mega')
          .replaceAll('gmax', 'Gigantamax')
          .replaceAll('alola', 'Alolan')
          .replaceAll('galar', 'Galarian')
          .replaceAll('hisui', 'Hisuian')
          .replaceAll('paldea', 'Paldean');
      if (formLabel != suffix) return '$baseName ($formLabel)';
      final niceSuffix = suffix.split('-').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
      return '$baseName ($niceSuffix)';
    }
    return parts.map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join('-');
  }

  String get idString => '#${id.toString().padLeft(4, '0')}';

  double get heightInMeters => height / 10.0;
  double get weightInKg => weight / 10.0;

  /// Species ID (base form ID). For forms (id > 10000), extracted from speciesUrl.
  int get speciesId {
    if (speciesUrl != null) {
      final segments = speciesUrl!.split('/').where((s) => s.isNotEmpty).toList();
      return int.tryParse(segments.last) ?? id;
    }
    return id;
  }

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

    // Extract sprite URLs from API response
    final sprites = json['sprites'] as Map<String, dynamic>?;
    String? artworkUrl;
    String? spriteUrl;
    if (sprites != null) {
      spriteUrl = sprites['front_default'] as String?;
      final other = sprites['other'] as Map<String, dynamic>?;
      artworkUrl = other?['official-artwork']?['front_default'] as String?;
    }

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
      artworkUrl: artworkUrl,
      spriteUrlFromApi: spriteUrl,
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

class FormVariety {
  final String name;
  final int id;
  final bool isDefault;

  FormVariety({required this.name, required this.id, required this.isDefault});

  /// Human-readable form label: "charizard-mega-x" → "Mega X"
  String get formLabel {
    // Default form
    if (isDefault) return 'Base';
    // Extract the suffix after the base name
    final baseName = name.split('-').first;
    final suffix = name.length > baseName.length
        ? name.substring(baseName.length + 1)
        : name;
    // Common form transformations
    final label = suffix
        .replaceAll('mega-x', 'Mega X')
        .replaceAll('mega-y', 'Mega Y')
        .replaceAll('mega', 'Mega')
        .replaceAll('gmax', 'Gigantamax')
        .replaceAll('alola', 'Alolan')
        .replaceAll('galar', 'Galarian')
        .replaceAll('hisui', 'Hisuian')
        .replaceAll('paldea', 'Paldean');
    // If no known transformation, just capitalize
    if (label == suffix) {
      return suffix.split('-').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
    }
    return label;
  }
}

class PokemonSpecies {
  final int id;
  final String name;
  final String? genus;
  final String? flavorText;
  final List<EvolutionInfo> evolutionChain;
  final int? evolutionChainId;
  final List<FormVariety> varieties;

  PokemonSpecies({
    required this.id,
    required this.name,
    this.genus,
    this.flavorText,
    this.evolutionChain = const [],
    this.evolutionChainId,
    this.varieties = const [],
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

    // Parse varieties (forms)
    final varieties = <FormVariety>[];
    final varietiesJson = json['varieties'] as List? ?? [];
    for (final v in varietiesJson) {
      final pokemonData = v['pokemon'];
      final pokemonUrl = pokemonData['url'] as String;
      final segments = pokemonUrl.split('/').where((s) => s.isNotEmpty).toList();
      final pokemonId = int.parse(segments.last);
      varieties.add(FormVariety(
        name: pokemonData['name'] as String,
        id: pokemonId,
        isDefault: v['is_default'] as bool? ?? false,
      ));
    }

    return PokemonSpecies(
      id: json['id'],
      name: json['name'],
      genus: genus,
      flavorText: flavorText,
      evolutionChainId: chainId,
      varieties: varieties,
    );
  }
}

class EvolutionInfo {
  final String name;
  final int id;
  final String? trigger;
  final int? minLevel;
  final String? item;
  final List<EvolutionInfo> evolvesTo;

  EvolutionInfo({
    required this.name,
    required this.id,
    this.trigger,
    this.minLevel,
    this.item,
    this.evolvesTo = const [],
  });

  String get displayTrigger {
    if (minLevel != null) return 'Lv. $minLevel';
    if (item != null) {
      return item!.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
    }
    if (trigger == 'trade') return 'Trade';
    return '';
  }

  String get displayName => name[0].toUpperCase() + name.substring(1);

  /// Flatten tree into a list (for simple iteration).
  List<EvolutionInfo> flatten() {
    final result = <EvolutionInfo>[this];
    for (final child in evolvesTo) {
      result.addAll(child.flatten());
    }
    return result;
  }

  /// Whether this chain has any branching.
  bool get hasBranches {
    if (evolvesTo.length > 1) return true;
    return evolvesTo.any((e) => e.hasBranches);
  }
}
