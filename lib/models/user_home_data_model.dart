class UserHomeDataModel {
  final HomeUserModel user;
  final HomeStatsModel stats;
  final List<HomeCategoryModel> categories;
  final List<HomeLessonModel> featuredLessons;
  final List<HomeJobModel> recommendedJobs;

  UserHomeDataModel({
    required this.user,
    required this.stats,
    required this.categories,
    required this.featuredLessons,
    required this.recommendedJobs,
  });

  factory UserHomeDataModel.fromJson(Map<String, dynamic> json) {
    return UserHomeDataModel(
      user: HomeUserModel.fromJson(json['user'] ?? {}),
      stats: HomeStatsModel.fromJson(json['stats'] ?? {}),
      categories: (json['categories'] as List? ?? [])
          .map((e) => HomeCategoryModel.fromJson(e))
          .toList(),
      featuredLessons: (json['featured_lessons'] as List? ?? [])
          .map((e) => HomeLessonModel.fromJson(e))
          .toList(),
      recommendedJobs: (json['recommended_jobs'] as List? ?? [])
          .map((e) => HomeJobModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'stats': stats.toJson(),
      'categories': categories.map((e) => e.toJson()).toList(),
      'featured_lessons': featuredLessons.map((e) => e.toJson()).toList(),
      'recommended_jobs': recommendedJobs.map((e) => e.toJson()).toList(),
    };
  }
}

class HomeUserModel {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final int? disabilityTypeId;
  final String? disabilityTypeName;

  HomeUserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.disabilityTypeId,
    this.disabilityTypeName,
  });

  factory HomeUserModel.fromJson(Map<String, dynamic> json) {
    return HomeUserModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      disabilityTypeId: json['disability_type_id'] == null
          ? null
          : int.tryParse(json['disability_type_id'].toString()),
      disabilityTypeName: json['disability_type_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'disability_type_id': disabilityTypeId,
      'disability_type_name': disabilityTypeName,
    };
  }
}

class HomeStatsModel {
  final int completedLessons;
  final int favoriteLessons;
  final int jobApplications;

  HomeStatsModel({
    required this.completedLessons,
    required this.favoriteLessons,
    required this.jobApplications,
  });

  factory HomeStatsModel.fromJson(Map<String, dynamic> json) {
    return HomeStatsModel(
      completedLessons: int.tryParse(json['completed_lessons'].toString()) ?? 0,
      favoriteLessons: int.tryParse(json['favorite_lessons'].toString()) ?? 0,
      jobApplications: int.tryParse(json['job_applications'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completed_lessons': completedLessons,
      'favorite_lessons': favoriteLessons,
      'job_applications': jobApplications,
    };
  }
}

class HomeCategoryModel {
  final int id;
  final String nameAr;
  final String? description;
  final String? icon;

  HomeCategoryModel({
    required this.id,
    required this.nameAr,
    this.description,
    this.icon,
  });

  factory HomeCategoryModel.fromJson(Map<String, dynamic> json) {
    return HomeCategoryModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      nameAr: json['name_ar'] ?? '',
      description: json['description'],
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_ar': nameAr,
      'description': description,
      'icon': icon,
    };
  }
}

class HomeLessonModel {
  final int id;
  final String titleAr;
  final String? shortDescription;
  final String lessonType;
  final String difficultyLevel;
  final int durationMinutes;
  final String? thumbnail;
  final int isFeatured;
  final String? categoryName;

  HomeLessonModel({
    required this.id,
    required this.titleAr,
    this.shortDescription,
    required this.lessonType,
    required this.difficultyLevel,
    required this.durationMinutes,
    this.thumbnail,
    required this.isFeatured,
    this.categoryName,
  });

  factory HomeLessonModel.fromJson(Map<String, dynamic> json) {
    return HomeLessonModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      titleAr: json['title_ar'] ?? '',
      shortDescription: json['short_description'],
      lessonType: json['lesson_type'] ?? 'text',
      difficultyLevel: json['difficulty_level'] ?? 'easy',
      durationMinutes: int.tryParse(json['duration_minutes'].toString()) ?? 0,
      thumbnail: json['thumbnail'],
      isFeatured: int.tryParse(json['is_featured'].toString()) ?? 0,
      categoryName: json['category_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title_ar': titleAr,
      'short_description': shortDescription,
      'lesson_type': lessonType,
      'difficulty_level': difficultyLevel,
      'duration_minutes': durationMinutes,
      'thumbnail': thumbnail,
      'is_featured': isFeatured,
      'category_name': categoryName,
    };
  }
}

class HomeJobModel {
  final int id;
  final String title;
  final String companyName;
  final String? location;
  final String employmentType;
  final String? salaryMin;
  final String? salaryMax;
  final String? applicationDeadline;
  final String? companyLogo;

  HomeJobModel({
    required this.id,
    required this.title,
    required this.companyName,
    this.location,
    required this.employmentType,
    this.salaryMin,
    this.salaryMax,
    this.applicationDeadline,
    this.companyLogo,
  });

  factory HomeJobModel.fromJson(Map<String, dynamic> json) {
    return HomeJobModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      companyName: json['company_name'] ?? '',
      location: json['location'],
      employmentType: json['employment_type'] ?? 'full_time',
      salaryMin: json['salary_min']?.toString(),
      salaryMax: json['salary_max']?.toString(),
      applicationDeadline: json['application_deadline']?.toString(),
      companyLogo: json['company_logo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'company_name': companyName,
      'location': location,
      'employment_type': employmentType,
      'salary_min': salaryMin,
      'salary_max': salaryMax,
      'application_deadline': applicationDeadline,
      'company_logo': companyLogo,
    };
  }
}
