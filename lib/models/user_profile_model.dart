class UserProfileModel {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String? gender;
  final String? birthDate;
  final int? disabilityTypeId;
  final String? disabilityTypeName;
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

  // إعدادات إمكانية الوصول
  final String fontSize;
  final bool highContrast;
  final bool textToSpeech;
  final bool simplifiedMode;
  final String preferredInput;

  UserProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.gender,
    this.birthDate,
    this.disabilityTypeId,
    this.disabilityTypeName,
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
    required this.fontSize,
    required this.highContrast,
    required this.textToSpeech,
    required this.simplifiedMode,
    required this.preferredInput,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      gender: json['gender'],
      birthDate: json['birth_date']?.toString(),
      disabilityTypeId: json['disability_type_id'] == null
          ? null
          : int.tryParse(json['disability_type_id'].toString()),
      disabilityTypeName: json['disability_type_name'],
      address: json['address'],
      city: json['city'],
      country: json['country'],
      educationLevel: json['education_level'],
      bio: json['bio'],
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactPhone: json['emergency_contact_phone'],
      guardianName: json['guardian_name'],
      guardianPhone: json['guardian_phone'],
      needsAssistant: json['needs_assistant'].toString() == '1',
      preferredLanguage: json['preferred_language'] ?? 'ar',
      fontSize: json['font_size'] ?? 'medium',
      highContrast: json['high_contrast'].toString() == '1',
      textToSpeech: json['text_to_speech'].toString() == '1',
      simplifiedMode: json['simplified_mode'].toString() == '1',
      preferredInput: json['preferred_input'] ?? 'touch',
    );
  }

  // 🔹 تحويل الكائن إلى JSON (إذا احتجته للإرسال)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'gender': gender,
      'birth_date': birthDate,
      'disability_type_id': disabilityTypeId,
      'disability_type_name': disabilityTypeName,
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
      'font_size': fontSize,
      'high_contrast': highContrast ? 1 : 0,
      'text_to_speech': textToSpeech ? 1 : 0,
      'simplified_mode': simplifiedMode ? 1 : 0,
      'preferred_input': preferredInput,
    };
  }
}