import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';
import '../models/move.dart';

class PokeApiService {
  static const String _baseUrl = 'https://pokeapi.co/api/v2';
  static final Map<String, dynamic> _cache = {};

  static Future<Map<String, dynamic>> _getJson(String url) async {
    if (_cache.containsKey(url)) return _cache[url];
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _cache[url] = data;
      return data;
    }
    throw Exception('Failed to load: $url (${response.statusCode})');
  }

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

  static Future<int> getTotalPokemonCount() async {
    final data = await _getJson('$_baseUrl/pokemon?limit=1');
    return data['count'] as int;
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

  static Future<List<EvolutionInfo>> getEvolutionChain(int chainId) async {
    final data = await _getJson('$_baseUrl/evolution-chain/$chainId');
    final List<EvolutionInfo> evolutions = [];
    _parseEvolutionChain(data['chain'], evolutions);
    return evolutions;
  }

  static void _parseEvolutionChain(
      Map<String, dynamic> chain, List<EvolutionInfo> evolutions) {
    final speciesUrl = chain['species']['url'] as String;
    final segments = speciesUrl.split('/').where((s) => s.isNotEmpty).toList();
    final id = int.parse(segments.last);
    final name = chain['species']['name'] as String;

    String? trigger;
    int? minLevel;
    final details = chain['evolution_details'] as List;
    if (details.isNotEmpty) {
      trigger = details[0]['trigger']?['name'];
      minLevel = details[0]['min_level'];
    }

    evolutions.add(EvolutionInfo(
      name: name,
      id: id,
      trigger: trigger,
      minLevel: minLevel,
    ));

    for (final next in chain['evolves_to'] as List) {
      _parseEvolutionChain(next, evolutions);
    }
  }

  static Future<MoveDetail> getMoveDetail(String name) async {
    final data = await _getJson('$_baseUrl/move/${name.toLowerCase()}');
    return MoveDetail.fromJson(data);
  }

  static Future<List<PokemonBasic>> searchPokemon(String query) async {
    // PokeAPI doesn't have a search endpoint, so we load all and filter
    final data = await _getJson('$_baseUrl/pokemon?limit=1025');
    final all = (data['results'] as List)
        .map((p) => PokemonBasic.fromJson(p))
        .toList();
    final q = query.toLowerCase();
    return all
        .where((p) =>
            p.name.contains(q) || p.id.toString() == q || p.idString.contains(q))
        .toList();
  }
}
