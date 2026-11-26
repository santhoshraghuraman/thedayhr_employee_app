import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thedayhr_employee_app/core/services/local_storage_service.dart';
import 'package:thedayhr_employee_app/core/utils/date_time_formatter.dart';
import 'package:thedayhr_employee_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:thedayhr_employee_app/features/hrms/domain/attendance_record.dart';
import 'package:thedayhr_employee_app/features/hrms/domain/attendance_repository.dart';
import 'package:thedayhr_employee_app/features/hrms/presentation/providers/clock_provider.dart';

/// Provides the [AttendanceRepository] implementation.
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return LocalAttendanceRepository(ref.watch(localStorageServiceProvider));
});

/// Today's high-level attendance status for the active employee.
enum TodayAttendanceStatus {
  notCheckedIn,
  checkedIn,
  checkedOut,
}

/// Immutable HRMS state scoped to the authenticated employee.
class HrmsState {
  const HrmsState({
    required this.employeeId,
    required this.records,
    this.isSaving = false,
    this.feedbackMessage,
    this.isErrorFeedback = false,
  });

  final String employeeId;
  final List<AttendanceRecord> records;
  final bool isSaving;
  final String? feedbackMessage;
  final bool isErrorFeedback;

  /// Returns today's attendance record if one exists.
  AttendanceRecord? todayRecordAt(DateTime now) {
    final todayKey = DateTimeFormatter.toDateKey(now);
    for (final record in records) {
      if (record.dateKey == todayKey) {
        return record;
      }
    }
    return null;
  }

  /// Determines today's attendance state for duplicate action prevention.
  TodayAttendanceStatus todayStatusAt(DateTime now) {
    final today = todayRecordAt(now);
    if (today == null) {
      return TodayAttendanceStatus.notCheckedIn;
    }
    return today.isCheckedOut
        ? TodayAttendanceStatus.checkedOut
        : TodayAttendanceStatus.checkedIn;
  }

  /// Total completed records across history.
  int get completedShiftsCount =>
      records.where((record) => record.isCheckedOut).length;

  /// Number of incomplete historical records (excluding an active today shift).
  int incompleteCountAt(DateTime now) {
    return records
        .where(
          (record) =>
              record.statusAt(now) == AttendanceRecordStatus.incomplete,
        )
        .length;
  }

  /// Sum of completed working hours plus active elapsed duration today.
  Duration totalLoggedDurationAt(DateTime now) {
    var total = Duration.zero;
    for (final record in records) {
      total += record.elapsedDurationAt(now);
    }
    return total;
  }

  /// Average duration across completed shifts.
  Duration get averageCompletedShiftDuration {
    final completed = records.where((record) => record.isCheckedOut).toList();
    if (completed.isEmpty) {
      return Duration.zero;
    }
    var sumMinutes = 0;
    for (final record in completed) {
      sumMinutes += record.workedDuration.inMinutes;
    }
    return Duration(minutes: sumMinutes ~/ completed.length);
  }

  HrmsState copyWith({
    String? employeeId,
    List<AttendanceRecord>? records,
    bool? isSaving,
    String? feedbackMessage,
    bool clearFeedback = false,
    bool? isErrorFeedback,
  }) {
    return HrmsState(
      employeeId: employeeId ?? this.employeeId,
      records: records ?? this.records,
      isSaving: isSaving ?? this.isSaving,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      isErrorFeedback: isErrorFeedback ?? this.isErrorFeedback,
    );
  }
}

/// Manages HRMS attendance state independently of Chat and UI navigation.
class HrmsNotifier extends Notifier<HrmsState> {
  @override
  HrmsState build() {
    final employeeId = ref.watch(
      authProvider.select((auth) => auth.user?.employeeId ?? ''),
    );
    if (employeeId.isEmpty) {
      return const HrmsState(employeeId: '', records: []);
    }

    final now = ref.read(currentTimeFunctionProvider)();
    final records = ref
        .read(attendanceRepositoryProvider)
        .loadRecords(employeeId, now: now);

    return HrmsState(
      employeeId: employeeId,
      records: records,
    );
  }

