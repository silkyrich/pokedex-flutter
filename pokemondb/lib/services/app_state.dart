import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pokemon.dart';

class AppColorTheme {
  final String id;
  final String label;
  final Color seed;
  final Brightness brightness;

  const AppColorTheme({
    required this.id,
    required this.label,
    required this.seed,
    required this.brightness,
  });

  bool get isDark => brightness == Brightness.dark;
}

const appColorThemes = [
  // Light themes
  AppColorTheme(id: 'ocean', label: 'Ocean', seed: Color(0xFF3B5BA7), brightness: Brightness.light),
  AppColorTheme(id: 'volcano', label: 'Volcano', seed: Color(0xFFDC3545), brightness: Brightness.light),
  AppColorTheme(id: 'forest', label: 'Forest', seed: Color(0xFF2E7D32), brightness: Brightness.light),
  AppColorTheme(id: 'fairy', label: 'Fairy', seed: Color(0xFFEC407A), brightness: Brightness.light),
  AppColorTheme(id: 'fire', label: 'Fire', seed: Color(0xFFE65100), brightness: Brightness.light),
  // Dark themes
  AppColorTheme(id: 'midnight', label: 'Midnight', seed: Color(0xFF5C6BC0), brightness: Brightness.dark),
  AppColorTheme(id: 'shadow', label: 'Shadow', seed: Color(0xFF7B1FA2), brightness: Brightness.dark),
  AppColorTheme(id: 'deep-sea', label: 'Deep Sea', seed: Color(0xFF00695C), brightness: Brightness.dark),
  AppColorTheme(id: 'steel', label: 'Steel', seed: Color(0xFF455A64), brightness: Brightness.dark),
  AppColorTheme(id: 'ember', label: 'Ember', seed: Color(0xFFBF360C), brightness: Brightness.dark),
];

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // Theme — brightness is determined by the selected theme
  String _colorThemeId = 'ocean';
  String get colorThemeId => _colorThemeId;
  AppColorTheme get colorTheme =>
      appColorThemes.firstWhere((t) => t.id == _colorThemeId,
          orElse: () => appColorThemes.first);
  ThemeMode get themeMode =>
      colorTheme.isDark ? ThemeMode.dark : ThemeMode.light;

  // Sprite style — pixel art (sprite) vs high-quality artwork
  bool _useArtwork = true; // Default to HD artwork
  bool get useArtwork => _useArtwork;

  // Card size scale — controls how large Pokemon cards appear (0.7 = smaller, 1.3 = larger)
  double _cardScale = 1.0;
  double get cardScale => _cardScale;

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

    // Load theme — migrate old dark_mode pref to new theme system
    final savedTheme = prefs.getString('color_theme');
    if (savedTheme != null && appColorThemes.any((t) => t.id == savedTheme)) {
      _colorThemeId = savedTheme;
    } else {
      final wasDark = prefs.getBool('dark_mode') ?? false;
      _colorThemeId = wasDark ? 'midnight' : 'ocean';
    }

    // Load favorites
    final favList = prefs.getStringList('favorites') ?? [];
    _favorites.addAll(favList.map(int.parse));

    // Load team
    final teamList = prefs.getStringList('team') ?? [];
    _team.addAll(teamList.map(int.parse));

    // Load sprite style preference
    _useArtwork = prefs.getBool('use_artwork') ?? false;

    // Load card scale preference
    _cardScale = prefs.getDouble('card_scale') ?? 1.0;

    notifyListeners();
  }

  Future<void> setColorTheme(String id) async {
    if (_colorThemeId == id) return;
    _colorThemeId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('color_theme', id);
  }

  Future<void> toggleSpriteStyle() async {
    _useArtwork = !_useArtwork;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_artwork', _useArtwork);
  }

  Future<void> setCardScale(double scale) async {
    _cardScale = scale.clamp(0.7, 1.3);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('card_scale', _cardScale);
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
