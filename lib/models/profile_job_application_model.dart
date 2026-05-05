class ProfileJobApplicationModel {
  final int id;
  final int jobId;
  final String title;
  final String? location;
  final String employmentType;
  final String companyName;
  final String status;
  final String? appliedAt;
  final String? coverLetter;
  final String? cvFile;

  ProfileJobApplicationModel({
    required this.id,
    required this.jobId,
    required this.title,
    this.location,
    required this.employmentType,
    required this.companyName,
    required this.status,
    this.appliedAt,
    this.coverLetter,
    this.cvFile,
  });

  factory ProfileJobApplicationModel.fromJson(Map<String, dynamic> json) {
    return ProfileJobApplicationModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      jobId: int.tryParse(json['job_id'].toString()) ?? 0,
      title: json['title'] ?? '',
      location: json['location'],
      employmentType: json['employment_type'] ?? 'full_time',
      companyName: json['company_name'] ?? '',
      status: json['status'] ?? 'pending',
      appliedAt: json['applied_at']?.toString(),
      coverLetter: json['cover_letter'],
      cvFile: json['cv_file'],
    );
  }

  // 🔹 تحويل الكائن إلى JSON (إذا احتجته للإرسال)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'title': title,
      'location': location,
      'employment_type': employmentType,
      'company_name': companyName,
      'status': status,
      'applied_at': appliedAt,
      'cover_letter': coverLetter,
      'cv_file': cvFile,
    };
  }
}