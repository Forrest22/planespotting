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
                  _DeckTile(count: viewModel.deckCount),
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

/// How many cards the game will draw from, and the way into the browser where the deck is edited.
class _DeckTile extends StatelessWidget {
  const _DeckTile({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // An empty deck can't be played, so it reads as a warning.
    final empty = count == 0;
    return ListTile(
      leading: empty ? Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error) : null,
      title: Text('${cardCount(count)} in the deck', style: theme.textTheme.titleMedium),
      subtitle: Text(
        empty ? 'Turn on at least one set and type in Browse cards' : 'Choose sets, types and cards in Browse cards',
        style: empty ? TextStyle(color: theme.colorScheme.error) : null,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pushNamed(context, browserRoute),
    );
  }
}
