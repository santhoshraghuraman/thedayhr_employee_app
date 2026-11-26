import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thedayhr_employee_app/app.dart';
import 'package:thedayhr_employee_app/core/constants/storage_keys.dart';
import 'package:thedayhr_employee_app/core/services/local_storage_service.dart';
import 'package:thedayhr_employee_app/features/auth/domain/auth_repository.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    Map<String, Object> initialPrefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const TheDayHRApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('validates empty and invalid inputs on LoginScreen', (tester) async {
    await pumpApp(tester);

    expect(find.text('TheDayHR'), findsOneWidget);
    expect(find.text('Demo Employee Credentials'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('login_submit_button')));
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Employee ID or work email is required.'),
      findsOneWidget,
    );
    expect(find.text('Password is required.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('login_identifier_field')),
      'bad@email',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      '123',
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid work email address.'), findsOneWidget);
    expect(
      find.text('Password must be at least 6 characters.'),
      findsOneWidget,
    );
  });

  testWidgets('shows auth error for wrong credentials and signs in via Fill Demo Employee',
      (tester) async {
    await pumpApp(tester);

    await tester.enterText(
      find.byKey(const Key('login_identifier_field')),
      LocalAuthRepository.primaryDemo.employeeId,
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'WrongPass99',
    );
    await tester.ensureVisible(find.byKey(const Key('login_submit_button')));
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Invalid Employee ID/email or password'),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const Key('fill_demo_employee_button')),
    );
    await tester.tap(find.byKey(const Key('fill_demo_employee_button')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('login_submit_button')));
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text(LocalAuthRepository.primaryDemo.user.name), findsOneWidget);
    expect(find.byKey(const Key('foundation_logout_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('foundation_logout_button')));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to your account'), findsOneWidget);
  });

  testWidgets('restores authenticated session across app restart', (tester) async {
    final demoUser = LocalAuthRepository.primaryDemo.user;
    await pumpApp(
      tester,
      initialPrefs: {
        StorageKeys.authSession: jsonEncode(demoUser.toJson()),
      },
    );

    expect(find.text(demoUser.name), findsOneWidget);
    expect(find.text('Sign in to your account'), findsNothing);
  });
}
