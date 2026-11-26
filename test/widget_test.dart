import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thedayhr_employee_app/app.dart';
import 'package:thedayhr_employee_app/core/constants/storage_keys.dart';
import 'package:thedayhr_employee_app/core/services/local_storage_service.dart';
import 'package:thedayhr_employee_app/features/auth/domain/auth_repository.dart';
import 'package:thedayhr_employee_app/features/hrms/presentation/providers/clock_provider.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    Map<String, Object> initialPrefs = const {},
    DateTime Function()? nowFn,
    Stream<DateTime>? clockStream,
  }) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    final prefs = await SharedPreferences.getInstance();
    final defaultNow = DateTime(2026, 11, 26, 9, 30, 0);
    final resolvedNowFn = nowFn ?? () => defaultNow;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentTimeFunctionProvider.overrideWithValue(resolvedNowFn),
          clockProvider.overrideWith(
            (ref) => clockStream ?? Stream<DateTime>.value(resolvedNowFn()),
          ),
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

  testWidgets(
      'navigates from Login to HRMS Dashboard and signs out cleanly',
      (tester) async {
    await pumpApp(tester);

    await tester.ensureVisible(
      find.byKey(const Key('fill_demo_employee_button')),
    );
    await tester.tap(find.byKey(const Key('fill_demo_employee_button')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('login_submit_button')));
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    final demoUser = LocalAuthRepository.primaryDemo.user;
    expect(find.text(demoUser.name), findsOneWidget);
    expect(find.textContaining(demoUser.employeeId), findsOneWidget);
    expect(find.text('HRMS Mode'), findsOneWidget);
    expect(find.byKey(const Key('hrms_live_clock_text')), findsOneWidget);

    await tester.tap(find.byKey(const Key('shell_logout_button')));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to your account'), findsOneWidget);
  });

  testWidgets(
      'check-in, live elapsed timer, mode switching preservation, check-out, and attendance history flow',
      (tester) async {
    final demoUser = LocalAuthRepository.primaryDemo.user;
    var currentTime = DateTime(2026, 11, 26, 9, 0, 0);
    final clockController = StreamController<DateTime>.broadcast();
    addTearDown(clockController.close);

    await pumpApp(
      tester,
      initialPrefs: {
        StorageKeys.authSession: jsonEncode(demoUser.toJson()),
      },
      nowFn: () => currentTime,
      clockStream: clockController.stream,
    );
    clockController.add(currentTime);
    await tester.pumpAndSettle();

    // Initially not checked in: Check In enabled, Check Out disabled.
    expect(find.text('Not Checked In'), findsOneWidget);
    final checkInButton = tester.widget<FilledButton>(
      find.byKey(const Key('hrms_check_in_button')),
    );
    final checkOutButtonBefore = tester.widget<FilledButton>(
      find.byKey(const Key('hrms_check_out_button')),
    );
    expect(checkInButton.onPressed, isNotNull);
    expect(checkOutButtonBefore.onPressed, isNull);

    // Perform Check In.
    await tester.ensureVisible(find.byKey(const Key('hrms_check_in_button')));
    await tester.tap(find.byKey(const Key('hrms_check_in_button')));
    await tester.pumpAndSettle();

    expect(find.text('Checked In • Active Shift'), findsOneWidget);

    // Advance time by 2 hours 15 minutes 10 seconds and emit clock tick.
    currentTime = DateTime(2026, 11, 26, 11, 15, 10);
    clockController.add(currentTime);
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(find.byKey(const Key('hrms_elapsed_timer_text')))
          .data,
      '02:15:10',
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('hrms_check_in_button')))
          .onPressed,
      isNull,
    );

    // Navigate to Attendance History before switching mode.
    await tester.ensureVisible(
      find.byKey(const Key('view_attendance_history_button')),
    );
    await tester.tap(find.byKey(const Key('view_attendance_history_button')));
    await tester.pumpAndSettle();

    expect(find.text('Attendance History'), findsOneWidget);
    expect(find.text('Sample'), findsWidgets);

    // Switch to Chat Mode and verify contact directory is shown.
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    expect(find.text('Chat Mode'), findsOneWidget);
    expect(find.text('Team Directory'), findsOneWidget);
    expect(find.text('Ananya Nair'), findsOneWidget);

    // Search for a contact and open individual conversation.
    await tester.enterText(
      find.byKey(const Key('chat_search_field')),
      'Ananya',
    );
    await tester.pumpAndSettle();
    expect(find.text('Karthik Menon'), findsNothing);

    await tester.tap(find.byKey(const Key('chat_contact_tile_EMP-1088')));
    await tester.pumpAndSettle();

    // Verify seeded received message is left-aligned.
    final receivedBubbleText = find.textContaining('Welcome to TheDayHR');
    expect(receivedBubbleText, findsOneWidget);
    final receivedAlign = tester.widget<Align>(
      find
          .ancestor(
            of: receivedBubbleText,
            matching: find.byType(Align),
          )
          .first,
    );
    expect(receivedAlign.alignment, Alignment.centerLeft);

    // Empty message send is prevented.
    await tester.tap(find.byKey(const Key('chat_send_button')));
    await tester.pumpAndSettle();
    expect(
      find.text('Please enter a message before sending.'),
      findsOneWidget,
    );

    // Send a real message and verify it renders right-aligned.
    await tester.enterText(
      find.byKey(const Key('chat_message_input')),
      'Checked in and starting today tasks!',
    );
    await tester.tap(find.byKey(const Key('chat_send_button')));
    await tester.pumpAndSettle();

    final sentBubbleText = find.text('Checked in and starting today tasks!');
    expect(sentBubbleText, findsOneWidget);
    final sentAlign = tester.widget<Align>(
      find
          .ancestor(
            of: sentBubbleText,
            matching: find.byType(Align),
          )
          .first,
    );
    expect(sentAlign.alignment, Alignment.centerRight);

    // Type an unsent draft, switch to HRMS Mode and back to Chat Mode, verify preservation.
    await tester.enterText(
      find.byKey(const Key('chat_message_input')),
      'Draft kept across modes',
    );
    await tester.pumpAndSettle();

    // Switch back to HRMS Mode and verify Attendance History screen & checked-in state are preserved.
    await tester.tap(find.text('HRMS'));
    await tester.pumpAndSettle();

    expect(find.text('HRMS Mode'), findsOneWidget);
    expect(find.text('Attendance History'), findsOneWidget);

    // Switch back to Chat Mode and confirm open conversation & unsent draft are intact.
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(find.text('Ananya Nair'), findsOneWidget);
    expect(find.text('Draft kept across modes'), findsOneWidget);

    // Navigate back to contacts and verify latest preview updated.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(
      find.text('You: Checked in and starting today tasks!'),
      findsOneWidget,
    );

    // Return to HRMS Mode and complete Check Out.
    await tester.tap(find.text('HRMS'));
    await tester.pumpAndSettle();

    // Pop back to HRMS Dashboard and perform Check Out.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(find.byKey(const Key('hrms_elapsed_timer_text')))
          .data,
      '02:15:10',
    );
    await tester.ensureVisible(find.byKey(const Key('hrms_check_out_button')));
    await tester.tap(find.byKey(const Key('hrms_check_out_button')));
    await tester.pumpAndSettle();

    expect(find.text('Shift Completed'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('hrms_completed_duration_text')))
          .data,
      '02h 15m',
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('hrms_check_out_button')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('renders cleanly without overflow on narrow mobile and wide desktop viewports',
      (tester) async {
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    // Ultra-narrow mobile phone (320x568) across Login, HRMS, History, Chat & Conversation.
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(320, 568);
    await pumpApp(tester);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(
      find.byKey(const Key('fill_demo_employee_button')),
    );
    await tester.tap(find.byKey(const Key('fill_demo_employee_button')));
    await tester.ensureVisible(find.byKey(const Key('login_submit_button')));
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('hrms_check_in_button')));
    await tester.tap(find.byKey(const Key('hrms_check_in_button')));
    await tester.pumpAndSettle();
    expect(find.text('Checked In • Active Shift'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(
      find.byKey(const Key('view_attendance_history_button')),
    );
    await tester.tap(find.byKey(const Key('view_attendance_history_button')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('chat_contact_tile_EMP-1088')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Wide desktop/tablet viewport (1280x800) switches to NavigationRail.
    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
