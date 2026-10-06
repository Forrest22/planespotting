import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:planespotting/data/repositories/card_repository.dart';
import 'package:planespotting/data/repositories/settings_repository.dart';
import 'package:planespotting/domain/formatting.dart';
import 'package:planespotting/domain/models/planechase_card.dart';
import 'package:planespotting/routes.dart';
import 'package:planespotting/ui/core/card_image.dart';
import 'package:planespotting/ui/features/game/view_models/game_view_model.dart';

const double _doubleTapZoom = 2.5;

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.cardRepository, required this.settingsRepository});

  final CardRepository cardRepository;
  final SettingsRepository settingsRepository;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameViewModel _viewModel = GameViewModel(
    cardRepository: widget.cardRepository,
    settingsRepository: widget.settingsRepository,
  );
  final PageController _pageController = PageController();
  final TransformationController _zoom = TransformationController();

  // Extra quarter turns added by the Rotate button, on top of the automatic fit.
  int _extraTurns = 0;
  bool _zoomed = false;
  int _pointers = 0;
  Offset _doubleTapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _zoom.addListener(() {
      final zoomed = _zoom.value.getMaxScaleOnAxis() > 1.01;
      if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
    });
  }

  @override
  void dispose() {
    _zoom.dispose();
    _pageController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(page, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _back() {
    if (_viewModel.canGoBack) _goTo(_viewModel.index - 1);
  }

  void _next() {
    if (_viewModel.hasCards) _goTo(_viewModel.index + 1);
  }

  void _toggleZoom() {
    if (_zoomed) {
      _zoom.value = Matrix4.identity();
    } else {
      // Zoom about the tapped point.
      final p = _doubleTapPosition;
      _zoom.value = Matrix4.identity()
        ..translateByDouble(p.dx * (1 - _doubleTapZoom), p.dy * (1 - _doubleTapZoom), 0, 1)
        ..scaleByDouble(_doubleTapZoom, _doubleTapZoom, _doubleTapZoom, 1);
    }
  }

  void _showText(PlanechaseCard card) {
    showModalBottomSheet<void>(
      context: context,
      // Wraps its content (up to the screen height, then scrolls) and is centered on wide windows.
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (context) {
        final theme = Theme.of(context).textTheme;
        final kind = card.type == CardType.plane ? 'Plane' : 'Phenomenon';
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.name, style: theme.titleLarge),
                const SizedBox(height: 4),
                Text('$kind · ${card.setName} · ${card.number}', style: theme.labelLarge),
                const SizedBox(height: 16),
                // Full width so the text lines up whatever its length.
                SizedBox(width: double.infinity, child: Text(formatOracleText(card.oracleText), style: theme.bodyLarge)),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _back,
        const SingleActivator(LogicalKeyboardKey.arrowRight): _next,
      },
      child: Focus(
        autofocus: true,
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final card = _viewModel.current;
            return Scaffold(
              appBar: AppBar(
                // Slimmer than the default 56 px to leave more room for the card.
                toolbarHeight: 44,
                // Large by default; long names scale down to fit instead of truncating.
                title: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(card?.name ?? 'Planeschasing', style: Theme.of(context).textTheme.headlineSmall),
                ),
              ),
              body: card == null ? _buildEmpty(context) : _buildPages(),
              bottomNavigationBar: card == null ? null : _buildActionBar(card),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No cards match your options'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, optionsRoute).then((_) => _viewModel.refresh()),
            child: const Text('Open Options'),
          ),
        ],
      ),
    );
  }

  Widget _buildPages() {
    final history = _viewModel.history;
    return Listener(
      onPointerDown: (_) => setState(() => _pointers++),
      onPointerUp: (_) => setState(() => _pointers--),
      onPointerCancel: (_) => setState(() => _pointers--),
      child: PageView.builder(
        controller: _pageController,
        // One-finger drags pan a zoomed card, and pinching must not turn the page.
        physics: _zoomed || _pointers > 1 ? const NeverScrollableScrollPhysics() : null,
        itemCount: history.length,
        onPageChanged: (page) {
          _zoom.value = Matrix4.identity();
          _viewModel.onPageChanged(page);
        },
        itemBuilder: (context, page) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // The card file is portrait with sideways text: fill a tall window as-is,
                // and turn it upright in a wide one.
                final autoTurns = constraints.maxWidth > constraints.maxHeight ? 1 : 0;
                return GestureDetector(
                  onDoubleTapDown: (details) => _doubleTapPosition = details.localPosition,
                  onDoubleTap: _toggleZoom,
                  child: InteractiveViewer(
                    transformationController: _zoom,
                    maxScale: 4,
                    panEnabled: _zoomed,
                    child: CardImage(card: history[page], quarterTurns: (autoTurns + _extraTurns) % 4),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionBar(PlanechaseCard card) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            tooltip: 'Previous card',
            icon: const Icon(Icons.arrow_back),
            onPressed: _viewModel.canGoBack ? _back : null,
          ),
          IconButton(
            tooltip: 'Rotate card',
            icon: const Icon(Icons.rotate_right),
            onPressed: () => setState(() => _extraTurns = (_extraTurns + 1) % 4),
          ),
          IconButton(
            tooltip: 'Card text',
            icon: const Icon(Icons.article_outlined),
            onPressed: () => _showText(card),
          ),
          IconButton(
            tooltip: 'Next card',
            icon: const Icon(Icons.arrow_forward),
            onPressed: _next,
          ),
        ],
      ),
    );
  }
}
