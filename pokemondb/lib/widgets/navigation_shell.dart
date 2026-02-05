import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/app_state.dart';
import '../utils/type_colors.dart';

class NavigationShell extends StatelessWidget {
  final Widget child;

  const NavigationShell({super.key, required this.child});

  // Bottom bar: 4 primary destinations
  static const _bottomItems = [
    _NavItem('/', 'Pokédex', Icons.catching_pokemon_outlined, Icons.catching_pokemon),
    _NavItem('/battle', 'Compare', Icons.compare_arrows_outlined, Icons.compare_arrows),
    _NavItem('/quiz', 'Quiz', Icons.quiz_outlined, Icons.quiz),
    _NavItem('/team', 'Team', Icons.groups_outlined, Icons.groups),
  ];

  // All destinations for drawer/sidebar, grouped
  static const _drawerSections = [
    _DrawerSection('Discover', [
      _NavItem('/', 'Pokédex', Icons.catching_pokemon_outlined, Icons.catching_pokemon),
      _NavItem('/pokedexes', 'Pokédexes', Icons.menu_book_outlined, Icons.menu_book),
      _NavItem('/moves', 'Moves', Icons.flash_on_outlined, Icons.flash_on),
      _NavItem('/items', 'Items', Icons.inventory_2_outlined, Icons.inventory_2),
      _NavItem('/locations', 'Locations', Icons.map_outlined, Icons.map),
      _NavItem('/types', 'Types', Icons.grid_view_outlined, Icons.grid_view_rounded),
      _NavItem('/favorites', 'Favorites', Icons.favorite_border, Icons.favorite),
    ]),
    _DrawerSection('Battle', [
      _NavItem('/battle', 'Head to Head', Icons.compare_arrows_outlined, Icons.compare_arrows),
      _NavItem('/team', 'Team Builder', Icons.groups_outlined, Icons.groups),
      _NavItem('/team/coverage', 'Team Coverage', Icons.grid_on_outlined, Icons.grid_on),
      _NavItem('/tools/damage-calc', 'Damage Calculator', Icons.local_fire_department_outlined, Icons.local_fire_department),
      _NavItem('/tools/stat-calc', 'Stat Calculator', Icons.bar_chart_outlined, Icons.bar_chart),
      _NavItem('/tools/speed-tiers', 'Speed Tiers', Icons.speed_outlined, Icons.speed),
      _NavItem('/tools/counter', 'Counter Lookup', Icons.shield_outlined, Icons.shield),
    ]),
    _DrawerSection('Track Progress', [
      _NavItem('/tools/nuzlocke', 'Nuzlocke Run', Icons.map_outlined, Icons.map),
      _NavItem('/tools/shiny', 'Shiny Hunter', Icons.auto_awesome_outlined, Icons.auto_awesome),
    ]),
    _DrawerSection('Play & Learn', [
      _NavItem('/quiz', 'Quiz', Icons.quiz_outlined, Icons.quiz),
      _NavItem('/learn', 'How This App Works', Icons.code_outlined, Icons.code_rounded),
      _NavItem('/stats-guide', 'The Maths of Pokémon', Icons.bar_chart_outlined, Icons.bar_chart_rounded),
      _NavItem('/official', 'Official Pokémon', Icons.videogame_asset_outlined, Icons.videogame_asset_rounded),
    ]),
  ];

