import 'profile_favorite_lesson_model.dart';
import 'profile_job_application_model.dart';
import 'profile_stats_model.dart';
import 'user_profile_model.dart';

class ProfileResponseModel {
  final UserProfileModel user;
  final ProfileStatsModel stats;
  final List<ProfileFavoriteLessonModel> favoriteLessons;
  final List<ProfileJobApplicationModel> jobApplications;

  ProfileResponseModel({
    required this.user,
    required this.stats,
    required this.favoriteLessons,
    required this.jobApplications,
  });

  factory ProfileResponseModel.fromJson(Map<String, dynamic> json) {
    return ProfileResponseModel(
      user: UserProfileModel.fromJson(json['user'] ?? {}),
      stats: ProfileStatsModel.fromJson(json['stats'] ?? {}),
      favoriteLessons: (json['favorite_lessons'] as List? ?? [])
          .map((e) => ProfileFavoriteLessonModel.fromJson(e))
          .toList(),
      jobApplications: (json['job_applications'] as List? ?? [])
          .map((e) => ProfileJobApplicationModel.fromJson(e))
          .toList(),
    );
  }

  // 🔹 تحويل الكائن إلى JSON (إذا احتجته للإرسال)
  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'stats': stats.toJson(),
      'favorite_lessons': favoriteLessons.map((e) => e.toJson()).toList(),
      'job_applications': jobApplications.map((e) => e.toJson()).toList(),
    };
  }
}