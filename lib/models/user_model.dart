class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final String? token;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      token: json['token'],
    );
  }

  // 🔹 تحويل الكائن إلى JSON (إذا احتجته للإرسال)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'role': role,
      'token': token,
    };
  }
}