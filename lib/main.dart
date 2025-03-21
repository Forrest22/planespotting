import 'package:flutter/material.dart';
import 'package:planespotting/about.dart';
import 'package:planespotting/options.dart';
import 'package:planespotting/planespotting.dart';
import 'routes.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MenuScreen(),
      routes: {
        planeschaseStartRoute: (context) => PlaneschasingStartPage(),
        optionsRoute: (context) => OptionsPage(),
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
            // MenuButton(text: 'Options', onPressed: () => Navigator.pushNamed(context, optionsRoute)),
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

