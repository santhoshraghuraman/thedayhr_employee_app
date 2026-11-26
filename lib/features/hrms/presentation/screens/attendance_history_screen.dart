import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thedayhr_employee_app/core/theme/app_theme.dart';
import 'package:thedayhr_employee_app/features/hrms/presentation/providers/clock_provider.dart';
import 'package:thedayhr_employee_app/features/hrms/presentation/providers/hrms_provider.dart';
import 'package:thedayhr_employee_app/features/hrms/presentation/widgets/attendance_tile.dart';

/// Displays chronological attendance history (newest date first) for the
/// currently signed-in employee.
class AttendanceHistoryScreen extends ConsumerWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hrmsState = ref.watch(hrmsProvider);
    final now = ref.watch(clockProvider).value ??
        ref.read(currentTimeFunctionProvider)();
    final records = hrmsState.records;
    final hasSampleRecords = records.any((record) => record.isSample);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: records.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No attendance records available yet.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: records.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _HistorySummaryBanner(
                          totalCount: records.length,
                          completedCount: hrmsState.completedShiftsCount,
                          incompleteCount: hrmsState.incompleteCountAt(now),
                          hasSampleRecords: hasSampleRecords,
                        );
                      }
                      final record = records[index - 1];
                      return AttendanceTile(
                        record: record,
                        referenceNow: now,
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _HistorySummaryBanner extends StatelessWidget {
  const _HistorySummaryBanner({
    required this.totalCount,
    required this.completedCount,
    required this.incompleteCount,
    required this.hasSampleRecords,
  });

  final int totalCount;
  final int completedCount;
  final int incompleteCount;
  final bool hasSampleRecords;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.primaryColor.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _SummaryChip(
                  label: '$totalCount Total Days',
                  icon: Icons.calendar_month_outlined,
                ),
                _SummaryChip(
                  label: '$completedCount Completed',
                  icon: Icons.check_circle_outline,
                ),
                if (incompleteCount > 0)
                  _SummaryChip(
                    label: '$incompleteCount Incomplete',
                    icon: Icons.warning_amber_rounded,
                  ),
              ],
            ),
            if (hasSampleRecords) ...[
              const SizedBox(height: 10),
              const Text(
                'Previous-day sample records are labeled "Sample". Today\'s record updates automatically when you Check In and Check Out.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

