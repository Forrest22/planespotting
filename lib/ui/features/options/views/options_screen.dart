import 'package:flutter/material.dart';
import 'package:planespotting/data/repositories/card_repository.dart';
import 'package:planespotting/data/repositories/settings_repository.dart';
import 'package:planespotting/routes.dart';
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
      appBar: AppBar(
        title: const Text('Options'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            return ListView(
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
    return ListTile(
      title: Text(
        '$count ${count == 1 ? 'card' : 'cards'} in the deck',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle:
          count == 0 ? const Text('Turn on at least one set and type') : null,
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
        '${section.enabledCardCount} ${section.enabledCardCount == 1 ? 'card' : 'cards'} enabled',
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Checkbox(
              value: section.allEnabled,
              onChanged: (value) => section.onSetAll(value ?? false),
            ),
            const Text('Select All'),
          ],
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

  @override
  Widget build(BuildContext context) {
    final count = viewModel.excludedCount;
    return Column(
      children: [
        ListTile(
          title: const Text('Excluded cards'),
          subtitle: Text(
            '$count ${count == 1 ? 'card' : 'cards'} excluded individually',
          ),
        ),
        // Wraps onto two lines when there isn't room for both buttons side by side.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OverflowBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pushNamed(context, browserRoute),
                child: const Text('Browse'),
              ),
              TextButton(
                onPressed: viewModel.restoreExcluded,
                child: const Text('Restore all'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
