import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/pokemon_detail_screen.dart';
import 'screens/type_chart_screen.dart';
import 'screens/moves_screen.dart';
import 'screens/search_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/team_screen.dart';
import 'screens/team_coverage_screen.dart';
import 'screens/move_detail_screen.dart';
import 'screens/type_matchup_screen.dart';
import 'screens/battle_screen.dart';
import 'screens/stat_calculator_screen.dart';
import 'screens/damage_calculator_screen.dart';
import 'screens/speed_tiers_screen.dart';
import 'screens/counter_screen.dart';
import 'screens/nuzlocke_screen.dart';
import 'screens/shiny_hunter_screen.dart';
import 'screens/about_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/stats_guide_screen.dart';
import 'screens/official_links_screen.dart';
import 'screens/items_screen.dart';
import 'screens/item_detail_screen.dart';
import 'screens/locations_screen.dart';
import 'screens/location_detail_screen.dart';
import 'screens/pokedexes_screen.dart';
import 'screens/pokedex_detail_screen.dart';
import 'widgets/navigation_shell.dart';
import 'services/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  await AppState().init();
  runApp(const PokemonDbApp());
}


final _router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => NavigationShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/moves', builder: (context, state) => const MovesScreen()),
        GoRoute(
          path: '/moves/:name',
          builder: (context, state) {
            final name = state.pathParameters['name']!;
            return MoveDetailScreen(moveName: name);
          },
        ),
        GoRoute(path: '/types', builder: (context, state) => const TypeChartScreen()),
        GoRoute(
          path: '/types/:atk/vs/:def',
          builder: (context, state) {
            final atk = state.pathParameters['atk']!;
            final def = state.pathParameters['def']!;
            return TypeMatchupScreen(attackingType: atk, defendingType: def);
          },
        ),
        GoRoute(path: '/battle', builder: (context, state) => const BattleScreen()),
        GoRoute(
          path: '/battle/:id1/:id2',
          builder: (context, state) {
            final id1 = int.tryParse(state.pathParameters['id1'] ?? '');
            final id2 = int.tryParse(state.pathParameters['id2'] ?? '');
            return BattleScreen(initialId1: id1, initialId2: id2);
          },
        ),
        GoRoute(path: '/team', builder: (context, state) => const TeamScreen()),
        GoRoute(path: '/team/coverage', builder: (context, state) => const TeamCoverageScreen()),
        GoRoute(path: '/tools', redirect: (_, __) => '/'),
        GoRoute(path: '/tools/stat-calc', builder: (context, state) => const StatCalculatorScreen()),
        GoRoute(
          path: '/tools/stat-calc/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            return StatCalculatorScreen(pokemonId: id);
          },
        ),
        GoRoute(path: '/tools/damage-calc', builder: (context, state) => const DamageCalculatorScreen()),
        GoRoute(path: '/tools/speed-tiers', builder: (context, state) => const SpeedTiersScreen()),
        GoRoute(path: '/tools/counter', builder: (context, state) => const CounterScreen()),
        GoRoute(
          path: '/tools/counter/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            return CounterScreen(pokemonId: id);
          },
        ),
        GoRoute(path: '/tools/nuzlocke', builder: (context, state) => const NuzlockeScreen()),
        GoRoute(path: '/tools/shiny', builder: (context, state) => const ShinyHunterScreen()),
        GoRoute(path: '/quiz', builder: (context, state) => const QuizScreen()),
        GoRoute(path: '/learn', builder: (context, state) => const LearnScreen()),
        GoRoute(path: '/stats-guide', builder: (context, state) => const StatsGuideScreen()),
        GoRoute(path: '/official', builder: (context, state) => const OfficialLinksScreen()),
        GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
        GoRoute(path: '/favorites', builder: (context, state) => const FavoritesScreen()),
        GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
        GoRoute(path: '/items', builder: (context, state) => const ItemsScreen()),
        GoRoute(
          path: '/items/:name',
          builder: (context, state) {
            final name = state.pathParameters['name']!;
            return ItemDetailScreen(itemName: name);
          },
        ),
        GoRoute(path: '/locations', builder: (context, state) => const LocationsScreen()),
        GoRoute(
          path: '/locations/:name',
          builder: (context, state) {
            final name = state.pathParameters['name']!;
            return LocationDetailScreen(locationName: name);
          },
        ),
        GoRoute(path: '/pokedexes', builder: (context, state) => const PokedexesScreen()),
        GoRoute(
          path: '/pokedexes/:name',
          builder: (context, state) {
            final name = state.pathParameters['name']!;
            return PokedexDetailScreen(pokedexName: name);
          },
        ),
        GoRoute(
          path: '/pokemon/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return PokemonDetailScreen(pokemonId: id);
          },
        ),
      ],
    ),
  ],
);

class PokemonDbApp extends StatelessWidget {
  const PokemonDbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState(),
      builder: (context, _) {
        final ct = AppState().colorTheme;
        final themeData = _buildTheme(ct);
        return MaterialApp.router(
          title: 'DexGuide',
          debugShowCheckedModeBanner: false,
          themeMode: AppState().themeMode,
          theme: ct.isDark ? null : themeData,
          darkTheme: ct.isDark ? themeData : null,
          routerConfig: _router,
        );
      },
    );
  }

  ThemeData _buildTheme(AppColorTheme ct) {
    final isDark = ct.isDark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: ct.seed,
      brightness: ct.brightness,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: isDark ? const Color(0xFF121218) : const Color(0xFFF8F9FA),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
          ),
        ),
        color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: isDark ? const Color(0xFF1E1E2A) : Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? const Color(0xFF1E1E2A) : Colors.white,
        indicatorColor: colorScheme.primary.withOpacity(isDark ? 0.15 : 0.12),
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
        ),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
          fontSize: 12,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1E1E2A) : Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primary.withOpacity(isDark ? 0.15 : 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 12);
          }
          return TextStyle(
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
            fontSize: 12,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
        space: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
