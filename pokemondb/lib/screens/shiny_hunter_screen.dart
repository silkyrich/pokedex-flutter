import 'package:flutter/material.dart';
import 'dart:math';

/// Shiny hunting toolkit with odds calculators, counters, and streak tracking.
class ShinyHunterScreen extends StatefulWidget {
  const ShinyHunterScreen({super.key});

  @override
  State<ShinyHunterScreen> createState() => _ShinyHunterScreenState();
}

class _ShinyHunterScreenState extends State<ShinyHunterScreen> {
  // Counter
  int _encounters = 0;
  bool _counting = false;

  // Method
  String _method = 'full_odds';
  int _chainLength = 0;
  bool _hasShinyCharm = false;

  // Calculated odds
  double get _currentOdds {
    final base = _hasShinyCharm ? 1 / 1365.33 : 1 / 4096.0;
    switch (_method) {
      case 'masuda':
        return _hasShinyCharm ? 1 / 512.0 : 1 / 682.67;
      case 'chain_fishing':
        final bonus = min(_chainLength, 20) * (1 / 4096.0);
        return base + bonus;
      case 'sos_chain':
        if (_chainLength >= 31) return _hasShinyCharm ? 1 / 273.07 : 1 / 315.08;
        if (_chainLength >= 21) return _hasShinyCharm ? 1 / 455.11 : 1 / 585.57;
        if (_chainLength >= 11) return _hasShinyCharm ? 1 / 682.67 : 1 / 1024.0;
        return base;
      case 'dexnav':
        final searchLevel = min(_chainLength, 999);
        final bonus = (searchLevel * 0.01) / 100; // simplified
        return base + bonus;
      case 'radar_chain':
        if (_chainLength >= 40) return _hasShinyCharm ? 1 / 99.0 : 1 / 100.0;
        if (_chainLength >= 30) return base * 5;
        if (_chainLength >= 20) return base * 3;
        return base;
      case 'mass_outbreak':
        return _hasShinyCharm ? 1 / 512.44 : 1 / 1024.38;
      case 'massive_mass':
        return _hasShinyCharm ? 1 / 373.11 : 1 / 585.57;
      default: // full_odds
        return base;
    }
  }

  double get _cumulativeProbability {
    if (_encounters == 0) return 0;
    return 1 - pow(1 - _currentOdds, _encounters).toDouble();
  }

  static const Map<String, String> _methodNames = {
    'full_odds': 'Full Odds',
    'masuda': 'Masuda Method',
    'chain_fishing': 'Chain Fishing',
    'sos_chain': 'SOS Chaining',
    'dexnav': 'DexNav',
    'radar_chain': 'Poke Radar',
    'mass_outbreak': 'Mass Outbreak',
    'massive_mass': 'Massive Mass Outbreak',
  };

  static const Map<String, String> _methodDescriptions = {
    'full_odds': 'Base rate random encounters. 1/4096 in Gen VI+.',
    'masuda': 'Breed two Pokemon from different-language games.',
    'chain_fishing': 'Fish consecutively without moving. Gen VI only.',
    'sos_chain': 'Chain SOS calls in Gen VII (Sun/Moon/USUM).',
    'dexnav': 'DexNav chaining in ORAS. Higher search level = better odds.',
    'radar_chain': 'Poke Radar chains in Gen IV / BDSP. Chain 40 = max odds.',
    'mass_outbreak': 'Legends Arceus / Scarlet-Violet mass outbreaks.',
    'massive_mass': 'Massive mass outbreaks in Legends Arceus.',
  };

