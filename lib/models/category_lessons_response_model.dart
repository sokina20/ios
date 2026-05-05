import 'category_model.dart';
import 'lesson_model.dart';

class CategoryLessonsResponseModel {
  final CategoryModel category;
  final List<LessonModel> lessons;

  CategoryLessonsResponseModel({
    required this.category,
    required this.lessons,
  });

  factory CategoryLessonsResponseModel.fromJson(Map<String, dynamic> json) {
    return CategoryLessonsResponseModel(
      category: CategoryModel.fromJson(json['category'] ?? {}),
      lessons: (json['lessons'] as List? ?? [])
          .map((e) => LessonModel.fromJson(e))
          .toList(),
    );
  }

  // 🔹 تحويل الكائن إلى JSON (إذا احتجته للإرسال)
  Map<String, dynamic> toJson() {
    return {
      'category': category.toJson(),
      'lessons': lessons.map((e) => e.toJson()).toList(),
    };
  }
}