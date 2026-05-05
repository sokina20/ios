class AdminJobApplicationModel {
  final int id;
  final int jobId;
  final int userId;
  final String applicantName;
  final String applicantEmail;
  final String? applicantPhone;
  final String jobTitle;
  final String companyName;
  final String? coverLetter;
  final String? cvFile;
  final String status;
  final String appliedAt;
  final String? reviewedAt;
  final String? notes;

  AdminJobApplicationModel({
    required this.id,
    required this.jobId,
    required this.userId,
    required this.applicantName,
    required this.applicantEmail,
    this.applicantPhone,
    required this.jobTitle,
    required this.companyName,
    this.coverLetter,
    this.cvFile,
    required this.status,
    required this.appliedAt,
    this.reviewedAt,
    this.notes,
  });

  factory AdminJobApplicationModel.fromJson(Map<String, dynamic> json) {
    return AdminJobApplicationModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      jobId: int.tryParse(json['job_id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      applicantName: json['applicant_name'] ?? '',
      applicantEmail: json['applicant_email'] ?? '',
      applicantPhone: json['applicant_phone'],
      jobTitle: json['job_title'] ?? '',
      companyName: json['company_name'] ?? '',
      coverLetter: json['cover_letter'],
      cvFile: json['cv_file'],
      status: json['status'] ?? 'pending',
      appliedAt: json['applied_at'] ?? '',
      reviewedAt: json['reviewed_at'],
      notes: json['notes'],
    );
  }

  // 🔹 تحويل الكائن إلى JSON (إذا احتجته للإرسال)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'user_id': userId,
      'applicant_name': applicantName,
      'applicant_email': applicantEmail,
      'applicant_phone': applicantPhone,
      'job_title': jobTitle,
      'company_name': companyName,
      'cover_letter': coverLetter,
      'cv_file': cvFile,
      'status': status,
      'applied_at': appliedAt,
      'reviewed_at': reviewedAt,
      'notes': notes,
    };
  }
}