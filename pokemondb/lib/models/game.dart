class GameVersion {
  final int id;
  final String name;
  final String versionGroup;

  GameVersion({
    required this.id,
    required this.name,
    required this.versionGroup,
  });

  String get displayName =>
      name.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

  factory GameVersion.fromJson(Map<String, dynamic> json) {
    return GameVersion(
      id: json['id'],
      name: json['name'],
      versionGroup: json['version_group']?['name'] ?? '',
    );
  }
}

class VersionGroup {
  final int id;
  final String name;
  final int generation;
  final List<String> versions;

  VersionGroup({
    required this.id,
    required this.name,
    required this.generation,
    this.versions = const [],
  });

  String get displayName =>
      name.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

  factory VersionGroup.fromJson(Map<String, dynamic> json) {
    final versions = <String>[];
    for (final v in json['versions'] as List? ?? []) {
      versions.add(v['name'] as String);
    }

    // Extract generation number
    int generation = 1;
    final genData = json['generation'];
    if (genData != null) {
      final genUrl = genData['url'] as String;
      final segments = genUrl.split('/').where((s) => s.isNotEmpty).toList();
      generation = int.tryParse(segments.last) ?? 1;
    }

    return VersionGroup(
      id: json['id'],
      name: json['name'],
      generation: generation,
      versions: versions,
    );
  }
}

class PokedexBasic {
  final int id;
  final String name;
  final String url;

  PokedexBasic({required this.id, required this.name, required this.url});

  String get displayName {
    // Special cases for well-known Pokedexes
    final nameMap = {
      'national': 'National Pokédex',
      'kanto': 'Kanto Pokédex',
      'original-johto': 'Johto Pokédex (Gen II)',
      'hoenn': 'Hoenn Pokédex',
      'original-sinnoh': 'Sinnoh Pokédex (Gen IV)',
      'extended-sinnoh': 'Sinnoh Pokédex (Platinum)',
      'updated-johto': 'Johto Pokédex (HGSS)',
      'original-unova': 'Unova Pokédex (BW)',
      'updated-unova': 'Unova Pokédex (B2W2)',
      'kalos-central': 'Kalos Central',
      'kalos-coastal': 'Kalos Coastal',
      'kalos-mountain': 'Kalos Mountain',
      'updated-hoenn': 'Hoenn Pokédex (ORAS)',
      'original-alola': 'Alola Pokédex (SM)',
      'updated-alola': 'Alola Pokédex (USUM)',
      'letsgo-kanto': 'Kanto Pokédex (Let\'s Go)',
      'galar': 'Galar Pokédex',
      'isle-of-armor': 'Isle of Armor',
      'crown-tundra': 'Crown Tundra',
      'hisui': 'Hisui Pokédex',
      'paldea': 'Paldea Pokédex',
      'kitakami': 'Kitakami Pokédex',
      'blueberry': 'Blueberry Pokédex',
    };

    return nameMap[name] ??
        name.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  factory PokedexBasic.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String;
    final segments = url.split('/').where((s) => s.isNotEmpty).toList();
    final id = int.parse(segments.last);
    return PokedexBasic(
      id: id,
      name: json['name'] as String,
      url: url,
    );
  }
}

class PokedexDetail {
  final int id;
  final String name;
  final bool isMainSeries;
  final List<PokedexEntry> pokemonEntries;
  final String? region;

  PokedexDetail({
    required this.id,
    required this.name,
    required this.isMainSeries,
    this.pokemonEntries = const [],
    this.region,
  });

  String get displayName {
    final basic = PokedexBasic(id: id, name: name, url: '');
    return basic.displayName;
  }

  factory PokedexDetail.fromJson(Map<String, dynamic> json) {
    final entries = <PokedexEntry>[];
    for (final entry in json['pokemon_entries'] as List? ?? []) {
      final pokemonData = entry['pokemon_species'];
      final url = pokemonData['url'] as String;
      final segments = url.split('/').where((s) => s.isNotEmpty).toList();
      final pokemonId = int.parse(segments.last);

      entries.add(PokedexEntry(
        entryNumber: entry['entry_number'] as int,
        pokemonId: pokemonId,
        pokemonName: pokemonData['name'] as String,
      ));
    }

    // Sort by entry number
    entries.sort((a, b) => a.entryNumber.compareTo(b.entryNumber));

    return PokedexDetail(
      id: json['id'],
      name: json['name'],
      isMainSeries: json['is_main_series'] as bool? ?? false,
      pokemonEntries: entries,
      region: json['region']?['name'] as String?,
    );
  }
}

class PokedexEntry {
  final int entryNumber;
  final int pokemonId;
  final String pokemonName;

  PokedexEntry({
    required this.entryNumber,
    required this.pokemonId,
    required this.pokemonName,
  });
}

class GrowthRateDetail {
  final int id;
  final String name;
  final String formula;
  final List<ExperienceLevel> levels;

  GrowthRateDetail({
    required this.id,
    required this.name,
    required this.formula,
    this.levels = const [],
  });

  String get displayName {
    switch (name) {
      case 'slow':
        return 'Slow';
      case 'medium':
        return 'Medium Fast';
      case 'fast':
        return 'Fast';
      case 'medium-slow':
        return 'Medium Slow';
      case 'slow-then-very-fast':
        return 'Erratic';
      case 'fast-then-very-slow':
        return 'Fluctuating';
      default:
        return name.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
    }
  }

  factory GrowthRateDetail.fromJson(Map<String, dynamic> json) {
    final levels = <ExperienceLevel>[];
    for (final level in json['levels'] as List? ?? []) {
      levels.add(ExperienceLevel(
        level: level['level'] as int,
        experience: level['experience'] as int,
      ));
    }

    return GrowthRateDetail(
      id: json['id'],
      name: json['name'],
      formula: json['formula'] as String? ?? '',
      levels: levels,
    );
  }
}

class ExperienceLevel {
  final int level;
  final int experience;

  ExperienceLevel({
    required this.level,
    required this.experience,
  });
}
