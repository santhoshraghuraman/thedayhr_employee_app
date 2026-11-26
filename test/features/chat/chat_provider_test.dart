import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thedayhr_employee_app/core/constants/storage_keys.dart';
import 'package:thedayhr_employee_app/core/services/local_storage_service.dart';
import 'package:thedayhr_employee_app/features/auth/domain/auth_repository.dart';
import 'package:thedayhr_employee_app/features/auth/domain/employee_user.dart';
import 'package:thedayhr_employee_app/features/chat/domain/chat_message.dart';
import 'package:thedayhr_employee_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:thedayhr_employee_app/features/hrms/presentation/providers/clock_provider.dart';
import 'package:thedayhr_employee_app/features/hrms/presentation/providers/hrms_provider.dart';
import 'package:thedayhr_employee_app/features/shell/presentation/providers/mode_provider.dart';

void main() {
  Future<ProviderContainer> createContainer({
    EmployeeUser? user,
    required DateTime Function() nowFn,
    Map<String, Object> initialPrefs = const {},
  }) async {
    final resolvedUser = user ?? LocalAuthRepository.primaryDemo.user;
    SharedPreferences.setMockInitialValues({
      StorageKeys.authSession: jsonEncode(resolvedUser.toJson()),
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

  group('ChatNotifier', () {
    test('loads mock directory contacts and seeds sample received messages',
        () async {
      final now = DateTime(2026, 11, 26, 10, 0);
      final container = await createContainer(nowFn: () => now);
      addTearDown(container.dispose);

      final chatState = container.read(chatProvider);
      expect(chatState.contacts.length, greaterThanOrEqualTo(4));
      expect(
        chatState.contacts
            .any((c) => c.id == LocalAuthRepository.primaryDemo.employeeId),
        isFalse,
      );

      final ananyaMessages = chatState.messagesForContact('EMP-1088');
      expect(ananyaMessages, isNotEmpty);
      expect(ananyaMessages.any((m) => !m.isSentByMe && m.isSample), isTrue);
      expect(ananyaMessages.any((m) => m.isSentByMe), isTrue);
    });

    test('filters contacts by name, role, or department', () async {
      final now = DateTime(2026, 11, 26, 10, 0);
      final container = await createContainer(nowFn: () => now);
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);

      notifier.setSearchQuery('Ananya');
      expect(
        container.read(chatProvider).filteredContacts.map((c) => c.id),
        ['EMP-1088'],
      );

      notifier.setSearchQuery('QA');
      expect(
        container.read(chatProvider).filteredContacts.map((c) => c.id),
        ['EMP-1051'],
      );

      notifier.setSearchQuery('Design Systems');
      expect(
        container.read(chatProvider).filteredContacts.map((c) => c.id),
        ['EMP-1024'],
      );

      notifier.setSearchQuery('');
      expect(
        container.read(chatProvider).filteredContacts.length,
        container.read(chatProvider).contacts.length,
      );
    });

    test('rejects empty or whitespace-only messages', () async {
      final now = DateTime(2026, 11, 26, 10, 0);
      final container = await createContainer(nowFn: () => now);
      addTearDown(container.dispose);

      final initialCount = container.read(chatProvider).messages.length;
      final notifier = container.read(chatProvider.notifier);

      final sentEmpty = await notifier.sendMessage(
        contactId: 'EMP-1088',
        text: '   \n\t  ',
      );
      expect(sentEmpty, isFalse);
      expect(container.read(chatProvider).messages.length, initialCount);
      expect(
        container.read(chatProvider).errorMessage,
        'Please enter a message before sending.',
      );
    });

    test(
        'sends messages in chronological order, updates latest preview, and clears draft',
        () async {
      var currentNow = DateTime(2026, 11, 26, 11, 0);
      final container = await createContainer(nowFn: () => currentNow);
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);
      notifier.updateDraft('EMP-1067', 'Checking IT access');
      expect(
        container.read(chatProvider).draftForContact('EMP-1067'),
        'Checking IT access',
      );

      final firstSent = await notifier.sendMessage(
        contactId: 'EMP-1067',
        text: 'Hi Divya, laptop VPN is ready?',
      );
      expect(firstSent, isTrue);
      expect(container.read(chatProvider).draftForContact('EMP-1067'), isEmpty);

      currentNow = DateTime(2026, 11, 26, 11, 5);
      final secondSent = await notifier.sendMessage(
        contactId: 'EMP-1067',
        text: 'Also need GitHub repo invite.',
      );
      expect(secondSent, isTrue);

      final state = container.read(chatProvider);
      final thread = state.messagesForContact('EMP-1067');
      expect(thread.length, 2);
      expect(thread[0].text, 'Hi Divya, laptop VPN is ready?');
      expect(thread[1].text, 'Also need GitHub repo invite.');
      expect(thread[0].timestamp.isBefore(thread[1].timestamp), isTrue);

      final latest = state.latestMessageForContact('EMP-1067');
      expect(latest?.text, 'Also need GitHub repo invite.');
      expect(state.filteredContacts.first.id, 'EMP-1067');
    });

    test('sorts out-of-order saved messages chronologically and ignores corrupt entries',
        () async {
      final demoUser = LocalAuthRepository.primaryDemo.user;
      final now = DateTime(2026, 11, 26, 12, 0);

      final container = await createContainer(
        user: demoUser,
        nowFn: () => now,
        initialPrefs: {
          StorageKeys.chatMessagesForEmployee(demoUser.employeeId): jsonEncode([
            ChatMessage(
              id: 'm2',
              contactId: 'EMP-1015',
              text: 'Second message',
              isSentByMe: true,
              timestamp: DateTime(2026, 11, 26, 10, 30),
            ).toJson(),
            {'broken': true},
            ChatMessage(
              id: 'm1',
              contactId: 'EMP-1015',
              text: 'First message',
              isSentByMe: false,
              timestamp: DateTime(2026, 11, 26, 9, 0),
            ).toJson(),
          ]),
        },
      );
      addTearDown(container.dispose);

      final thread = container.read(chatProvider).messagesForContact('EMP-1015');
      expect(thread.length, 2);
      expect(thread[0].text, 'First message');
      expect(thread[1].text, 'Second message');
    });

    test('persists chat history per employee and isolates separate employees',
        () async {
      final now = DateTime(2026, 11, 26, 14, 0);
      final user1 = LocalAuthRepository.primaryDemo.user;
      final user2 = LocalAuthRepository.secondaryDemo.user;

      SharedPreferences.setMockInitialValues({
        StorageKeys.authSession: jsonEncode(user1.toJson()),
      });
      final prefs = await SharedPreferences.getInstance();

      // Session 1 (EMP-1042): send message.
      final c1 = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentTimeFunctionProvider.overrideWithValue(() => now),
        ],
      );
      await c1.read(chatProvider.notifier).sendMessage(
            contactId: 'EMP-1015',
            text: 'Private message from Santhosh',
          );
      c1.dispose();

      // Reload as EMP-1042: persisted message exists.
      final c1Reloaded = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentTimeFunctionProvider.overrideWithValue(() => now),
        ],
      );
      expect(
        c1Reloaded
            .read(chatProvider)
            .messagesForContact('EMP-1015')
            .any((m) => m.text == 'Private message from Santhosh'),
        isTrue,
      );
      c1Reloaded.dispose();

      // Switch to EMP-1088: EMP-1042's private message is isolated.
      await prefs.setString(
        StorageKeys.authSession,
        jsonEncode(user2.toJson()),
      );
      final c2 = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentTimeFunctionProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(c2.dispose);

      expect(
        c2
            .read(chatProvider)
            .messagesForContact('EMP-1015')
            .any((m) => m.text == 'Private message from Santhosh'),
        isFalse,
      );
    });

    test('mode switching preserves both Chat and HRMS states independently',
        () async {
      final now = DateTime(2026, 11, 26, 9, 45);
      final container = await createContainer(nowFn: () => now);
      addTearDown(container.dispose);

      await container.read(hrmsProvider.notifier).checkIn();
      container
          .read(chatProvider.notifier)
          .updateDraft('EMP-1088', 'Unsent draft note');

      container.read(appModeProvider.notifier).setMode(AppMode.chat);
      expect(
        container.read(hrmsProvider).todayStatusAt(now),
        TodayAttendanceStatus.checkedIn,
      );
      expect(
        container.read(chatProvider).draftForContact('EMP-1088'),
        'Unsent draft note',
      );

      container.read(appModeProvider.notifier).setMode(AppMode.hrms);
      expect(
        container.read(hrmsProvider).todayStatusAt(now),
        TodayAttendanceStatus.checkedIn,
      );
      expect(
        container.read(chatProvider).draftForContact('EMP-1088'),
        'Unsent draft note',
      );
    });
  });

  group('ChatMessage safety', () {
    test('returns null on malformed JSON payloads', () {
      expect(ChatMessage.tryFromJson(null), isNull);
      expect(
        ChatMessage.tryFromJson({
          'id': '1',
          'contactId': 'EMP-1088',
          'text': '   ',
          'isSentByMe': true,
          'timestamp': '2026-11-26T10:00:00.000',
        }),
        isNull,
      );
      expect(
        ChatMessage.tryFromJson({
          'id': '1',
          'contactId': 'EMP-1088',
          'text': 'Hello',
          'isSentByMe': true,
          'timestamp': 'invalid-date',
        }),
        isNull,
      );
    });
  });
}

