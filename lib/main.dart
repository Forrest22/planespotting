import 'package:flutter/material.dart';
import 'package:planespotting/about.dart';
import 'package:planespotting/data/repositories/card_repository.dart';
import 'package:planespotting/data/repositories/settings_repository.dart';
import 'package:planespotting/data/services/card_asset_service.dart';
import 'package:planespotting/data/services/settings_service.dart';
import 'package:planespotting/ui/features/browser/views/browser_screen.dart';
import 'package:planespotting/ui/features/game/views/game_screen.dart';
import 'package:planespotting/ui/features/options/views/options_screen.dart';
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cardRepository = CardRepository(CardAssetService());
  await cardRepository.load();
  final settingsRepository = SettingsRepository(await SettingsService.create());
  await settingsRepository.load(cardRepository.sets);

  runApp(MyApp(cardRepository: cardRepository, settingsRepository: settingsRepository));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.cardRepository, required this.settingsRepository});

  final CardRepository cardRepository;
  final SettingsRepository settingsRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MenuScreen(),
      routes: {
        planeschaseStartRoute: (context) => GameScreen(
              cardRepository: cardRepository,
              settingsRepository: settingsRepository,
            ),
        optionsRoute: (context) => OptionsScreen(
              cardRepository: cardRepository,
              settingsRepository: settingsRepository,
            ),
        browserRoute: (context) => BrowserScreen(
              cardRepository: cardRepository,
              settingsRepository: settingsRepository,
            ),
        aboutRoute: (context) => AboutPage(),
      },
    );
  }
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Planespotting'), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
      // Scrolls when the window is short (or the text is large), instead of overflowing.
      body: Stack(
        children: [
          const _TextFieldWarmUp(),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MenuButton(text: 'Start', onPressed: () => Navigator.pushNamed(context, planeschaseStartRoute), isMain: true),
                  MenuButton(text: 'Browse cards', onPressed: () => Navigator.pushNamed(context, browserRoute)),
                  MenuButton(text: 'Options', onPressed: () => Navigator.pushNamed(context, optionsRoute)),
                  MenuButton(text: 'About', onPressed: () => Navigator.pushNamed(context, aboutRoute)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lays out a text field and its icons once, out of sight, when the menu first appears. The first
/// text field in the process is slow to lay out (about 50 ms: text shaping and the icon font start
/// cold), which otherwise lands as a pause the first time the card browser opens.
class _TextFieldWarmUp extends StatelessWidget {
  const _TextFieldWarmUp();

  @override
  Widget build(BuildContext context) {
    return const ExcludeFocus(
      child: ExcludeSemantics(
        child: Offstage(
          child: SizedBox(
            width: 200,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
                suffixIcon: Icon(Icons.clear),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MenuButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isMain;

  const MenuButton({super.key, required this.text, required this.onPressed, this.isMain = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      // Up to 300 wide, narrower in a narrow window.
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isMain ? Colors.deepPurpleAccent : null,
              foregroundColor: isMain ? Colors.white : null,
            ),
            onPressed: onPressed,
            child: Text(text),
          ),
        ),
      )
    );
  }
}
