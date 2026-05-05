class LessonModel {
  final int id;
  final int categoryId;
  final String titleAr;
  final String? titleEn;
  final String? shortDescription;
  final String? content;
  final String lessonType;
  final String difficultyLevel;
  final int? targetDisabilityId;
  final String? thumbnail;
  final String? lessonFile;
  final String? lessonFileType;
  final int durationMinutes;
  final int isFeatured;
  final String? categoryName;
  final String? disabilityName;
  final double progressPercent;
  final bool isCompleted;
  final bool isFavorite;
  final double averageRating;
  final int ratingsCount;
  final int userRating;

  LessonModel({
    required this.id,
    required this.categoryId,
    required this.titleAr,
    this.titleEn,
    this.shortDescription,
    this.content,
    required this.lessonType,
    required this.difficultyLevel,
    this.targetDisabilityId,
    this.thumbnail,
    this.lessonFile,
    this.lessonFileType,
    required this.durationMinutes,
    required this.isFeatured,
    this.categoryName,
    this.disabilityName,
    required this.progressPercent,
    required this.isCompleted,
    required this.isFavorite,
    required this.averageRating,
    required this.ratingsCount,
    required this.userRating,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      categoryId: int.tryParse(json['category_id'].toString()) ?? 0,
      titleAr: json['title_ar'] ?? '',
      titleEn: json['title_en'],
      shortDescription: json['short_description'],
      content: json['content'],
      lessonType: json['lesson_type'] ?? 'text',
      difficultyLevel: json['difficulty_level'] ?? 'easy',
      targetDisabilityId: json['target_disability_id'] == null
          ? null
          : int.tryParse(json['target_disability_id'].toString()),
      thumbnail: json['thumbnail'],
      lessonFile: json['lesson_file'],
      lessonFileType: json['lesson_file_type'],
      durationMinutes: int.tryParse(json['duration_minutes'].toString()) ?? 0,
      isFeatured: int.tryParse(json['is_featured'].toString()) ?? 0,
      categoryName: json['category_name'],
      disabilityName: json['disability_name'],
      progressPercent: double.tryParse(json['progress_percent'].toString()) ?? 0,
      isCompleted: json['is_completed'].toString() == '1',
      isFavorite: json['is_favorite'].toString() == '1',
      averageRating: double.tryParse(json['average_rating'].toString()) ?? 0,
      ratingsCount: int.tryParse(json['ratings_count'].toString()) ?? 0,
      userRating: int.tryParse(json['user_rating'].toString()) ?? 0,
    );
  }

  // 🔹 تحويل الكائن إلى JSON (إذا احتجته للإرسال)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'title_ar': titleAr,
      'title_en': titleEn,
      'short_description': shortDescription,
      'content': content,
      'lesson_type': lessonType,
      'difficulty_level': difficultyLevel,
      'target_disability_id': targetDisabilityId,
      'thumbnail': thumbnail,
      'lesson_file': lessonFile,
      'lesson_file_type': lessonFileType,
      'duration_minutes': durationMinutes,
      'is_featured': isFeatured,
      'category_name': categoryName,
      'disability_name': disabilityName,
      'progress_percent': progressPercent,
      'is_completed': isCompleted ? '1' : '0',
      'is_favorite': isFavorite ? '1' : '0',
      'average_rating': averageRating,
      'ratings_count': ratingsCount,
      'user_rating': userRating,
    };
  }
}
