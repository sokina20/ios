class CategoryModel {
  final int id;
  final String nameAr;
  final String? nameEn;
  final String? description;
  final String? icon;

  CategoryModel({
    required this.id,
    required this.nameAr,
    this.nameEn,
    this.description,
    this.icon,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      nameAr: json['name_ar'] ?? '',
      nameEn: json['name_en'],
      description: json['description'],
      icon: json['icon'],
    );
  }

  // 🔹 تحويل الكائن إلى JSON (إذا احتجته للإرسال)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'description': description,
      'icon': icon,
    };
  }
}