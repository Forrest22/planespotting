import 'package:flutter/material.dart';
import 'package:planespotting/domain/models/planechase_card.dart';
import 'package:planespotting/ui/core/card_image.dart';
import 'package:planespotting/ui/core/card_text_panel.dart';
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
  late final PageController _pages = PageController(initialPage: widget.initialIndex);
  final TransformationController _zoom = TransformationController();
  late int _index = widget.initialIndex;
  bool _zoomed = false;

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
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.cards[_index];
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final excluded = widget.viewModel.isExcluded(card);
        return Scaffold(
          appBar: AppBar(
            title: Text(card.name),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                tooltip: excluded ? 'Include in game' : 'Exclude from game',
                icon: Icon(excluded ? Icons.undo : Icons.block),
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
                  physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
                  itemCount: widget.cards.length,
                  onPageChanged: (page) {
                    _zoom.value = Matrix4.identity();
                    setState(() => _index = page);
                    widget.onIndexChanged?.call(page);
                  },
                  itemBuilder: (context, page) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: LayoutBuilder(
                      builder: (context, constraints) => InteractiveViewer(
                        transformationController: _zoom,
                        maxScale: 4,
                        panEnabled: _zoomed,
                        // Tall window: the file as is. Wide window: turned upright.
                        child: CardImage(
                          card: widget.cards[page],
                          quarterTurns: constraints.maxWidth > constraints.maxHeight ? 1 : 0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 600,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                ),
                child: CardTextPanel(card: card),
              ),
            ],
          ),
        );
      },
    );
  }
}
