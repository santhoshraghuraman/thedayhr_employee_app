import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thedayhr_employee_app/core/theme/app_theme.dart';
import 'package:thedayhr_employee_app/core/utils/date_time_formatter.dart';
import 'package:thedayhr_employee_app/features/auth/domain/employee_user.dart';
import 'package:thedayhr_employee_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:thedayhr_employee_app/features/hrms/presentation/providers/clock_provider.dart';
import 'package:thedayhr_employee_app/features/hrms/presentation/providers/hrms_provider.dart';
import 'package:thedayhr_employee_app/features/hrms/presentation/screens/attendance_history_screen.dart';
import 'package:thedayhr_employee_app/features/hrms/presentation/widgets/attendance_action_card.dart';
import 'package:thedayhr_employee_app/features/hrms/presentation/widgets/attendance_tile.dart';

/// Main HRMS dashboard displaying employee info, live clock, Check-In/Out
/// actions, working-hours summary, and quick access to Attendance History.
class HrmsDashboardScreen extends ConsumerWidget {
  const HrmsDashboardScreen({super.key});

  String _greetingForHour(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _openAttendanceHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AttendanceHistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider.select((auth) => auth.user));
    if (user == null) {
      return const SizedBox.shrink();
    }

    final hrmsState = ref.watch(hrmsProvider);
    final now = ref.watch(clockProvider).value ??
        ref.read(currentTimeFunctionProvider)();
    final todayRecord = hrmsState.todayRecordAt(now);
    final todayStatus = hrmsState.todayStatusAt(now);

    final todayHoursText = switch (todayStatus) {
      TodayAttendanceStatus.notCheckedIn => '00h 00m',
      TodayAttendanceStatus.checkedIn =>
        DateTimeFormatter.formatElapsedClock(
          todayRecord!.elapsedDurationAt(now),
        ),
      TodayAttendanceStatus.checkedOut =>
        DateTimeFormatter.formatHoursMinutes(todayRecord!.workedDuration),
    };

    final recentRecords = hrmsState.records.take(2).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _EmployeeWelcomeCard(
                user: user,
                greeting: _greetingForHour(now.hour),
                now: now,
              ),
              const SizedBox(height: 16),
              AttendanceActionCard(
                status: todayStatus,
                todayRecord: todayRecord,
                now: now,
                isSaving: hrmsState.isSaving,
                onCheckIn: () => ref.read(hrmsProvider.notifier).checkIn(),
                onCheckOut: () => ref.read(hrmsProvider.notifier).checkOut(),
                feedbackMessage: hrmsState.feedbackMessage,
                isErrorFeedback: hrmsState.isErrorFeedback,
              ),
              const SizedBox(height: 16),
              _AttendanceSummaryGrid(
                todayHours: todayHoursText,
                completedShifts: '${hrmsState.completedShiftsCount} Days',
                averageDuration: DateTimeFormatter.formatHoursMinutes(
                  hrmsState.averageCompletedShiftDuration,
                ),
                totalLogged: DateTimeFormatter.formatHoursMinutes(
                  hrmsState.totalLoggedDurationAt(now),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recent Attendance',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                  ),
                  TextButton.icon(
                    key: const Key('view_attendance_history_button'),
                    onPressed: () => _openAttendanceHistory(context),
                    icon: const Icon(Icons.history_rounded, size: 18),
                    label: const Text('View History'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (recentRecords.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No attendance history recorded yet.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                ...recentRecords.map(
                  (record) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AttendanceTile(
                      record: record,
                      referenceNow: now,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeeWelcomeCard extends StatelessWidget {
  const _EmployeeWelcomeCard({
    required this.user,
    required this.greeting,
    required this.now,
  });

  final EmployeeUser user;
  final String greeting;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 560;
          final profileHeader = Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  user.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user.employeeId} • ${user.designation}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final clockPanel = Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment:
                  isWide ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  DateTimeFormatter.formatDate(now),
                  key: const Key('hrms_current_date_text'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateTimeFormatter.formatLiveClock(now),
                  key: const Key('hrms_live_clock_text'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(child: profileHeader),
                const SizedBox(width: 16),
                clockPanel,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              profileHeader,
              const SizedBox(height: 14),
              clockPanel,
            ],
          );
        },
      ),
    );
  }
}

class _AttendanceSummaryGrid extends StatelessWidget {
  const _AttendanceSummaryGrid({
    required this.todayHours,
    required this.completedShifts,
    required this.averageDuration,
    required this.totalLogged,
  });

  final String todayHours;
  final String completedShifts;
  final String averageDuration;
  final String totalLogged;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (
        'Today\'s Hours',
        todayHours,
        Icons.timer_outlined,
        AppTheme.secondaryColor,
      ),
      (
        'Completed Shifts',
        completedShifts,
        Icons.event_available_outlined,
        AppTheme.primaryColor,
      ),
      (
        'Avg Shift Length',
        averageDuration,
        Icons.insights_outlined,
        AppTheme.successColor,
      ),
      (
        'Total Logged',
        totalLogged,
        Icons.work_history_outlined,
        AppTheme.textPrimary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 680 ? 4 : 2;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
                crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics.map((metric) {
            return SizedBox(
              width: itemWidth,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(metric.$3, size: 20, color: metric.$4),
                      const SizedBox(height: 10),
                      Text(
                        metric.$2,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        metric.$1,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

