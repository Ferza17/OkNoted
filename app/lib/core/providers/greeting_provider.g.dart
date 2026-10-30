// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'greeting_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Greeting computed in Rust; proves the Dart <-> Rust bridge works (M0).

@ProviderFor(greeting)
final greetingProvider = GreetingProvider._();

/// Greeting computed in Rust; proves the Dart <-> Rust bridge works (M0).

final class GreetingProvider extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Greeting computed in Rust; proves the Dart <-> Rust bridge works (M0).
  GreetingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'greetingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$greetingHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return greeting(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$greetingHash() => r'6e075de35820a81a1dde9b3464c3c02fdb3000b4';
