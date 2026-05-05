import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons; // للأيقونات الإضافية
import 'package:flutter/rendering.dart';
import 'package:saedny/core/theme/app_colors.dart';
import 'package:saedny/database/database_helper.dart';
import 'package:saedny/models/category_model.dart';
import 'package:saedny/screens/user/lessons/category_lessons_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final int userId;

  const CategoriesScreen({
    super.key,
    required this.userId,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    
    // ✅ إعلان ترحيبي لمستخدمي VoiceOver
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        'صفحة الأقسام، اختر القسم المناسب لك',
        Directionality.of(context),
      );
    });
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final dbHelper = DatabaseHelper();
      final categoriesData = await dbHelper.getActiveCategories();
      
      final categories = categoriesData.map((c) => CategoryModel(
        id: c['id'] as int,
        nameAr: c['name_ar'] as String,
        nameEn: c['name_en'] as String?,
        description: c['description'] as String?,
        icon: c['icon'] as String?,
      )).toList();

      if (!mounted) return;
      
      // ✅ إعلان عند نجاح التحميل
      if (categories.isNotEmpty) {
        SemanticsService.announce(
          'تم تحميل ${categories.length} قسم',
          Directionality.of(context),
        );
      }
      
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
      
      // ✅ إعلان عند حدوث خطأ
      SemanticsService.announce(
        'حدث خطأ: ${e.toString()}',
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
        return Icons.school;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'work':
        return Icons.work;
      case 'favorite':
        return Icons.favorite;
      case 'groups':
        return Icons.groups;
      case 'car':
        return Icons.directions_car;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Semantics(
          header: true,
          label: 'صفحة الأقسام التعليمية',
          child: const Text(
            'الأقسام',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
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
        label: 'جاري تحميل الأقسام',
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
          label: 'حدث خطأ أثناء تحميل الأقسام',
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
                hint: 'اضغط مرتين لإعادة تحميل الأقسام',
                child: CupertinoButton(
                  color: AppColors.primary,
                  onPressed: _loadCategories,
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
    if (_categories.isEmpty) {
      return Center(
        child: Semantics(
          label: 'لا توجد أقسام متاحة حالياً',
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.category_outlined,
                size: 64,
                color: AppColors.textSecondary,
                semanticLabel: 'أيقونة أقسام فارغة',
              ),
              const SizedBox(height: 16),
              const Text(
                'لا توجد أقسام متاحة حالياً',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                button: true,
                label: 'زر تحديث',
                hint: 'اضغط لتحديث قائمة الأقسام',
                child: CupertinoButton(
                  color: AppColors.primary,
                  onPressed: _loadCategories,
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
            onRefresh: _loadCategories,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = _categories[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildCategoryCard(category),
                  );
                },
                childCount: _categories.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return Semantics(
      button: true,
          label: 'قسم ${category.nameAr}',
      hint: 'اضغط مرتين لعرض الدروس داخل هذا القسم',
      child: GestureDetector(
        onTap: () {
          // ✅ إعلان عند فتح القسم
          SemanticsService.announce(
            'جاري فتح قسم ${category.nameAr}',
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              // ✅ أيقونة القسم مع دعم Accessibility
              Semantics(
                label: 'أيقونة قسم ${category.nameAr}',
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getCategoryIcon(category.icon),
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
                      category.nameAr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if ((category.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        category.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
    );
  }
}