  int _bottomIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _bottomItems.length; i++) {
      if (location == _bottomItems[i].path) return i;
      if (_bottomItems[i].path != '/' && location.startsWith(_bottomItems[i].path)) return i;
    }
    // If we're on a non-bottom-bar page, return -1 (no selection)
    if (location.startsWith('/moves') ||
        location.startsWith('/types') ||
        location.startsWith('/tools') ||
        location.startsWith('/favorites') ||
        location.startsWith('/search') ||
        location.startsWith('/pokemon')) {
      return -1;
    }
    return 0;
  }

  static String _currentPath(BuildContext context) {
    return GoRouterState.of(context).uri.toString();
  }

  @override
  Widget build(BuildContext context) {
    // Use desktop sidebar only on large screens (desktop/laptop)
    // iPads (1024-1366px) will use mobile drawer for maximum space
    final isDesktop = MediaQuery.of(context).size.width > 1200;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _DesktopSidebar(currentPath: _currentPath(context)),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    final bottomIndex = _bottomIndex(context);

    return Scaffold(
      appBar: _MobileAppBar(
        onSearch: () => context.go('/search'),
      ),
      drawer: _MobileDrawer(currentPath: _currentPath(context)),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: bottomIndex.clamp(0, _bottomItems.length - 1),
        onDestinationSelected: (i) => context.go(_bottomItems[i].path),
        height: 68,
        destinations: _bottomItems.map((item) => NavigationDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.activeIcon),
          label: item.label,
        )).toList(),
      ),
    );
  }
}

class _NavItem {
  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem(this.path, this.label, this.icon, this.activeIcon);
}

class _DrawerSection {
  final String title;
  final List<_NavItem> items;

  const _DrawerSection(this.title, this.items);
}

// --- Mobile Drawer ---

class _MobileDrawer extends StatelessWidget {
  final String currentPath;

  const _MobileDrawer({required this.currentPath});

