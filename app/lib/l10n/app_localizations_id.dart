// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get spikeTitle => 'Uji risiko web (M1)';

  @override
  String get sqliteSection => 'SQLite di OPFS';

  @override
  String get sqliteWrite => 'Tulis 1.000 baris';

  @override
  String get sqliteRead => 'Baca baris';

  @override
  String sqliteRows(String count) {
    return '$count baris tersimpan';
  }

  @override
  String get loroSection => 'CRDT Loro';

  @override
  String get loroRun => 'Jalankan uji bolak-balik';

  @override
  String loroResult(String text) {
    return 'Teks gabungan: $text';
  }

  @override
  String get rtcSection => 'WebRTC antar tab';

  @override
  String get rtcRelay => 'URL relay';

  @override
  String get rtcRoom => 'Ruang';

  @override
  String get rtcConnect => 'Hubungkan';

  @override
  String get rtcMessage => 'Pesan';

  @override
  String get rtcSend => 'Kirim';

  @override
  String rtcJoined(String me) {
    return 'Bergabung sebagai $me';
  }

  @override
  String rtcPeerJoined(String peer) {
    return 'Rekan $peer bergabung';
  }

  @override
  String rtcPeerLeft(String peer) {
    return 'Rekan $peer keluar';
  }

  @override
  String rtcConnected(String peer) {
    return 'DataChannel terbuka ke $peer';
  }

  @override
  String rtcReceived(String text) {
    return 'Diterima: $text';
  }

  @override
  String rtcSent(String text) {
    return 'Terkirim: $text';
  }

  @override
  String get rtcClosed => 'Koneksi ditutup';

  @override
  String errorDetail(String detail) {
    return 'Galat: $detail';
  }
}
