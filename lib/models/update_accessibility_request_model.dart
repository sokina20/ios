class UpdateAccessibilityRequestModel {
  final int userId;
  final String fontSize;
  final bool highContrast;
  final bool textToSpeech;
  final bool simplifiedMode;
  final String preferredInput;

  UpdateAccessibilityRequestModel({
    required this.userId,
    required this.fontSize,
    required this.highContrast,
    required this.textToSpeech,
    required this.simplifiedMode,
    required this.preferredInput,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'font_size': fontSize,
      'high_contrast': highContrast ? 1 : 0,
      'text_to_speech': textToSpeech ? 1 : 0,
      'simplified_mode': simplifiedMode ? 1 : 0,
      'preferred_input': preferredInput,
    };
  }

  // 🔹 إضافة fromJson (إذا كنت تستقبل نفس البيانات من السيرفر)
  factory UpdateAccessibilityRequestModel.fromJson(Map<String, dynamic> json) {
    return UpdateAccessibilityRequestModel(
      userId: json['user_id'] as int,
      fontSize: json['font_size'] as String,
      highContrast: json['high_contrast'] == 1,
      textToSpeech: json['text_to_speech'] == 1,
      simplifiedMode: json['simplified_mode'] == 1,
      preferredInput: json['preferred_input'] as String,
    );
  }
}