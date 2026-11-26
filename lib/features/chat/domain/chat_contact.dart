/// Represents a coworker available in the internal employee chat directory.
class ChatContact {
  const ChatContact({
    required this.id,
    required this.name,
    required this.role,
    required this.department,
    required this.isOnline,
    required this.statusLabel,
  });

  final String id;
  final String name;
  final String role;
  final String department;
  final bool isOnline;
  final String statusLabel;

  /// Returns avatar initials (e.g. `AN` for `Ananya Nair`).
  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'E';
    }
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'department': department,
        'isOnline': isOnline,
        'statusLabel': statusLabel,
      };

  static ChatContact? tryFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = json['id'];
    final name = json['name'];
    final role = json['role'];
    final department = json['department'];
    final isOnline = json['isOnline'];
    final statusLabel = json['statusLabel'];

    if (id is! String ||
        id.trim().isEmpty ||
        name is! String ||
        name.trim().isEmpty ||
        role is! String ||
        department is! String) {
      return null;
    }

    return ChatContact(
      id: id.trim(),
      name: name.trim(),
      role: role.trim(),
      department: department.trim(),
      isOnline: isOnline is bool ? isOnline : false,
      statusLabel:
          statusLabel is String && statusLabel.trim().isNotEmpty
              ? statusLabel.trim()
              : 'Available',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatContact &&
        other.id == id &&
        other.name == name &&
        other.role == role &&
        other.department == department &&
        other.isOnline == isOnline &&
        other.statusLabel == statusLabel;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, role, department, isOnline, statusLabel);
}

