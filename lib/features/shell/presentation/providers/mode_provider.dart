import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Top-level operational modes inside the authenticated workspace.
enum AppMode {
  hrms,
  chat,
}

/// Manages only the active workspace mode, leaving HRMS and Chat states
/// completely independent.
class AppModeNotifier extends Notifier<AppMode> {
  @override
  AppMode build() => AppMode.hrms;

  void setMode(AppMode mode) {
    if (state != mode) {
      state = mode;
    }
  }
}

/// Global mode switcher provider.
final appModeProvider = NotifierProvider<AppModeNotifier, AppMode>(
  AppModeNotifier.new,
);

