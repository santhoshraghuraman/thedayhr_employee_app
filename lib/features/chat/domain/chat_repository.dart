import 'package:thedayhr_employee_app/core/constants/storage_keys.dart';
import 'package:thedayhr_employee_app/core/services/local_storage_service.dart';
import 'package:thedayhr_employee_app/features/chat/domain/chat_contact.dart';
import 'package:thedayhr_employee_app/features/chat/domain/chat_message.dart';

/// Persistence contract for internal employee directory and chat history.
abstract class ChatRepository {
  List<ChatContact> loadContacts({required String currentEmployeeId});

  List<ChatMessage> loadMessages(String employeeId, {DateTime? now});

  Future<bool> saveMessages(String employeeId, List<ChatMessage> messages);
}

/// Local [ChatRepository] backed by [LocalStorageService].
class LocalChatRepository implements ChatRepository {
  LocalChatRepository(this._storage);

  final LocalStorageService _storage;

  static const List<ChatContact> _directory = [
    ChatContact(
      id: 'EMP-1088',
      name: 'Ananya Nair',
      role: 'HR Specialist',
      department: 'People Operations',
      isOnline: true,
      statusLabel: 'Online',
    ),
    ChatContact(
      id: 'EMP-1015',
      name: 'Karthik Menon',
      role: 'Engineering Lead',
      department: 'Mobile Engineering',
      isOnline: true,
      statusLabel: 'Online',
    ),
    ChatContact(
      id: 'EMP-1024',
      name: 'Meera Krishnan',
      role: 'Product Designer',
      department: 'Design Systems',
      isOnline: false,
      statusLabel: 'In a meeting',
    ),
    ChatContact(
      id: 'EMP-1051',
      name: 'Rahul Verma',
      role: 'QA Engineer',
      department: 'Quality Assurance',
      isOnline: true,
      statusLabel: 'Online',
    ),
    ChatContact(
      id: 'EMP-1067',
      name: 'Divya Sharma',
      role: 'IT Operations',
      department: 'Workplace Tech',
      isOnline: false,
      statusLabel: 'Away',
    ),
  ];

  @override
  List<ChatContact> loadContacts({required String currentEmployeeId}) {
    final normalizedCurrent = currentEmployeeId.trim().toUpperCase();
    return _directory
        .where((contact) => contact.id.toUpperCase() != normalizedCurrent)
        .toList();
  }

  @override
  List<ChatMessage> loadMessages(String employeeId, {DateTime? now}) {
    final key = StorageKeys.chatMessagesForEmployee(employeeId);
    final raw = _storage.readString(key);

    if (raw == null) {
      final seeded = _buildInitialSampleMessages(
        employeeId: employeeId,
        referenceNow: now ?? DateTime.now(),
      );
      saveMessages(employeeId, seeded);
      return seeded;
    }

    final decodedList = _storage.readJsonList(key);
    if (decodedList == null) {
      // Corrupt payload; recover safely without crashing.
      return const [];
    }

    final messages = <ChatMessage>[];
    for (final item in decodedList) {
      final parsed = ChatMessage.tryFromJson(item);
      if (parsed != null) {
        messages.add(parsed);
      }
    }

    return sortChronological(messages);
  }

  @override
  Future<bool> saveMessages(String employeeId, List<ChatMessage> messages) {
    final key = StorageKeys.chatMessagesForEmployee(employeeId);
    final sorted = sortChronological(messages);
    final payload = sorted.map((message) => message.toJson()).toList();
    return _storage.writeJsonList(key, payload);
  }

  /// Sorts messages oldest-to-newest by timestamp for chronological chat feeds.
  static List<ChatMessage> sortChronological(List<ChatMessage> messages) {
    final copy = List<ChatMessage>.from(messages);
    copy.sort((a, b) {
      final timeOrder = a.timestamp.compareTo(b.timestamp);
      if (timeOrder != 0) {
        return timeOrder;
      }
      return a.id.compareTo(b.id);
    });
    return copy;
  }

  static List<ChatMessage> _buildInitialSampleMessages({
    required String employeeId,
    required DateTime referenceNow,
  }) {
    final todayBase = DateTime(
      referenceNow.year,
      referenceNow.month,
      referenceNow.day,
    );
    final yesterdayBase = todayBase.subtract(const Duration(days: 1));
    final normalizedEmployee = employeeId.trim().toUpperCase();

    final messages = <ChatMessage>[
      if (normalizedEmployee != 'EMP-1088') ...[
        ChatMessage(
          id: 'sample_chat_${employeeId}_1',
          contactId: 'EMP-1088',
          text:
              'Hi! Welcome to TheDayHR. Let me know if you need anything for your onboarding checklist.',
          isSentByMe: false,
          timestamp: yesterdayBase.add(const Duration(hours: 10, minutes: 15)),
          isSample: true,
        ),
        ChatMessage(
          id: 'sample_chat_${employeeId}_2',
          contactId: 'EMP-1088',
          text: 'Thanks Ananya! I have reviewed the schedule and guidelines.',
          isSentByMe: true,
          timestamp: yesterdayBase.add(const Duration(hours: 10, minutes: 24)),
          isSample: true,
        ),
        ChatMessage(
          id: 'sample_chat_${employeeId}_3',
          contactId: 'EMP-1088',
          text:
              'Great! Remember to check in from the HRMS dashboard before starting your shift.',
          isSentByMe: false,
          timestamp: todayBase.add(const Duration(hours: 8, minutes: 50)),
          isSample: true,
        ),
      ],
      if (normalizedEmployee != 'EMP-1015') ...[
        ChatMessage(
          id: 'sample_chat_${employeeId}_4',
          contactId: 'EMP-1015',
          text:
              'Morning! Our mobile sprint standup starts at 10:30 AM. Please share your progress update.',
          isSentByMe: false,
          timestamp: todayBase.add(const Duration(hours: 9, minutes: 5)),
          isSample: true,
        ),
      ],
      if (normalizedEmployee != 'EMP-1024') ...[
        ChatMessage(
          id: 'sample_chat_${employeeId}_5',
          contactId: 'EMP-1024',
          text:
              'I uploaded the updated Material 3 card spacing specs for the employee app.',
          isSentByMe: false,
          timestamp: yesterdayBase.add(const Duration(hours: 16, minutes: 40)),
          isSample: true,
        ),
      ],
      if (normalizedEmployee != 'EMP-1051') ...[
        ChatMessage(
          id: 'sample_chat_${employeeId}_6',
          contactId: 'EMP-1051',
          text:
              'Can you share the APK build once your attendance and chat tests pass?',
          isSentByMe: false,
          timestamp: todayBase.add(const Duration(hours: 9, minutes: 20)),
          isSample: true,
        ),
      ],
    ];

    return sortChronological(messages);
  }
}

