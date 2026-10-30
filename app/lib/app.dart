import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/greeting_provider.dart';

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
      home: const _GreetingScreen(),
    );
  }
}

class _GreetingScreen extends ConsumerWidget {
  const _GreetingScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Text(
          ref.watch(greetingProvider),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
