// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spike_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(spikeApi)
final spikeApiProvider = SpikeApiProvider._();

final class SpikeApiProvider
    extends $FunctionalProvider<SpikeApi, SpikeApi, SpikeApi>
    with $Provider<SpikeApi> {
  SpikeApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'spikeApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$spikeApiHash();

  @$internal
  @override
  $ProviderElement<SpikeApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SpikeApi create(Ref ref) {
    return spikeApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpikeApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpikeApi>(value),
    );
  }
}

String _$spikeApiHash() => r'ef69c5c5539749b81461742470bf52737c30b5e4';
