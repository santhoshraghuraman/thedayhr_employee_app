import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thedayhr_employee_app/core/constants/storage_keys.dart';
import 'package:thedayhr_employee_app/core/services/local_storage_service.dart';
import 'package:thedayhr_employee_app/core/utils/date_time_formatter.dart';
import 'package:thedayhr_employee_app/features/auth/domain/auth_repository.dart';
import 'package:thedayhr_employee_app/features/hrms/domain/attendance_record.dart';
import 'package:thedayhr_employee_app/features/hrms/presentation/providers/clock_provider.dart';
import 'package:thedayhr_employee_app/features/hrms/presentation/providers/hrms_provider.dart';
import 'package:thedayhr_employee_app/features/shell/presentation/providers/mode_provider.dart';

void main() {
  Future<ProviderContainer> createAuthenticatedContainer({
    required DateTime Function() nowFn,
    Map<String, Object> initialPrefs = const {},
  }) async {
    final demoUser = LocalAuthRepository.primaryDemo.user;
    SharedPreferences.setMockInitialValues({
      StorageKeys.authSession: jsonEncode(demoUser.toJson()),
      ...initialPrefs,
    });
    final prefs = await SharedPreferences.getInstance();

    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentTimeFunctionProvider.overrideWithValue(nowFn),
      ],
    );
  }

  group('HrmsNotifier attendance rules', () {
    test('seeds previous-day sample records sorted newest-first without today',
        () async {
      final now = DateTime(2026, 11, 26, 9, 0);
      final container = await createAuthenticatedContainer(nowFn: () => now);
      addTearDown(container.dispose);

      final state = container.read(hrmsProvider);
      final todayKey = DateTimeFormatter.toDateKey(now);

      expect(state.records, isNotEmpty);
      expect(state.records.every((r) => r.isSample), isTrue);
      expect(state.records.any((r) => r.dateKey == todayKey), isFalse);
      expect(state.todayStatusAt(now), TodayAttendanceStatus.notCheckedIn);

      for (var i = 0; i < state.records.length - 1; i++) {
        expect(
          state.records[i].dateKey.compareTo(state.records[i + 1].dateKey),
          greaterThanOrEqualTo(0),
        );
      }
    });

    test('prevents check-out before check-in', () async {
      final now = DateTime(2026, 11, 26, 9, 0);
      final container = await createAuthenticatedContainer(nowFn: () => now);
      addTearDown(container.dispose);

      final notifier = container.read(hrmsProvider.notifier);
      final result = await notifier.checkOut();
      final state = container.read(hrmsProvider);

      expect(result, isFalse);
      expect(state.todayStatusAt(now), TodayAttendanceStatus.notCheckedIn);
      expect(state.isErrorFeedback, isTrue);
      expect(
        state.feedbackMessage,
        'Please check in before checking out.',
      );
    });

    test('check-in succeeds and prevents duplicate check-in', () async {
      var currentNow = DateTime(2026, 11, 26, 9, 15);
      final container = await createAuthenticatedContainer(
        nowFn: () => currentNow,
      );
      addTearDown(container.dispose);

      final notifier = container.read(hrmsProvider.notifier);
      final firstCheckIn = await notifier.checkIn();

      expect(firstCheckIn, isTrue);
      var state = container.read(hrmsProvider);
      expect(state.todayStatusAt(currentNow), TodayAttendanceStatus.checkedIn);
      expect(state.isErrorFeedback, isFalse);

      // Duplicate check-in attempt in the same shift.
      currentNow = DateTime(2026, 11, 26, 10, 0);
      final duplicateCheckIn = await notifier.checkIn();
      state = container.read(hrmsProvider);

      expect(duplicateCheckIn, isFalse);
      expect(state.isErrorFeedback, isTrue);
      expect(
        state.feedbackMessage,
        'You are already checked in for today.',
      );

      final todayRecords = state.records
          .where((r) => r.dateKey == DateTimeFormatter.toDateKey(currentNow))
          .toList();
      expect(todayRecords.length, 1);
    });

    test(
        'check-out calculates working hours accurately and prevents duplicate check-out or second check-in today',
        () async {
      var currentNow = DateTime(2026, 11, 26, 9, 0);
      final container = await createAuthenticatedContainer(
        nowFn: () => currentNow,
      );
      addTearDown(container.dispose);

      final notifier = container.read(hrmsProvider.notifier);
      await notifier.checkIn();

      // Advance 8 hours 45 minutes.
      currentNow = DateTime(2026, 11, 26, 17, 45);
      final checkOutOk = await notifier.checkOut();
      expect(checkOutOk, isTrue);

      var state = container.read(hrmsProvider);
      final todayRecord = state.todayRecordAt(currentNow);
      expect(todayRecord, isNotNull);
      expect(todayRecord!.workedDuration, const Duration(hours: 8, minutes: 45));
      expect(state.todayStatusAt(currentNow), TodayAttendanceStatus.checkedOut);

      // Duplicate check-out attempt.
      final duplicateOut = await notifier.checkOut();
      state = container.read(hrmsProvider);
      expect(duplicateOut, isFalse);
      expect(state.isErrorFeedback, isTrue);
      expect(
        state.feedbackMessage,
        'You have already checked out for today.',
      );

      // Same-day second check-in attempt.
      final secondInToday = await notifier.checkIn();
      state = container.read(hrmsProvider);
      expect(secondInToday, isFalse);
      expect(state.isErrorFeedback, isTrue);
      expect(
        state.feedbackMessage,
        'Today\'s attendance is already completed.',
      );
    });

    test('persists attendance records across reload using employee-specific key',
        () async {
      var currentNow = DateTime(2026, 11, 26, 9, 10);
      final demoUser = LocalAuthRepository.primaryDemo.user;
      SharedPreferences.setMockInitialValues({
        StorageKeys.authSession: jsonEncode(demoUser.toJson()),
      });
      final prefs = await SharedPreferences.getInstance();

      // First app session: check in and check out.
      final firstContainer = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentTimeFunctionProvider.overrideWithValue(() => currentNow),
        ],
      );
      await firstContainer.read(hrmsProvider.notifier).checkIn();
      currentNow = DateTime(2026, 11, 26, 18, 10);
      await firstContainer.read(hrmsProvider.notifier).checkOut();
      firstContainer.dispose();

      // Verify stored under employee-specific key.
      final storedJson = prefs.getString(
        StorageKeys.attendanceForEmployee(demoUser.employeeId),
      );
      expect(storedJson, isNotNull);
      expect(
        prefs.getString(StorageKeys.attendanceForEmployee('EMP-1088')),
        isNull,
      );

      // Simulated app restart: fresh ProviderContainer reads persisted state.
      final reloadedContainer = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentTimeFunctionProvider.overrideWithValue(() => currentNow),
        ],
      );
      addTearDown(reloadedContainer.dispose);

      final reloadedState = reloadedContainer.read(hrmsProvider);
      final restoredToday = reloadedState.todayRecordAt(currentNow);
      expect(restoredToday, isNotNull);
      expect(restoredToday!.isCheckedOut, isTrue);
      expect(restoredToday.workedDuration, const Duration(hours: 9));
      expect(
        reloadedState.todayStatusAt(currentNow),
        TodayAttendanceStatus.checkedOut,
      );
    });

    test('switching mode does not reset HRMS attendance state', () async {
      final now = DateTime(2026, 11, 26, 9, 30);
      final container = await createAuthenticatedContainer(nowFn: () => now);
      addTearDown(container.dispose);

      await container.read(hrmsProvider.notifier).checkIn();
      expect(
        container.read(hrmsProvider).todayStatusAt(now),
        TodayAttendanceStatus.checkedIn,
      );

      container.read(appModeProvider.notifier).setMode(AppMode.chat);
      expect(container.read(appModeProvider), AppMode.chat);
      expect(
        container.read(hrmsProvider).todayStatusAt(now),
        TodayAttendanceStatus.checkedIn,
      );

      container.read(appModeProvider.notifier).setMode(AppMode.hrms);
      expect(container.read(appModeProvider), AppMode.hrms);
      expect(
        container.read(hrmsProvider).todayStatusAt(now),
        TodayAttendanceStatus.checkedIn,
      );
    });
  });

  group('AttendanceRecord safety', () {
    test('returns null on malformed JSON payloads', () {
      expect(AttendanceRecord.tryFromJson(null), isNull);
      expect(AttendanceRecord.tryFromJson({'id': ''}), isNull);
      expect(
        AttendanceRecord.tryFromJson({
          'id': '1',
          'dateKey': '2026-11-26',
          'checkInTime': 'not-a-date',
        }),
        isNull,
      );
    });
  });
}

