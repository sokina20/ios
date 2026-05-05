import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, LinearProgressIndicator;
import 'package:flutter/rendering.dart';
import 'package:saedny/core/theme/app_colors.dart';
import '../../../database/database_helper.dart';
import '../../../models/lesson_model.dart';
import 'lesson_details_screen.dart';

class CategoryLessonsScreen extends StatefulWidget {
  final int userId;
  final int categoryId;
  final String categoryName;

  const CategoryLessonsScreen({
    super.key,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryLessonsScreen> createState() => _CategoryLessonsScreenState();
}

class _CategoryLessonsScreenState extends State<CategoryLessonsScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<LessonModel> _lessons = [];

  @override
  void initState() {
    super.initState();
    _loadLessons();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        'دروس قسم ${widget.categoryName}',
        Directionality.of(context),
      );
    });
  }

  Future<void> _loadLessons() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final dbHelper = DatabaseHelper();
      
      final lessonsData = await dbHelper.getLessonsByCategory(widget.userId, widget.categoryId);
      
      final List<LessonModel> lessons = [];
      
      for (var lessonData in lessonsData) {
        final lesson = LessonModel(
          id: lessonData['id'] as int,
          categoryId: lessonData['category_id'] as int,
          titleAr: lessonData['title_ar'] as String,
          titleEn: lessonData['title_en'] as String?,
          shortDescription: lessonData['short_description'] as String?,
          content: lessonData['content'] as String?,
          lessonType: lessonData['lesson_type'] as String,
          difficultyLevel: lessonData['difficulty_level'] as String,
          targetDisabilityId: lessonData['target_disability_id'] as int?,
          thumbnail: lessonData['thumbnail'] as String?,
          lessonFile: lessonData['lesson_file'] as String?,
          lessonFileType: lessonData['lesson_file_type'] as String?,
          durationMinutes: lessonData['duration_minutes'] as int,
          isFeatured: lessonData['is_featured'] as int,
          categoryName: lessonData['category_name'] as String?,
          disabilityName: await dbHelper.getDisabilityTypeName(lessonData['target_disability_id'] as int?),
          progressPercent: (lessonData['progress_percent'] as num?)?.toDouble() ?? 0,
          isCompleted: (lessonData['is_completed'] as int?) == 1,
          isFavorite: (lessonData['is_favorite'] as int?) == 1,
          averageRating: (lessonData['average_rating'] as num?)?.toDouble() ?? 0,
          ratingsCount: (lessonData['ratings_count'] as int?) ?? 0,
          userRating: (lessonData['user_rating'] as int?) ?? 0,
        );
        
        lessons.add(lesson);
      }

      if (!mounted) return;
      
      if (lessons.isNotEmpty) {
        SemanticsService.announce(
          'تم تحميل ${lessons.length} درس في هذا القسم',
          Directionality.of(context),
        );
      }
      
      setState(() {
        _lessons = lessons;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
      
      SemanticsService.announce(
        'فشل تحميل الدروس: ${e.toString()}',
        Directionality.of(context),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
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

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.accent;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Semantics(
          header: true,
          label: 'دروس قسم ${widget.categoryName}',
          child: Text(
            widget.categoryName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
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
        label: 'جاري تحميل الدروس',
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
          label: 'حدث خطأ أثناء تحميل الدروس',
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
                hint: 'اضغط مرتين لإعادة تحميل الدروس',
                child: CupertinoButton(
                  color: AppColors.primary,
                  onPressed: _loadLessons,
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
    if (_lessons.isEmpty) {
      return Center(
        child: Semantics(
          label: 'لا توجد دروس في هذا القسم حالياً',
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.menu_book_outlined,
                size: 64,
                color: AppColors.textSecondary,
                semanticLabel: 'أيقونة دروس فارغة',
              ),
              const SizedBox(height: 16),
              const Text(
                'لا توجد دروس مناسبة في هذا القسم حاليًا',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Semantics(
                button: true,
                label: 'زر تحديث',
                hint: 'اضغط لتحديث قائمة الدروس',
                child: CupertinoButton(
                  color: AppColors.primary,
                  onPressed: _loadLessons,
                  child: const Text('تحديث'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CupertinoScrollbar(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: _loadLessons,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final lesson = _lessons[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildLessonCard(lesson),
                  );
                },
                childCount: _lessons.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(LessonModel lesson) {
    return Semantics(
      button: true,
      label: 'درس ${lesson.titleAr}، المستوى ${_difficultyText(lesson.difficultyLevel)}، التقدم ${lesson.progressPercent.toStringAsFixed(0)} بالمئة',
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
          
          SemanticsService.announce(
            'جاري تحديث تقدم الدرس',
            Directionality.of(context),
          );
          await _loadLessons();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان الدرس مع أيقونة النوع
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lesson.titleAr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  _buildLessonTypeIcon(lesson.lessonType),
                ],
              ),
              
              // الوصف المختصر
              if ((lesson.shortDescription ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  lesson.shortDescription!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // الشيبس (معلومات سريعة)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(
                    Icons.category_outlined,
                    _lessonTypeText(lesson.lessonType),
                  ),
                  _chip(
                    Icons.timer_outlined,
                    'المدة: ${lesson.durationMinutes} دقيقة',
                  ),
                  _chip(
                    Icons.star_outline,
                    'التقييم: ${lesson.averageRating.toStringAsFixed(1)}',
                  ),
                  _buildDifficultyChip(lesson.difficultyLevel),
                  if (lesson.isFavorite)
                    _chip(
                      Icons.favorite,
                      'في المفضلة',
                      isFavorite: true,
                    ),
                  if (lesson.isCompleted)
                    _chip(
                      Icons.check_circle,
                      'مكتمل',
                      isCompleted: true,
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // شريط التقدم
              Semantics(
                label: 'نسبة التقدم ${lesson.progressPercent.toStringAsFixed(0)} بالمئة',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: lesson.progressPercent / 100,
                        minHeight: 8,
                        backgroundColor: AppColors.border,
                        color: lesson.isCompleted
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'التقدم',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${lesson.progressPercent.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: lesson.isCompleted
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ تصحيح: استخدام أيقونات موجودة فقط
  Widget _buildLessonTypeIcon(String type) {
    IconData icon;
    switch (type) {
      case 'video':
        icon = CupertinoIcons.video_camera; // ✅ موجود
        break;
      case 'audio':
        icon = CupertinoIcons.music_albums; // ✅ موجود
        break;
      case 'interactive':
        icon = CupertinoIcons.hand_raised; // ✅ موجود (بدلاً من hand_tap)
        break;
      default:
        icon = CupertinoIcons.doc_text; // ✅ موجود
    }
    
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 18,
        color: AppColors.primary,
      ),
    );
  }

  Widget _chip(IconData icon, String text, {
    bool isFavorite = false,
    bool isCompleted = false,
  }) {
    Color getTextColor() {
      if (isFavorite) return AppColors.accent;
      if (isCompleted) return AppColors.success;
      return AppColors.textSecondary;
    }
    
    Color getBgColor() {
      if (isFavorite) return AppColors.accent.withOpacity(0.1);
      if (isCompleted) return AppColors.success.withOpacity(0.1);
      return AppColors.background;
    }
    
    return Semantics(
      label: text,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: getBgColor(),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: getTextColor().withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: getTextColor(),
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: getTextColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(String difficulty) {
    final color = _getDifficultyColor(difficulty);
    final text = _difficultyText(difficulty);
    
    return Semantics(
      label: 'مستوى $text',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.speed,
              size: 12,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}