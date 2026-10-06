import 'package:flutter/material.dart';
import 'package:planespotting/about.dart';
import 'package:planespotting/data/repositories/card_repository.dart';
import 'package:planespotting/data/repositories/settings_repository.dart';
import 'package:planespotting/data/services/card_asset_service.dart';
import 'package:planespotting/data/services/settings_service.dart';
import 'package:planespotting/planespotting.dart';
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
        planeschaseStartRoute: (context) => PlaneschasingStartPage(
              cardRepository: cardRepository,
              settingsRepository: settingsRepository,
            ),
        optionsRoute: (context) => OptionsScreen(
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
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MenuButton(text: 'Start', onPressed: () => Navigator.pushNamed(context, planeschaseStartRoute), isMain: true),
            MenuButton(text: 'Options', onPressed: () => Navigator.pushNamed(context, optionsRoute)),
            MenuButton(text: 'About', onPressed: () => Navigator.pushNamed(context, aboutRoute)),
          ],
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
      child: SizedBox(width: 300, child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isMain ? Colors.deepPurpleAccent : null,
          foregroundColor: isMain ? Colors.white : null,
        ),
        onPressed: onPressed,
        child: Text(text),
      ),)
    );
  }
}
