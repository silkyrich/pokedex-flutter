import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/app_state.dart';

/// Tools hub — gateway to Nuzlocke, Shiny Hunter, Speed Tiers,
/// Damage Calc, Stat Calc, Counter Lookup, and Favorites.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 800;
    final crossAxisCount = isWide ? 3 : 2;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tools', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('Competitive tools, trackers, and calculators.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                const SizedBox(height: 24),
                // Competitive section
                _SectionLabel(label: 'Competitive', theme: theme),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: isWide ? 2.0 : 1.6,
                  children: [
                    _ToolCard(
                      icon: Icons.calculate_rounded,
                      title: 'Damage Calculator',
                      subtitle: 'Showdown-style damage calc with EVs, IVs, natures',
                      color: const Color(0xFFEF4444),
                      onTap: () => context.go('/tools/damage-calc'),
                      isDark: isDark,
                    ),
                    _ToolCard(
                      icon: Icons.bar_chart_rounded,
                      title: 'Stat Calculator',
                      subtitle: 'Calculate stats with EVs, IVs, natures at any level',
                      color: const Color(0xFF3B82F6),
                      onTap: () => context.go('/tools/stat-calc'),
                      isDark: isDark,
                    ),
                    _ToolCard(
                      icon: Icons.speed_rounded,
                      title: 'Speed Tiers',
                      subtitle: 'Compare speed stats — who outspeeds whom?',
                      color: const Color(0xFF8B5CF6),
                      onTap: () => context.go('/tools/speed-tiers'),
                      isDark: isDark,
                    ),
                    _ToolCard(
                      icon: Icons.bolt_rounded,
                      title: 'What Beats This?',
                      subtitle: 'Instant counter lookup for any Pokemon',
                      color: const Color(0xFFF59E0B),
                      onTap: () => context.go('/tools/counter'),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                // Trackers section
                _SectionLabel(label: 'Trackers', theme: theme),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: isWide ? 2.0 : 1.6,
                  children: [
                    _ToolCard(
                      icon: Icons.dangerous_outlined,
                      title: 'Nuzlocke Tracker',
                      subtitle: 'Route encounters, death log, rules enforcement',
                      color: const Color(0xFFDC2626),
                      onTap: () => context.go('/tools/nuzlocke'),
                      isDark: isDark,
                    ),
                    _ToolCard(
                      icon: Icons.auto_awesome,
                      title: 'Shiny Hunter',
                      subtitle: 'Odds calculator, live counter, streak tracking',
                      color: const Color(0xFFFFD700),
                      onTap: () => context.go('/tools/shiny'),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                // Quick links
                _SectionLabel(label: 'Quick Links', theme: theme),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: isWide ? 2.0 : 1.6,
                  children: [
                    _ToolCard(
                      icon: Icons.favorite,
                      title: 'Favorites',
                      subtitle: '${AppState().favorites.length} saved Pokemon',
                      color: Colors.red,
                      onTap: () => context.go('/favorites'),
                      isDark: isDark,
                    ),
                    _ToolCard(
                      icon: Icons.compare_arrows,
                      title: 'Battle Simulator',
                      subtitle: 'Head-to-head Pokemon comparison',
                      color: theme.colorScheme.primary,
                      onTap: () => context.go('/battle'),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final ThemeData theme;
  const _SectionLabel({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: theme.colorScheme.onSurface.withOpacity(0.5),
        letterSpacing: 1,
      ),
    );
  }
}

class _ToolCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _ToolCard({
    required this.icon, required this.title, required this.subtitle,
    required this.color, required this.onTap, required this.isDark,
  });

  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withOpacity(widget.isDark ? 0.12 : 0.06)
                : widget.isDark ? Colors.white.withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? widget.color.withOpacity(0.3)
                  : widget.isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
            ),
            boxShadow: _hovered ? [
              BoxShadow(color: widget.color.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 4)),
            ] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(widget.isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: _hovered ? widget.color : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
