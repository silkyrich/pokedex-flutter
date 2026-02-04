import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';
import '../models/move.dart';

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

    String? trigger;
    int? minLevel;
    String? item;
    final details = chain['evolution_details'] as List;
    if (details.isNotEmpty) {
      trigger = details[0]['trigger']?['name'];
      minLevel = details[0]['min_level'];
      item = details[0]['item']?['name'];
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
}
