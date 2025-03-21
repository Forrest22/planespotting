import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';

// Create a new class OptionSection which has a title and list of options
class OptionSection {
  final String sectionTitle;
  final List<String> options;

  OptionSection({required this.sectionTitle, required this.options});
}

class OptionsPage extends StatefulWidget {
  const OptionsPage({super.key});

  @override
  OptionsPageState createState() => OptionsPageState();
}

final List<OptionSection> optionSections = [
  OptionSection(sectionTitle: 'Sets', options: ['Planechase Anthology Planes', 'March of the Machine Commander']),
  OptionSection(sectionTitle: 'Types', options: ['Planes', 'Phenomena']),
];

class OptionsPageState extends State<OptionsPage> {
  // List of OptionSections, each containing a title and list of options


  // Map to store the state of each checkbox for each section
  Map<String, Map<String, bool>> sectionCheckboxes = {};

  // Function to load the saved checkbox states from SharedPreferences
  Future<void> loadCheckboxState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Initialize the sectionCheckboxes map for all sections
    for (var section in optionSections) {
      // If the section doesn't have an entry in sectionCheckboxes, initialize it
      sectionCheckboxes[section.sectionTitle] ??= {};

      for (var option in section.options) {
        // Load each checkbox's state from SharedPreferences
        bool value = prefs.getBool('${section.sectionTitle}_$option') ?? true;
        sectionCheckboxes[section.sectionTitle]![option] = value;
      }
    }

    // Ensure the UI is rebuilt after loading data
    setState(() {});
    debugPrint('sectionCheckboxes: $sectionCheckboxes');
}

  // Function to save the checkbox states to SharedPreferences
  Future<void> _saveCheckboxState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    for (var section in optionSections) {
      for (var option in section.options) {
        // Save each checkbox's state to SharedPreferences
        bool value = sectionCheckboxes[section.sectionTitle]?[option] ?? false;
        prefs.setBool('${section.sectionTitle}_$option', value);
      }
    }
  }

  // Function to handle the "Select All" checkbox for each section
  void _toggleSelectAll(int sectionIndex, bool? value) {
    setState(() {
      // Set the value for all checkboxes in the selected section
      sectionCheckboxes[optionSections[sectionIndex].sectionTitle]?.updateAll((key, _) => value ?? false);
      // Save the updated state to SharedPreferences
      _saveCheckboxState();
    });
  }

  // Function to handle an individual checkbox toggle within a section
  void _toggleCheckbox(int sectionIndex, String optionName, bool? value) {
    setState(() {
      sectionCheckboxes[optionSections[sectionIndex].sectionTitle]?[optionName] = value ?? false;
      // Save the updated state to SharedPreferences
      _saveCheckboxState();
    });
  }

  @override
  void initState() {
    super.initState();
    // Load saved state from SharedPreferences and then rebuild the UI
    loadCheckboxState();
  }

  @override
  void dispose() {
    // Save the checkbox state when navigating away from the page
    _saveCheckboxState();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Options'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: sectionCheckboxes.isEmpty // Wait until data is loaded
            ? Center(child: CircularProgressIndicator()) // Show a loading indicator until data is loaded
            : ListView(
                children: 
                optionSections.asMap().entries.map((entry) {
                  int sectionIndex = entry.key;
                  OptionSection section = entry.value;

                  // Make sure the sectionCheckboxes map is initialized for this section
                  if (sectionCheckboxes[section.sectionTitle] == null) {
                    sectionCheckboxes[section.sectionTitle] = {};
                    for (var option in section.options) {
                      sectionCheckboxes[section.sectionTitle]![option] = false;
                    }
                  }

                  // Check if all options in the section are selected to update "Select All"
                  bool selectAll = sectionCheckboxes[section.sectionTitle]!.values.every((checked) => checked);

                  return ExpansionTile(
                    title: Text(section.sectionTitle),
                    children: [
                      // Select All Checkbox for the section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end, // Align to the right
                        children: [
                          Checkbox(
                            value: selectAll,
                            onChanged: (bool? value) {
                              _toggleSelectAll(sectionIndex, value);
                            },
                          ),
                          Text('Select All'),
                        ],
                      ),
                      // Checkboxes for each option in the section
                      ...section.options.map((optionName) {
                        return CheckboxListTile(
                          title: Text(optionName),
                          value: sectionCheckboxes[section.sectionTitle]?[optionName] ?? false,
                          onChanged: (bool? value) {
                            _toggleCheckbox(sectionIndex, optionName, value);
                          },
                        );
                      }),
                      // TODO: add in count?
                    ],
                  );
                }).toList(),
              ),
      ),
    );
  }
}
