class UserModel {
  final String id;
  final String name;
  final String studentId;
  final String email;
  final String phone;
  final String department;
  final String program;
  final String bloodGroup;
  final String role; 

  const UserModel({
    required this.id,
    required this.name,
    required this.studentId,
    required this.email,
    required this.phone,
    required this.department,
    required this.program,
    required this.bloodGroup,
    required this.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      studentId: map['student_id'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      department: map['department'] ?? '',
      program: map['program'] ?? '',
      bloodGroup: map['blood_group'] ?? '',
      role: map['role'] ?? 'student',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'student_id': studentId,
        'email': email,
        'phone': phone,
        'department': department,
        'program': program,
        'blood_group': bloodGroup,
        'role': role,
      };
}