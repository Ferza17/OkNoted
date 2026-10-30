import 'package:flutter/material.dart';

import 'features/spike/presentation/spike_screen.dart';
import 'l10n/app_localizations.dart';

/// Root widget of the OkNoted app.
class OkNotedApp extends StatelessWidget {
  const OkNotedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OkNoted',
      theme: ThemeData(colorSchemeSeed: Colors.blueGrey),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blueGrey,
        brightness: Brightness.dark,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SpikeScreen(),
    );
  }
}
