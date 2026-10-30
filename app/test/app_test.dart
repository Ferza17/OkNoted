import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oknoted/app.dart';
import 'package:oknoted/core/providers/greeting_provider.dart';

void main() {
  testWidgets('shows the greeting from Rust', (tester) async {
    // Fake the Rust call: widget tests never load the native library.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [greetingProvider.overrideWithValue('Hello, test!')],
        child: const OkNotedApp(),
      ),
    );

    expect(find.text('Hello, test!'), findsOneWidget);
  });
}
