class UpdateProfileRequestModel {
  final int userId;
  final String fullName;
  final String? phone;
  final String? gender;
  final String? birthDate;
  final int? disabilityTypeId;
  final String? address;
  final String? city;
  final String? country;
  final String? educationLevel;
  final String? bio;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? guardianName;
  final String? guardianPhone;
  final bool needsAssistant;
  final String preferredLanguage;

  UpdateProfileRequestModel({
    required this.userId,
    required this.fullName,
    this.phone,
    this.gender,
    this.birthDate,
    this.disabilityTypeId,
    this.address,
    this.city,
    this.country,
    this.educationLevel,
    this.bio,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.guardianName,
    this.guardianPhone,
    required this.needsAssistant,
    required this.preferredLanguage,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'gender': gender,
      'birth_date': birthDate,
      'disability_type_id': disabilityTypeId,
      'address': address,
      'city': city,
      'country': country,
      'education_level': educationLevel,
      'bio': bio,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'guardian_name': guardianName,
      'guardian_phone': guardianPhone,
      'needs_assistant': needsAssistant ? 1 : 0,
      'preferred_language': preferredLanguage,
    };
  }

  // 🔹 إضافة fromJson (إذا كنت تستقبل نفس البيانات من السيرفر)
  factory UpdateProfileRequestModel.fromJson(Map<String, dynamic> json) {
    return UpdateProfileRequestModel(
      userId: json['user_id'] as int,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      gender: json['gender'] as String?,
      birthDate: json['birth_date'] as String?,
      disabilityTypeId: json['disability_type_id'] as int?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      educationLevel: json['education_level'] as String?,
      bio: json['bio'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      guardianName: json['guardian_name'] as String?,
      guardianPhone: json['guardian_phone'] as String?,
      needsAssistant: json['needs_assistant'] == 1,
      preferredLanguage: json['preferred_language'] as String,
    );
  }
}