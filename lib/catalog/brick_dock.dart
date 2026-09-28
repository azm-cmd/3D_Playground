import 'package:flutter/material.dart';

import 'brick_catalog.dart';
import 'brick_catalog_card.dart';
import 'brick_definition.dart';

/// The browse/search dock for the brick catalog.
///
/// Purely a browser: tapping a card highlights it here and reports it via
/// [onBrickSelected], but placing it into the 3D scene is out of scope for
/// this widget (and this phase).
class BrickDock extends StatefulWidget {
  final List<BrickDefinition> bricks;
  final ValueChanged<BrickDefinition>? onBrickSelected;

  /// Optional controller for the results grid, so a host like a
  /// [DraggableScrollableSheet] can drive scrolling from its drag handle.
  final ScrollController? scrollController;

  const BrickDock({
    super.key,
    this.bricks = kStarterBricks,
    this.onBrickSelected,
    this.scrollController,
  });

  @override
  State<BrickDock> createState() => _BrickDockState();
}

class _BrickDockState extends State<BrickDock> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _highlightedId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
  }

  void _clearSearch() {
    _searchController.clear();
    _onQueryChanged('');
  }

  void _onBrickTap(BrickDefinition brick) {
    setState(() {
      _highlightedId = _highlightedId == brick.id ? null : brick.id;
    });
    widget.onBrickSelected?.call(brick);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = filterBricks(widget.bricks, _query);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text('Bricks', style: theme.textTheme.titleMedium),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Semantics(
            textField: true,
            label: 'Search brick catalog',
            child: TextField(
              controller: _searchController,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search bricks',
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear search',
                        onPressed: _clearSearch,
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              liveRegion: true,
              child: Text(
                results.isEmpty
                    ? 'No bricks match "$_query"'
                    : '${results.length} of ${widget.bricks.length} bricks',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: results.isEmpty
              ? _EmptyResults(query: _query)
              : GridView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 160,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final brick = results[index];
                    return BrickCatalogCard(
                      key: ValueKey(brick.id),
                      brick: brick,
                      highlighted: brick.id == _highlightedId,
                      onTap: () => _onBrickTap(brick),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final String query;

  const _EmptyResults({required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No bricks match "$query"',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
