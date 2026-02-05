import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/item.dart';
import '../services/pokeapi_service.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemName;

  const ItemDetailScreen({super.key, required this.itemName});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  ItemDetail? _item;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  @override
  void didUpdateWidget(ItemDetailScreen old) {
    super.didUpdateWidget(old);
    if (old.itemName != widget.itemName) _loadItem();
  }

  Future<void> _loadItem() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final item = await PokeApiService.getItemDetail(widget.itemName);
      if (mounted) {
        setState(() {
          _item = item;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Loading item...',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load item',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _loadItem,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final item = _item!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/items'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.displayName,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Item image and basic info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        // Sprite
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(
                              isDark ? 0.1 : 0.05,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Image.network(
                              item.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.inventory_2_outlined,
                                size: 48,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.category != null)
                                _infoRow(
                                  'Category',
                                  ItemCategory.displayName(item.category!),
                                  theme,
                                ),
                              _infoRow(
                                'Cost',
                                item.cost > 0
                                    ? '₽${item.cost}'
                                    : 'Not for sale',
                                theme,
                              ),
                              if (item.attributes.isNotEmpty)
                                _infoRow(
                                  'Type',
                                  item.attributes
                                      .map((a) => a
                                          .split('-')
                                          .map((w) => w[0].toUpperCase() +
                                              w.substring(1))
                                          .join(' '))
                                      .join(', '),
                                  theme,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Effect
                if (item.effect != null || item.shortEffect != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Effect',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item.shortEffect ?? item.effect ?? 'No description available.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
