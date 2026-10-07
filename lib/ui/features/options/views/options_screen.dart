import 'package:flutter/material.dart';
import 'package:planespotting/data/repositories/card_repository.dart';
import 'package:planespotting/data/repositories/settings_repository.dart';
import 'package:planespotting/routes.dart';
import 'package:planespotting/ui/core/ui_constants.dart';
import 'package:planespotting/ui/features/options/view_models/options_view_model.dart';

class OptionsScreen extends StatefulWidget {
  const OptionsScreen({
    super.key,
    required this.cardRepository,
    required this.settingsRepository,
  });

  final CardRepository cardRepository;
  final SettingsRepository settingsRepository;

  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  late final OptionsViewModel viewModel = OptionsViewModel(
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
    return Scaffold(
      appBar: AppBar(title: const Text('Options')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: contentMaxWidth),
          child: ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                const _SectionHeader('Game'),
                SwitchListTile(
                  title: const Text('Planeswalk automatically'),
                  subtitle: const Text(
                    'Moves to the next plane after a planeswalk roll',
                  ),
                  value: viewModel.autoPlaneswalk,
                  onChanged: viewModel.setAutoPlaneswalk,
                ),
                SwitchListTile(
                  title: const Text('Keep screen on during a game'),
                  value: viewModel.keepScreenOn,
                  onChanged: viewModel.setKeepScreenOn,
                ),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const _SectionHeader('Deck'),
                _DeckTotalTile(count: viewModel.deckCount),
                if (viewModel.excludedCount > 0)
                  _ExcludedCardsTile(viewModel: viewModel),
                for (final section in viewModel.sections)
                  _SectionTile(section: section),
              ],
            );
          },
          ),
        ),
      ),
    );
  }
}

/// A label that groups the tiles below it.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      // Roomy above (the gap between sections), tight below (the tiles it labels).
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
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

  final OptionSection section;

  @override
  Widget build(BuildContext context) {
    if (section.items.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      title: Text(section.title),
      subtitle: Text(
        '${cardCount(section.enabledCardCount)} enabled',
      ),
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

/// Cards excluded one by one in the card browser, with shortcuts to review or undo that.
class _ExcludedCardsTile extends StatelessWidget {
  const _ExcludedCardsTile({required this.viewModel});

  final OptionsViewModel viewModel;

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
    final count = viewModel.excludedCount;
    return Column(
      children: [
        ListTile(
          title: const Text('Excluded cards'),
          subtitle: Text('${cardCount(count)} excluded individually'),
        ),
        // Wraps onto two lines when there isn't room for both buttons side by side.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OverflowBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pushNamed(context, browserRoute),
                child: const Text('Browse cards'),
              ),
              TextButton(
                onPressed: () => _restore(context),
                child: const Text('Restore all'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
