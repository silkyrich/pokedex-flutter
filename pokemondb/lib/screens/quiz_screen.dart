import 'dart:math';
import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../services/pokeapi_service.dart';
import '../services/app_state.dart';
import '../utils/type_colors.dart';
import '../widgets/pokemon_image.dart';

enum QuizMode { whoseThat, typeMatchup, statShowdown }

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  QuizMode? _activeMode;
  int _streak = 0;
  int _bestStreak = 0;

  // Question state
  bool _loading = false;
  _QuizQuestion? _question;
  int? _selectedAnswer;
  bool _answered = false;

  // Pokemon pool
  List<PokemonBasic>? _allPokemon;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _loadPokemonPool();
  }

  Future<void> _loadPokemonPool() async {
    try {
      _allPokemon = await PokeApiService.getAllPokemonBasic();
    } catch (_) {}
  }

  void _startMode(QuizMode mode) {
    setState(() {
      _activeMode = mode;
      _streak = 0;
    });
    _nextQuestion();
  }

  void _backToMenu() {
    setState(() {
      _activeMode = null;
      _question = null;
      _selectedAnswer = null;
      _answered = false;
    });
  }

  Future<void> _nextQuestion() async {
    setState(() {
      _loading = true;
      _selectedAnswer = null;
      _answered = false;
    });

    try {
      _QuizQuestion q;
      switch (_activeMode!) {
        case QuizMode.whoseThat:
          q = await _generateWhoseThat();
        case QuizMode.typeMatchup:
          q = _generateTypeMatchup();
        case QuizMode.statShowdown:
          q = await _generateStatShowdown();
      }
      if (mounted) setState(() { _question = q; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  void _submitAnswer(int index) {
    if (_answered) return;
    final correct = index == _question!.correctIndex;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (correct) {
        _streak++;
        if (_streak > _bestStreak) _bestStreak = _streak;
      } else {
        _streak = 0;
      }
    });
  }

  // --- Question generators ---

  Future<_QuizQuestion> _generateWhoseThat() async {
    final pool = _allPokemon ?? await PokeApiService.getAllPokemonBasic();
    final picks = <PokemonBasic>[];
    final used = <int>{};
    while (picks.length < 4) {
      final p = pool[_random.nextInt(pool.length)];
      if (p.id > 1025 || used.contains(p.id)) continue;
      used.add(p.id);
      picks.add(p);
    }
    final correctIdx = _random.nextInt(4);
    final correct = picks[correctIdx];

    return _QuizQuestion(
      prompt: "Who's that Pokémon?",
      imageUrl: correct.imageUrl,
      imageId: correct.id,
      options: picks.map((p) => p.displayName).toList(),
      correctIndex: correctIdx,
      explanation: '${correct.displayName} (#${correct.id})',
    );
  }

  _QuizQuestion _generateTypeMatchup() {
    final types = TypeChart.types;

    // Pick a random defending type
    final defType = types[_random.nextInt(types.length)];
    final defIdx = types.indexOf(defType);

    // Find all super-effective attackers
    final superEffective = <String>[];
    for (int i = 0; i < types.length; i++) {
      if (TypeChart.effectiveness[i][defIdx] >= 2) {
        superEffective.add(types[i]);
      }
    }

    // If nothing is super effective, retry with different type
    if (superEffective.isEmpty) return _generateTypeMatchup();

    final correctType = superEffective[_random.nextInt(superEffective.length)];

    // Build wrong answers from types that are NOT super effective
    final wrongPool = types.where((t) {
      final ai = types.indexOf(t);
      return TypeChart.effectiveness[ai][defIdx] < 2 && t != correctType;
    }).toList()..shuffle(_random);

    final options = <String>[correctType];
    for (final w in wrongPool) {
      if (options.length >= 4) break;
      options.add(w);
    }
    while (options.length < 4) {
      options.add(types[_random.nextInt(types.length)]);
    }

    final correctIdx = _random.nextInt(options.length);
    final saved = options[correctIdx];
    options[correctIdx] = options[0];
    options[0] = saved;

    return _QuizQuestion(
      prompt: 'Which type is super effective against ${_capitalize(defType)}?',
      options: options.map(_capitalize).toList(),
      correctIndex: correctIdx,
      explanation: '${_capitalize(correctType)} → ${_capitalize(defType)} = 2×',
      typeColors: options.map((t) => TypeColors.getColor(t.toLowerCase())).toList(),
    );
  }

  Future<_QuizQuestion> _generateStatShowdown() async {
    final pool = _allPokemon ?? await PokeApiService.getAllPokemonBasic();

    // Pick two pokemon
    PokemonBasic a, b;
    do {
      a = pool[_random.nextInt(pool.length)];
      b = pool[_random.nextInt(pool.length)];
    } while (a.id == b.id || a.id > 1025 || b.id > 1025);

    final detailA = await PokeApiService.getPokemonDetail(a.id);
    final detailB = await PokeApiService.getPokemonDetail(b.id);

    // Pick a stat
    final statNames = ['hp', 'attack', 'defense', 'special-attack', 'special-defense', 'speed'];
    final statLabels = ['HP', 'Attack', 'Defense', 'Sp. Atk', 'Sp. Def', 'Speed'];
    final si = _random.nextInt(statNames.length);
    final statKey = statNames[si];
    final statLabel = statLabels[si];

    final valA = detailA.stats[statKey] ?? 0;
    final valB = detailB.stats[statKey] ?? 0;

    // If equal, retry
    if (valA == valB) return _generateStatShowdown();

    final correctIdx = valA > valB ? 0 : 1;

    return _QuizQuestion(
      prompt: 'Which has higher base $statLabel?',
      options: [detailA.displayName, detailB.displayName],
      correctIndex: correctIdx,
      explanation: '${detailA.displayName}: $valA  vs  ${detailB.displayName}: $valB',
      pokemonIds: [detailA.id, detailB.id],
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    if (_activeMode == null) return _buildModeSelect(context);
    return _buildQuiz(context);
  }

  Widget _buildModeSelect(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quiz',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 28,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Test your knowledge — how long can you keep the streak?',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          if (_bestStreak > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department_rounded, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Best streak: $_bestStreak',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          _ModeCard(
            icon: Icons.catching_pokemon,
            title: "Who's That Pokémon?",
            subtitle: 'Identify Pokémon from their artwork',
            color: const Color(0xFFEE8130),
            isDark: isDark,
            onTap: () => _startMode(QuizMode.whoseThat),
          ),
          const SizedBox(height: 12),
          _ModeCard(
            icon: Icons.bolt_rounded,
            title: 'Type Matchup',
            subtitle: 'Pick the super effective type',
            color: const Color(0xFFF7D02C),
            isDark: isDark,
            onTap: () => _startMode(QuizMode.typeMatchup),
          ),
          const SizedBox(height: 12),
          _ModeCard(
            icon: Icons.bar_chart_rounded,
            title: 'Stat Showdown',
            subtitle: 'Which Pokémon has the higher stat?',
            color: const Color(0xFF6390F0),
            isDark: isDark,
            onTap: () => _startMode(QuizMode.statShowdown),
          ),
        ],
      ),
    );
  }

  Widget _buildQuiz(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Top bar with back, mode name, streak
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _backToMenu,
              ),
              const SizedBox(width: 4),
              Text(
                _modeName(_activeMode!),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _streak > 0
                      ? Colors.orange.withOpacity(isDark ? 0.2 : 0.1)
                      : colorScheme.onSurface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 16,
                      color: _streak > 0 ? Colors.orange : colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_streak',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: _streak > 0 ? Colors.orange : colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Question content
        Expanded(
          child: _loading || _question == null
              ? const Center(child: CircularProgressIndicator())
              : _buildQuestion(theme, colorScheme, isDark),
        ),
      ],
    );
  }

  Widget _buildQuestion(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    final q = _question!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        children: [
          // Image (for Who's That Pokemon)
          if (q.imageUrl != null) ...[
            Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(isDark ? 0.08 : 0.04),
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: ColorFiltered(
                  colorFilter: _answered
                      ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                      : const ColorFilter.matrix([
                          0, 0, 0, 0, 0.15,
                          0, 0, 0, 0, 0.15,
                          0, 0, 0, 0, 0.2,
                          0, 0, 0, 1, 0,
                        ]),
                  child: PokemonImage(
                          imageUrl: q.imageUrl!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                          fallbackIconSize: 80,
                          fallbackIconColor: colorScheme.onSurface.withOpacity(0.2),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Pokemon sprites for stat showdown
          if (q.pokemonIds != null && q.pokemonIds!.length == 2) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pokemonSprite(q.pokemonIds![0], colorScheme, isDark),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                ),
                _pokemonSprite(q.pokemonIds![1], colorScheme, isDark),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Prompt
          Text(
            q.prompt,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Options
          ...List.generate(q.options.length, (i) {
            final isCorrect = i == q.correctIndex;
            final isSelected = i == _selectedAnswer;
            Color? bgColor;
            Color? borderColor;

            if (_answered) {
              if (isCorrect) {
                bgColor = Colors.green.withOpacity(isDark ? 0.2 : 0.1);
                borderColor = Colors.green;
              } else if (isSelected) {
                bgColor = Colors.red.withOpacity(isDark ? 0.2 : 0.1);
                borderColor = Colors.red;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _answered ? null : () => _submitAnswer(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: bgColor ?? (q.typeColors != null
                          ? q.typeColors![i].withOpacity(isDark ? 0.12 : 0.08)
                          : colorScheme.onSurface.withOpacity(isDark ? 0.06 : 0.04)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: borderColor ?? (q.typeColors != null
                            ? q.typeColors![i].withOpacity(0.3)
                            : colorScheme.onSurface.withOpacity(0.1)),
                        width: (isSelected || (isCorrect && _answered)) ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (q.typeColors != null) ...[
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: q.typeColors![i],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            q.options[i],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: borderColor ?? colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (_answered && isCorrect)
                          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
                        if (_answered && isSelected && !isCorrect)
                          const Icon(Icons.cancel_rounded, color: Colors.red, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          // Explanation + next button
          if (_answered) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(isDark ? 0.06 : 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                q.explanation,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _nextQuestion,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(_selectedAnswer == _question!.correctIndex ? 'Next' : 'Try Again'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pokemonSprite(int id, ColorScheme colorScheme, bool isDark) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(isDark ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: PokemonImage.artwork(id,
              width: 100,
              height: 100,
              fallbackIconSize: 48,
            ),
    );
  }

  String _modeName(QuizMode mode) => switch (mode) {
    QuizMode.whoseThat => "Who's That Pokémon?",
    QuizMode.typeMatchup => 'Type Matchup',
    QuizMode.statShowdown => 'Stat Showdown',
  };
}

// --- Data classes ---

class _QuizQuestion {
  final String prompt;
  final String? imageUrl;
  final int? imageId;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final List<Color>? typeColors;
  final List<int>? pokemonIds;

  _QuizQuestion({
    required this.prompt,
    this.imageUrl,
    this.imageId,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.typeColors,
    this.pokemonIds,
  });
}

// --- Mode card widget ---

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.12 : 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
