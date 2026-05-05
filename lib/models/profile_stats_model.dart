class ProfileStatsModel {
  final int completedLessons;
  final int startedLessons;
  final int favoriteLessons;
  final int jobApplications;

  ProfileStatsModel({
    required this.completedLessons,
    required this.startedLessons,
    required this.favoriteLessons,
    required this.jobApplications,
  });

  factory ProfileStatsModel.fromJson(Map<String, dynamic> json) {
    return ProfileStatsModel(
      completedLessons: int.tryParse(json['completed_lessons'].toString()) ?? 0,
      startedLessons: int.tryParse(json['started_lessons'].toString()) ?? 0,
      favoriteLessons: int.tryParse(json['favorite_lessons'].toString()) ?? 0,
      jobApplications: int.tryParse(json['job_applications'].toString()) ?? 0,
    );
  }

  // 🔹 تحويل الكائن إلى JSON (إذا احتجته للإرسال)
  Map<String, dynamic> toJson() {
    return {
      'completed_lessons': completedLessons,
      'started_lessons': startedLessons,
      'favorite_lessons': favoriteLessons,
      'job_applications': jobApplications,
    };
  }
}