class ProfileFavoriteLessonModel {
  final int id;
  final String titleAr;
  final String? shortDescription;
  final String lessonType;
  final String difficultyLevel;
  final int durationMinutes;
  final String? thumbnail;
  final String? categoryName;

  ProfileFavoriteLessonModel({
    required this.id,
    required this.titleAr,
    this.shortDescription,
    required this.lessonType,
    required this.difficultyLevel,
    required this.durationMinutes,
    this.thumbnail,
    this.categoryName,
  });

  factory ProfileFavoriteLessonModel.fromJson(Map<String, dynamic> json) {
    return ProfileFavoriteLessonModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      titleAr: json['title_ar'] ?? '',
      shortDescription: json['short_description'],
      lessonType: json['lesson_type'] ?? 'text',
      difficultyLevel: json['difficulty_level'] ?? 'easy',
      durationMinutes: int.tryParse(json['duration_minutes'].toString()) ?? 0,
      thumbnail: json['thumbnail'],
      categoryName: json['category_name'],
    );
  }

  // 🔹 تحويل الكائن إلى JSON (إذا احتجته للإرسال)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title_ar': titleAr,
      'short_description': shortDescription,
      'lesson_type': lessonType,
      'difficulty_level': difficultyLevel,
      'duration_minutes': durationMinutes,
      'thumbnail': thumbnail,
      'category_name': categoryName,
    };
  }
}