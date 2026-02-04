import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/app_state.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    final appState = AppState();

    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      elevation: 2,
      title: GestureDetector(
        onTap: () => context.go('/'),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.catching_pokemon, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              Text(
                isWide ? 'Pokémon Database' : 'PokémonDB',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (isWide) ...[
          _NavButton(label: 'Pokédex', onTap: () => context.go('/')),
          _NavButton(label: 'Moves', onTap: () => context.go('/moves')),
          _NavButton(label: 'Types', onTap: () => context.go('/types')),
          _NavButton(label: 'Team', onTap: () => context.go('/team')),
        ],
        IconButton(
          icon: const Icon(Icons.favorite, color: Colors.white, size: 20),
          tooltip: 'Favorites',
          onPressed: () => context.go('/favorites'),
        ),
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          tooltip: 'Search',
          onPressed: () => context.go('/search'),
        ),
        // Dark mode toggle
        ListenableBuilder(
          listenable: appState,
          builder: (context, _) => IconButton(
            icon: Icon(
              appState.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
              size: 20,
            ),
            tooltip: appState.themeMode == ThemeMode.dark ? 'Light mode' : 'Dark mode',
            onPressed: () => appState.toggleTheme(),
          ),
        ),
        if (!isWide)
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.white),
            onSelected: (route) => context.go(route),
            itemBuilder: (_) => const [
              PopupMenuItem(value: '/', child: Text('Pokédex')),
              PopupMenuItem(value: '/moves', child: Text('Moves')),
              PopupMenuItem(value: '/types', child: Text('Type Chart')),
              PopupMenuItem(value: '/team', child: Text('My Team')),
              PopupMenuItem(value: '/favorites', child: Text('Favorites')),
            ],
          ),
      ],
    );
  }
}

class _NavButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _NavButton({required this.label, required this.onTap});

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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: _hovered ? Colors.white.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
