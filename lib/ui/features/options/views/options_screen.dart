import 'package:flutter/material.dart';
import 'package:planespotting/data/repositories/card_repository.dart';
import 'package:planespotting/data/repositories/settings_repository.dart';
import 'package:planespotting/routes.dart';
import 'package:planespotting/ui/features/options/view_models/options_view_model.dart';

class OptionsScreen extends StatefulWidget {
  const OptionsScreen({super.key, required this.cardRepository, required this.settingsRepository});

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
                if (viewModel.excludedCount > 0) _ExcludedCardsTile(viewModel: viewModel),
                for (final section in viewModel.sections) _SectionTile(section: section),
              ],
            );
          },
        ),
      ),
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
          subtitle: Text('$count ${count == 1 ? 'card' : 'cards'} excluded individually'),
        ),
        // Wraps onto two lines when there isn't room for both buttons side by side.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OverflowBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.pushNamed(context, browserRoute), child: const Text('Browse')),
              TextButton(onPressed: viewModel.restoreExcluded, child: const Text('Restore all')),
            ],
          ),
        ),
      ],
    );
  }
}