  static const Map<String, IconData> _methodIcons = {
    'full_odds': Icons.casino_outlined,
    'masuda': Icons.egg_outlined,
    'chain_fishing': Icons.phishing_outlined,
    'sos_chain': Icons.record_voice_over_outlined,
    'dexnav': Icons.radar_outlined,
    'radar_chain': Icons.track_changes_outlined,
    'mass_outbreak': Icons.groups_outlined,
    'massive_mass': Icons.groups_3_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shiny Hunter', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('Track your shiny hunts with odds calculators for every method.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                const SizedBox(height: 24),
                // Counter
                _buildCounter(theme, isDark),
                const SizedBox(height: 20),
                // Method selector
                _buildMethodSelector(theme, isDark),
                const SizedBox(height: 20),
                // Odds display
                _buildOddsDisplay(theme, isDark),
                const SizedBox(height: 20),
                // Options
                _buildOptions(theme, isDark),
                const SizedBox(height: 20),
                // Probability chart
                _buildProbabilityChart(theme, isDark),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCounter(ThemeData theme, bool isDark) {
    final shinyGold = const Color(0xFFFFD700);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Main counter display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    shinyGold.withOpacity(isDark ? 0.08 : 0.04),
                    Colors.purple.withOpacity(isDark ? 0.08 : 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: shinyGold.withOpacity(0.15)),
              ),
              child: Column(
                children: [
                  Text(
                    '$_encounters',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 64,
                      color: shinyGold,
                      letterSpacing: -2,
                      shadows: [Shadow(color: shinyGold.withOpacity(0.3), blurRadius: 20)],
                    ),
                  ),
                  Text(
                    'Encounters',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_cumulativeProbability * 100).toStringAsFixed(1)}% chance found by now',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Counter buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CounterButton(
                  icon: Icons.remove_rounded,
                  onTap: () { if (_encounters > 0) setState(() => _encounters--); },
                  color: theme.colorScheme.error,
                  isDark: isDark,
                ),
                const SizedBox(width: 16),
                // Big tap button
                GestureDetector(
                  onTap: () => setState(() => _encounters++),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [shinyGold, shinyGold.withOpacity(0.7)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: shinyGold.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.add_rounded, size: 36, color: Colors.black87),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _CounterButton(
                  icon: Icons.refresh_rounded,
                  onTap: () => setState(() { _encounters = 0; _chainLength = 0; }),
                  color: theme.colorScheme.primary,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Tap the gold button for each encounter',
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.4))),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodSelector(ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science_outlined, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text('Hunting Method', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _methodNames.entries.map((e) {
                final isSelected = _method == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _method = e.key),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1)
                            : isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _methodIcons[e.key] ?? Icons.help_outline,
                            size: 16,
                            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                          const SizedBox(width: 8),
                          Text(e.value, style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.7),
                          )),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              _methodDescriptions[_method] ?? '',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOddsDisplay(ThemeData theme, bool isDark) {
    final oddsStr = '1 / ${(1 / _currentOdds).toStringAsFixed(0)}';
    final pctStr = '${(_currentOdds * 100).toStringAsFixed(4)}%';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: const Color(0xFFFFD700), size: 22),
                const SizedBox(width: 8),
                Text('Current Odds', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        const Color(0xFFFFD700).withOpacity(isDark ? 0.1 : 0.06),
                        Colors.purple.withOpacity(isDark ? 0.1 : 0.06),
                      ]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text('Per Encounter', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                        const SizedBox(height: 4),
                        Text(oddsStr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFFFFD700))),
                        Text(pctStr, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(isDark ? 0.1 : 0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text('Cumulative', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                        const SizedBox(height: 4),
                        Text(
                          '${(_cumulativeProbability * 100).toStringAsFixed(1)}%',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: theme.colorScheme.primary),
                        ),
                        Text('after $_encounters', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions(ThemeData theme, bool isDark) {
    final needsChain = _method == 'chain_fishing' || _method == 'sos_chain' ||
        _method == 'dexnav' || _method == 'radar_chain';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Options', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            // Shiny Charm
            Row(
              children: [
                SizedBox(
                  width: 20, height: 20,
                  child: Checkbox(
                    value: _hasShinyCharm,
                    onChanged: (v) => setState(() => _hasShinyCharm = v ?? false),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.auto_awesome, size: 16, color: const Color(0xFFFFD700)),
                const SizedBox(width: 6),
                Text('Shiny Charm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.7))),
                const SizedBox(width: 8),
                Text('+2 extra rolls', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.4))),
              ],
            ),
            if (needsChain) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Chain Length:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: TextEditingController(text: '$_chainLength'),
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                      onChanged: (v) {
                        final n = int.tryParse(v);
                        if (n != null && n >= 0) setState(() => _chainLength = n);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        activeTrackColor: const Color(0xFFFFD700),
                        inactiveTrackColor: const Color(0xFFFFD700).withOpacity(0.15),
                        thumbColor: const Color(0xFFFFD700),
                      ),
                      child: Slider(
                        value: _chainLength.toDouble().clamp(0, 100),
                        min: 0, max: 100,
                        onChanged: (v) => setState(() => _chainLength = v.round()),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProbabilityChart(ThemeData theme, bool isDark) {
    // Show milestones
    final milestones = <int>[100, 500, 1000, 2000, 4096, 8192];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Probability Milestones', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Chance of finding at least one shiny by N encounters',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4))),
            const SizedBox(height: 16),
            ...milestones.map((n) {
              final prob = 1 - pow(1 - _currentOdds, n).toDouble();
              final pct = (prob * 100).clamp(0, 100);
              final isOver = _encounters >= n;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        '$n',
                        style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13,
                          color: isOver ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 10,
                          child: Stack(
                            children: [
                              Container(color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade100),
                              FractionallySizedBox(
                                widthFactor: pct / 100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      const Color(0xFFFFD700),
                                      const Color(0xFFFFD700).withOpacity(0.7),
                                    ]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 56,
                      child: Text(
                        '${pct.toStringAsFixed(1)}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFFFFD700)),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool isDark;
  const _CounterButton({required this.icon, required this.onTap, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.15 : 0.08),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Center(child: Icon(icon, color: color, size: 22)),
        ),
      ),
    );
  }
}
