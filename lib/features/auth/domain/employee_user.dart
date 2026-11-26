/// Represents an authenticated employee session.
///
/// Intentionally excludes password or secret fields so credentials are never
/// serialized into local storage.
class EmployeeUser {
  const EmployeeUser({
    required this.employeeId,
    required this.name,
    required this.email,
    required this.department,
    required this.designation,
  });

  final String employeeId;
  final String name;
  final String email;
  final String department;
  final String designation;

  /// Returns user initials for avatar badges (e.g. `SR` for `Santhosh R`).
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
        'employeeId': employeeId,
        'name': name,
        'email': email,
        'department': department,
        'designation': designation,
      };

  /// Parses an [EmployeeUser] from a decoded JSON map, returning `null` if any
  /// required field is missing or malformed.
  static EmployeeUser? tryFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    final employeeId = json['employeeId'];
    final name = json['name'];
    final email = json['email'];
    final department = json['department'];
    final designation = json['designation'];

    if (employeeId is! String ||
        name is! String ||
        email is! String ||
        department is! String ||
        designation is! String) {
      return null;
    }

    if (employeeId.trim().isEmpty ||
        name.trim().isEmpty ||
        email.trim().isEmpty) {
      return null;
    }

    return EmployeeUser(
      employeeId: employeeId.trim(),
      name: name.trim(),
      email: email.trim(),
      department: department.trim(),
      designation: designation.trim(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmployeeUser &&
        other.employeeId == employeeId &&
        other.name == name &&
        other.email == email &&
        other.department == department &&
        other.designation == designation;
  }

  @override
  int get hashCode =>
      Object.hash(employeeId, name, email, department, designation);
}

