import 'user_model.dart';

class AuthResponse {
  final bool success;
  final String message;
  final UserModel? user;

  AuthResponse({
    required this.success,
    required this.message,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] == true,
      message: json['message'] ?? '',
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }

  // 🔹 تحويل الكائن إلى JSON (إذا احتجته للإرسال)
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'user': user?.toJson(),
    };
  }
}