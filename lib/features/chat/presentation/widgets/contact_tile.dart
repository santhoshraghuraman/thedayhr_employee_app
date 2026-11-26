import 'package:flutter/material.dart';
import 'package:thedayhr_employee_app/core/theme/app_theme.dart';
import 'package:thedayhr_employee_app/core/utils/date_time_formatter.dart';
import 'package:thedayhr_employee_app/features/chat/domain/chat_contact.dart';
import 'package:thedayhr_employee_app/features/chat/domain/chat_message.dart';

/// Displays one employee contact row with availability indicator, latest
/// message preview, and timestamp.
class ContactTile extends StatelessWidget {
  const ContactTile({
    super.key,
    required this.contact,
    required this.latestMessage,
    required this.referenceNow,
    required this.onTap,
  });

  final ChatContact contact;
  final ChatMessage? latestMessage;
  final DateTime referenceNow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final previewText = latestMessage == null
        ? 'No messages yet • Tap to start chatting'
        : (latestMessage!.isSentByMe
            ? 'You: ${latestMessage!.text}'
            : latestMessage!.text);

    final timestampText = latestMessage == null
        ? contact.statusLabel
        : DateTimeFormatter.formatContactTimestamp(
            latestMessage!.timestamp,
            referenceNow,
          );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('chat_contact_tile_${contact.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.12),
                    child: Text(
                      contact.initials,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: contact.isOnline
                            ? AppTheme.secondaryColor
                            : AppTheme.textSecondary.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.surfaceCard,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            contact.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timestampText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: latestMessage != null
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${contact.role} • ${contact.department}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      previewText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: latestMessage == null
                            ? AppTheme.textSecondary.withValues(alpha: 0.85)
                            : AppTheme.textSecondary,
                        fontStyle: latestMessage == null
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

