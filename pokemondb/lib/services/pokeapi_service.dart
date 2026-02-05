import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';
import '../models/move.dart';
import '../models/ability.dart';
import '../models/breeding.dart';
import '../models/item.dart';
import '../models/location.dart';

class PokeApiService {
  static const String _baseUrl = 'https://pokeapi.co/api/v2';
  static final Map<String, dynamic> _cache = {};
  static const int _batchSize = 10;
  static const int _maxRetries = 3;

  /// Fetch JSON with retry logic and caching.
  static Future<Map<String, dynamic>> _getJson(String url) async {
    if (_cache.containsKey(url)) return _cache[url];

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _cache[url] = data;
          return data;
        }
        if (response.statusCode == 429) {
          // Rate limited — back off
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
          continue;
        }
        throw Exception('HTTP ${response.statusCode}');
      } catch (e) {
        if (attempt == _maxRetries - 1) rethrow;
        await Future.delayed(Duration(seconds: (attempt + 1)));
      }
    }
    throw Exception('Failed after $_maxRetries retries: $url');
  }

  /// Get a page of pokemon (name + url only).
  static Future<List<PokemonBasic>> getPokemonList({
    int offset = 0,
    int limit = 50,
  }) async {
    final data = await _getJson(
      '$_baseUrl/pokemon?offset=$offset&limit=$limit',
    );
    return (data['results'] as List)
        .map((p) => PokemonBasic.fromJson(p))
        .toList();
  }

  /// Batch-fetch full details for a list of pokemon IDs.
  /// Returns results in order, with nulls for any that failed.
  static Future<List<PokemonDetail?>> getPokemonDetailsBatch(
    List<int> ids, {
    void Function(int loaded, int total)? onProgress,
  }) async {
    final results = List<PokemonDetail?>.filled(ids.length, null);
    int loaded = 0;

    for (int i = 0; i < ids.length; i += _batchSize) {
      final batchEnd = (i + _batchSize).clamp(0, ids.length);
      final batchIds = ids.sublist(i, batchEnd);

      final futures = batchIds.map((id) async {
        try {
          return await getPokemonDetail(id);
        } catch (_) {
          return null;
        }
      }).toList();

      final batchResults = await Future.wait(futures);
      for (int j = 0; j < batchResults.length; j++) {
        results[i + j] = batchResults[j];
      }

      loaded += batchResults.length;
      onProgress?.call(loaded, ids.length);
    }

    return results;
  }

  static Future<PokemonDetail> getPokemonDetail(int id) async {
    final data = await _getJson('$_baseUrl/pokemon/$id');
    return PokemonDetail.fromJson(data);
  }

  static Future<PokemonDetail> getPokemonDetailByName(String name) async {
    final data = await _getJson('$_baseUrl/pokemon/${name.toLowerCase()}');
    return PokemonDetail.fromJson(data);
  }

  static Future<PokemonSpecies> getPokemonSpecies(int id) async {
    final data = await _getJson('$_baseUrl/pokemon-species/$id');
    return PokemonSpecies.fromJson(data);
  }

  /// Returns the root of the evolution tree.
  static Future<EvolutionInfo> getEvolutionChain(int chainId) async {
    final data = await _getJson('$_baseUrl/evolution-chain/$chainId');
    return _parseEvolutionChain(data['chain']);
  }

  static EvolutionInfo _parseEvolutionChain(Map<String, dynamic> chain) {
    final speciesUrl = chain['species']['url'] as String;
    final segments = speciesUrl.split('/').where((s) => s.isNotEmpty).toList();
    final id = int.parse(segments.last);
    final name = chain['species']['name'] as String;

    // Extract evolution details (Phase 2: extended fields)
    String? trigger;
    int? minLevel;
    String? item;
    String? heldItem;
    String? knownMove;
    String? knownMoveType;
    String? location;
    int? minHappiness;
    int? minBeauty;
    int? minAffection;
    String? timeOfDay;
    String? partySpecies;
    int? relativePhysicalStats;
    String? tradeSpecies;
    int? gender;
    bool needsOverworldRain = false;
    bool turnUpsideDown = false;

    final details = chain['evolution_details'] as List;
    if (details.isNotEmpty) {
      final detail = details[0];
      trigger = detail['trigger']?['name'];
      minLevel = detail['min_level'];
      item = detail['item']?['name'];
      heldItem = detail['held_item']?['name'];
      knownMove = detail['known_move']?['name'];
      knownMoveType = detail['known_move_type']?['name'];
      location = detail['location']?['name'];
      minHappiness = detail['min_happiness'];
      minBeauty = detail['min_beauty'];
      minAffection = detail['min_affection'];
      timeOfDay = detail['time_of_day'] as String?;
      if (timeOfDay != null && timeOfDay.isEmpty) timeOfDay = null;
      partySpecies = detail['party_species']?['name'];
      relativePhysicalStats = detail['relative_physical_stats'];
      tradeSpecies = detail['trade_species']?['name'];
      gender = detail['gender'];
      needsOverworldRain = detail['needs_overworld_rain'] as bool? ?? false;
      turnUpsideDown = detail['turn_upside_down'] as bool? ?? false;
    }

    final children = <EvolutionInfo>[];
    for (final next in chain['evolves_to'] as List) {
      children.add(_parseEvolutionChain(next));
    }

    return EvolutionInfo(
      name: name,
      id: id,
      trigger: trigger,
      minLevel: minLevel,
      item: item,
      heldItem: heldItem,
      knownMove: knownMove,
      knownMoveType: knownMoveType,
      location: location,
      minHappiness: minHappiness,
      minBeauty: minBeauty,
      minAffection: minAffection,
      timeOfDay: timeOfDay,
      partySpecies: partySpecies,
      relativePhysicalStats: relativePhysicalStats,
      tradeSpecies: tradeSpecies,
      gender: gender,
      needsOverworldRain: needsOverworldRain,
      turnUpsideDown: turnUpsideDown,
      evolvesTo: children,
    );
  }

  static Future<MoveDetail> getMoveDetail(String nameOrId) async {
    final data = await _getJson('$_baseUrl/move/${nameOrId.toLowerCase()}');
    return MoveDetail.fromJson(data);
  }

  /// Batch-fetch move details.
  static Future<List<MoveDetail>> getMoveDetailsBatch(
    List<int> ids, {
    void Function(int loaded, int total)? onProgress,
  }) async {
    final results = <MoveDetail>[];
    int loaded = 0;

    for (int i = 0; i < ids.length; i += _batchSize) {
      final batchEnd = (i + _batchSize).clamp(0, ids.length);
      final batchIds = ids.sublist(i, batchEnd);

      final futures = batchIds.map((id) async {
        try {
          return await getMoveDetail(id.toString());
        } catch (_) {
          return null;
        }
      }).toList();

      final batchResults = await Future.wait(futures);
      for (final r in batchResults) {
        if (r != null) results.add(r);
      }

      loaded += batchResults.length;
      onProgress?.call(loaded, ids.length);
    }

    return results;
  }

  /// Search pokemon by name or ID.
  static Future<List<PokemonBasic>> searchPokemon(String query) async {
    final data = await _getJson('$_baseUrl/pokemon?limit=1025');
    final all = (data['results'] as List)
        .map((p) => PokemonBasic.fromJson(p))
        .toList();
    final q = query.toLowerCase();
    return all
        .where((p) =>
            p.name.contains(q) ||
            p.id.toString() == q ||
            p.idString.contains(q))
        .toList();
  }

  /// Pre-warm the full pokemon list cache.
  static Future<List<PokemonBasic>> getAllPokemonBasic() async {
    final data = await _getJson('$_baseUrl/pokemon?limit=1025');
    return (data['results'] as List)
        .map((p) => PokemonBasic.fromJson(p))
        .toList();
  }

  // Phase 1: Ability endpoints
  static Future<AbilityDetail> getAbilityDetail(String nameOrId) async {
    final data = await _getJson('$_baseUrl/ability/${nameOrId.toLowerCase()}');
    return AbilityDetail.fromJson(data);
  }

  static Future<List<AbilityDetail>> getAbilityDetailsBatch(
    List<String> names, {
    void Function(int loaded, int total)? onProgress,
  }) async {
    final results = <AbilityDetail>[];
    int loaded = 0;

    for (int i = 0; i < names.length; i += _batchSize) {
      final batchEnd = (i + _batchSize).clamp(0, names.length);
      final batchNames = names.sublist(i, batchEnd);

      final futures = batchNames.map((name) async {
        try {
          return await getAbilityDetail(name);
        } catch (_) {
          return null;
        }
      }).toList();

      final batchResults = await Future.wait(futures);
      for (final r in batchResults) {
        if (r != null) results.add(r);
      }

      loaded += batchResults.length;
      onProgress?.call(loaded, names.length);
    }

    return results;
  }

  static Future<EggGroupDetail> getEggGroup(String nameOrId) async {
    final data = await _getJson('$_baseUrl/egg-group/${nameOrId.toLowerCase()}');
    return EggGroupDetail.fromJson(data);
  }

  // Phase 2: Item endpoints
  static Future<List<ItemBasic>> getItemsList({
    int offset = 0,
    int limit = 100,
  }) async {
    final data = await _getJson(
      '$_baseUrl/item?offset=$offset&limit=$limit',
    );
    return (data['results'] as List)
        .map((i) => ItemBasic.fromJson(i))
        .toList();
  }

  static Future<ItemDetail> getItemDetail(String nameOrId) async {
    final data = await _getJson('$_baseUrl/item/${nameOrId.toLowerCase()}');
    return ItemDetail.fromJson(data);
  }

  static Future<BerryDetail> getBerryDetail(String nameOrId) async {
    final data = await _getJson('$_baseUrl/berry/${nameOrId.toLowerCase()}');
    return BerryDetail.fromJson(data);
  }

  /// Search items by name.
  static Future<List<ItemBasic>> searchItems(String query) async {
    final data = await _getJson('$_baseUrl/item?limit=2000');
    final all = (data['results'] as List)
        .map((i) => ItemBasic.fromJson(i))
        .toList();
    final q = query.toLowerCase();
    return all
        .where((i) =>
            i.name.contains(q) ||
            i.displayName.toLowerCase().contains(q))
        .toList();
  }

  /// Pre-warm the full items list cache.
  static Future<List<ItemBasic>> getAllItemsBasic() async {
    final data = await _getJson('$_baseUrl/item?limit=2000');
    return (data['results'] as List)
        .map((i) => ItemBasic.fromJson(i))
        .toList();
  }

  // Phase 3: Location and Encounter endpoints
  static Future<List<LocationBasic>> getLocationsList({
    int offset = 0,
    int limit = 100,
  }) async {
    final data = await _getJson(
      '$_baseUrl/location?offset=$offset&limit=$limit',
    );
    return (data['results'] as List)
        .map((l) => LocationBasic.fromJson(l))
        .toList();
  }

  static Future<LocationDetail> getLocationDetail(String nameOrId) async {
    final data = await _getJson('$_baseUrl/location/${nameOrId.toLowerCase()}');
    return LocationDetail.fromJson(data);
  }

  static Future<LocationArea> getLocationArea(String nameOrId) async {
    final data = await _getJson('$_baseUrl/location-area/${nameOrId.toLowerCase()}');
    return LocationArea.fromJson(data);
  }

  static Future<List<EncounterVersionDetail>> getPokemonEncounters(int pokemonId) async {
    final data = await _getJson('$_baseUrl/pokemon/$pokemonId/encounters');
    final encounters = <EncounterVersionDetail>[];

    // The API returns a list of location areas with encounter details
    for (final locationArea in data as List) {
      final versionDetails = locationArea['version_details'] as List? ?? [];
      for (final vd in versionDetails) {
        encounters.add(EncounterVersionDetail.fromJson(vd));
      }
    }

    return encounters;
  }

  /// Search locations by name.
  static Future<List<LocationBasic>> searchLocations(String query) async {
    final data = await _getJson('$_baseUrl/location?limit=1000');
    final all = (data['results'] as List)
        .map((l) => LocationBasic.fromJson(l))
        .toList();
    final q = query.toLowerCase();
    return all
        .where((l) =>
            l.name.contains(q) ||
            l.displayName.toLowerCase().contains(q))
        .toList();
  }

  /// Pre-warm the full locations list cache.
  static Future<List<LocationBasic>> getAllLocationsBasic() async {
    final data = await _getJson('$_baseUrl/location?limit=1000');
    return (data['results'] as List)
        .map((l) => LocationBasic.fromJson(l))
        .toList();
  }
}
