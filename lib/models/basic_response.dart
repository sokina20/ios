class BasicResponse {
  final bool success;
  final String message;

  BasicResponse({
    required this.success,
    required this.message,
  });

  factory BasicResponse.fromJson(Map<String, dynamic> json) {
    return BasicResponse(
      success: json['success'] == true,
      message: json['message'] ?? '',
    );
  }

  // 🔹 تحويل الكائن إلى JSON (إذا احتجته للإرسال)
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
    };
  }
}