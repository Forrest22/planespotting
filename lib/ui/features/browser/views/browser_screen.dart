import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:planespotting/data/repositories/card_repository.dart';
import 'package:planespotting/data/repositories/settings_repository.dart';
import 'package:planespotting/domain/models/planechase_card.dart';
import 'package:planespotting/ui/core/card_image.dart';
import 'package:planespotting/ui/features/browser/view_models/browser_view_model.dart';
import 'package:planespotting/ui/features/browser/views/card_viewer_screen.dart';

// Grid geometry, shared by the grid delegate and the preload window below so they can't drift.
const double _gridPadding = 12;
const double _gridSpacing = 8;
const double _maxTileWidth = 220;
const double _tileAspectRatio = 1.1;

// Tiles are built, and so their images loaded, this many rows beyond the screen.
const int _preloadRows = 3;

// The grid is revealed about this many tiles per frame (whole rows), so opening the screen never
// lays out every visible tile in one frame. A tile costs roughly a millisecond to build and lay out.
const int _revealTilesPerFrame = 12;

// Card files are 1040x1490 (portrait, with the card printed sideways).
const double _cardAspectRatio = 1490 / 1040;

/// Columns and row height of the grid at [width], worked out the way
/// SliverGridDelegateWithMaxCrossAxisExtent does (its column count includes the spacing).
({int columns, double rowExtent}) _gridMetrics(double width) {
  final usable = width - 2 * _gridPadding;
  final columns = (usable / (_maxTileWidth + _gridSpacing)).ceil();
  final tileWidth = (usable - _gridSpacing * (columns - 1)) / columns;
  return (columns: columns, rowExtent: tileWidth / _tileAspectRatio + _gridSpacing);
}

