import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:planespotting/options.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlaneschasingStartPage extends StatefulWidget {
  const PlaneschasingStartPage({super.key});

  @override
  PlaneschasingStartPageState createState() => PlaneschasingStartPageState();
}

class PlaneschasingStartPageState extends State<PlaneschasingStartPage> {
  bool _isExpanded = false;

  // Example image URL or asset
  String _imagePath = "loading";

  // Function to handle reroll (change the image path or do any logic)
  void _reroll() async {
    // Logic to change the image (or randomize)
    // 1. Get options
    // savedOptions = getSavedOptions()

    // 2. Get potential cards
    final images = json.decode(await rootBundle.loadString('AssetManifest.json')).keys
    .where((String key) => key.contains('assets/planeschase/'))
    .toList();

    // 3. Randomly pick one
    int min = 0;
    int max = images.length-1;
    var rand = Random();
    int r = min + rand.nextInt(max - min);
    String imageName  = images[r].toString();
    
    setState(() {
      _imagePath = imageName; // Update with new image
    });
  }

  // Function to handle image rotation
  void _rotate() {
    // Logic to rotate the image (you can modify the angle as needed)
    setState(() {
      // Toggle the rotation angle
      _imageRotation = (_imageRotation + 90) % 360;
    });
  }

  double _imageRotation = 90;

  @override
  void initState() {
    super.initState(); // make sure this is called in the beggining
    _reroll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Planeschasing")),
      body: Stack(
        children: [
          Center(
            child: (_imagePath == "loading")? CircularProgressIndicator() : Transform.rotate(
              angle: _imageRotation * 3.14159 / 180, // Rotate image based on angle
              child: Image.asset(_imagePath), // Display image
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 500),
              child: _isExpanded
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Reroll Button
                        IconButton(
                          key: ValueKey('reroll'),
                          icon: Icon(Icons.autorenew),
                          onPressed: _reroll,
                          tooltip: 'New Card',
                        ),
                        SizedBox(width: 10),
                        // Rotate Button
                        IconButton(
                          key: ValueKey('rotate'),
                          icon: Icon(Icons.rotate_right),
                          onPressed: _rotate,
                          tooltip: 'Rotate Image',
                        ),
                      ],
                    )
                  : FloatingActionButton(
                      key: ValueKey('fab'),
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Icon(Icons.add),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
