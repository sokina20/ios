import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/rendering.dart';
import 'package:saedny/core/theme/app_colors.dart';
import 'package:saedny/screens/auth/login_screen.dart';
import '../../../../../database/database_helper.dart';
import '../../../../../models/profile_response_model.dart';
import '../../../../../models/user_profile_model.dart';
import '../../../../../models/profile_stats_model.dart';
import '../../../../../models/profile_favorite_lesson_model.dart';
import '../../../../../models/profile_job_application_model.dart';
import 'edit_profile_screen.dart';
import 'accessibility_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  ProfileResponseModel? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    
    // ✅ إعلان ترحيبي عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        'الملف الشخصي',
        Directionality.of(context),
      );
    });
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final dbHelper = DatabaseHelper();

      final userData = await dbHelper.getUserById(widget.userId);
      if (userData == null) throw Exception('المستخدم غير موجود');

      final profileData = await dbHelper.getUserProfile(widget.userId);
      final accessibilityData = await dbHelper.getAccessibilitySettings(widget.userId);
      final statsData = await dbHelper.getUserStats(widget.userId);
      final favoriteLessonsData = await dbHelper.getUserFavoriteLessons(widget.userId);
      final jobApplicationsData = await dbHelper.getUserJobApplications(widget.userId);

      final user = UserProfileModel(
        id: userData['id'] as int,
        fullName: userData['full_name'] as String,
        email: userData['email'] as String,
        phone: userData['phone'] as String?,
        gender: userData['gender'] as String?,
        birthDate: userData['birth_date'] as String?,
        disabilityTypeId: userData['disability_type_id'] as int?,
        disabilityTypeName: await dbHelper.getDisabilityTypeName(userData['disability_type_id'] as int?),
        address: profileData?['address'] as String?,
        city: profileData?['city'] as String?,
        country: profileData?['country'] as String?,
        educationLevel: profileData?['education_level'] as String?,
        bio: profileData?['bio'] as String?,
        emergencyContactName: profileData?['emergency_contact_name'] as String?,
        emergencyContactPhone: profileData?['emergency_contact_phone'] as String?,
        guardianName: profileData?['guardian_name'] as String?,
        guardianPhone: profileData?['guardian_phone'] as String?,
        needsAssistant: (profileData?['needs_assistant'] as int?) == 1,
        preferredLanguage: profileData?['preferred_language'] as String? ?? 'ar',
        fontSize: accessibilityData?['font_size'] as String? ?? 'medium',
        highContrast: (accessibilityData?['high_contrast'] as int?) == 1,
        textToSpeech: (accessibilityData?['text_to_speech'] as int?) == 1,
        simplifiedMode: (accessibilityData?['simplified_mode'] as int?) == 1,
        preferredInput: accessibilityData?['preferred_input'] as String? ?? 'touch',
      );

      final stats = ProfileStatsModel(
        completedLessons: statsData['completed_lessons'] ?? 0,
        startedLessons: statsData['started_lessons'] ?? 0,
        favoriteLessons: statsData['favorite_lessons'] ?? 0,
        jobApplications: statsData['job_applications'] ?? 0,
      );

      final favoriteLessons = favoriteLessonsData.map((l) => ProfileFavoriteLessonModel(
        id: l['id'] as int,
        titleAr: l['title_ar'] as String,
        shortDescription: l['short_description'] as String?,
        lessonType: l['lesson_type'] as String,
        difficultyLevel: l['difficulty_level'] as String,
        durationMinutes: l['duration_minutes'] as int,
        thumbnail: l['thumbnail'] as String?,
        categoryName: l['category_name'] as String?,
      )).toList();

      final jobApplications = jobApplicationsData.map((j) => ProfileJobApplicationModel(
        id: j['id'] as int,
        jobId: j['job_id'] as int,
        title: j['title'] as String,
        location: j['location'] as String?,
        employmentType: j['employment_type'] as String,
        companyName: j['company_name'] as String,
        status: j['status'] as String,
        appliedAt: j['applied_at'] as String?,
        coverLetter: j['cover_letter'] as String?,
        cvFile: j['cv_file'] as String?,
      )).toList();

      if (!mounted) return;
      
      SemanticsService.announce(
        'تم تحميل الملف الشخصي للمستخدم ${user.fullName}',
        Directionality.of(context),
      );
      
      setState(() {
        _profile = ProfileResponseModel(
          user: user,
          stats: stats,
          favoriteLessons: favoriteLessons,
          jobApplications: jobApplications,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
      
      SemanticsService.announce(
        'فشل تحميل الملف الشخصي',
        Directionality.of(context),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final dbHelper = DatabaseHelper();
    await dbHelper.clearLoggedInUser();

    if (!mounted) return;

    SemanticsService.announce(
      'تم تسجيل الخروج، جاري الانتقال إلى شاشة تسجيل الدخول',
      Directionality.of(context),
    );

    Navigator.pushAndRemoveUntil(
      context,
      CupertinoPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showLogoutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            isDestructiveAction: true,
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  String _employmentTypeText(String type) {
    switch (type) {
      case 'full_time':
        return 'دوام كامل';
      case 'part_time':
        return 'دوام جزئي';
      case 'remote':
        return 'عن بعد';
      case 'internship':
        return 'تدريب';
      default:
        return type;
    }
  }

  String _applicationStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'reviewed':
        return 'تمت المراجعة';
      case 'accepted':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'reviewed':
        return AppColors.accent;
      default:
        return AppColors.textSecondary;
    }
  }

  String _lessonTypeText(String type) {
    switch (type) {
      case 'text':
        return 'نصي';
      case 'video':
        return 'فيديو';
      case 'audio':
        return 'صوتي';
      case 'interactive':
        return 'تفاعلي';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Semantics(
          header: true,
          label: 'الملف الشخصي',
          child: const Text(
            'الملف الشخصي',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing: Semantics(
          button: true,
          label: 'زر تعديل الملف الشخصي',
          hint: 'اضغط مرتين للانتقال إلى شاشة تعديل الملف الشخصي',
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _profile == null
                ? null
                : () async {
                    final updated = await Navigator.push<bool>(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => EditProfileScreen(
                          userId: widget.userId,
                          profile: _profile!.user,
                        ),
                      ),
                    );

                    if (updated == true) {
                      await _loadProfile();
                    }
                  },
            child: Icon(
              CupertinoIcons.pencil,
              size: 22,
              color: AppColors.primary,
            ),
          ),
        ),
        backgroundColor: AppColors.surface,
      ),
      child: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return  Center(
      child: Semantics(
        label: 'جاري تحميل الملف الشخصي',
        child: CupertinoActivityIndicator(
          radius: 18,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          label: 'حدث خطأ أثناء تحميل الملف الشخصي',
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
                semanticLabel: 'أيقونة خطأ',
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                button: true,
                label: 'زر إعادة المحاولة',
                hint: 'اضغط مرتين لإعادة تحميل الملف الشخصي',
                child: CupertinoButton(
                  color: AppColors.primary,
                  onPressed: _loadProfile,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.refresh, size: 18),
                      SizedBox(width: 8),
                      Text('إعادة المحاولة'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final profile = _profile!;
    final user = profile.user;
    final stats = profile.stats;

    return CupertinoScrollbar(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: _loadProfile,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ✅ بطاقة معلومات المستخدم
                Semantics(
                  label: 'معلومات المستخدم: ${user.fullName}',
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.secondary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.border,
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Icon(
                                CupertinoIcons.person_alt,
                                size: 32,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.fullName,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.email,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if ((user.phone ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.phone,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  user.phone!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if ((user.disabilityTypeName ?? '').isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.accessible,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'نوع الإعاقة: ${user.disabilityTypeName}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ✅ ملخص الحساب
                Semantics(
                  header: true,
                  label: 'ملخص الحساب',
                  child: const Text(
                    'ملخص الحساب',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'الدروس المكتملة',
                        stats.completedLessons.toString(),
                        CupertinoIcons.checkmark_circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'الدروس المبدوءة',
                        stats.startedLessons.toString(),
                        CupertinoIcons.play_circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'المفضلة',
                        stats.favoriteLessons.toString(),
                        CupertinoIcons.heart,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'طلبات الوظائف',
                        stats.jobApplications.toString(),
                        CupertinoIcons.briefcase,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ✅ زر إعدادات الوصول
                Semantics(
                  button: true,
                  label: 'زر إعدادات الوصول',
                  hint: 'اضغط لفتح إعدادات الوصول والتسهيلات',
                  child: CupertinoButton(
                    color: AppColors.secondary.withOpacity(0.1),
                    onPressed: () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => AccessibilitySettingsScreen(
                            userId: widget.userId,
                            currentFontSize: user.fontSize,
                            currentHighContrast: user.highContrast,
                            currentSimplifiedMode: user.simplifiedMode,
                            currentPreferredInput: user.preferredInput,
                          ),
                        ),
                      );

                      if (updated == true) {
                        await _loadProfile();
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.accessibility_new,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'إعدادات الوصول',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ✅ زر تسجيل الخروج
                Semantics(
                  button: true,
                  label: 'زر تسجيل الخروج',
                  hint: 'اضغط مرتين لتسجيل الخروج من التطبيق',
                  child: CupertinoButton(
                    color: AppColors.error.withOpacity(0.1),
                    onPressed: _showLogoutDialog,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.clear,
                          size: 20,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'تسجيل الخروج',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ✅ الدروس المفضلة
                Semantics(
                  header: true,
                  label: 'الدروس المفضلة',
                  child: const Text(
                    'الدروس المفضلة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (profile.favoriteLessons.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'لا توجد دروس مفضلة حالياً',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  ...profile.favoriteLessons.map((lesson) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.border,
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.titleAr,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if ((lesson.shortDescription ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  lesson.shortDescription!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildChip(
                                  Icons.category_outlined,
                                  lesson.categoryName ?? "-",
                                ),
                                _buildChip(
                                  CupertinoIcons.doc_text,
                                  _lessonTypeText(lesson.lessonType),
                                ),
                                _buildChip(
                                  CupertinoIcons.timer,
                                  '${lesson.durationMinutes} دقيقة',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 24),

                // ✅ الوظائف المقدم عليها
                Semantics(
                  header: true,
                  label: 'الوظائف المقدم عليها',
                  child: const Text(
                    'الوظائف المقدّم عليها',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (profile.jobApplications.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'لم تقم بالتقديم على وظائف بعد',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  ...profile.jobApplications.map((application) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.border,
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              application.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              application.companyName,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildStatusChip(
                                  _applicationStatusText(application.status),
                                  _getStatusColor(application.status),
                                ),
                                _buildChip(
                                  CupertinoIcons.briefcase,
                                  _employmentTypeText(application.employmentType),
                                ),
                                if ((application.location ?? '').isNotEmpty)
                                  _buildChip(
                                    CupertinoIcons.location,
                                    application.location!,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Semantics(
      label: '$title: $value',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }
}