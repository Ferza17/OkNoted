import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../src/rust/api/spike.dart' as rust;

// Event types only: widgets switch on them but never call Rust directly.
export '../../../src/rust/api/spike.dart'
    show
        SpikeRtcEvent,
        SpikeRtcEvent_Joined,
        SpikeRtcEvent_PeerJoined,
        SpikeRtcEvent_PeerLeft,
        SpikeRtcEvent_Connected,
        SpikeRtcEvent_Message,
        SpikeRtcEvent_Closed,
        SpikeRtcEvent_Error;

part 'spike_api.g.dart';

/// M1 spike calls into Rust (see docs/decisions/0007). Replaced from M2 on.
class SpikeApi {
  const SpikeApi();

  /// Starts the database worker; must run before the other SQLite calls.
  Future<void> initSqlite() => rust.spikeSqliteInit();

  Future<BigInt> writeRows(int rows) => rust.spikeSqliteInsert(rows: rows);

  Future<BigInt> readRows() => rust.spikeSqliteCount();

  String loroRoundtrip() => rust.spikeLoroRoundtrip();

  Stream<rust.SpikeRtcEvent> connect(String relayUrl, String room) =>
      rust.spikeWebrtcConnect(relayUrl: relayUrl, room: room);

  void send(String text) => rust.spikeWebrtcSend(text: text);
}

@riverpod
SpikeApi spikeApi(Ref ref) => const SpikeApi();
