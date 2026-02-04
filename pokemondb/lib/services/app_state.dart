import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pokemon.dart';

class AppColorTheme {
  final String id;
  final String label;
  final Color seed;
  final Color accent;

  const AppColorTheme({
    required this.id,
    required this.label,
    required this.seed,
    required this.accent,
  });
}

const appColorThemes = [
  AppColorTheme(id: 'blue', label: 'Ocean', seed: Color(0xFF3B5BA7), accent: Color(0xFFDC3545)),
  AppColorTheme(id: 'red', label: 'Volcano', seed: Color(0xFFDC3545), accent: Color(0xFFFF8A50)),
  AppColorTheme(id: 'green', label: 'Forest', seed: Color(0xFF2E7D32), accent: Color(0xFF81C784)),
  AppColorTheme(id: 'purple', label: 'Ghost', seed: Color(0xFF7B1FA2), accent: Color(0xFFCE93D8)),
  AppColorTheme(id: 'orange', label: 'Fire', seed: Color(0xFFE65100), accent: Color(0xFFFFAB40)),
  AppColorTheme(id: 'teal', label: 'Water', seed: Color(0xFF00695C), accent: Color(0xFF4DB6AC)),
  AppColorTheme(id: 'pink', label: 'Fairy', seed: Color(0xFFEC407A), accent: Color(0xFFF48FB1)),
  AppColorTheme(id: 'slate', label: 'Steel', seed: Color(0xFF455A64), accent: Color(0xFF90A4AE)),
];

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // Theme
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  String _colorThemeId = 'blue';
  String get colorThemeId => _colorThemeId;
  AppColorTheme get colorTheme =>
      appColorThemes.firstWhere((t) => t.id == _colorThemeId,
          orElse: () => appColorThemes.first);

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
    _colorThemeId = prefs.getString('color_theme') ?? 'blue';

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

  Future<void> setColorTheme(String id) async {
    if (_colorThemeId == id) return;
    _colorThemeId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('color_theme', id);
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
