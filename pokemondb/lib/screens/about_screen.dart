import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

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
                      child: const Icon(Icons.catching_pokemon, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DexDB',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Creature Database',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Text(
                  'An unofficial fan-built creature database and competitive toolkit. '
                  'Browse every Pokémon, compare stats, calculate damage, build teams, '
                  'and track your collection.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 32),

                // Disclaimer
                _SectionCard(
                  title: 'Disclaimer',
                  icon: Icons.info_outline_rounded,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Text(
                    'This is an unofficial, non-commercial fan project. It is not '
                    'affiliated with, endorsed by, or in any way officially connected '
                    'to Nintendo, Game Freak, Creatures Inc., or The Pokémon Company.\n\n'
                    'Pokémon and all associated names, characters, and imagery are '
                    'trademarks and copyright of their respective owners.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Data Attribution
                _SectionCard(
                  title: 'Data Attribution',
                  icon: Icons.storage_outlined,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Pokémon data is provided by PokéAPI, a free and open '
                        'RESTful API for Pokémon data.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LinkButton(
                        label: 'pokeapi.co',
                        url: 'https://pokeapi.co',
                        colorScheme: colorScheme,
                        onTap: () => _openUrl('https://pokeapi.co'),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.grey.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Copyright © 2013–2025 Paul Hallett and PokéAPI contributors.\n'
                          'Licensed under the BSD 3-Clause License.\n\n'
                          'Redistribution and use in source and binary forms, with or '
                          'without modification, are permitted provided that '
                          'redistributions retain the above copyright notice and '
                          'disclaimer.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.5,
                            fontFamily: 'monospace',
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Artwork
                _SectionCard(
                  title: 'Artwork & Sprites',
                  icon: Icons.image_outlined,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Text(
                    'Pokémon artwork and sprites are sourced from the PokéAPI sprites '
                    'repository and are the property of Nintendo, Game Freak, and '
                    'The Pokémon Company. They are used here under fair use for '
                    'non-commercial, educational, and fan purposes.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Open Source
                _SectionCard(
                  title: 'Open Source',
                  icon: Icons.code_rounded,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This app is open source. Built with Flutter.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LinkButton(
                        label: 'View on GitHub',
                        url: 'https://github.com/silkyrich/pokedex-flutter',
                        colorScheme: colorScheme,
                        onTap: () => _openUrl('https://github.com/silkyrich/pokedex-flutter'),
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
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: colorScheme.onSurface,
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

class _LinkButton extends StatelessWidget {
  final String label;
  final String url;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _LinkButton({
    required this.label,
    required this.url,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.open_in_new_rounded, size: 14, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
                decoration: TextDecoration.underline,
                decorationColor: colorScheme.primary.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
