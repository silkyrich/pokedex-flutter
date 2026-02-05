import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

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
                      child: const Icon(Icons.code_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How This App Works',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Learn to code by building something cool',
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

                Text(
                  'DexGuide is a real app built with real tools that professional developers use. '
                  'This page explains how it all works — and how you could build something like it yourself.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 32),

                // What is an API?
                _SectionCard(
                  title: 'What is an API?',
                  icon: Icons.cloud_outlined,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _para(colorScheme,
                        'Every Pokémon you see in this app comes from the internet. '
                        'When you tap on Charizard, the app sends a message to a server asking '
                        '"tell me everything about Pokémon #6." The server sends back the answer '
                        'as structured data. This request-and-response system is called an API — '
                        'an Application Programming Interface.'
                      ),
                      const SizedBox(height: 12),
                      _para(colorScheme,
                        'Think of it like ordering food. You (the app) look at the menu (the API documentation), '
                        'place an order (make a request), and the kitchen (the server) sends back your meal (the data).'
                      ),
                      const SizedBox(height: 12),
                      _para(colorScheme,
                        'This app uses PokéAPI, a free API that anyone can use. Try clicking the link below — '
                        'it will show you the raw data for Pikachu, exactly what this app receives:'
                      ),
                      const SizedBox(height: 12),
                      _LinkButton(
                        label: 'pokeapi.co/api/v2/pokemon/25 (Pikachu!)',
                        url: 'https://pokeapi.co/api/v2/pokemon/25',
                        colorScheme: colorScheme,
                        onTap: () => _openUrl('https://pokeapi.co/api/v2/pokemon/25'),
                      ),
                      const SizedBox(height: 8),
                      _para(colorScheme,
                        'That jumble of text is called JSON (JavaScript Object Notation). '
                        'Every programming language can read it. The app takes that JSON and '
                        'turns it into the nice-looking pages you see here.'
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // REST — the language of the web
                _SectionCard(
                  title: 'REST — The Language of the Web',
                  icon: Icons.language_rounded,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _para(colorScheme,
                        'PokéAPI is a REST API. REST stands for Representational State Transfer — '
                        'a fancy name for a simple idea: every piece of data has its own URL.'
                      ),
                      const SizedBox(height: 12),
                      _codeBlock(isDark, colorScheme,
                        '# Get Pokémon #6 (Charizard)\n'
                        'https://pokeapi.co/api/v2/pokemon/6\n\n'
                        '# Get the move "Flamethrower"\n'
                        'https://pokeapi.co/api/v2/move/53\n\n'
                        '# Get the type "Fire"\n'
                        'https://pokeapi.co/api/v2/type/10\n\n'
                        '# Get all 1025 Pokémon (paginated)\n'
                        'https://pokeapi.co/api/v2/pokemon?limit=1025'
                      ),
                      const SizedBox(height: 12),
                      _para(colorScheme,
                        'Every website, every app on your phone, every game with online features '
                        'uses APIs like this. Instagram, YouTube, Spotify — they all work the same '
                        'way under the hood. Learning how APIs work is one of the most useful '
                        'skills in programming.'
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // What is Flutter?
                _SectionCard(
                  title: 'What is Flutter?',
                  icon: Icons.widgets_outlined,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _para(colorScheme,
                        'DexGuide is built with Flutter, a free toolkit made by Google. '
                        'Flutter lets you write one codebase in the Dart programming language '
                        'and run it on the web, Android, iOS, Windows, Mac, and Linux.'
                      ),
                      const SizedBox(height: 12),
                      _para(colorScheme,
                        'Everything you see on screen is a "Widget." A button is a widget. '
                        'A text label is a widget. The entire page is a widget made of smaller widgets, '
                        'like LEGO bricks snapping together.'
                      ),
                      const SizedBox(height: 12),
                      _codeBlock(isDark, colorScheme,
                        '// This is real Dart code from this app!\n'
                        'Column(\n'
                        '  children: [\n'
                        '    Text("Charizard"),         // A text widget\n'
                        '    Image.network(spriteUrl),  // An image widget\n'
                        '    Row(\n'
                        '      children: [\n'
                        '        Chip(label: Text("Fire")),\n'
                        '        Chip(label: Text("Flying")),\n'
                        '      ],\n'
                        '    ),\n'
                        '  ],\n'
                        ')'
                      ),
                      const SizedBox(height: 12),
                      _LinkButton(
                        label: 'flutter.dev — Get started with Flutter',
                        url: 'https://flutter.dev',
                        colorScheme: colorScheme,
                        onTap: () => _openUrl('https://flutter.dev'),
                      ),
                      const SizedBox(height: 8),
                      _LinkButton(
                        label: 'dartpad.dev — Write Dart code in your browser',
                        url: 'https://dartpad.dev',
                        colorScheme: colorScheme,
                        onTap: () => _openUrl('https://dartpad.dev'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // How the data flows
                _SectionCard(
                  title: 'How the Data Flows',
                  icon: Icons.account_tree_outlined,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _para(colorScheme,
                        'Here\'s what happens when you search for a Pokémon in this app:'
                      ),
                      const SizedBox(height: 12),
                      _numberedStep(colorScheme, '1', 'You type a name or tap a sprite'),
                      _numberedStep(colorScheme, '2', 'The app sends an HTTP GET request to PokéAPI'),
                      _numberedStep(colorScheme, '3', 'PokéAPI\'s server looks up the data in its database'),
                      _numberedStep(colorScheme, '4', 'The server sends back JSON with stats, types, moves, and more'),
                      _numberedStep(colorScheme, '5', 'The app parses the JSON into Dart objects (called "models")'),
                      _numberedStep(colorScheme, '6', 'Flutter widgets read those objects and draw the UI'),
                      const SizedBox(height: 12),
                      _para(colorScheme,
                        'This pattern — fetch data, parse it, display it — is the foundation of '
                        'almost every app and website in existence. Once you understand it, '
                        'you can build anything.'
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Concepts you'll learn
                _SectionCard(
                  title: 'Programming Concepts in This App',
                  icon: Icons.lightbulb_outline_rounded,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _conceptRow(colorScheme, 'Variables & Types',
                        'Each Pokémon\'s HP, Attack, and Speed are stored as numbers. Its name is a string. Its types are a list.'),
                      const Divider(height: 24),
                      _conceptRow(colorScheme, 'Conditionals',
                        'if (move.type == "fire" && target.type == "grass") → super effective! The type chart is a giant set of if/else logic.'),
                      const Divider(height: 24),
                      _conceptRow(colorScheme, 'Loops',
                        'To show all 1025 Pokémon, the app loops through a list and creates a card widget for each one.'),
                      const Divider(height: 24),
                      _conceptRow(colorScheme, 'Functions',
                        'The damage calculator is a function: give it an attacker, defender, and move, and it returns the damage number.'),
                      const Divider(height: 24),
                      _conceptRow(colorScheme, 'Async / Await',
                        'API calls take time. The app uses "await" to pause until the data arrives, then continues.'),
                      const Divider(height: 24),
                      _conceptRow(colorScheme, 'State Management',
                        'When you add a Pokémon to your team, the app updates its "state" and every widget that cares about the team redraws itself.'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // See the source code
                _SectionCard(
                  title: 'See the Source Code',
                  icon: Icons.source_outlined,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _para(colorScheme,
                        'DexGuide is completely open source. You can read every line of code, '
                        'copy it, modify it, and learn from it. That\'s how most programmers '
                        'learn — by reading and tweaking real projects.'
                      ),
                      const SizedBox(height: 12),
                      _LinkButton(
                        label: 'DexGuide on GitHub',
                        url: 'https://github.com/silkyrich/pokedex-flutter',
                        colorScheme: colorScheme,
                        onTap: () => _openUrl('https://github.com/silkyrich/pokedex-flutter'),
                      ),
                      const SizedBox(height: 8),
                      _LinkButton(
                        label: 'PokéAPI documentation',
                        url: 'https://pokeapi.co/docs/v2',
                        colorScheme: colorScheme,
                        onTap: () => _openUrl('https://pokeapi.co/docs/v2'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Where to start learning
                _SectionCard(
                  title: 'Where to Start Learning',
                  icon: Icons.school_outlined,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _para(colorScheme,
                        'If you\'ve never written code before, here are some great free resources:'
                      ),
                      const SizedBox(height: 12),
                      _LinkButton(
                        label: 'Scratch (MIT) — Visual coding for beginners',
                        url: 'https://scratch.mit.edu',
                        colorScheme: colorScheme,
                        onTap: () => _openUrl('https://scratch.mit.edu'),
                      ),
                      const SizedBox(height: 8),
                      _LinkButton(
                        label: 'Khan Academy — Intro to programming',
                        url: 'https://www.khanacademy.org/computing/computer-programming',
                        colorScheme: colorScheme,
                        onTap: () => _openUrl('https://www.khanacademy.org/computing/computer-programming'),
                      ),
                      const SizedBox(height: 8),
                      _LinkButton(
                        label: 'freeCodeCamp — Full web dev courses',
                        url: 'https://www.freecodecamp.org',
                        colorScheme: colorScheme,
                        onTap: () => _openUrl('https://www.freecodecamp.org'),
                      ),
                      const SizedBox(height: 8),
                      _LinkButton(
                        label: 'DartPad — Try the language this app uses',
                        url: 'https://dartpad.dev',
                        colorScheme: colorScheme,
                        onTap: () => _openUrl('https://dartpad.dev'),
                      ),
                      const SizedBox(height: 12),
                      _para(colorScheme,
                        'The best way to learn is to build something you care about. '
                        'If you love Pokémon, try building your own Pokédex. '
                        'Start small — just fetch one Pokémon and display its name. '
                        'Then add its image. Then its stats. Before you know it, you\'ll have '
                        'an app.'
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

  static Widget _numberedStep(ColorScheme colorScheme, String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                num,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
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
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: colorScheme.primary.withOpacity(0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
