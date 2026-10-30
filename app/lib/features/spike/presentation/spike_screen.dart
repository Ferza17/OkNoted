import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/greeting_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../application/spike_api.dart';

/// M1 web risk spike: SQLite in OPFS, Loro, and WebRTC between two tabs.
class SpikeScreen extends ConsumerStatefulWidget {
  const SpikeScreen({super.key});

  @override
  ConsumerState<SpikeScreen> createState() => _SpikeScreenState();
}

typedef _Line = String Function(AppLocalizations l10n);

class _SpikeScreenState extends ConsumerState<SpikeScreen> {
  final _relay = TextEditingController(
    text: 'ws://${Uri.base.host.isEmpty ? '127.0.0.1' : Uri.base.host}:8787',
  );
  final _room = TextEditingController(text: 'spike');
  final _message = TextEditingController();
  final _log = <_Line>[];
  StreamSubscription<SpikeRtcEvent>? _events;
  Future<void>? _sqliteReady;
  _Line? _sqliteStatus;
  _Line? _loroStatus;

  SpikeApi get _api => ref.read(spikeApiProvider);

  @override
  void dispose() {
    _events?.cancel();
    _relay.dispose();
    _room.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _sqlite(Future<BigInt> Function() action) async {
    try {
      await (_sqliteReady ??= _api.initSqlite());
      final rows = (await action()).toString();
      setState(() => _sqliteStatus = (l10n) => l10n.sqliteRows(rows));
    } catch (error) {
      _sqliteReady = null;
      setState(() => _sqliteStatus = (l10n) => l10n.errorDetail('$error'));
    }
  }

  void _runLoro() {
    try {
      final text = _api.loroRoundtrip();
      setState(() => _loroStatus = (l10n) => l10n.loroResult(text));
    } catch (error) {
      setState(() => _loroStatus = (l10n) => l10n.errorDetail('$error'));
    }
  }

  void _connect() {
    _events?.cancel();
    setState(_log.clear);
    _events = _api.connect(_relay.text, _room.text).listen(
      (event) => setState(() => _log.add(_describe(event))),
      onError: (Object error) =>
          setState(() => _log.add((l10n) => l10n.errorDetail('$error'))),
    );
  }

  void _send() {
    final text = _message.text;
    if (text.isEmpty) return;
    try {
      _api.send(text);
      _message.clear();
      setState(() => _log.add((l10n) => l10n.rtcSent(text)));
    } catch (error) {
      setState(() => _log.add((l10n) => l10n.errorDetail('$error')));
    }
  }

  _Line _describe(SpikeRtcEvent event) => switch (event) {
    SpikeRtcEvent_Joined(:final me) => (l10n) => l10n.rtcJoined(me),
    SpikeRtcEvent_PeerJoined(:final peer) => (l10n) => l10n.rtcPeerJoined(peer),
    SpikeRtcEvent_PeerLeft(:final peer) => (l10n) => l10n.rtcPeerLeft(peer),
    SpikeRtcEvent_Connected(:final peer) => (l10n) => l10n.rtcConnected(peer),
    SpikeRtcEvent_Message(:final text) => (l10n) => l10n.rtcReceived(text),
    SpikeRtcEvent_Closed() => (l10n) => l10n.rtcClosed,
    SpikeRtcEvent_Error(:final message) => (l10n) => l10n.errorDetail(message),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.spikeTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            ref.watch(greetingProvider),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          _Section(
            title: l10n.sqliteSection,
            actions: [
              FilledButton(
                onPressed: () => _sqlite(() => _api.writeRows(1000)),
                child: Text(l10n.sqliteWrite),
              ),
              OutlinedButton(
                onPressed: () => _sqlite(_api.readRows),
                child: Text(l10n.sqliteRead),
              ),
            ],
            lines: [?_sqliteStatus?.call(l10n)],
          ),
          _Section(
            title: l10n.loroSection,
            actions: [
              FilledButton(onPressed: _runLoro, child: Text(l10n.loroRun)),
            ],
            lines: [?_loroStatus?.call(l10n)],
          ),
          _Section(
            title: l10n.rtcSection,
            fields: [
              TextField(
                controller: _relay,
                decoration: InputDecoration(labelText: l10n.rtcRelay),
              ),
              TextField(
                controller: _room,
                decoration: InputDecoration(labelText: l10n.rtcRoom),
              ),
              TextField(
                controller: _message,
                decoration: InputDecoration(labelText: l10n.rtcMessage),
                onSubmitted: (_) => _send(),
              ),
            ],
            actions: [
              FilledButton(onPressed: _connect, child: Text(l10n.rtcConnect)),
              OutlinedButton(onPressed: _send, child: Text(l10n.rtcSend)),
            ],
            lines: [for (final line in _log) line(l10n)],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.actions,
    required this.lines,
    this.fields = const [],
  });

  final String title;
  final List<Widget> fields;
  final List<Widget> actions;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            ...fields,
            Wrap(spacing: 8, runSpacing: 8, children: actions),
            for (final line in lines) Text(line),
          ],
        ),
      ),
    );
  }
}
