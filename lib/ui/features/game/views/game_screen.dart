import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:planespotting/data/repositories/card_repository.dart';
import 'package:planespotting/data/repositories/settings_repository.dart';
import 'package:planespotting/domain/formatting.dart';
import 'package:planespotting/domain/models/planechase_card.dart';
import 'package:planespotting/domain/planar_die.dart';
import 'package:planespotting/routes.dart';
import 'package:planespotting/ui/core/card_image.dart';
import 'package:planespotting/ui/features/game/view_models/game_view_model.dart';
import 'package:planespotting/ui/features/game/views/planar_die_button.dart';

const double _doubleTapZoom = 2.5;

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.cardRepository,
    required this.settingsRepository,
  });

  final CardRepository cardRepository;
  final SettingsRepository settingsRepository;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final GameViewModel _viewModel = GameViewModel(
    cardRepository: widget.cardRepository,
    settingsRepository: widget.settingsRepository,
  );
  final PageController _pageController = PageController();
  final TransformationController _zoom = TransformationController();
  // The die flashes through faces, then lands on the result.
  late final AnimationController _rollController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  final Random _flickerRandom = Random(); // cosmetic only, not the game's RNG
  List<DieFace> _flicker = const [];
  DieFace _pendingResult = DieFace.blank;

  // Extra quarter turns added by the Rotate button, on top of the automatic fit.
  int _extraTurns = 0;
  // The card-text sheet is a mode: once on, every card shows its text.
  bool _textVisible = false;
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
    _rollController.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      // The first roll is a planeswalk that reveals the opening plane.
      _viewModel.started
          ? _viewModel.rollDie(_pendingResult)
          : _viewModel.start();
    });
  }

  @override
  void dispose() {
    _zoom.dispose();
    _rollController.dispose();
    _pageController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _back() {
    if (_viewModel.canGoBack) _goTo(_viewModel.index - 1);
  }

  void _next() {
    if (!_viewModel.hasCards) return;
    _viewModel.started ? _goTo(_viewModel.index + 1) : _viewModel.start();
  }

  void _roll() {
    if (!_viewModel.hasCards || _rollController.isAnimating) return;
    // Decide the result up front so the flicker can end on it.
    _pendingResult =
        _viewModel.started ? _viewModel.nextRoll() : DieFace.planeswalk;
    setState(() => _flicker = rollFlicker(_pendingResult, _flickerRandom));
    _rollController.forward(from: 0);
  }

  void _toggleZoom() {
    if (_zoomed) {
      _zoom.value = Matrix4.identity();
    } else {
      // Zoom about the tapped point.
      final p = _doubleTapPosition;
      _zoom.value =
          Matrix4.identity()
            ..translateByDouble(
              p.dx * (1 - _doubleTapZoom),
              p.dy * (1 - _doubleTapZoom),
              0,
              1,
            )
            ..scaleByDouble(_doubleTapZoom, _doubleTapZoom, _doubleTapZoom, 1);
    }
  }

  void _toggleText() => setState(() => _textVisible = !_textVisible);

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _back,
        const SingleActivator(LogicalKeyboardKey.arrowRight): _next,
        const SingleActivator(LogicalKeyboardKey.space): _roll,
      },
      child: Focus(
        autofocus: true,
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final card = _viewModel.current;
            final hasCards = _viewModel.hasCards;
            return Scaffold(
              appBar: AppBar(
                // Slimmer than the default 56 px to leave more room for the card.
                toolbarHeight: 44,
                // Large by default; long names scale down to fit instead of truncating.
                title: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    card?.name ?? 'Planeschasing',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
              body:
                  !hasCards
                      ? _buildEmpty(context)
                      : card == null
                      ? _buildStartPrompt(context)
                      : LayoutBuilder(
                        builder:
                            (context, constraints) => Stack(
                              children: [
                                _buildPages(),
                                // Grows up out of the bottom bar.
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: _buildTextSheet(
                                    card,
                                    constraints.maxHeight * 0.6,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  left: 12,
                                  right: 12,
                                  child: _buildBanner(),
                                ),
                              ],
                            ),
                      ),
              bottomNavigationBar: !hasCards ? null : _buildActionBar(card),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStartPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PlanarDieFace(face: DieFace.planeswalk, size: 96),
          const SizedBox(height: 16),
          Text(
            'Planeswalk to begin',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _next, child: const Text('Planeswalk')),
        ],
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
            onPressed:
                () => Navigator.pushNamed(
                  context,
                  optionsRoute,
                ).then((_) => _viewModel.refresh()),
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
        physics:
            _zoomed || _pointers > 1
                ? const NeverScrollableScrollPhysics()
                : null,
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
                final autoTurns =
                    constraints.maxWidth > constraints.maxHeight ? 1 : 0;
                return GestureDetector(
                  onDoubleTapDown:
                      (details) => _doubleTapPosition = details.localPosition,
                  onDoubleTap: _toggleZoom,
                  child: InteractiveViewer(
                    transformationController: _zoom,
                    maxScale: 4,
                    panEnabled: _zoomed,
                    child: CardImage(
                      card: history[page],
                      quarterTurns: (autoTurns + _extraTurns) % 4,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBanner() {
    final roll = _viewModel.lastRoll;
    return Align(
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        reverseDuration: const Duration(milliseconds: 200),
        // Pops in with a little overshoot.
        transitionBuilder:
            (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                  reverseCurve: Curves.easeIn,
                ),
                child: child,
              ),
            ),
        child:
            roll == null
                ? const SizedBox.shrink()
                : _RollBanner(
                  key: ValueKey(_viewModel.rollCount),
                  face: roll,
                  onPlaneswalk: _next,
                  textVisible: _textVisible,
                  onToggleText: _toggleText,
                ),
      ),
    );
  }

  Widget _buildTextSheet(PlanechaseCard card, double maxHeight) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder:
          (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              // Anchored to the bar, so the sheet rises out of it.
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
      child:
          _textVisible
              ? Align(
                key: const ValueKey('card-text-sheet'),
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 600,
                    maxHeight: maxHeight,
                  ),
                  // The sheet covers the pages, so it passes swipes on to them.
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      final velocity = details.velocity.pixelsPerSecond.dx;
                      if (velocity < -300) _next();
                      if (velocity > 300) _back();
                    },
                    child: _CardTextPanel(
                      key: const ValueKey('card-text-panel'),
                      card: card,
                    ),
                  ),
                ),
              )
              : const SizedBox.shrink(),
    );
  }

  Widget _buildActionBar(PlanechaseCard? card) {
    return BottomAppBar(
      height: 116,
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
            onPressed:
                () => setState(() => _extraTurns = (_extraTurns + 1) % 4),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlanarDieButton(
                // Before the game starts the die waits on a planeswalk.
                face:
                    _viewModel.started
                        ? _viewModel.lastRoll
                        : DieFace.planeswalk,
                rolling: _rollController,
                flicker: _flicker,
                onRoll: _roll,
              ),
              ExcludeSemantics(
                child: InkWell(
                  onTap: _roll,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    child: Text(
                      'Roll die',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: _textVisible ? 'Hide card text' : 'Show card text',
            isSelected: _textVisible,
            icon: const Icon(Icons.article_outlined),
            selectedIcon: const Icon(Icons.article),
            onPressed: card == null ? null : _toggleText,
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

/// The result of a roll. Blank fades away by itself; the others stay until dismissed,
/// the plane changes, or the next roll.
class _RollBanner extends StatefulWidget {
  const _RollBanner({
    super.key,
    required this.face,
    required this.onPlaneswalk,
    required this.textVisible,
    required this.onToggleText,
  });

  final DieFace face;
  final VoidCallback onPlaneswalk;
  final bool textVisible;
  final VoidCallback onToggleText;

  @override
  State<_RollBanner> createState() => _RollBannerState();
}

class _RollBannerState extends State<_RollBanner> {
  Timer? _timer;
  bool _hidden = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.face == DieFace.blank) {
      _timer = Timer(
        const Duration(seconds: 3),
        () => setState(() => _hidden = true),
      );
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final title = switch (widget.face) {
      DieFace.planeswalk => 'Planeswalk!',
      DieFace.chaos => 'Chaos!',
      DieFace.blank => 'Nothing happens',
    };
    // A different colour per result, so it reads at a glance.
    final (container, onContainer) = switch (widget.face) {
      DieFace.planeswalk => (scheme.primaryContainer, scheme.onPrimaryContainer),
      DieFace.chaos => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      DieFace.blank => (scheme.surfaceContainerHighest, scheme.onSurface),
    };
    return IgnorePointer(
      ignoring: _hidden,
      child: AnimatedOpacity(
        opacity: _hidden ? 0 : 1,
        duration: const Duration(milliseconds: 400),
        child: Semantics(
          liveRegion: true,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(20),
            color: container,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Just the symbol, tinted like the text beside it, so it doesn't read as a mini die.
                  PlanarDieGlyph(
                    face: widget.face,
                    size: 44,
                    color: onContainer,
                  ),
                  const SizedBox(width: 12),
                  // Shrinks rather than overflowing on a narrow screen.
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: onContainer,
                        ),
                      ),
                    ),
                  ),
                  if (widget.face == DieFace.planeswalk)
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: onContainer),
                      onPressed: widget.onPlaneswalk,
                      child: const Text('Planeswalk'),
                    ),
                  if (widget.face == DieFace.chaos)
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: onContainer),
                      onPressed: widget.onToggleText,
                      child: Text(
                        widget.textVisible ? 'Hide text' : 'Show text',
                      ),
                    ),
                  IconButton(
                    tooltip: 'Dismiss',
                    color: onContainer,
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _hidden = true),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The card's name, type line, rules text and artist, on a sheet attached to the bottom bar.
class _CardTextPanel extends StatelessWidget {
  const _CardTextPanel({super.key, required this.card});

  final PlanechaseCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final kind = card.type == CardType.plane ? 'Plane' : 'Phenomenon';
    return Material(
      elevation: 6,
      // Rounded on top only: the bottom edge sits flush on the bar.
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      color: colors.surface.withValues(alpha: 0.96),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Column(
            key: ValueKey(card.id),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.name, style: theme.titleLarge),
              const SizedBox(height: 4),
              Text(
                '$kind · ${card.setName} · ${card.number}',
                style: theme.labelLarge,
              ),
              const SizedBox(height: 12),
              // Full width so the text lines up whatever its length.
              SizedBox(
                width: double.infinity,
                child: Text(
                  formatOracleText(card.oracleText),
                  style: theme.bodyLarge,
                ),
              ),
              if (card.artist.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Illustrated by ${card.artist}',
                  style: theme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
