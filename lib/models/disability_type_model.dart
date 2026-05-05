class DisabilityTypeModel {
  final int id;
  final String nameAr;
  final String? nameEn;

  DisabilityTypeModel({
    required this.id,
    required this.nameAr,
    this.nameEn,
  });

  factory DisabilityTypeModel.fromJson(Map<String, dynamic> json) {
    return DisabilityTypeModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      nameAr: json['name_ar']?.toString() ?? '',
      nameEn: json['name_en']?.toString(),
    );
  }

  // 🔹 تحويل الكائن إلى JSON (إذا احتجته للإرسال)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
    };
  }
}