import 'package:flutter/material.dart';
import 'package:planespotting/data/repositories/card_repository.dart';
import 'package:planespotting/data/repositories/settings_repository.dart';
import 'package:planespotting/ui/core/ui_constants.dart';
import 'package:planespotting/ui/features/browser/view_models/deck_view_model.dart';

/// Opens the deck settings: which sets and types the game draws from, and the excluded cards.
Future<void> showDeckSheet(
  BuildContext context, {
  required CardRepository cardRepository,
  required SettingsRepository settingsRepository,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: contentMaxWidth),
    builder: (context) => _DeckSheet(cardRepository: cardRepository, settingsRepository: settingsRepository),
  );
}

class _DeckSheet extends StatefulWidget {
  const _DeckSheet({required this.cardRepository, required this.settingsRepository});

  final CardRepository cardRepository;
  final SettingsRepository settingsRepository;

  @override
  State<_DeckSheet> createState() => _DeckSheetState();
}

class _DeckSheetState extends State<_DeckSheet> {
  late final DeckViewModel viewModel = DeckViewModel(
    cardRepository: widget.cardRepository,
    settingsRepository: widget.settingsRepository,
  );

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Its own messenger, so the Undo SnackBar shows on the sheet and not behind it.
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, controller) => ListenableBuilder(
            listenable: viewModel,
            builder: (context, _) => ListView(
              controller: controller,
              children: [
                _DeckTotalTile(count: viewModel.deckCount),
                if (viewModel.excludedCount > 0) _ExcludedCardsTile(viewModel: viewModel),
                for (final section in viewModel.sections) _SectionTile(section: section),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// How many cards the game will draw from, across every setting and exclusion.
class _DeckTotalTile extends StatelessWidget {
  const _DeckTotalTile({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // An empty deck can't be played, so it reads as a warning.
    final empty = count == 0;
    return ListTile(
      leading: empty ? Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error) : null,
      title: Text('${cardCount(count)} in the deck', style: theme.textTheme.titleMedium),
      subtitle: empty
          ? Text('Turn on at least one set and type', style: TextStyle(color: theme.colorScheme.error))
          : null,
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.section});

  final DeckSection section;

  @override
  Widget build(BuildContext context) {
    if (section.items.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      title: Text(section.title),
      subtitle: Text('${cardCount(section.enabledCardCount)} enabled'),
      children: [
        CheckboxListTile(
          title: const Text('Select all'),
          value: section.allEnabled,
          onChanged: (value) => section.onSetAll(value ?? false),
        ),
        for (final item in section.items)
          CheckboxListTile(
            title: Text('${item.label} (${item.count})'),
            value: item.enabled,
            onChanged: (value) => item.onChanged(value ?? false),
          ),
      ],
    );
  }
}

/// Cards excluded one by one in the browser, with a shortcut to undo that.
class _ExcludedCardsTile extends StatelessWidget {
  const _ExcludedCardsTile({required this.viewModel});

  final DeckViewModel viewModel;

  Future<void> _restore(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final restored = await viewModel.restoreExcluded();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${cardCount(restored.length)} restored'),
        action: SnackBarAction(label: 'Undo', onPressed: () => viewModel.undoRestore(restored)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Excluded cards'),
      subtitle: Text('${cardCount(viewModel.excludedCount)} excluded individually'),
      trailing: TextButton(onPressed: () => _restore(context), child: const Text('Restore all')),
    );
  }
}
