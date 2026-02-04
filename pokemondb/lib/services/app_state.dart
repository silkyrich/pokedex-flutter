import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pokemon.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // Theme
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  // Favorites
  final Set<int> _favorites = {};
  Set<int> get favorites => Set.unmodifiable(_favorites);
  bool isFavorite(int id) => _favorites.contains(id);

  // Team (max 6)
  final List<int> _team = [];
  List<int> get team => List.unmodifiable(_team);
  bool isOnTeam(int id) => _team.contains(id);
  bool get teamFull => _team.length >= 6;

  // Active Pokemon context — flows from detail page to tools
  PokemonDetail? _activePokemon;
  PokemonDetail? get activePokemon => _activePokemon;

  final List<PokemonDetail> _recentPokemon = [];
  List<PokemonDetail> get recentPokemon => List.unmodifiable(_recentPokemon);

  void setActivePokemon(PokemonDetail pokemon) {
    _activePokemon = pokemon;
    _recentPokemon.removeWhere((p) => p.id == pokemon.id);
    _recentPokemon.insert(0, pokemon);
    if (_recentPokemon.length > 8) _recentPokemon.removeLast();
    notifyListeners();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme
    final isDark = prefs.getBool('dark_mode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    // Load favorites
    final favList = prefs.getStringList('favorites') ?? [];
    _favorites.addAll(favList.map(int.parse));

    // Load team
    final teamList = prefs.getStringList('team') ?? [];
    _team.addAll(teamList.map(int.parse));

    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _themeMode == ThemeMode.dark);
  }

  Future<void> toggleFavorite(int id) async {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites.map((e) => e.toString()).toList());
  }

  Future<void> toggleTeamMember(int id) async {
    if (_team.contains(id)) {
      _team.remove(id);
    } else if (_team.length < 6) {
      _team.add(id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('team', _team.map((e) => e.toString()).toList());
  }

  Future<void> reorderTeam(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final item = _team.removeAt(oldIndex);
    _team.insert(newIndex, item);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('team', _team.map((e) => e.toString()).toList());
  }

  Future<void> clearTeam() async {
    _team.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('team', []);
  }
}
