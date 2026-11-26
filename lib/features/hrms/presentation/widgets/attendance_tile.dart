import 'package:flutter/material.dart';
import 'package:thedayhr_employee_app/core/theme/app_theme.dart';
import 'package:thedayhr_employee_app/core/utils/date_time_formatter.dart';
import 'package:thedayhr_employee_app/features/hrms/domain/attendance_record.dart';

/// Displays one [AttendanceRecord] row with date, check-in/out times, worked
/// hours, and status indicator.
class AttendanceTile extends StatelessWidget {
  const AttendanceTile({
    super.key,
    required this.record,
    required this.referenceNow,
  });

  final AttendanceRecord record;
  final DateTime referenceNow;

  @override
  Widget build(BuildContext context) {
    final status = record.statusAt(referenceNow);
    final elapsed = record.elapsedDurationAt(referenceNow);

    final (statusLabel, statusColor, statusIcon) = switch (status) {
      AttendanceRecordStatus.completed => (
          'Completed',
          AppTheme.successColor,
          Icons.check_circle_outline,
        ),
      AttendanceRecordStatus.active => (
          'Checked In',
          AppTheme.secondaryColor,
          Icons.timelapse_rounded,
        ),
      AttendanceRecordStatus.incomplete => (
          'Incomplete',
          AppTheme.warningColor,
          Icons.warning_amber_rounded,
        ),
    };

    final hoursText = switch (status) {
      AttendanceRecordStatus.completed =>
        DateTimeFormatter.formatHoursMinutes(record.workedDuration),
      AttendanceRecordStatus.active =>
        DateTimeFormatter.formatElapsedClock(elapsed),
      AttendanceRecordStatus.incomplete => 'Incomplete',
    };

    final checkOutText = switch (status) {
      AttendanceRecordStatus.completed =>
        DateTimeFormatter.formatTime(record.checkOutTime!),
      AttendanceRecordStatus.active => 'In progress',
      AttendanceRecordStatus.incomplete => 'Not recorded',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        DateTimeFormatter.formatDate(record.checkInTime),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      if (record.isSample)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Sample',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.borderSubtle),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final items = [
                  _TimeMetric(
                    label: 'Check In',
                    value: DateTimeFormatter.formatTime(record.checkInTime),
                    icon: Icons.login_rounded,
                  ),
                  _TimeMetric(
                    label: 'Check Out',
                    value: checkOutText,
                    icon: Icons.logout_rounded,
                  ),
                  _TimeMetric(
                    label: 'Worked',
                    value: hoursText,
                    icon: Icons.schedule_rounded,
                    highlightColor: status == AttendanceRecordStatus.incomplete
                        ? AppTheme.warningColor
                        : AppTheme.textPrimary,
                  ),
                ];

                if (constraints.maxWidth < 300) {
                  return Wrap(
                    spacing: 20,
                    runSpacing: 12,
                    children: items,
                  );
                }

                return Row(
                  children: items
                      .map((item) => Expanded(child: item))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeMetric extends StatelessWidget {
  const _TimeMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.highlightColor = AppTheme.textPrimary,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: highlightColor,
          ),
        ),
      ],
    );
  }
}

