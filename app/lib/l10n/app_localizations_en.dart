// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get spikeTitle => 'Web risk spike (M1)';

  @override
  String get sqliteSection => 'SQLite in OPFS';

  @override
  String get sqliteWrite => 'Write 1,000 rows';

  @override
  String get sqliteRead => 'Read rows';

  @override
  String sqliteRows(String count) {
    return '$count rows stored';
  }

  @override
  String get loroSection => 'Loro CRDT';

  @override
  String get loroRun => 'Run round-trip';

  @override
  String loroResult(String text) {
    return 'Merged text: $text';
  }

  @override
  String get rtcSection => 'WebRTC between tabs';

  @override
  String get rtcRelay => 'Relay URL';

  @override
  String get rtcRoom => 'Room';

  @override
  String get rtcConnect => 'Connect';

  @override
  String get rtcMessage => 'Message';

  @override
  String get rtcSend => 'Send';

  @override
  String rtcJoined(String me) {
    return 'Joined as $me';
  }

  @override
  String rtcPeerJoined(String peer) {
    return 'Peer $peer joined';
  }

  @override
  String rtcPeerLeft(String peer) {
    return 'Peer $peer left';
  }

  @override
  String rtcConnected(String peer) {
    return 'DataChannel open to $peer';
  }

  @override
  String rtcReceived(String text) {
    return 'Received: $text';
  }

  @override
  String rtcSent(String text) {
    return 'Sent: $text';
  }

  @override
  String get rtcClosed => 'Connection closed';

  @override
  String errorDetail(String detail) {
    return 'Error: $detail';
  }
}
