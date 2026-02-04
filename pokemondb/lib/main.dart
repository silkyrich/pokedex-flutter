import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/pokemon_detail_screen.dart';
import 'screens/type_chart_screen.dart';
import 'screens/moves_screen.dart';
import 'screens/search_screen.dart';

void main() {
  runApp(const PokemonDbApp());
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/pokemon/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return PokemonDetailScreen(pokemonId: id);
      },
    ),
    GoRoute(
      path: '/types',
      builder: (context, state) => const TypeChartScreen(),
    ),
    GoRoute(
      path: '/moves',
      builder: (context, state) => const MovesScreen(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),
  ],
);

class PokemonDbApp extends StatelessWidget {
  const PokemonDbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pokémon Database',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF3B5BA7),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'Roboto'),
        ),
      ),
      routerConfig: _router,
    );
  }
}
