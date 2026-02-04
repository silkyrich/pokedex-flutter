import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/app_state.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    final appState = AppState();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
              : [const Color(0xFF3B5BA7), const Color(0xFF2A4480)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Logo + title
              GestureDetector(
                onTap: () => context.go('/'),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.catching_pokemon,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isWide ? 'Pokémon Database' : 'PokémonDB',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (isWide) ...[
                _NavButton(label: 'Pokédex', icon: Icons.grid_view_rounded, onTap: () => context.go('/')),
                _NavButton(label: 'Moves', icon: Icons.flash_on_rounded, onTap: () => context.go('/moves')),
                _NavButton(label: 'Types', icon: Icons.shield_rounded, onTap: () => context.go('/types')),
                _NavButton(label: 'Team', icon: Icons.groups_rounded, onTap: () => context.go('/team')),
                const SizedBox(width: 4),
                Container(width: 1, height: 28, color: Colors.white24),
                const SizedBox(width: 4),
              ],
              _HeaderIcon(
                icon: Icons.favorite_rounded,
                tooltip: 'Favorites',
                onTap: () => context.go('/favorites'),
              ),
              _HeaderIcon(
                icon: Icons.search_rounded,
                tooltip: 'Search',
                onTap: () => context.go('/search'),
              ),
              // Dark mode toggle
              ListenableBuilder(
                listenable: appState,
                builder: (context, _) => _HeaderIcon(
                  icon: appState.themeMode == ThemeMode.dark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  tooltip: appState.themeMode == ThemeMode.dark
                      ? 'Light mode'
                      : 'Dark mode',
                  onTap: () => appState.toggleTheme(),
                ),
              ),
              if (!isWide)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                  onSelected: (route) => context.go(route),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: '/', child: Text('Pokédex')),
                    PopupMenuItem(value: '/moves', child: Text('Moves')),
                    PopupMenuItem(value: '/types', child: Text('Type Chart')),
                    PopupMenuItem(value: '/team', child: Text('My Team')),
                    PopupMenuItem(
                        value: '/favorites', child: Text('Favorites')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIcon(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  State<_HeaderIcon> createState() => _HeaderIconState();
}

class _HeaderIconState extends State<_HeaderIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color:
                  _hovered ? Colors.white.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color:
                _hovered ? Colors.white.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
