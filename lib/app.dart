import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thedayhr_employee_app/core/theme/app_theme.dart';
import 'package:thedayhr_employee_app/features/auth/domain/employee_user.dart';
import 'package:thedayhr_employee_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:thedayhr_employee_app/features/auth/presentation/screens/login_screen.dart';

/// Root widget configuring Material 3 theme and auth-gated routing.
class TheDayHRApp extends ConsumerWidget {
  const TheDayHRApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            ? _AuthenticatedFoundationView(
                key: ValueKey(authState.user!.employeeId),
                user: authState.user!,
              )
            : const LoginScreen(key: ValueKey('login_screen')),
      ),
    );
  }
}

/// Temporary authenticated view for Phase 3 verification before HRMS & Chat
/// modules are implemented in Phase 4.
class _AuthenticatedFoundationView extends ConsumerWidget {
  const _AuthenticatedFoundationView({
    super.key,
    required this.user,
  });

  final EmployeeUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TheDayHR Workspace'),
        actions: [
          TextButton.icon(
            key: const Key('foundation_logout_button'),
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign Out'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          user.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user.designation} • ${user.department}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Chip(label: Text('${user.employeeId} • ${user.email}')),
                      const SizedBox(height: 16),
                      const Text(
                        'Authentication and local session persistence are active. HRMS and Chat modules will be added next.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