  /// Records a new check-in for today, preventing duplicate check-ins or
  /// multiple records on the same calendar day.
  Future<bool> checkIn() async {
    if (state.employeeId.isEmpty || state.isSaving) {
      return false;
    }

    final now = ref.read(currentTimeFunctionProvider)();
    final status = state.todayStatusAt(now);

    if (status == TodayAttendanceStatus.checkedIn) {
      state = state.copyWith(
        feedbackMessage: 'You are already checked in for today.',
        isErrorFeedback: true,
      );
      return false;
    }

    if (status == TodayAttendanceStatus.checkedOut) {
      state = state.copyWith(
        feedbackMessage: 'Today\'s attendance is already completed.',
        isErrorFeedback: true,
      );
      return false;
    }

    final todayKey = DateTimeFormatter.toDateKey(now);
    final newRecord = AttendanceRecord(
      id: 'att_${state.employeeId}_$todayKey',
      dateKey: todayKey,
      checkInTime: now,
      isSample: false,
    );

    final updatedRecords = LocalAttendanceRepository.sortNewestFirst([
      newRecord,
      ...state.records,
    ]);

    state = state.copyWith(isSaving: true, clearFeedback: true);
    final saved = await ref
        .read(attendanceRepositoryProvider)
        .saveRecords(state.employeeId, updatedRecords);

    if (!saved) {
      state = state.copyWith(
        isSaving: false,
        feedbackMessage: 'Unable to save check-in locally. Please try again.',
        isErrorFeedback: true,
      );
      return false;
    }

    state = state.copyWith(
      records: updatedRecords,
      isSaving: false,
      feedbackMessage:
          'Checked in at ${DateTimeFormatter.formatTime(now)}.',
      isErrorFeedback: false,
    );
    return true;
  }

  /// Records today's check-out time, preventing check-out before check-in or
  /// duplicate check-out.
  Future<bool> checkOut() async {
    if (state.employeeId.isEmpty || state.isSaving) {
      return false;
    }

    final now = ref.read(currentTimeFunctionProvider)();
    final status = state.todayStatusAt(now);

    if (status == TodayAttendanceStatus.notCheckedIn) {
      state = state.copyWith(
        feedbackMessage: 'Please check in before checking out.',
        isErrorFeedback: true,
      );
      return false;
    }

    if (status == TodayAttendanceStatus.checkedOut) {
      state = state.copyWith(
        feedbackMessage: 'You have already checked out for today.',
        isErrorFeedback: true,
      );
      return false;
    }

    final today = state.todayRecordAt(now);
    if (today == null) {
      return false;
    }

    final safeCheckOutTime =
        now.isBefore(today.checkInTime) ? today.checkInTime : now;
    final completedRecord = today.copyWith(checkOutTime: safeCheckOutTime);

    final updatedRecords = LocalAttendanceRepository.sortNewestFirst(
      state.records
          .map((r) => r.dateKey == today.dateKey ? completedRecord : r)
          .toList(),
    );

    state = state.copyWith(isSaving: true, clearFeedback: true);
    final saved = await ref
        .read(attendanceRepositoryProvider)
        .saveRecords(state.employeeId, updatedRecords);

    if (!saved) {
      state = state.copyWith(
        isSaving: false,
        feedbackMessage: 'Unable to save check-out locally. Please try again.',
        isErrorFeedback: true,
      );
      return false;
    }

    final workedLabel =
        DateTimeFormatter.formatHoursMinutes(completedRecord.workedDuration);
    state = state.copyWith(
      records: updatedRecords,
      isSaving: false,
      feedbackMessage:
          'Checked out at ${DateTimeFormatter.formatTime(safeCheckOutTime)} • Worked $workedLabel',
      isErrorFeedback: false,
    );
    return true;
  }

  void clearFeedback() {
    if (state.feedbackMessage != null) {
      state = state.copyWith(clearFeedback: true, isErrorFeedback: false);
    }
  }
}

/// Independent HRMS attendance state provider.
final hrmsProvider = NotifierProvider<HrmsNotifier, HrmsState>(
  HrmsNotifier.new,
);

