import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:saedny/core/theme/app_colors.dart';
import 'package:saedny/screens/user/profile/profile_screen.dart';
import '../../../database/database_helper.dart';
import '../../../models/user_home_data_model.dart';
import '../categories/categories_screen.dart';
import '../lessons/category_lessons_screen.dart';
import '../lessons/lesson_details_screen.dart';
import '../jobs/jobs_screen.dart';
import '../jobs/job_details_screen.dart';

class UserHomeScreen extends StatefulWidget {
  final int userId;

  const UserHomeScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  UserHomeDataModel? _homeData;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    
    // ✅ إعلان ترحيبي لمستخدمي VoiceOver
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        'مرحباً بك في الصفحة الرئيسية لتطبيق ساعدني',
        Directionality.of(context),
      );
    });
  }

  Future<void> _loadHomeData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final dbHelper = DatabaseHelper();
      
      final userData = await dbHelper.getUserById(widget.userId);
      if (userData == null) throw Exception('المستخدم غير موجود');
      
      final user = HomeUserModel(
        id: userData['id'] as int,
        fullName: userData['full_name'] as String,
        email: userData['email'] as String,
        phone: userData['phone'] as String?,
        disabilityTypeId: userData['disability_type_id'] as int?,
        disabilityTypeName: await dbHelper.getDisabilityTypeName(userData['disability_type_id'] as int?),
      );

      final statsData = await dbHelper.getUserStats(widget.userId);
      final stats = HomeStatsModel(
        completedLessons: statsData['completed_lessons'] as int,
        favoriteLessons: statsData['favorite_lessons'] as int,
        jobApplications: statsData['job_applications'] as int,
      );

      final categoriesData = await dbHelper.getActiveCategories();
      final categories = categoriesData.map((c) => HomeCategoryModel(
        id: c['id'] as int,
        nameAr: c['name_ar'] as String,
        description: c['description'] as String?,
        icon: c['icon'] as String?,
      )).toList();

      final featuredLessonsData = await dbHelper.getFeaturedLessons(widget.userId);
      final featuredLessons = featuredLessonsData.map((l) => HomeLessonModel(
        id: l['id'] as int,
        titleAr: l['title_ar'] as String,
        shortDescription: l['short_description'] as String?,
        lessonType: l['lesson_type'] as String,
        difficultyLevel: l['difficulty_level'] as String,
        durationMinutes: l['duration_minutes'] as int,
        thumbnail: l['thumbnail'] as String?,
        isFeatured: l['is_featured'] as int,
        categoryName: l['category_name'] as String?,
      )).toList();

      final userDisabilityId = userData['disability_type_id'] as int?;
      final recommendedJobsData = await dbHelper.getRecommendedJobs(widget.userId, userDisabilityId);
      final recommendedJobs = recommendedJobsData.map((j) => HomeJobModel(
        id: j['id'] as int,
        title: j['title'] as String,
        companyName: j['company_name'] as String,
        location: j['location'] as String?,
        employmentType: j['employment_type'] as String,
        salaryMin: j['salary_min']?.toString(),
        salaryMax: j['salary_max']?.toString(),
        applicationDeadline: j['application_deadline'] as String?,
        companyLogo: j['company_logo'] as String?,
      )).toList();

      if (!mounted) return;
      
      // ✅ إعلان عند نجاح التحميل
      SemanticsService.announce(
        'تم تحميل البيانات بنجاح',
        Directionality.of(context),
      );
      
      setState(() {
        _homeData = UserHomeDataModel(
          user: user,
          stats: stats,
          categories: categories,
          featuredLessons: featuredLessons,
          recommendedJobs: recommendedJobs,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      
      // ✅ إعلان عند حدوث خطأ
      SemanticsService.announce(
        'حدث خطأ: $_errorMessage',
        Directionality.of(context),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'school':
        return CupertinoIcons.book;
      case 'fitness_center':
        return CupertinoIcons.hand_thumbsup;
      case 'work':
        return CupertinoIcons.briefcase;
      case 'favorite':
        return CupertinoIcons.heart;
      case 'groups':
        return CupertinoIcons.group;
      default:
        return CupertinoIcons.square_grid_2x2;
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

  String _difficultyText(String value) {
    switch (value) {
      case 'easy':
        return 'سهل';
      case 'medium':
        return 'متوسط';
      case 'hard':
        return 'صعب';
      default:
        return value;
    }
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Semantics(
          header: true,
          label: 'الصفحة الرئيسية لتطبيق ساعدني',
          child: const Text(
            'ساعدني',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing: Semantics(
          button: true,
          label: 'الملف الشخصي',
          hint: 'اضغط مرتين لفتح الملف الشخصي',
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => ProfileScreen(userId: widget.userId),
                ),
              );
            },
            child: const Icon(
              CupertinoIcons.person_circle,
              size: 30,
            ),
          ),
        ),
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
        label: 'جاري تحميل الصفحة الرئيسية',
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
          label: 'حدث خطأ أثناء تحميل الصفحة الرئيسية',
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Icon(
                CupertinoIcons.cloud,
                size: 64,
                semanticLabel: 'أيقونة خطأ تحميل البيانات',
              ),
              const SizedBox(height: 16),
              const Text(
                'تعذر تحميل البيانات',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Semantics(
                button: true,
                label: 'زر إعادة المحاولة',
                hint: 'اضغط مرتين لإعادة تحميل الصفحة الرئيسية',
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: AppColors.primary,
                    onPressed: _loadHomeData,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.refresh),
                        SizedBox(width: 8),
                        Text('إعادة المحاولة'),
                      ],
                    ),
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
    final data = _homeData!;

    return CupertinoScrollbar(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: _loadHomeData,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildWelcomeCard(data.user),
                const SizedBox(height: 16),
                _buildQuickStats(data.stats),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  title: 'الأقسام',
                  actionText: 'عرض الكل',
                  semanticsLabel: 'قسم الأقسام',
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => CategoriesScreen(userId: widget.userId),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildCategoriesGrid(data.categories),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  title: 'دروس مناسبة لك',
                  actionText: data.featuredLessons.isNotEmpty ? 'عرض المزيد' : null,
                  semanticsLabel: 'قسم الدروس المناسبة',
                  onTap: data.featuredLessons.isNotEmpty
                      ? () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (_) => CategoriesScreen(userId: widget.userId),
                            ),
                          );
                        }
                      : null,
                ),
                const SizedBox(height: 12),
                _buildLessonsList(data.featuredLessons),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  title: 'وظائف حديثة',
                  actionText: data.recommendedJobs.isNotEmpty ? 'عرض الكل' : null,
                  semanticsLabel: 'قسم الوظائف الحديثة',
                  onTap: data.recommendedJobs.isNotEmpty
                      ? () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (_) => JobsScreen(userId: widget.userId),
                            ),
                          );
                        }
                      : null,
                ),
                const SizedBox(height: 12),
                _buildJobsList(data.recommendedJobs),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(HomeUserModel user) {
    return Semantics(
      label: 'بطاقة ترحيب بالمستخدم ${user.fullName}',
      container: true,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: 'صورة المستخدم ${user.fullName}',
              child: const CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.secondary,
                child: Icon(
                  CupertinoIcons.person,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    label: user.fullName,
                    child: Text(
                      'مرحبًا ${user.fullName}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    label: user.disabilityTypeName == null || user.disabilityTypeName!.trim().isEmpty
                        ? 'تم تجهيز الصفحة الرئيسية لتكون واضحة وسهلة الاستخدام'
                        : 'تم تخصيص المحتوى حسب نوع الإعاقة: ${user.disabilityTypeName}',
                    child: Text(
                      user.disabilityTypeName == null || user.disabilityTypeName!.trim().isEmpty
                          ? 'تم تجهيز الصفحة الرئيسية لتكون واضحة وسهلة الاستخدام.'
                          : 'تم تخصيص المحتوى حسب نوع الإعاقة: ${user.disabilityTypeName}',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    label: 'البريد الإلكتروني: ${user.email}',
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.mail,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            user.email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if ((user.phone ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'رقم الهاتف: ${user.phone}',
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.phone,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              user.phone!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(HomeStatsModel stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          label: 'إحصائيات سريعة',
          child: const Text(
            'إحصائيات سريعة',
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
                label: 'الدروس المكتملة',
                value: stats.completedLessons.toString(),
                icon: CupertinoIcons.checkmark_circle,
                semanticsLabel: 'عدد الدروس المكتملة ${stats.completedLessons}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: 'المفضلة',
                value: stats.favoriteLessons.toString(),
                icon: CupertinoIcons.heart,
                semanticsLabel: 'عدد الدروس في المفضلة ${stats.favoriteLessons}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: 'طلبات الوظائف',
                value: stats.jobApplications.toString(),
                icon: CupertinoIcons.briefcase,
                semanticsLabel: 'عدد طلبات الوظائف ${stats.jobApplications}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required String semanticsLabel,
  }) {
    return Semantics(
      label: semanticsLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.3,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String semanticsLabel,
    String? actionText,
    VoidCallback? onTap,
  }) {
    return Semantics(
      container: true,
      label: semanticsLabel,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              label: title,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          if (actionText != null)
            Semantics(
              button: true,
              label: actionText,
              hint: 'اضغط مرتين لفتح المزيد',
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onTap,
                child: Text(
                  actionText,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid(List<HomeCategoryModel> categories) {
    if (categories.isEmpty) {
      return _buildEmptyCard(
        message: 'لا توجد أقسام متاحة حاليًا',
        icon: CupertinoIcons.square_grid_2x2,
      );
    }

    final displayedCategories = categories.take(4).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayedCategories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.18,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final category = displayedCategories[index];

        return Semantics(
          button: true,
          label: 'قسم ${category.nameAr}',
          hint: 'اضغط مرتين لعرض الدروس الخاصة بهذا القسم',
          child: GestureDetector(
            onTap: () {
              SemanticsService.announce(
                'تم فتح قسم ${category.nameAr}',
                Directionality.of(context),
              );
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => CategoryLessonsScreen(
                    userId: widget.userId,
                    categoryId: category.id,
                    categoryName: category.nameAr,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border, width: 0.5),
                color: AppColors.surface,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getCategoryIcon(category.icon),
                    size: 34,
                    color: AppColors.primary,
                    semanticLabel: 'أيقونة قسم ${category.nameAr}',
                  ),
                  const SizedBox(height: 10),
                  Text(
                    category.nameAr,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if ((category.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      category.description!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.3,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLessonsList(List<HomeLessonModel> lessons) {
    if (lessons.isEmpty) {
      return _buildEmptyCard(
        message: 'لا توجد دروس مناسبة حاليًا',
        icon: CupertinoIcons.book,
      );
    }

    final displayedLessons = lessons.take(3).toList();

    return Column(
      children: displayedLessons.map((lesson) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Semantics(
            button: true,
            label: 'درس ${lesson.titleAr}',
            hint: 'اضغط مرتين لعرض تفاصيل الدرس',
            child: GestureDetector(
              onTap: () async {
                SemanticsService.announce(
                  'جاري فتح درس ${lesson.titleAr}',
                  Directionality.of(context),
                );
                await Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => LessonDetailsScreen(
                      userId: widget.userId,
                      lessonId: lesson.id,
                    ),
                  ),
                );
                if (!mounted) return;
                await _loadHomeData();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border, width: 0.5),
                  color: AppColors.surface,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: 'أيقونة الدرس',
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          CupertinoIcons.play_circle,
                          size: 28,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.titleAr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            lesson.shortDescription?.trim().isNotEmpty == true
                                ? lesson.shortDescription!
                                : 'لا يوجد وصف مختصر لهذا الدرس',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildMetaChip('النوع: ${_lessonTypeText(lesson.lessonType)}'),
                              _buildMetaChip('المدة: ${lesson.durationMinutes} دقيقة'),
                              _buildMetaChip('المستوى: ${_difficultyText(lesson.difficultyLevel)}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      CupertinoIcons.forward,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildJobsList(List<HomeJobModel> jobs) {
    if (jobs.isEmpty) {
      return _buildEmptyCard(
        message: 'لا توجد وظائف مناسبة حاليًا',
        icon: CupertinoIcons.briefcase,
      );
    }

    final displayedJobs = jobs.take(3).toList();

    return Column(
      children: displayedJobs.map((job) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Semantics(
            button: true,
            label: 'وظيفة ${job.title} في شركة ${job.companyName}',
            hint: 'اضغط مرتين لعرض تفاصيل الوظيفة',
            child: GestureDetector(
              onTap: () async {
                SemanticsService.announce(
                  'جاري فتح تفاصيل وظيفة ${job.title}',
                  Directionality.of(context),
                );
                await Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => JobDetailsScreen(
                      userId: widget.userId,
                      jobId: job.id,
                    ),
                  ),
                );
                if (!mounted) return;
                await _loadHomeData();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border, width: 0.5),
                  color: AppColors.surface,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: 'أيقونة الوظيفة',
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          CupertinoIcons.briefcase,
                          size: 28,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.companyName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if ((job.location ?? '').trim().isNotEmpty)
                                _buildMetaChip('الموقع: ${job.location}'),
                              _buildMetaChip('النوع: ${_employmentTypeText(job.employmentType)}'),
                              if ((job.applicationDeadline ?? '').trim().isNotEmpty)
                                _buildMetaChip('آخر موعد: ${job.applicationDeadline}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      CupertinoIcons.forward,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetaChip(String text) {
    return Semantics(
      label: text,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13.5,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard({
    required String message,
    required IconData icon,
  }) {
    return Semantics(
      label: message,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 0.5),
          color: AppColors.background,
        ),
        child: Column(
          children: [
            Icon(icon, size: 38, color: AppColors.textSecondary),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}