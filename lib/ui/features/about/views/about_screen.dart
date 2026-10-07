import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:planespotting/ui/core/ui_constants.dart';
import 'package:url_launcher/url_launcher.dart';

const String _appName = 'Planespotting';
final Uri _scryfallUri = Uri.parse('https://scryfall.com');
final Uri _websiteUri = Uri.parse('https://forrestthe.dev');

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  Future<void> _openLink(Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Falls through to the message below.
    }
    if (!opened) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open ${uri.host}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: contentMaxWidth),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                _appName,
                style: textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              FutureBuilder<PackageInfo>(
                future: _info,
                builder: (context, snapshot) {
                  final info = snapshot.data;
                  return Text(
                    // A space while loading keeps the line's height, so nothing jumps.
                    info == null
                        ? ' '
                        : 'Version ${info.version} (${info.buildNumber})',
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Thanks for using this app. Made by Forrest.',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              Align(
                child: TextButton(
                  onPressed: () => _openLink(_websiteUri),
                  child: Text(_websiteUri.host),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Planespotting is unofficial Fan Content permitted under the Wizards of the Coast Fan Content '
                'Policy. It is not approved or endorsed by Wizards. Portions of the materials used are property '
                'of Wizards of the Coast. ©Wizards of the Coast LLC.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Card images and card data come from Scryfall. Scryfall is not affiliated with this app.',
                style: textTheme.bodyMedium,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _openLink(_scryfallUri),
                  child: const Text('scryfall.com'),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () async {
                    final info = await _info;
                    if (!context.mounted) return;
                    showLicensePage(
                      context: context,
                      applicationName: _appName,
                      applicationVersion: info.version,
                    );
                  },
                  child: const Text('Open-source licenses'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
