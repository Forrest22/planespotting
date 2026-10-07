import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:planespotting/ui/features/about/views/about_screen.dart';
import 'package:planespotting/data/repositories/card_repository.dart';
import 'package:planespotting/data/repositories/settings_repository.dart';
import 'package:planespotting/data/services/card_asset_service.dart';
import 'package:planespotting/data/services/settings_service.dart';
import 'package:planespotting/ui/core/theme.dart';
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
      title: 'Planespotting',
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      themeMode: ThemeMode.system,
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
        aboutRoute: (context) => AboutScreen(),
      },
    );
  }
}

/// The magnifying-glass-over-cards artwork (also the launcher icon), tinted to the theme.
class _MenuLogo extends StatelessWidget {
  const _MenuLogo();

  @override
  Widget build(BuildContext context) {
    // Smaller in a short window (e.g. a phone on its side) to leave room for the buttons.
    final size = MediaQuery.sizeOf(context).height < 520 ? 80.0 : 120.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SvgPicture.asset(
        'assets/die/cards-lens.svg',
        width: size,
        height: size,
        excludeFromSemantics: true, // decoration
        colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planespotting')),
      // Scrolls when the window is short (or the text is large), instead of overflowing.
      body: Stack(
        children: [
          const _TextFieldWarmUp(),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _MenuLogo(),
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
          // The main action is a solid button; the others are a quieter tonal shade.
          child: isMain
              ? FilledButton(onPressed: onPressed, child: Text(text))
              : FilledButton.tonal(onPressed: onPressed, child: Text(text)),
        ),
      )
    );
  }
}
