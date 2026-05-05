import 'lesson_model.dart';
import 'lesson_resource_model.dart';

class LessonDetailsResponseModel {
  final LessonModel lesson;
  final List<LessonResourceModel> resources;

  LessonDetailsResponseModel({
    required this.lesson,
    required this.resources,
  });

  factory LessonDetailsResponseModel.fromJson(Map<String, dynamic> json) {
    return LessonDetailsResponseModel(
      lesson: LessonModel.fromJson(json['lesson'] ?? {}),
      resources: (json['resources'] as List? ?? [])
          .map((e) => LessonResourceModel.fromJson(e))
          .toList(),
    );
  }

  // 🔹 تحويل الكائن إلى JSON (إذا احتجته للإرسال)
  Map<String, dynamic> toJson() {
    return {
      'lesson': lesson.toJson(),
      'resources': resources.map((e) => e.toJson()).toList(),
    };
  }
}