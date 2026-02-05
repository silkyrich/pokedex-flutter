import 'package:flutter/material.dart';

class StatsGuideScreen extends StatelessWidget {
  const StatsGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'The Maths of Pokémon',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Statistics, probability, and hidden numbers',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _para(colorScheme,
                  'Every Pokémon battle is a maths problem in disguise. When you play Pokémon, '
                  'you\'re already doing statistics, probability, and algebra — you just might not '
                  'realise it yet. Let\'s break down the numbers behind the game.'
                ),

                const SizedBox(height: 32),

                // Base Stats
                _SectionCard(
                  title: 'Base Stats — Every Pokémon\'s DNA',
                  icon: Icons.analytics_outlined,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _para(colorScheme,
                        'Every Pokémon has six base stats that define its strengths and weaknesses. '
                        'These are fixed numbers — every Charizard has the same base stats.'
                      ),
                      const SizedBox(height: 16),
                      _statExample(colorScheme, 'HP', 78, 255, 'How much damage it can take'),
                      _statExample(colorScheme, 'Attack', 84, 255, 'Physical move power'),
                      _statExample(colorScheme, 'Defense', 78, 255, 'Resistance to physical moves'),
                      _statExample(colorScheme, 'Sp. Atk', 109, 255, 'Special move power'),
                      _statExample(colorScheme, 'Sp. Def', 85, 255, 'Resistance to special moves'),
                      _statExample(colorScheme, 'Speed', 100, 255, 'Who attacks first'),
                      const SizedBox(height: 12),
                      _para(colorScheme,
                        'Charizard\'s Sp. Atk (109) is much higher than its Attack (84). '
                        'This tells you it\'s better at special moves like Flamethrower '
                        'than physical moves like Slash. Choosing the right moves for your '
                        'Pokémon\'s stats is basic optimisation — a key concept in maths '
                        'and computer science.'
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // BST — Base Stat Total
                _SectionCard(
                  title: 'BST — Comparing with Totals',
                  icon: Icons.functions_rounded,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _para(colorScheme,
                        'Add up all six base stats and you get the Base Stat Total (BST). '
                        'This is a quick way to compare how strong two Pokémon are overall.'
                      ),
                      const SizedBox(height: 12),
                      _bstComparison(colorScheme, isDark),
                      const SizedBox(height: 12),
                      _para(colorScheme,
                        'In statistics, this is called an aggregate measure — combining '
                        'multiple values into a single number for easier comparison. '
                        'It\'s the same idea as a football team\'s total goals across a season, '
                        'or your total marks across all subjects.'
                      ),
                      const SizedBox(height: 8),
                      _para(colorScheme,
                        'But BST doesn\'t tell the whole story. Shuckle has a BST of 505, '
                        'split almost entirely into Defence and Sp. Def. It\'s a wall, not a fighter. '
                        'Distribution matters as much as the total — another key statistical insight.'
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Type effectiveness — Multiplication
                _SectionCard(
                  title: 'Type Matchups — Multiplication in Action',
                  icon: Icons.grid_view_rounded,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _para(colorScheme,
                        'When a Fire move hits a Grass Pokémon, damage is multiplied by 2. '
                        'When it hits a Water Pokémon, damage is multiplied by 0.5. This is '
                        'multiplication used as a game mechanic.'
                      ),
                      const SizedBox(height: 12),
                      _codeBlock(isDark, colorScheme,
                        'Fire vs Grass     = 1 × 2.0  = 2x  (super effective)\n'
                        'Fire vs Water     = 1 × 0.5  = 0.5x (not very effective)\n'
                        'Fire vs Rock      = 1 × 0.5  = 0.5x\n'
                        'Fire vs Fire      = 1 × 0.5  = 0.5x\n'
                        'Fire vs Bug/Grass = 2 × 2.0  = 4x!  (double super effective)'
                      ),
                      const SizedBox(height: 12),
                      _para(colorScheme,
                        'Dual-type Pokémon are where it gets interesting. Against a Bug/Grass '
                        'Pokémon, Fire does 2× for each type, and the multipliers are multiplied '
                        'together: 2 × 2 = 4× damage. Against Water/Ground, Fire does '
                        '0.5 × 2 = 1× — they cancel out!'
                      ),
                      const SizedBox(height: 8),
                      _para(colorScheme,
                        'This is exactly how compound percentages work in the real world. '
                        'A 10% increase followed by a 10% decrease doesn\'t get you back to '
                        'where you started — just like type matchups don\'t always cancel evenly.'
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // The Damage Formula
                _SectionCard(
                  title: 'The Damage Formula — Algebra You Already Use',
                  icon: Icons.calculate_outlined,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _para(colorScheme,
                        'Every time a Pokémon attacks, the game runs this formula:'
                      ),
                      const SizedBox(height: 12),
                      _codeBlock(isDark, colorScheme,
                        'Damage = ((2 × Level / 5 + 2) × Power × A / D) / 50 + 2\n'
                        '       × STAB      (×1.5 if move type matches Pokémon type)\n'
                        '       × Type      (×0.25 to ×4, from the type chart)\n'
                        '       × Random    (×0.85 to ×1.0, a random roll)'
                      ),
                      const SizedBox(height: 12),
                      _para(colorScheme,
                        'This single formula contains:\n'
                        '  • Variables (Level, Power, Attack, Defence)\n'
                        '  • Order of operations (brackets first)\n'
                        '  • Multiplication and division\n'
                        '  • Randomness (probability)\n\n'
                        'If you can understand why Flamethrower sometimes does 91 damage '
                        'and sometimes does 105, you understand variables and random distributions. '
                        'That\'s GCSE-level maths, learned from playing a game.'
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // STAB
                _SectionCard(
                  title: 'STAB — Percentages and Bonuses',
                  icon: Icons.flash_on_rounded,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _para(colorScheme,
                        'STAB stands for Same Type Attack Bonus. When a Fire-type Pokémon '
                        'uses a Fire-type move, the damage is multiplied by 1.5. That\'s a '
                        '50% bonus — the same concept as adding VAT, calculating tips, or '
                        'understanding sale discounts.'
                      ),
                      const SizedBox(height: 12),
                      _codeBlock(isDark, colorScheme,
                        'Charizard using Flamethrower (Fire move):\n'
                        '  Base damage: 90\n'
                        '  With STAB:   90 × 1.5 = 135 effective power\n\n'
                        'Charizard using Earthquake (Ground move):\n'
                        '  Base damage: 100\n'
                        '  No STAB:     100 × 1.0 = 100 effective power\n\n'
                        'Flamethrower (90) hits HARDER than Earthquake (100)\n'
                        'because of the 50% STAB bonus!'
                      ),
                      const SizedBox(height: 12),
                      _para(colorScheme,
                        'This is why Pokémon teams are built around type synergy. '
                        'The best competitive players are doing percentage calculations '
                        'in their heads constantly — working out which move does the most '
                        'damage after all the multipliers stack up.'
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Speed and probability
                _SectionCard(
                  title: 'Speed Ties & Probability',
                  icon: Icons.speed_rounded,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _para(colorScheme,
                        'The fastest Pokémon attacks first. But when two Pokémon have exactly '
                        'the same Speed stat, it\'s a 50/50 coin flip. This is pure probability.'
                      ),
                      const SizedBox(height: 12),
                      _para(colorScheme,
                        'Competitive players think about this constantly:\n\n'
                        '  • "My Pokémon has 300 Speed. The opponent\'s is 298. I\'m guaranteed to go first."\n'
                        '  • "If I invest in Speed EVs, I outspeed 73% of the meta."\n'
                        '  • "There\'s a 10% chance this move misses. Is it worth the risk?"'
                      ),
                      const SizedBox(height: 12),
                      _para(colorScheme,
                        'Move accuracy is another probability exercise. Hydro Pump has '
                        '80% accuracy — that means a 20% miss chance. Over five turns, '
                        'the probability of missing at least once is '
                        '1 - 0.8\u2075 = 67%. More than half the time, you\'ll miss. '
                        'Understanding these odds is what separates good players from great ones.'
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // EVs and IVs
                _SectionCard(
                  title: 'EVs & IVs — Hidden Distributions',
                  icon: Icons.tune_rounded,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _para(colorScheme,
                        'Every Pokémon has hidden numbers that make each individual unique:'
                      ),
                      const SizedBox(height: 12),
                      _conceptRow(colorScheme, 'IVs (Individual Values)',
                        'Random numbers from 0–31, assigned when you catch or hatch a Pokémon. '
                        'Like genetics — each Pokémon is born with slightly different potential. '
                        'This is a uniform random distribution.'),
                      const SizedBox(height: 16),
                      _conceptRow(colorScheme, 'EVs (Effort Values)',
                        'Points earned from battling. You get 510 total to distribute across stats, '
                        'max 252 per stat. This is resource allocation — a classic optimisation problem. '
                        'Where do you invest your limited budget for maximum return?'),
                      const SizedBox(height: 16),
                      _codeBlock(isDark, colorScheme,
                        'Final Stat at Level 50:\n'
                        '= ((2 × Base + IV + EV/4) × 50/100 + 5) × Nature\n\n'
                        'Two Charizards with different IVs and EVs:\n'
                        '  Charizard A: Sp.Atk IV=31, EV=252 → Sp.Atk = 161\n'
                        '  Charizard B: Sp.Atk IV=0,  EV=0   → Sp.Atk = 121\n\n'
                        'Same species, 33% difference in power!'
                      ),
                      const SizedBox(height: 12),
                      _para(colorScheme,
                        'IVs follow a uniform distribution (each value 0–31 equally likely), '
                        'while competitive players optimise EV spreads — essentially solving '
                        'a constrained optimisation problem with a budget of 510 points.'
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Real-world connections
                _SectionCard(
                  title: 'Real-World Connections',
                  icon: Icons.public_rounded,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _para(colorScheme,
                        'The maths concepts in Pokémon show up everywhere in real life:'
                      ),
                      const SizedBox(height: 12),
                      _connectionRow(colorScheme,
                        'Type multipliers', 'Compound interest, exchange rates, tax calculations'),
                      const Divider(height: 20),
                      _connectionRow(colorScheme,
                        'Base stats & BST', 'Averages, aggregates, comparing data sets'),
                      const Divider(height: 20),
                      _connectionRow(colorScheme,
                        'EV allocation', 'Budgeting, resource management, optimisation'),
                      const Divider(height: 20),
                      _connectionRow(colorScheme,
                        'IV distributions', 'Probability, randomness, genetics'),
                      const Divider(height: 20),
                      _connectionRow(colorScheme,
                        'Move accuracy', 'Risk assessment, expected value'),
                      const Divider(height: 20),
                      _connectionRow(colorScheme,
                        'Damage formula', 'Algebra, variables, order of operations'),
                      const Divider(height: 20),
                      _connectionRow(colorScheme,
                        'Team building', 'Portfolio theory, diversification'),
                      const SizedBox(height: 16),
                      _para(colorScheme,
                        'Next time someone says maths isn\'t useful, remind them: '
                        'you\'ve been solving optimisation problems and calculating '
                        'conditional probabilities since you were ten. '
                        'You just called it "playing Pokémon."'
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _para(ColorScheme colorScheme, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        height: 1.6,
        color: colorScheme.onSurface.withOpacity(0.7),
      ),
    );
  }

  static Widget _codeBlock(bool isDark, ColorScheme colorScheme, String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.grey.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontSize: 12,
          height: 1.5,
          fontFamily: 'monospace',
          color: colorScheme.onSurface.withOpacity(0.8),
        ),
      ),
    );
  }

  static Widget _statExample(ColorScheme colorScheme, String name, int value, int max, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 55,
            child: Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: value / max,
                minHeight: 6,
                backgroundColor: colorScheme.onSurface.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation(
                  value >= 100 ? Colors.green : value >= 60 ? Colors.orange : Colors.red,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              desc,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _bstComparison(ColorScheme colorScheme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.grey.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _bstRow(colorScheme, 'Pichu', 205),
          const SizedBox(height: 6),
          _bstRow(colorScheme, 'Pikachu', 320),
          const SizedBox(height: 6),
          _bstRow(colorScheme, 'Raichu', 485),
          const SizedBox(height: 6),
          _bstRow(colorScheme, 'Charizard', 534),
          const SizedBox(height: 6),
          _bstRow(colorScheme, 'Mewtwo', 680),
        ],
      ),
    );
  }

  static Widget _bstRow(ColorScheme colorScheme, String name, int bst) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        SizedBox(
          width: 30,
          child: Text(
            '$bst',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: bst / 720,
              minHeight: 8,
              backgroundColor: colorScheme.onSurface.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _conceptRow(ColorScheme colorScheme, String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  static Widget _connectionRow(ColorScheme colorScheme, String pokemon, String realWorld) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.catching_pokemon, size: 14, color: colorScheme.primary.withOpacity(0.6)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$pokemon → ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                TextSpan(
                  text: realWorld,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final ColorScheme colorScheme;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.colorScheme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