enum _BulkAction { exclude, include }

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key, required this.cardRepository, required this.settingsRepository});

  final CardRepository cardRepository;
  final SettingsRepository settingsRepository;

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  late final BrowserViewModel _viewModel = BrowserViewModel(
    cardRepository: widget.cardRepository,
    settingsRepository: widget.settingsRepository,
  );
  final TextEditingController _search = TextEditingController();
  final ScrollController _grid = ScrollController();

  // The grid is only built once the page-open animation has finished, and then it fills in a few
  // rows per frame (see _revealTilesPerFrame), so opening the screen never lays out dozens of tiles at once.
  bool _gridReady = false;
  // How many tiles the grid has been given so far. A notifier, so each batch rebuilds only the
  // grid, not the search field and chips above it.
  final ValueNotifier<int> _revealed = ValueNotifier(0);
  bool _revealScheduled = false;
  Animation<double>? _routeAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gridReady || _routeAnimation != null) return;
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) {
      _showGrid();
    } else {
      _routeAnimation = animation..addStatusListener(_onRouteStatus);
    }
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    if (mounted) setState(_showGrid);
  }

  void _showGrid() => _gridReady = true;

  /// Gives the grid more tiles after the current frame.
  void _revealMore(int target) {
    if (_revealScheduled) return;
    _revealScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealScheduled = false;
      if (mounted) _revealed.value = target;
    });
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _revealed.dispose();
    _grid.dispose();
    _search.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _search.clear();
    _viewModel.clearFilters();
  }

  void _open(List<PlanechaseCard> cards, int index) {
    var lastViewed = index;
    Navigator.of(context)
        .push(MaterialPageRoute<void>(
          builder: (context) => CardViewerScreen(
            viewModel: _viewModel,
            cards: cards,
            initialIndex: index,
            onIndexChanged: (page) => lastViewed = page,
          ),
        ))
        .then((_) {
      if (mounted) _revealCard(lastViewed);
    });
  }

  /// Scrolls the grid so the row holding the [index]th card is on screen, if it isn't already.
  void _revealCard(int index) {
    if (!_grid.hasClients) return;
    final last = _viewModel.entries.length - 1; // the list may have shrunk while the viewer was open
    if (last < 0) return;
    final metrics = _gridMetrics(MediaQuery.sizeOf(context).width);
    final top = _gridPadding + (index.clamp(0, last) ~/ metrics.columns) * metrics.rowExtent;
    final bottom = top + metrics.rowExtent - _gridSpacing;
    final position = _grid.position;
    if (top >= position.pixels && bottom <= position.pixels + position.viewportDimension) return;
    // Land with a row of context above it.
    _grid.animateTo(
      (top - metrics.rowExtent).clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _confirmBulk(_BulkAction action) async {
    final exclude = action == _BulkAction.exclude;
    final count = exclude ? _viewModel.excludableCount : _viewModel.includableCount;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${exclude ? 'Exclude' : 'Include'} $count ${count == 1 ? 'card' : 'cards'}?'),
        content: Text(
          exclude
              ? "They won't come up in games. Include them again here, or with Restore all in Options."
              : 'They can come up in games again.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(exclude ? 'Exclude' : 'Include')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (exclude) {
      await _viewModel.excludeShown();
    } else {
      await _viewModel.includeShown();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse cards'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) => PopupMenuButton<_BulkAction>(
              tooltip: 'Exclude or include all shown',
              onSelected: _confirmBulk,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _BulkAction.exclude,
                  enabled: _viewModel.excludableCount > 0,
                  child: Text('Exclude ${_viewModel.excludableCount} shown'),
                ),
                PopupMenuItem(
                  value: _BulkAction.include,
                  enabled: _viewModel.includableCount > 0,
                  child: Text('Include ${_viewModel.includableCount} shown'),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final entries = _viewModel.entries;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _search,
                  onChanged: _viewModel.setQuery,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search name, rules text or artist',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _viewModel.query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _search.clear();
                              _viewModel.setQuery('');
                            },
                          ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              _buildChips(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${entries.length} ${entries.length == 1 ? 'card' : 'cards'} · '
                    'Filters only. Turn sets on or off in Options.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              Expanded(child: !_gridReady ? const SizedBox.expand() : (entries.isEmpty ? _buildEmpty() : _buildGrid(entries))),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final set in _viewModel.sets)
            _chip(set.name, _viewModel.selectedSets.contains(set.code), () => _viewModel.toggleSet(set.code)),
          _chip('Planes', _viewModel.selectedTypes.contains(CardType.plane), () => _viewModel.toggleType(CardType.plane)),
          _chip(
            'Phenomena',
            _viewModel.selectedTypes.contains(CardType.phenomenon),
            () => _viewModel.toggleType(CardType.phenomenon),
          ),
          _chip('Excluded only', _viewModel.excludedOnly, () => _viewModel.setExcludedOnly(!_viewModel.excludedOnly)),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No cards match'),
          if (_viewModel.hasActiveFilters) ...[
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _clearFilters, child: const Text('Clear filters')),
          ],
        ],
      ),
    );
  }

  Widget _buildGrid(List<PlanechaseCard> entries) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // How tall one row is at this width, to turn "3 rows" into pixels.
        final metrics = _gridMetrics(constraints.maxWidth);
        final int batch = metrics.columns * math.max<int>(1, _revealTilesPerFrame ~/ metrics.columns);
        // Only the grid listens to the reveal, so each batch rebuilds just the grid.
        return ValueListenableBuilder<int>(
          valueListenable: _revealed,
          builder: (context, revealed, _) {
            final int shown = math.min<int>(entries.length, math.max<int>(revealed, batch));
            if (shown < entries.length) _revealMore(shown + batch);
            return GridView.builder(
              controller: _grid,
              padding: const EdgeInsets.all(_gridPadding),
              // Only the screen plus a few rows are built, so only their images are loaded; the rows
              // just ahead load before they scroll in.
              scrollCacheExtent: ScrollCacheExtent.pixels(_preloadRows * metrics.rowExtent),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: _maxTileWidth,
                childAspectRatio: _tileAspectRatio,
                mainAxisSpacing: _gridSpacing,
                crossAxisSpacing: _gridSpacing,
              ),
              itemCount: shown,
              itemBuilder: (context, index) => _CardTile(
                card: entries[index],
                viewModel: _viewModel,
                onOpen: () => _open(entries, index),
              ),
            );
          },
        );
      },
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card, required this.viewModel, required this.onOpen});

  final PlanechaseCard card;
  final BrowserViewModel viewModel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final excluded = viewModel.isExcluded(card);
    final hidden = viewModel.isHiddenByOptions(card);
    return Stack(
      children: [
        // Say out loud what the dimming shows.
        Semantics(
          value: excluded ? 'Excluded' : (hidden ? 'Set or type is off' : null),
          child: InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                // The file is portrait with the card printed sideways: turn it upright.
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Shown while the image decodes; the image fades in over it.
                      Center(
                        child: AspectRatio(
                          aspectRatio: _cardAspectRatio,
                          child: DecoratedBox(
                            key: const ValueKey('image-placeholder'),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      // No shadow: a blur under dozens of tiles is costly to draw.
                      CardImage(
                        card: card,
                        quarterTurns: 1,
                        thumbnail: true,
                        cacheWidth: 360,
                        fadeIn: true,
                        shadow: false,
                        excludeFromSemantics: true, // the name below already says it
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(card.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
        // Dimmed when the game can't draw it: a see-through wash, which is cheaper than an
        // Opacity layer.
        if (!viewModel.isInPlay(card))
          Positioned.fill(
            child: IgnorePointer(child: ColoredBox(color: colors.surface.withValues(alpha: 0.6))),
          ),
        if (hidden) const Positioned(top: 6, left: 6, child: Icon(Icons.visibility_off, size: 20)),
        Positioned(
          top: 2,
          right: 2,
          child: _ExcludeButton(excluded: excluded, onPressed: () => viewModel.toggleExcluded(card)),
        ),
      ],
    );
  }
}

/// The round exclude / include button on a tile. Deliberately plain (no tooltip or filled-button
/// machinery), because there is one on every tile in the grid.
class _ExcludeButton extends StatelessWidget {
  const _ExcludeButton({required this.excluded, required this.onPressed});

  final bool excluded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: excluded ? 'Include in game' : 'Exclude from game',
      onTap: onPressed,
      child: Material(
        color: colors.secondaryContainer,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(excluded ? Icons.undo : Icons.block, size: 18, color: colors.onSecondaryContainer),
          ),
        ),
      ),
    );
  }
}
