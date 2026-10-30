import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../src/rust/api/simple.dart' as rust;

part 'greeting_provider.g.dart';

/// Greeting computed in Rust; proves the Dart <-> Rust bridge works (M0).
@riverpod
String greeting(Ref ref) => rust.greet(name: 'OkNoted');
