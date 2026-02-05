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
  // Phase 1: Extended species data
  final int? captureRate;
  final int? baseHappiness;
  final int? genderRate; // -1 = genderless, 0 = always male, 8 = always female, 1-7 = ratio
  final int? hatchCounter;
  final List<String> eggGroups;
  final String? habitat;
  final String? shape;
  final String? color;
  final bool isBaby;
  final bool isLegendary;
  final bool isMythical;
  final int generation;
  // Phase 4: Growth rate
  final String? growthRate;

  PokemonSpecies({
    required this.id,
    required this.name,
    this.genus,
    this.flavorText,
    this.evolutionChain = const [],
    this.evolutionChainId,
    this.varieties = const [],
    this.captureRate,
    this.baseHappiness,
    this.genderRate,
    this.hatchCounter,
    this.eggGroups = const [],
    this.habitat,
    this.shape,
    this.color,
    this.isBaby = false,
    this.isLegendary = false,
    this.isMythical = false,
    this.generation = 1,
    this.growthRate,
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

    // Parse egg groups
    final eggGroupsList = <String>[];
    for (final eg in json['egg_groups'] as List? ?? []) {
      eggGroupsList.add(eg['name'] as String);
    }

    // Parse generation (e.g., "generation-i" -> 1)
    int generation = 1;
    final genName = json['generation']?['name'] as String?;
    if (genName != null) {
      final romanNumerals = {'i': 1, 'ii': 2, 'iii': 3, 'iv': 4, 'v': 5, 'vi': 6, 'vii': 7, 'viii': 8, 'ix': 9};
      final genPart = genName.split('-').last.toLowerCase();
      generation = romanNumerals[genPart] ?? 1;
    }

    return PokemonSpecies(
      id: json['id'],
      name: json['name'],
      genus: genus,
      flavorText: flavorText,
      evolutionChainId: chainId,
      varieties: varieties,
      captureRate: json['capture_rate'] as int?,
      baseHappiness: json['base_happiness'] as int?,
      genderRate: json['gender_rate'] as int?,
      hatchCounter: json['hatch_counter'] as int?,
      eggGroups: eggGroupsList,
      habitat: json['habitat']?['name'] as String?,
      shape: json['shape']?['name'] as String?,
      color: json['color']?['name'] as String?,
      isBaby: json['is_baby'] as bool? ?? false,
      isLegendary: json['is_legendary'] as bool? ?? false,
      isMythical: json['is_mythical'] as bool? ?? false,
      generation: generation,
      growthRate: json['growth_rate']?['name'] as String?,
    );
  }
}

class EvolutionInfo {
  final String name;
  final int id;
  final String? trigger;
  final int? minLevel;
  final String? item;
  // Phase 2: Extended evolution conditions
  final String? heldItem;
  final String? knownMove;
  final String? knownMoveType;
  final String? location;
  final int? minHappiness;
  final int? minBeauty;
  final int? minAffection;
  final String? timeOfDay;
  final String? partySpecies;
  final int? relativePhysicalStats; // 1 = Atk > Def, -1 = Atk < Def, 0 = Atk == Def
  final String? tradeSpecies;
  final int? gender; // 1 = female, 2 = male
  final bool needsOverworldRain;
  final bool turnUpsideDown;
  final List<EvolutionInfo> evolvesTo;

  EvolutionInfo({
    required this.name,
    required this.id,
    this.trigger,
    this.minLevel,
    this.item,
    this.heldItem,
    this.knownMove,
    this.knownMoveType,
    this.location,
    this.minHappiness,
    this.minBeauty,
    this.minAffection,
    this.timeOfDay,
    this.partySpecies,
    this.relativePhysicalStats,
    this.tradeSpecies,
    this.gender,
    this.needsOverworldRain = false,
    this.turnUpsideDown = false,
    this.evolvesTo = const [],
  });

  String get displayTrigger {
    final parts = <String>[];

    // Level requirement
    if (minLevel != null) {
      parts.add('Lv. $minLevel');
    }

    // Item (evolution stone, etc.)
    if (item != null) {
      parts.add(item!.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' '));
    }

    // Trade
    if (trigger == 'trade') {
      if (tradeSpecies != null) {
        parts.add('Trade for ${tradeSpecies!.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')}');
      } else if (heldItem != null) {
        parts.add('Trade holding ${heldItem!.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')}');
      } else {
        parts.add('Trade');
      }
    }

    // Friendship/Happiness
    if (minHappiness != null) {
      parts.add('Friendship ≥ $minHappiness');
    }

    // Affection
    if (minAffection != null) {
      parts.add('Affection ≥ $minAffection');
    }

    // Beauty
    if (minBeauty != null) {
      parts.add('Beauty ≥ $minBeauty');
    }

    // Time of day
    if (timeOfDay != null && timeOfDay!.isNotEmpty) {
      parts.add(timeOfDay![0].toUpperCase() + timeOfDay!.substring(1));
    }

    // Known move
    if (knownMove != null) {
      parts.add('Knows ${knownMove!.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')}');
    }

    // Known move type
    if (knownMoveType != null) {
      parts.add('Knows ${knownMoveType![0].toUpperCase() + knownMoveType!.substring(1)}-type move');
    }

    // Location
    if (location != null) {
      parts.add('at ${location!.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')}');
    }

    // Party species
    if (partySpecies != null) {
      parts.add('with ${partySpecies!.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')} in party');
    }

    // Relative stats (Hitmonlee/Hitmonchan/Hitmontop)
    if (relativePhysicalStats != null) {
      if (relativePhysicalStats! > 0) {
        parts.add('Attack > Defense');
      } else if (relativePhysicalStats! < 0) {
        parts.add('Attack < Defense');
      } else {
        parts.add('Attack = Defense');
      }
    }

    // Gender
    if (gender != null) {
      parts.add(gender == 1 ? 'Female' : 'Male');
    }

    // Special conditions
    if (needsOverworldRain) {
      parts.add('During rain');
    }

    if (turnUpsideDown) {
      parts.add('Turn console upside down');
    }

    return parts.isEmpty ? '' : parts.join(' + ');
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
