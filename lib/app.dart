import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thedayhr_employee_app/core/theme/app_theme.dart';
import 'package:thedayhr_employee_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:thedayhr_employee_app/features/auth/presentation/screens/login_screen.dart';
import 'package:thedayhr_employee_app/features/shell/presentation/providers/mode_provider.dart';
import 'package:thedayhr_employee_app/features/shell/presentation/screens/app_shell_screen.dart';

/// Root widget configuring Material 3 theme and auth-gated routing.
class TheDayHRApp extends ConsumerWidget {
  const TheDayHRApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reset mode back to HRMS whenever an employee signs out.
    ref.listen<bool>(
      authProvider.select((auth) => auth.isAuthenticated),
      (previous, isAuthenticated) {
        if (previous == true && !isAuthenticated) {
          ref.read(appModeProvider.notifier).setMode(AppMode.hrms);
        }
      },
    );

    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'TheDayHR Employee',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: authState.isAuthenticated
            ? AppShellScreen(
                key: ValueKey('shell_${authState.user!.employeeId}'),
              )
            : const LoginScreen(key: ValueKey('login_screen')),
      ),
    );
  }
}