  bool _isActive(String path) {
    if (path == '/') return currentPath == '/';
    return currentPath.startsWith(path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final appState = AppState();

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.catching_pokemon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DexGuide',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Creature Database',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Active Pokemon context
            ListenableBuilder(
              listenable: appState,
              builder: (context, _) {
                final active = appState.activePokemon;
                if (active == null) return const SizedBox.shrink();
                final primaryType = active.types.isNotEmpty ? active.types.first.name : 'normal';
                final typeColor = TypeColors.getColor(primaryType);
                return Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: typeColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Image.network(
                        active.spriteUrl,
                        width: 40,
                        height: 40,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.catching_pokemon,
                          size: 40,
                          color: typeColor.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Viewing',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface.withOpacity(0.4),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              active.displayName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '#${active.id}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Sections
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final section in NavigationShell._drawerSections) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Text(
                        section.title.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface.withOpacity(0.35),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    for (final item in section.items)
                      _DrawerItem(
                        item: item,
                        isActive: _isActive(item.path),
                        onTap: () {
                          Navigator.of(context).pop(); // close drawer
                          context.go(item.path);
                        },
                      ),
                  ],
                ],
              ),
            ),

            // Bottom: about + search + theme
            const Divider(height: 1),
            _DrawerItem(
              item: const _NavItem('/about', 'About & Legal', Icons.info_outline_rounded, Icons.info_rounded),
              isActive: _isActive('/about'),
              onTap: () {
                Navigator.of(context).pop();
                context.go('/about');
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _DrawerBottomButton(
                      icon: Icons.search_rounded,
                      label: 'Search',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/search');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DrawerBottomButton(
                      icon: Icons.palette_outlined,
                      label: 'Theme',
                      onTap: () {
                        Navigator.of(context).pop();
                        _showThemePicker(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerItem({required this.item, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: 20,
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerBottomButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerBottomButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: isActive
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.5)),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Desktop Sidebar (grouped like drawer) ---

class _DesktopSidebar extends StatelessWidget {
  final String currentPath;

  const _DesktopSidebar({required this.currentPath});

  bool _isActive(String path) {
    if (path == '/') return currentPath == '/';
    return currentPath.startsWith(path);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = AppState();

    return SizedBox(
      width: 240,
      child: Column(
        children: [
          // Logo area
          GestureDetector(
            onTap: () => context.go('/'),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.catching_pokemon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DexGuide',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Creature Database',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),

          // Active Pokemon context
          ListenableBuilder(
            listenable: appState,
            builder: (context, _) {
              final active = appState.activePokemon;
              if (active == null) return const SizedBox.shrink();
              final primaryType = active.types.isNotEmpty ? active.types.first.name : 'normal';
              final typeColor = TypeColors.getColor(primaryType);
              return GestureDetector(
                onTap: () => context.go('/pokemon/${active.id}'),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: typeColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Image.network(
                          active.spriteUrl,
                          width: 32,
                          height: 32,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.catching_pokemon,
                            size: 32,
                            color: typeColor.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            active.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '#${active.id}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Grouped nav sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8),
              children: [
                for (final section in NavigationShell._drawerSections) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                    child: Text(
                      section.title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface.withOpacity(0.3),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  for (final item in section.items) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => context.go(item.path),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: _isActive(item.path)
                                  ? colorScheme.primary.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isActive(item.path) ? item.activeIcon : item.icon,
                                  size: 20,
                                  color: _isActive(item.path)
                                      ? colorScheme.primary
                                      : colorScheme.onSurface.withOpacity(0.5),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontWeight: _isActive(item.path) ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 13,
                                    color: _isActive(item.path)
                                        ? colorScheme.primary
                                        : colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),

          // Bottom actions
          const Divider(height: 1),
          _SidebarButton(
            icon: Icons.info_outline_rounded,
            label: 'About & Legal',
            isActive: _isActive('/about'),
            colorScheme: colorScheme,
            onTap: () => context.go('/about'),
          ),
          _SidebarButton(
            icon: Icons.search,
            label: 'Search',
            isActive: _isActive('/search'),
            colorScheme: colorScheme,
            onTap: () => context.go('/search'),
          ),
          _SidebarButton(
            icon: Icons.palette_outlined,
            label: 'Theme',
            isActive: false,
            colorScheme: colorScheme,
            onTap: () => _showThemePicker(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// --- Mobile App Bar ---

class _MobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onSearch;

  const _MobileAppBar({required this.onSearch});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      toolbarHeight: 60,
      // Leading is auto-populated with hamburger icon when drawer is present
      title: GestureDetector(
        onTap: () => context.go('/'),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.catching_pokemon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'DexGuide',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          tooltip: 'Search',
          onPressed: onSearch,
        ),
        IconButton(
          icon: const Icon(Icons.palette_outlined),
          tooltip: 'Theme',
          onPressed: () => _showThemePicker(context),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// --- Theme Picker ---

void _showThemePicker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _ThemePickerSheet(),
  );
}

class _ThemePickerSheet extends StatelessWidget {
  const _ThemePickerSheet();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lightThemes = appColorThemes.where((t) => !t.isDark).toList();
    final darkThemes = appColorThemes.where((t) => t.isDark).toList();

    return ListenableBuilder(
      listenable: AppState(),
      builder: (context, _) {
        final appState = AppState();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'Theme',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),

                // Light section
                _sectionLabel(context, Icons.light_mode_rounded, 'LIGHT'),
                const SizedBox(height: 10),
                _themeGrid(appState, lightThemes),
                const SizedBox(height: 20),

                // Dark section
                _sectionLabel(context, Icons.dark_mode_rounded, 'DARK'),
                const SizedBox(height: 10),
                _themeGrid(appState, darkThemes),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(BuildContext context, IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurface.withOpacity(0.4)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 10,
            color: colorScheme.onSurface.withOpacity(0.4),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _themeGrid(AppState appState, List<AppColorTheme> themes) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 5,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.2,
      children: [
        for (final theme in themes)
          _ColorThemeTile(
            theme: theme,
            isSelected: appState.colorThemeId == theme.id,
            onTap: () => appState.setColorTheme(theme.id),
          ),
      ],
    );
  }
}

class _ColorThemeTile extends StatelessWidget {
  final AppColorTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorThemeTile({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = theme.isDark ? const Color(0xFF1E1E2A) : Colors.white;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? theme.seed : colorScheme.onSurface.withOpacity(0.1),
              width: isSelected ? 2.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: theme.seed,
                  shape: BoxShape.circle,
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                theme.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? theme.seed
                      : colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
