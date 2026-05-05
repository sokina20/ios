class JobModel {
  final int id;
  final int companyId;
  final String title;
  final String description;
  final String? requirements;
  final String? location;
  final String employmentType;
  final String? salaryMin;
  final String? salaryMax;
  final int? targetDisabilityId;
  final String? applicationDeadline;
  final String? createdAt;
  final String companyName;
  final String? companyLogo;
  final String? disabilityName;
  final bool hasApplied;
  final String applicationStatus;

  // حقول إضافية للشركة والتقديم
  final String? companyEmail;
  final String? companyPhone;
  final String? companyWebsite;
  final String? companyCity;
  final String? companyAddress;
  final String? companyDescription;
  final String? coverLetter;
  final String? cvFile;
  final String? notes;

  JobModel({
    required this.id,
    required this.companyId,
    required this.title,
    required this.description,
    this.requirements,
    this.location,
    required this.employmentType,
    this.salaryMin,
    this.salaryMax,
    this.targetDisabilityId,
    this.applicationDeadline,
    this.createdAt,
    required this.companyName,
    this.companyLogo,
    this.disabilityName,
    required this.hasApplied,
    required this.applicationStatus,
    this.companyEmail,
    this.companyPhone,
    this.companyWebsite,
    this.companyCity,
    this.companyAddress,
    this.companyDescription,
    this.coverLetter,
    this.cvFile,
    this.notes,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      companyId: int.tryParse(json['company_id'].toString()) ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      requirements: json['requirements'],
      location: json['location'],
      employmentType: json['employment_type'] ?? 'full_time',
      salaryMin: json['salary_min']?.toString(),
      salaryMax: json['salary_max']?.toString(),
      targetDisabilityId: json['target_disability_id'] == null
          ? null
          : int.tryParse(json['target_disability_id'].toString()),
      applicationDeadline: json['application_deadline']?.toString(),
      createdAt: json['created_at']?.toString(),
      companyName: json['company_name'] ?? '',
      companyLogo: json['company_logo'],
      disabilityName: json['disability_name'],
      hasApplied: json['has_applied'].toString() == '1',
      applicationStatus: json['application_status']?.toString() ?? '',
      companyEmail: json['company_email'],
      companyPhone: json['company_phone'],
      companyWebsite: json['company_website'],
      companyCity: json['company_city'],
      companyAddress: json['company_address'],
      companyDescription: json['company_description'],
      coverLetter: json['cover_letter'],
      cvFile: json['cv_file'],
      notes: json['notes'],
    );
  }

  // 🔹 تحويل الكائن إلى JSON (إذا احتجته للإرسال)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'title': title,
      'description': description,
      'requirements': requirements,
      'location': location,
      'employment_type': employmentType,
      'salary_min': salaryMin,
      'salary_max': salaryMax,
      'target_disability_id': targetDisabilityId,
      'application_deadline': applicationDeadline,
      'created_at': createdAt,
      'company_name': companyName,
      'company_logo': companyLogo,
      'disability_name': disabilityName,
      'has_applied': hasApplied ? '1' : '0',
      'application_status': applicationStatus,
      'company_email': companyEmail,
      'company_phone': companyPhone,
      'company_website': companyWebsite,
      'company_city': companyCity,
      'company_address': companyAddress,
      'company_description': companyDescription,
      'cover_letter': coverLetter,
      'cv_file': cvFile,
      'notes': notes,
    };
  }
}