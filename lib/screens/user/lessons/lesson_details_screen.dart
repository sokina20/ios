import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, LinearProgressIndicator, Colors;
import 'package:flutter/rendering.dart';
import 'package:saedny/core/theme/app_colors.dart';
import '../../../database/database_helper.dart';
import '../../../models/lesson_model.dart';
import '../../../models/lesson_resource_model.dart';

class LessonDetailsScreen extends StatefulWidget {
  final int userId;
  final int lessonId;

  const LessonDetailsScreen({
    super.key,
    required this.userId,
    required this.lessonId,
  });

  @override
  State<LessonDetailsScreen> createState() => _LessonDetailsScreenState();
}

class _LessonDetailsScreenState extends State<LessonDetailsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';
  LessonModel? _lesson;
  List<LessonResourceModel> _resources = [];
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLessonDetails();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadLessonDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final dbHelper = DatabaseHelper();
      
      final lessonData = await dbHelper.getLessonDetails(widget.lessonId, widget.userId);
      if (lessonData == null) throw Exception('الدرس غير موجود');
      
      final disabilityName = await dbHelper.getDisabilityTypeName(lessonData['target_disability_id'] as int?);
      
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
        disabilityName: disabilityName,
        progressPercent: (lessonData['progress_percent'] as num?)?.toDouble() ?? 0,
        isCompleted: (lessonData['is_completed'] as int?) == 1,
        isFavorite: (lessonData['is_favorite'] as int?) == 1,
        averageRating: (lessonData['average_rating'] as num?)?.toDouble() ?? 0,
        ratingsCount: (lessonData['ratings_count'] as int?) ?? 0,
        userRating: (lessonData['user_rating'] as int?) ?? 0,
      );
      
      final resourcesData = await dbHelper.getLessonResources(widget.lessonId);
      final resources = resourcesData.map((r) => LessonResourceModel(
        id: r['id'] as int,
        lessonId: r['lesson_id'] as int,
        resourceType: r['resource_type'] as String,
        filePath: r['file_path'] as String?,
        externalUrl: r['external_url'] as String?,
        title: r['title'] as String?,
      )).toList();

      if (!mounted) return;
      
      SemanticsService.announce(
        'تم تحميل تفاصيل الدرس ${lesson.titleAr}',
        Directionality.of(context),
      );
      
      setState(() {
        _lesson = lesson;
        _resources = resources;
        _selectedRating = lesson.userRating;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
      
      SemanticsService.announce(
        'فشل تحميل تفاصيل الدرس',
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

  Future<void> _saveProgress({
    required double progressPercent,
    required bool isCompleted,
  }) async {
    try {
      setState(() => _isSaving = true);

      SemanticsService.announce(
        isCompleted ? 'جاري إنهاء الدرس' : 'جاري حفظ التقدم',
        Directionality.of(context),
      );

      final dbHelper = DatabaseHelper();
      await dbHelper.updateLessonProgress(
        widget.userId,
        widget.lessonId,
        progressPercent.toInt(),
        isCompleted: isCompleted,
      );

      await _loadLessonDetails();

      if (!mounted) return;
      
      SemanticsService.announce(
        isCompleted ? 'تم إنهاء الدرس بنجاح' : 'تم حفظ التقدم بنجاح',
        Directionality.of(context),
      );
      
      _showSuccessMessage(isCompleted ? 'تم إنهاء الدرس بنجاح' : 'تم حفظ التقدم بنجاح');
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('حدث خطأ: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      setState(() => _isSaving = true);

      final dbHelper = DatabaseHelper();
      await dbHelper.toggleFavorite(widget.userId, widget.lessonId);

      await _loadLessonDetails();

      if (!mounted) return;
      
      final message = (_lesson?.isFavorite ?? false)
          ? 'تمت إضافة الدرس إلى المفضلة'
          : 'تمت إزالة الدرس من المفضلة';
      
      SemanticsService.announce(message, Directionality.of(context));
      _showSuccessMessage(message);
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('حدث خطأ: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  Future<void> _submitRating() async {
    if (_selectedRating < 1 || _selectedRating > 5) {
      _showErrorMessage('الرجاء اختيار تقييم من 1 إلى 5');
      return;
    }

    try {
      setState(() => _isSaving = true);

      SemanticsService.announce(
        'جاري إرسال تقييمك للدرس',
        Directionality.of(context),
      );

      final dbHelper = DatabaseHelper();
      await dbHelper.addOrUpdateRating(
        widget.userId,
        widget.lessonId,
        _selectedRating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      await _loadLessonDetails();

      if (!mounted) return;
      
      SemanticsService.announce('تم إرسال التقييم بنجاح', Directionality.of(context));
      _showSuccessMessage('تم إرسال التقييم بنجاح');
      
      _commentController.clear();
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('حدث خطأ: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  void _showSuccessMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('نجاح'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('خطأ'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Semantics(
          header: true,
          label: lesson == null ? 'تفاصيل الدرس' : 'تفاصيل درس ${lesson.titleAr}',
          child: Text(
            lesson?.titleAr ?? 'تفاصيل الدرس',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: lesson != null
            ? Semantics(
                button: true,
                label: lesson.isFavorite
                    ? 'إزالة الدرس من المفضلة'
                    : 'إضافة الدرس إلى المفضلة',
                hint: 'اضغط مرتين لتحديث حالة المفضلة',
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                  onPressed: _isSaving ? null : _toggleFavorite,
                  child: Icon(
                    lesson.isFavorite
                        ? CupertinoIcons.heart_fill
                        : CupertinoIcons.heart,
                    color: lesson.isFavorite ? AppColors.accent : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
              )
            : null,
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
        label: 'جاري تحميل تفاصيل الدرس',
        child: CupertinoActivityIndicator(radius: 18),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          label: 'حدث خطأ أثناء تحميل تفاصيل الدرس',
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
                hint: 'اضغط مرتين لإعادة تحميل تفاصيل الدرس',
                child: CupertinoButton(
                  color: AppColors.primary,
                  onPressed: _loadLessonDetails,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.refresh, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'إعادة المحاولة',
                        style: TextStyle(color: Colors.white),
                      ),
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
    final lesson = _lesson!;

    return CupertinoScrollbar(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: _loadLessonDetails,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // عنوان الدرس
                Semantics(
                  label: 'عنوان الدرس ${lesson.titleAr}',
                  child: Text(
                    lesson.titleAr,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // وصف مختصر
                if ((lesson.shortDescription ?? '').isNotEmpty)
                  Text(
                    lesson.shortDescription!,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 16),

                // شيبس المعلومات
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(Icons.category_outlined, 'القسم: ${lesson.categoryName ?? "-"}'),
                    _chip(_getLessonTypeIcon(lesson.lessonType), 'النوع: ${_lessonTypeText(lesson.lessonType)}'),
                    _buildDifficultyChip(lesson.difficultyLevel),
                    _chip(Icons.timer_outlined, 'المدة: ${lesson.durationMinutes} دقيقة'),
                    if ((lesson.disabilityName ?? '').isNotEmpty)
                      _chip(Icons.accessible, 'مناسب لـ ${lesson.disabilityName}'),
                  ],
                ),

                const SizedBox(height: 24),
                
                // نسبة التقدم
                Semantics(
                  label: 'نسبة التقدم الحالية ${lesson.progressPercent.toStringAsFixed(0)} بالمئة',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'التقدم',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: lesson.progressPercent / 100,
                          minHeight: 10,
                          backgroundColor: AppColors.border,
                          color: lesson.isCompleted
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'التقدم الحالي: ${lesson.progressPercent.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          color: lesson.isCompleted
                              ? AppColors.success
                              : AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                
                // أزرار التقدم
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Semantics(
                      button: true,
                      label: 'زر تحديد الدرس كمفتوح',
                      hint: 'يحفظ التقدم بنسبة 10 بالمئة',
                      child: CupertinoButton(
                        color: AppColors.secondary,
                        onPressed: _isSaving
                            ? null
                            : () => _saveProgress(
                                  progressPercent: lesson.progressPercent < 10 ? 10 : lesson.progressPercent,
                                  isCompleted: false,
                                ),
                        child: const Text(
                          'بدأت الدرس',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'زر إنهاء الدرس',
                      hint: 'يحفظ التقدم بنسبة 100 بالمئة ويجعل الدرس مكتمل',
                      child: CupertinoButton(
                        color: AppColors.primary,
                        onPressed: _isSaving
                            ? null
                            : () => _saveProgress(
                                  progressPercent: 100,
                                  isCompleted: true,
                                ),
                        child: const Text(
                          'إنهاء الدرس',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                
                // محتوى الدرس
                Semantics(
                  header: true,
                  label: 'محتوى الدرس',
                  child: const Text(
                    'محتوى الدرس',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.border,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    (lesson.content ?? '').isNotEmpty
                        ? lesson.content!
                        : 'لا يوجد محتوى متاح لهذا الدرس حاليًا',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.7,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                
                // موارد إضافية
                Semantics(
                  header: true,
                  label: 'موارد إضافية',
                  child: const Text(
                    'موارد إضافية',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_resources.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'لا توجد موارد إضافية حاليًا',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  ..._resources.map(_buildResourceCard),

                const SizedBox(height: 24),
                
                // التقييمات
                Semantics(
                  label: 'متوسط التقييم ${lesson.averageRating.toStringAsFixed(1)} من 5 بعدد ${lesson.ratingsCount} تقييم',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'التقييمات',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            final star = index + 1;
                            final isFilled = star <= lesson.averageRating.round();
                            return Icon(
                              isFilled ? CupertinoIcons.star_fill : CupertinoIcons.star,
                              size: 16,
                              color: isFilled ? AppColors.accent : AppColors.border,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            '${lesson.averageRating.toStringAsFixed(1)} / 5',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'عدد التقييمات: ${lesson.ratingsCount}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                
                // تقييم المستخدم
                const Text(
                  'قيّم هذا الدرس',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    final isSelected = star <= _selectedRating;

                    return Semantics(
                      button: true,
                      label: 'تقييم $star من 5',
                      hint: 'اضغط مرتين لاختيار هذا التقييم',
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(44, 44),
                        onPressed: _isSaving
                            ? null
                            : () {
                                setState(() {
                                  _selectedRating = star;
                                });
                                SemanticsService.announce(
                                  'تم اختيار تقييم $star من 5',
                                  Directionality.of(context),
                                );
                              },
                        child: Icon(
                          isSelected ? CupertinoIcons.star_fill : CupertinoIcons.star,
                          size: 32,
                          color: isSelected ? AppColors.accent : AppColors.border,
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 12),
                
                // حقل التعليق
                Semantics(
                  label: 'حقل تعليق التقييم',
                  hint: 'أدخل تعليقًا اختياريًا عن الدرس',
                  textField: true,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border,
                        width: 0.5,
                      ),
                    ),
                    child: CupertinoTextField(
                      controller: _commentController,
                      maxLines: 3,
                      minLines: 2,
                      placeholder: 'اكتب رأيك في الدرس...',
                      placeholderStyle: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                
                // زر إرسال التقييم
                Semantics(
                  button: true,
                  label: 'زر إرسال التقييم',
                  hint: 'اضغط مرتين لإرسال تقييمك لهذا الدرس',
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: AppColors.primary,
                      onPressed: _isSaving ? null : _submitRating,
                      child: _isSaving
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : const Text(
                              'إرسال التقييم',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(LessonResourceModel resource) {
    final title = resource.title ?? 'مورد إضافي';
    final resourceType = resource.resourceType == 'file' ? 'ملف' : 'رابط';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        label: 'مورد إضافي $title من نوع $resourceType',
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
          child: Row(
            children: [
              Icon(
                resource.resourceType == 'file'
                    ? CupertinoIcons.doc
                    : CupertinoIcons.link,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$title ($resourceType)',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                CupertinoIcons.forward,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Semantics(
      label: text,
      child: Container(
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
            Icon(
              icon,
              size: 12,
              color: AppColors.textSecondary,
            ),
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
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

  IconData _getLessonTypeIcon(String type) {
    switch (type) {
      case 'video':
        return CupertinoIcons.video_camera;
      case 'audio':
        return CupertinoIcons.music_albums;
      case 'interactive':
        return CupertinoIcons.hand_raised;
      default:
        return CupertinoIcons.doc_text;
    }
  }
}