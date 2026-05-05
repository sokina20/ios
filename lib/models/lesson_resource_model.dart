class LessonResourceModel {
  final int id;
  final int lessonId;
  final String resourceType;
  final String? filePath;
  final String? externalUrl;
  final String? title;

  LessonResourceModel({
    required this.id,
    required this.lessonId,
    required this.resourceType,
    this.filePath,
    this.externalUrl,
    this.title,
  });

  factory LessonResourceModel.fromJson(Map<String, dynamic> json) {
    return LessonResourceModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      lessonId: int.tryParse(json['lesson_id'].toString()) ?? 0,
      resourceType: json['resource_type'] ?? '',
      filePath: json['file_path'],
      externalUrl: json['external_url'],
      title: json['title'],
    );
  }

  // 🔹 تحويل الكائن إلى JSON (إذا احتجته للإرسال)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lesson_id': lessonId,
      'resource_type': resourceType,
      'file_path': filePath,
      'external_url': externalUrl,
      'title': title,
    };
  }
}
