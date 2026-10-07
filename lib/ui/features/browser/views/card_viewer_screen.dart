import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:planespotting/domain/models/planechase_card.dart';
import 'package:planespotting/ui/core/app_bar_title.dart';
import 'package:planespotting/ui/core/card_text_panel.dart';
import 'package:planespotting/ui/core/exclude_toggle.dart';
import 'package:planespotting/ui/core/ui_constants.dart';
import 'package:planespotting/ui/core/zoomable_card.dart';
import 'package:planespotting/ui/features/browser/view_models/browser_view_model.dart';

/// One card full screen, with its text and artist. Swipe to move through [cards].
class CardViewerScreen extends StatefulWidget {
  const CardViewerScreen({
    super.key,
    required this.viewModel,
    required this.cards,
    required this.initialIndex,
    this.onIndexChanged,
  });

  final BrowserViewModel viewModel;
  final List<PlanechaseCard> cards;
  final int initialIndex;

  /// Told which card is showing, so the grid behind can scroll to it when this screen closes.
  final ValueChanged<int>? onIndexChanged;

  @override
  State<CardViewerScreen> createState() => _CardViewerScreenState();
}

class _CardViewerScreenState extends State<CardViewerScreen> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  final CardZoomController _zoom = CardZoomController();
  late int _index = widget.initialIndex;

  @override
  void initState() {
    super.initState();
    // Rebuilds only when the card crosses between zoomed in and not.
    _zoom.zoomed.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _zoom.dispose();
    _pages.dispose();
    super.dispose();
  }

  static const _pageDuration = Duration(milliseconds: 250);

  void _turn(int delta) {
    if (_zoom.isZoomed) return;
    final target = _index + delta;
    if (target < 0 || target >= widget.cards.length) return;
    _pages.animateToPage(
      target,
      duration: _pageDuration,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.cards[_index];
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final excluded = widget.viewModel.isExcluded(card);
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowLeft):
                () => _turn(-1),
            const SingleActivator(LogicalKeyboardKey.arrowRight):
                () => _turn(1),
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              appBar: AppBar(
                title: AppBarTitle(card.name),
                actions: [
                  IconButton(
                    tooltip: excludeLabel(excluded),
                    icon: Icon(excludeIcon(excluded)),
                    onPressed: () => widget.viewModel.toggleExcluded(card),
                  ),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pages,
                      // A zoomed card pans with one finger instead of turning the page.
                      physics:
                          _zoom.isZoomed
                              ? const NeverScrollableScrollPhysics()
                              : null,
                      itemCount: widget.cards.length,
                      onPageChanged: (page) {
                        _zoom.reset();
                        setState(() => _index = page);
                        widget.onIndexChanged?.call(page);
                      },
                      itemBuilder:
                          (context, page) => ZoomableCard(
                            card: widget.cards[page],
                            controller: _zoom,
                          ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: contentMaxWidth,
                      maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                    ),
                    child: CardTextPanel(card: card),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
