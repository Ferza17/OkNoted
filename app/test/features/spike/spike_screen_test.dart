import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oknoted/app.dart';
import 'package:oknoted/core/providers/greeting_provider.dart';
import 'package:oknoted/features/spike/application/spike_api.dart';

class _FakeSpikeApi implements SpikeApi {
  var _rows = BigInt.zero;
  final sent = <String>[];

  @override
  Future<void> initSqlite() async {}

  @override
  Future<BigInt> writeRows(int rows) async => _rows += BigInt.from(rows);

  @override
  Future<BigInt> readRows() async => _rows;

  @override
  String loroRoundtrip() => 'Hello, WASM Loro!';

  @override
  Stream<SpikeRtcEvent> connect(String relayUrl, String room) =>
      Stream.fromIterable(const [
        SpikeRtcEvent.joined(me: 'me1'),
        SpikeRtcEvent.connected(peer: 'peer2'),
        SpikeRtcEvent.message(text: 'hi there'),
      ]);

  @override
  void send(String text) => sent.add(text);
}

void main() {
  late _FakeSpikeApi api;

  Future<void> pumpScreen(WidgetTester tester) async {
    api = _FakeSpikeApi();
    // Tall enough that the whole spike page (and its WebRTC log) is laid out.
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          greetingProvider.overrideWithValue('Hello, test!'),
          spikeApiProvider.overrideWithValue(api),
        ],
        child: const OkNotedApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('writes and reads SQLite rows', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Write 1,000 rows'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Write 1,000 rows'));
    await tester.pumpAndSettle();
    expect(find.text('2000 rows stored'), findsOneWidget);
  });

  testWidgets('shows the merged Loro text', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Run round-trip'));
    await tester.pump();
    expect(find.text('Merged text: Hello, WASM Loro!'), findsOneWidget);
  });

  testWidgets('logs WebRTC events and sends a message', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    expect(find.text('Joined as me1'), findsOneWidget);
    expect(find.text('DataChannel open to peer2'), findsOneWidget);
    expect(find.text('Received: hi there'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Message'), 'yo');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(api.sent, ['yo']);
    expect(find.text('Sent: yo'), findsOneWidget);
  });
}
