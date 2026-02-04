import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/pokemon_detail_screen.dart';
import 'screens/type_chart_screen.dart';
import 'screens/moves_screen.dart';
import 'screens/search_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/team_screen.dart';
import 'services/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState().init();
  runApp(const PokemonDbApp());
}

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/pokemon/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return PokemonDetailScreen(pokemonId: id);
      },
    ),
    GoRoute(path: '/types', builder: (context, state) => const TypeChartScreen()),
    GoRoute(path: '/moves', builder: (context, state) => const MovesScreen()),
    GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
    GoRoute(path: '/favorites', builder: (context, state) => const FavoritesScreen()),
    GoRoute(path: '/team', builder: (context, state) => const TeamScreen()),
  ],
);

const _pokemonBlue = Color(0xFF3B5BA7);

class PokemonDbApp extends StatelessWidget {
  const PokemonDbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState(),
      builder: (context, _) {
        return MaterialApp.router(
          title: 'Pokémon Database',
          debugShowCheckedModeBanner: false,
          themeMode: AppState().themeMode,
          theme: ThemeData(
            colorSchemeSeed: _pokemonBlue,
            brightness: Brightness.light,
            useMaterial3: true,
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: _pokemonBlue,
            brightness: Brightness.dark,
            useMaterial3: true,
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade800),
              ),
            ),
          ),
          routerConfig: _router,
        );
      },
    );
  }
}
