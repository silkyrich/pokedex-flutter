import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OfficialLinksScreen extends StatelessWidget {
  const OfficialLinksScreen({super.key});

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
                      child: const Icon(Icons.videogame_asset_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Official Pokémon',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Games, events, and more from The Pokémon Company',
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
                  'DexGuide is a fan-made companion tool. The real magic happens in the '
                  'official games, events, and products from The Pokémon Company. '
                  'Here\'s where to find them.'
                ),

                const SizedBox(height: 32),

                // Latest Games
                _SectionCard(
                  title: 'Latest Games',
                  icon: Icons.sports_esports_outlined,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _gameCard(context, colorScheme, isDark,
                        title: 'Pokémon Legends: Z-A',
                        platform: 'Nintendo Switch',
                        description: 'Return to Lumiose City in this upcoming action RPG '
                            'set in the Kalos region.',
                        url: 'https://www.pokemon.com/us/pokemon-video-games/pokemon-legends-z-a',
                      ),
                      const SizedBox(height: 12),
                      _gameCard(context, colorScheme, isDark,
                        title: 'Pokémon Scarlet & Violet',
                        platform: 'Nintendo Switch',
                        description: 'The latest mainline games with open-world exploration '
                            'across the Paldea region. Includes The Hidden Treasure of Area Zero DLC.',
                        url: 'https://scarletviolet.pokemon.com',
                      ),
                      const SizedBox(height: 12),
                      _gameCard(context, colorScheme, isDark,
                        title: 'Pokémon Legends: Arceus',
                        platform: 'Nintendo Switch',
                        description: 'Explore the ancient Hisui region in this action-focused '
                            'adventure that reimagined how Pokémon games play.',
                        url: 'https://legends.pokemon.com/en-us/',
                      ),
                      const SizedBox(height: 12),
                      _gameCard(context, colorScheme, isDark,
                        title: 'Pokémon Brilliant Diamond & Shining Pearl',
                        platform: 'Nintendo Switch',
                        description: 'Faithful remakes of the beloved Generation IV games '
                            'set in the Sinnoh region.',
                        url: 'https://diamondpearl.pokemon.com/en-us/',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Mobile & Free-to-Play
                _SectionCard(
                  title: 'Mobile & Free-to-Play',
                  icon: Icons.phone_android_rounded,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _gameCard(context, colorScheme, isDark,
                        title: 'Pokémon GO',
                        platform: 'iOS & Android',
                        description: 'Discover Pokémon in the real world using your phone\'s GPS. '
                            'Walk, catch, trade, battle, and join community events worldwide.',
                        url: 'https://pokemongolive.com',
                      ),
                      const SizedBox(height: 12),
                      _gameCard(context, colorScheme, isDark,
                        title: 'Pokémon TCG Pocket',
                        platform: 'iOS & Android',
                        description: 'Collect and battle with digital Pokémon cards. Open booster '
                            'packs, build decks, and enjoy the Trading Card Game on mobile.',
                        url: 'https://www.pokemon.com/us/app/pokemon-tcg-pocket',
                      ),
                      const SizedBox(height: 12),
                      _gameCard(context, colorScheme, isDark,
                        title: 'Pokémon UNITE',
                        platform: 'Switch, iOS & Android',
                        description: 'A free-to-play team battle game. Work together with '
                            'your team to defeat wild Pokémon and score points.',
                        url: 'https://unite.pokemon.com/en-us/',
                      ),
                      const SizedBox(height: 12),
                      _gameCard(context, colorScheme, isDark,
                        title: 'Pokémon Sleep',
                        platform: 'iOS & Android',
                        description: 'Track your sleep and wake up to find Pokémon drawn to your '
                            'sleeping style. Turns rest into an adventure.',
                        url: 'https://www.pokemonsleep.net',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Trading Card Game
                _SectionCard(
                  title: 'Trading Card Game',
                  icon: Icons.style_outlined,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _para(colorScheme,
                        'The Pokémon Trading Card Game has been going strong since 1996. '
                        'Collect cards, build decks, and play with friends or competitively.'
                      ),
                      const SizedBox(height: 12),
                      _LinkButton(
                        label: 'Official Pokémon TCG site',
                        url: 'https://www.pokemon.com/us/pokemon-tcg',
                        colorScheme: colorScheme,
                        onTap: () => _openUrl('https://www.pokemon.com/us/pokemon-tcg'),
                      ),
                      const SizedBox(height: 8),
                      _LinkButton(
                        label: 'Find a TCG league or event near you',
                        url: 'https://events.pokemon.com',
                        colorScheme: colorScheme,
                        onTap: () => _openUrl('https://events.pokemon.com'),
                      ),
                      const SizedBox(height: 8),
                      _LinkButton(
                        label: 'Learn to play the TCG',
                        url: 'https://www.pokemon.com/us/pokemon-tcg/rules',
                        colorScheme: colorScheme,
                        onTap: () => _openUrl('https://www.pokemon.com/us/pokemon-tcg/rules'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Competitive Battling
                _SectionCard(
                  title: 'Competitive Battling',
                  icon: Icons.emoji_events_outlined,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _para(colorScheme,
                        'Think you\'re ready to battle the best? The Pokémon Video Game '
                        'Championships (VGC) hold tournaments around the world. Watch the '
                        'top players compete or enter yourself!'
                      ),
                      const SizedBox(height: 12),
                      _LinkButton(
                        label: 'Pokémon VGC — Official competitive play',
                        url: 'https://www.pokemon.com/us/strategy/an-introduction-to-the-video-game-championships',
                        colorScheme: colorScheme,
                        onTap: () => _openUrl('https://www.pokemon.com/us/strategy/an-introduction-to-the-video-game-championships'),
                      ),
                      const SizedBox(height: 8),
                      _LinkButton(
                        label: 'Find Pokémon events near you',
                        url: 'https://events.pokemon.com',
                        colorScheme: colorScheme,
                        onTap: () => _openUrl('https://events.pokemon.com'),
                      ),
                      const SizedBox(height: 8),
                      _LinkButton(
                        label: 'Pokémon Championship Series (Play! Pokémon)',
                        url: 'https://www.pokemon.com/us/play-pokemon',
                        colorScheme: colorScheme,
                        onTap: () => _openUrl('https://www.pokemon.com/us/play-pokemon'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Shop & Merchandise
                _SectionCard(
                  title: 'Shop & Merchandise',
                  icon: Icons.shopping_bag_outlined,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _para(colorScheme,
                        'From plush toys to apparel, the Pokémon Center is the official shop '
                        'for all Pokémon merchandise.'
                      ),
                      const SizedBox(height: 12),
                      _LinkButton(
                        label: 'Pokémon Center — Official online shop',
                        url: 'https://www.pokemoncenter.com',
                        colorScheme: colorScheme,
                        onTap: () => _openUrl('https://www.pokemoncenter.com'),
                      ),
                      const SizedBox(height: 8),
                      _LinkButton(
                        label: 'Nintendo eShop — Digital game purchases',
                        url: 'https://www.nintendo.com/us/store/games/#p=1&sort=df&f=franchises&franchises=Pok%C3%A9mon',
                        colorScheme: colorScheme,
                        onTap: () => _openUrl('https://www.nintendo.com/us/store/games/#p=1&sort=df&f=franchises&franchises=Pok%C3%A9mon'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // TV & Movies
                _SectionCard(
                  title: 'Watch Pokémon',
                  icon: Icons.movie_outlined,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _para(colorScheme,
                        'Watch the animated series, movies, and specials from the Pokémon universe.'
                      ),
                      const SizedBox(height: 12),
                      _LinkButton(
                        label: 'Pokémon TV & Movies — Official streaming',
                        url: 'https://www.pokemon.com/us/pokemon-episodes',
                        colorScheme: colorScheme,
                        onTap: () => _openUrl('https://www.pokemon.com/us/pokemon-episodes'),
                      ),
                      const SizedBox(height: 8),
                      _LinkButton(
                        label: 'Pokémon Horizons on Netflix',
                        url: 'https://www.netflix.com/title/81Pokemon',
                        colorScheme: colorScheme,
                        onTap: () => _openUrl('https://www.pokemon.com/us/animation'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Fan community note
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(isDark ? 0.1 : 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.favorite_rounded, size: 18, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'DexGuide is made by fans, for fans. We encourage everyone to support '
                          'the official Pokémon games and products that make this amazing world possible. '
                          'Pokémon and all associated names are trademarks of Nintendo, Game Freak, '
                          'and The Pokémon Company.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.6,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
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

  Widget _gameCard(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark, {
    required String title,
    required String platform,
    required String description,
    required String url,
  }) {
    return InkWell(
      onTap: () => _openUrl(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.grey.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.onSurface.withOpacity(0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    platform,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.open_in_new_rounded, size: 12, color: colorScheme.primary.withOpacity(0.7)),
                const SizedBox(width: 4),
                Text(
                  'Learn more',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
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
