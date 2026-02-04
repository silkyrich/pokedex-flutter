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
    GoRoute(
        path: '/types',
        builder: (context, state) => const TypeChartScreen()),
    GoRoute(
        path: '/moves', builder: (context, state) => const MovesScreen()),
    GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen()),
    GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen()),
    GoRoute(
        path: '/team', builder: (context, state) => const TeamScreen()),
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
            fontFamily: 'Segoe UI',
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              color: Colors.white,
            ),
            chipTheme: ChipThemeData(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
              ),
            ),
            dividerTheme: DividerThemeData(
              color: Colors.grey.shade200,
              thickness: 1,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: _pokemonBlue,
            brightness: Brightness.dark,
            useMaterial3: true,
            fontFamily: 'Segoe UI',
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade800),
              ),
              color: const Color(0xFF1E1E2E),
            ),
            chipTheme: ChipThemeData(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
              ),
            ),
            dividerTheme: DividerThemeData(
              color: Colors.grey.shade800,
              thickness: 1,
            ),
            scaffoldBackgroundColor: const Color(0xFF121218),
          ),
          routerConfig: _router,
        );
      },
    );
  }
}
