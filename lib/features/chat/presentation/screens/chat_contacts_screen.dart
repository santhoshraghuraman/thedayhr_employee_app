import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thedayhr_employee_app/core/theme/app_theme.dart';
import 'package:thedayhr_employee_app/features/chat/domain/chat_contact.dart';
import 'package:thedayhr_employee_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:thedayhr_employee_app/features/chat/presentation/screens/chat_conversation_screen.dart';
import 'package:thedayhr_employee_app/features/chat/presentation/widgets/contact_tile.dart';
import 'package:thedayhr_employee_app/features/hrms/presentation/providers/clock_provider.dart';

/// Displays the searchable employee contact directory and opens individual
/// conversation threads.
class ChatContactsScreen extends ConsumerStatefulWidget {
  const ChatContactsScreen({super.key});

  @override
  ConsumerState<ChatContactsScreen> createState() => _ChatContactsScreenState();
}

class _ChatContactsScreenState extends ConsumerState<ChatContactsScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(chatProvider).searchQuery,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openConversation(ChatContact contact) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatConversationScreen(contact: contact),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final contacts = chatState.filteredContacts;
    final now = ref.watch(clockProvider).value ??
        ref.read(currentTimeFunctionProvider)();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Team Directory',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.secondaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${contacts.length} Colleagues',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('chat_search_field'),
                    controller: _searchController,
                    onChanged: (value) =>
                        ref.read(chatProvider.notifier).setSearchQuery(value),
                    decoration: InputDecoration(
                      hintText: 'Search by name, role, or department...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: chatState.searchQuery.isEmpty
                          ? null
                          : IconButton(
                              key: const Key('chat_search_clear_button'),
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(chatProvider.notifier)
                                    .setSearchQuery('');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: contacts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person_search_outlined,
                              size: 44,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              chatState.searchQuery.isEmpty
                                  ? 'No colleagues available in directory.'
                                  : 'No colleagues match "${chatState.searchQuery}".',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      itemCount: contacts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        final latest =
                            chatState.latestMessageForContact(contact.id);
                        return ContactTile(
                          contact: contact,
                          latestMessage: latest,
                          referenceNow: now,
                          onTap: () => _openConversation(contact),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

