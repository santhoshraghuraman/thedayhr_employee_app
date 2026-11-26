import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thedayhr_employee_app/core/services/local_storage_service.dart';
import 'package:thedayhr_employee_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:thedayhr_employee_app/features/chat/domain/chat_contact.dart';
import 'package:thedayhr_employee_app/features/chat/domain/chat_message.dart';
import 'package:thedayhr_employee_app/features/chat/domain/chat_repository.dart';
import 'package:thedayhr_employee_app/features/hrms/presentation/providers/clock_provider.dart';

/// Provides the [ChatRepository] implementation.
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return LocalChatRepository(ref.watch(localStorageServiceProvider));
});

/// Immutable Internal Chat state scoped to the authenticated employee.
class ChatState {
  const ChatState({
    required this.employeeId,
    required this.contacts,
    required this.messages,
    this.searchQuery = '',
    this.draftsByContact = const {},
    this.isSending = false,
    this.errorMessage,
  });

  final String employeeId;
  final List<ChatContact> contacts;
  final List<ChatMessage> messages;
  final String searchQuery;
  final Map<String, String> draftsByContact;
  final bool isSending;
  final String? errorMessage;

  /// Returns contacts matching [searchQuery], ordered with newest activity
  /// first while keeping directory order for contacts without messages.
  List<ChatContact> get filteredContacts {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    final matching = normalizedQuery.isEmpty
        ? List<ChatContact>.from(contacts)
        : contacts.where((contact) {
            return contact.name.toLowerCase().contains(normalizedQuery) ||
                contact.role.toLowerCase().contains(normalizedQuery) ||
                contact.department.toLowerCase().contains(normalizedQuery);
          }).toList();

    matching.sort((a, b) {
      final latestA = latestMessageForContact(a.id);
      final latestB = latestMessageForContact(b.id);
      if (latestA == null && latestB == null) {
        return contacts.indexOf(a).compareTo(contacts.indexOf(b));
      }
      if (latestA == null) return 1;
      if (latestB == null) return -1;
      return latestB.timestamp.compareTo(latestA.timestamp);
    });

    return matching;
  }

  /// Returns all messages for [contactId] sorted chronologically (oldest first).
  List<ChatMessage> messagesForContact(String contactId) {
    final filtered = messages
        .where((message) => message.contactId == contactId)
        .toList();
    return LocalChatRepository.sortChronological(filtered);
  }

  /// Returns the most recent message for [contactId], or `null` if none.
  ChatMessage? latestMessageForContact(String contactId) {
    final thread = messagesForContact(contactId);
    return thread.isEmpty ? null : thread.last;
  }

  /// Returns the current unsent draft text for [contactId].
  String draftForContact(String contactId) => draftsByContact[contactId] ?? '';

  ChatState copyWith({
    String? employeeId,
    List<ChatContact>? contacts,
    List<ChatMessage>? messages,
    String? searchQuery,
    Map<String, String>? draftsByContact,
    bool? isSending,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      employeeId: employeeId ?? this.employeeId,
      contacts: contacts ?? this.contacts,
      messages: messages ?? this.messages,
      searchQuery: searchQuery ?? this.searchQuery,
      draftsByContact: draftsByContact ?? this.draftsByContact,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Manages Internal Chat contacts, drafts, and message persistence independently
/// of HRMS attendance state.
class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() {
    final employeeId = ref.watch(
      authProvider.select((auth) => auth.user?.employeeId ?? ''),
    );
    if (employeeId.isEmpty) {
      return const ChatState(
        employeeId: '',
        contacts: [],
        messages: [],
      );
    }

    final repo = ref.read(chatRepositoryProvider);
    final now = ref.read(currentTimeFunctionProvider)();
    final contacts = repo.loadContacts(currentEmployeeId: employeeId);
    final messages = repo.loadMessages(employeeId, now: now);

    return ChatState(
      employeeId: employeeId,
      contacts: contacts,
      messages: messages,
    );
  }

  void setSearchQuery(String query) {
    if (state.searchQuery != query) {
      state = state.copyWith(searchQuery: query);
    }
  }

  void updateDraft(String contactId, String draft) {
    final existing = state.draftsByContact[contactId] ?? '';
    if (existing == draft && state.errorMessage == null) {
      return;
    }
    final nextDrafts = Map<String, String>.from(state.draftsByContact);
    if (draft.isEmpty) {
      nextDrafts.remove(contactId);
    } else {
      nextDrafts[contactId] = draft;
    }
    state = state.copyWith(
      draftsByContact: nextDrafts,
      clearError: true,
    );
  }

  /// Sends a new message to [contactId], rejecting empty/whitespace-only text
  /// and persisting chronologically under the current employee's storage key.
  Future<bool> sendMessage({
    required String contactId,
    required String text,
  }) async {
    if (state.employeeId.isEmpty || state.isSending) {
      return false;
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please enter a message before sending.',
      );
      return false;
    }

    final now = ref.read(currentTimeFunctionProvider)();
    final message = ChatMessage(
      id: 'msg_${now.microsecondsSinceEpoch}_${state.messages.length}',
      contactId: contactId,
      text: trimmed,
      isSentByMe: true,
      timestamp: now,
      isSample: false,
    );

    final updatedMessages = LocalChatRepository.sortChronological([
      ...state.messages,
      message,
    ]);

    state = state.copyWith(isSending: true, clearError: true);
    final saved = await ref
        .read(chatRepositoryProvider)
        .saveMessages(state.employeeId, updatedMessages);

    if (!saved) {
      state = state.copyWith(
        isSending: false,
        errorMessage: 'Unable to save message locally. Please try again.',
      );
      return false;
    }

    final nextDrafts = Map<String, String>.from(state.draftsByContact)
      ..remove(contactId);

    state = state.copyWith(
      messages: updatedMessages,
      draftsByContact: nextDrafts,
      isSending: false,
      clearError: true,
    );
    return true;
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }
}

/// Independent Internal Chat state provider.
final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);

