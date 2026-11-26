/// Represents a single message inside an employee-to-employee conversation.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.contactId,
    required this.text,
    required this.isSentByMe,
    required this.timestamp,
    this.isSample = false,
  });

  final String id;
  final String contactId;
  final String text;
  final bool isSentByMe;
  final DateTime timestamp;
  final bool isSample;

  Map<String, dynamic> toJson() => {
        'id': id,
        'contactId': contactId,
        'text': text,
        'isSentByMe': isSentByMe,
        'timestamp': timestamp.toIso8601String(),
        'isSample': isSample,
      };

  static ChatMessage? tryFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = json['id'];
    final contactId = json['contactId'];
    final text = json['text'];
    final isSentByMe = json['isSentByMe'];
    final timestampRaw = json['timestamp'];
    final isSample = json['isSample'];

    if (id is! String ||
        id.trim().isEmpty ||
        contactId is! String ||
        contactId.trim().isEmpty ||
        text is! String ||
        text.trim().isEmpty ||
        isSentByMe is! bool ||
        timestampRaw is! String) {
      return null;
    }

    final parsedTimestamp = DateTime.tryParse(timestampRaw);
    if (parsedTimestamp == null) {
      return null;
    }

    return ChatMessage(
      id: id.trim(),
      contactId: contactId.trim(),
      text: text,
      isSentByMe: isSentByMe,
      timestamp: parsedTimestamp,
      isSample: isSample is bool ? isSample : false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.id == id &&
        other.contactId == contactId &&
        other.text == text &&
        other.isSentByMe == isSentByMe &&
        other.timestamp == timestamp &&
        other.isSample == isSample;
  }

  @override
  int get hashCode =>
      Object.hash(id, contactId, text, isSentByMe, timestamp, isSample);
}

