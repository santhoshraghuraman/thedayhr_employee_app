import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Clock source function that can be overridden in unit/widget tests for
/// deterministic time assertions.
final currentTimeFunctionProvider = Provider<DateTime Function()>((ref) {
  return DateTime.now;
});

/// Emits the current local [DateTime] every second for live dashboard clocks
/// and elapsed working-hours counters.
final clockProvider = StreamProvider<DateTime>((ref) async* {
  final nowFn = ref.watch(currentTimeFunctionProvider);
  yield nowFn();
  yield* Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => nowFn(),
  );
});

