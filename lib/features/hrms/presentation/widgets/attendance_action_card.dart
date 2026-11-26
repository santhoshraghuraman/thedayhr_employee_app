import 'package:flutter/material.dart';
import 'package:thedayhr_employee_app/core/theme/app_theme.dart';
import 'package:thedayhr_employee_app/core/utils/date_time_formatter.dart';
import 'package:thedayhr_employee_app/features/hrms/domain/attendance_record.dart';
import 'package:thedayhr_employee_app/features/hrms/presentation/providers/hrms_provider.dart';

/// Primary attendance action card handling Check-In, Check-Out, live elapsed
/// hours, and duplicate action prevention feedback.
class AttendanceActionCard extends StatelessWidget {
  const AttendanceActionCard({
    super.key,
    required this.status,
    required this.todayRecord,
    required this.now,
    required this.isSaving,
    required this.onCheckIn,
    required this.onCheckOut,
    this.feedbackMessage,
    this.isErrorFeedback = false,
  });

  final TodayAttendanceStatus status;
  final AttendanceRecord? todayRecord;
  final DateTime now;
  final bool isSaving;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;
  final String? feedbackMessage;
  final bool isErrorFeedback;

  @override
  Widget build(BuildContext context) {
    final (badgeText, badgeColor, badgeIcon) = switch (status) {
      TodayAttendanceStatus.notCheckedIn => (
          'Not Checked In',
          AppTheme.warningColor,
          Icons.pending_actions_rounded,
        ),
      TodayAttendanceStatus.checkedIn => (
          'Checked In • Active Shift',
          AppTheme.secondaryColor,
          Icons.play_circle_outline_rounded,
        ),
      TodayAttendanceStatus.checkedOut => (
          'Shift Completed',
          AppTheme.successColor,
          Icons.verified_outlined,
        ),
    };

    final elapsed = todayRecord?.elapsedDurationAt(now) ?? Duration.zero;
    final canCheckIn =
        status == TodayAttendanceStatus.notCheckedIn && !isSaving;
    final canCheckOut = status == TodayAttendanceStatus.checkedIn && !isSaving;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Today\'s Attendance',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, size: 15, color: badgeColor),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            badgeText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: Container(
                key: ValueKey(status),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.scaffoldBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: switch (status) {
                  TodayAttendanceStatus.notCheckedIn => const Row(
                      children: [
                        Icon(
                          Icons.wb_sunny_outlined,
                          color: AppTheme.primaryColor,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ready to start your shift. Tap Check In to record your start time.',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  TodayAttendanceStatus.checkedIn => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Elapsed Working Time',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'In at ${DateTimeFormatter.formatTime(todayRecord!.checkInTime)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateTimeFormatter.formatElapsedClock(elapsed),
                          key: const Key('hrms_elapsed_timer_text'),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.secondaryColor,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ],
                    ),
                  TodayAttendanceStatus.checkedOut => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Completed Working Duration',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                DateTimeFormatter.formatHoursMinutes(
                                  todayRecord!.workedDuration,
                                ),
                                key: const Key('hrms_completed_duration_text'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.successColor,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Checked in at ${DateTimeFormatter.formatTime(todayRecord!.checkInTime)} • '
                          'Checked out at ${DateTimeFormatter.formatTime(todayRecord!.checkOutTime!)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('hrms_check_in_button'),
                    onPressed: canCheckIn ? onCheckIn : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Check In'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('hrms_check_out_button'),
                    onPressed: canCheckOut ? onCheckOut : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Check Out'),
                  ),
                ),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: feedbackMessage == null
                  ? const SizedBox.shrink()
                  : Padding(
                      key: ValueKey(feedbackMessage),
                      padding: const EdgeInsets.only(top: 14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: (isErrorFeedback
                                  ? AppTheme.errorColor
                                  : AppTheme.successColor)
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (isErrorFeedback
                                    ? AppTheme.errorColor
                                    : AppTheme.successColor)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isErrorFeedback
                                  ? Icons.info_outline
                                  : Icons.check_circle_outline,
                              size: 18,
                              color: isErrorFeedback
                                  ? AppTheme.errorColor
                                  : AppTheme.successColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feedbackMessage!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isErrorFeedback
                                      ? AppTheme.errorColor
                                      : AppTheme.successColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

