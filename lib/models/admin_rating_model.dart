class AdminRatingModel {
  final int id;
  final int lessonId;
  final int userId;
  final int rating;
  final String? comment;
  final String status;
  final String createdAt;
  final String lessonTitle;
  final String userName;
  final String? userEmail;

  AdminRatingModel({
    required this.id,
    required this.lessonId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.status,
    required this.createdAt,
    required this.lessonTitle,
    required this.userName,
    this.userEmail,
  });

  factory AdminRatingModel.fromJson(Map<String, dynamic> json) {
    return AdminRatingModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      lessonId: int.tryParse(json['lesson_id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      rating: int.tryParse(json['rating'].toString()) ?? 0,
      comment: json['comment']?.toString(),
      status: json['status']?.toString() ?? 'visible',
      createdAt: json['created_at']?.toString() ?? '',
      lessonTitle: json['lesson_title']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? '',
      userEmail: json['user_email']?.toString(),
    );
  }

  // 🔹 تحويل الكائن إلى JSON (إذا احتجته للإرسال)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lesson_id': lessonId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
      'status': status,
      'created_at': createdAt,
      'lesson_title': lessonTitle,
      'user_name': userName,
      'user_email': userEmail,
    };
  }
}