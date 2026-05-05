class JobApplicationRequestModel {
  final int jobId;
  final int userId;
  final String? coverLetter;
  final String? cvFile;

  JobApplicationRequestModel({
    required this.jobId,
    required this.userId,
    this.coverLetter,
    this.cvFile,
  });

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'user_id': userId,
      'cover_letter': coverLetter,
      'cv_file': cvFile,
    };
  }

  // 🔹 إضافة fromJson (إذا كنت تستقبل نفس البيانات من السيرفر)
  factory JobApplicationRequestModel.fromJson(Map<String, dynamic> json) {
    return JobApplicationRequestModel(
      jobId: json['job_id'] as int,
      userId: json['user_id'] as int,
      coverLetter: json['cover_letter'] as String?,
      cvFile: json['cv_file'] as String?,
    );
  }
}