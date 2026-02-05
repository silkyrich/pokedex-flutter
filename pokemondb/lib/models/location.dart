class LocationBasic {
  final int id;
  final String name;
  final String url;

  LocationBasic({required this.id, required this.name, required this.url});

  String get displayName =>
      name.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

  factory LocationBasic.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String;
    final segments = url.split('/').where((s) => s.isNotEmpty).toList();
    final id = int.parse(segments.last);
    return LocationBasic(
      id: id,
      name: json['name'] as String,
      url: url,
    );
  }
}

class LocationDetail {
  final int id;
  final String name;
  final String? region;
  final List<LocationAreaRef> areas;

  LocationDetail({
    required this.id,
    required this.name,
    this.region,
    this.areas = const [],
  });

  String get displayName =>
      name.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

  factory LocationDetail.fromJson(Map<String, dynamic> json) {
    final areas = <LocationAreaRef>[];
    for (final area in json['areas'] as List? ?? []) {
      final url = area['url'] as String;
      final segments = url.split('/').where((s) => s.isNotEmpty).toList();
      final id = int.parse(segments.last);
      areas.add(LocationAreaRef(
        id: id,
        name: area['name'] as String,
        url: url,
      ));
    }

    return LocationDetail(
      id: json['id'],
      name: json['name'],
      region: json['region']?['name'] as String?,
      areas: areas,
    );
  }
}

class LocationAreaRef {
  final int id;
  final String name;
  final String url;

  LocationAreaRef({
    required this.id,
    required this.name,
    required this.url,
  });

  String get displayName =>
      name.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}

class LocationArea {
  final int id;
  final String name;
  final String? location;
  final List<PokemonEncounter> pokemonEncounters;

  LocationArea({
    required this.id,
    required this.name,
    this.location,
    this.pokemonEncounters = const [],
  });

  String get displayName =>
      name.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

  factory LocationArea.fromJson(Map<String, dynamic> json) {
    final encounters = <PokemonEncounter>[];
    for (final enc in json['pokemon_encounters'] as List? ?? []) {
      final pokemonData = enc['pokemon'];
      final url = pokemonData['url'] as String;
      final segments = url.split('/').where((s) => s.isNotEmpty).toList();
      final pokemonId = int.parse(segments.last);

      final versionDetails = <EncounterVersionDetail>[];
      for (final detail in enc['version_details'] as List? ?? []) {
        versionDetails.add(EncounterVersionDetail.fromJson(detail));
      }

      encounters.add(PokemonEncounter(
        pokemonId: pokemonId,
        pokemonName: pokemonData['name'] as String,
        versionDetails: versionDetails,
      ));
    }

    return LocationArea(
      id: json['id'],
      name: json['name'],
      location: json['location']?['name'] as String?,
      pokemonEncounters: encounters,
    );
  }
}

class PokemonEncounter {
  final int pokemonId;
  final String pokemonName;
  final List<EncounterVersionDetail> versionDetails;

  PokemonEncounter({
    required this.pokemonId,
    required this.pokemonName,
    this.versionDetails = const [],
  });

  String get displayName =>
      pokemonName.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}

class EncounterVersionDetail {
  final String version;
  final int maxChance;
  final List<EncounterMethodRate> encounterDetails;

  EncounterVersionDetail({
    required this.version,
    required this.maxChance,
    this.encounterDetails = const [],
  });

  factory EncounterVersionDetail.fromJson(Map<String, dynamic> json) {
    final details = <EncounterMethodRate>[];
    for (final detail in json['encounter_details'] as List? ?? []) {
      details.add(EncounterMethodRate.fromJson(detail));
    }

    return EncounterVersionDetail(
      version: json['version']['name'] as String,
      maxChance: json['max_chance'] as int? ?? 0,
      encounterDetails: details,
    );
  }
}

class EncounterMethodRate {
  final String method;
  final int chance;
  final int minLevel;
  final int maxLevel;
  final List<String> conditionValues;

  EncounterMethodRate({
    required this.method,
    required this.chance,
    required this.minLevel,
    required this.maxLevel,
    this.conditionValues = const [],
  });

  String get displayMethod {
    switch (method) {
      case 'walk':
        return 'Walking';
      case 'old-rod':
        return 'Old Rod';
      case 'good-rod':
        return 'Good Rod';
      case 'super-rod':
        return 'Super Rod';
      case 'surf':
        return 'Surfing';
      case 'rock-smash':
        return 'Rock Smash';
      case 'headbutt':
        return 'Headbutt';
      case 'dark-grass':
        return 'Dark Grass';
      case 'grass-spots':
        return 'Rustling Grass';
      case 'cave-spots':
        return 'Dust Cloud';
      case 'bridge-spots':
        return 'Bridge Shadow';
      case 'super-rod-spots':
        return 'Fishing Spot';
      case 'surf-spots':
        return 'Surf Spot';
      case 'yellow-flowers':
        return 'Yellow Flowers';
      case 'purple-flowers':
        return 'Purple Flowers';
      case 'red-flowers':
        return 'Red Flowers';
      case 'rough-terrain':
        return 'Rough Terrain';
      default:
        return method.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
    }
  }

  factory EncounterMethodRate.fromJson(Map<String, dynamic> json) {
    final conditions = <String>[];
    for (final cond in json['condition_values'] as List? ?? []) {
      conditions.add(cond['name'] as String);
    }

    return EncounterMethodRate(
      method: json['method']['name'] as String,
      chance: json['chance'] as int? ?? 0,
      minLevel: json['min_level'] as int? ?? 0,
      maxLevel: json['max_level'] as int? ?? 0,
      conditionValues: conditions,
    );
  }
}
