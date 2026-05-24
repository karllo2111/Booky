class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? nis;
  final String? kelas;
  final String? phone;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.nis,
    this.kelas,
    this.phone,
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:    json['id'],
      name:  json['name'] ?? '',
      email: json['email'] ?? '',
      role:  json['role'] ?? 'student',
      nis:   json['nis'],
      kelas: json['kelas'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email, 'role': role,
    'nis': nis, 'kelas': kelas, 'phone': phone,
  };
}
