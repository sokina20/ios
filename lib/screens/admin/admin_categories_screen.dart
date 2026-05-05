import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Colors;
import 'package:flutter/rendering.dart';
import 'package:saedny/core/theme/app_colors.dart';
import '../../database/database_helper.dart';
import 'widgets/admin_menu_sheet.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _filteredCategories = [];

  final TextEditingController _searchController = TextEditingController();
  
  final int _adminId = 1;
  final String _adminName = 'مدير النظام';
  final String _adminEmail = 'admin@saedny.com';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(_filterCategories);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        'لوحة تحكم المدير - إدارة الأقسام',
        Directionality.of(context),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    try {
      final dbHelper = DatabaseHelper();
      final categories = await dbHelper.query('categories', orderBy: 'id ASC');
      
      if (!mounted) return;
      
      SemanticsService.announce(
        'تم تحميل ${categories.length} قسم',
        Directionality.of(context),
      );
      
      setState(() {
        _categories = categories;
        _filteredCategories = categories;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorMessage('حدث خطأ: ${e.toString()}');
    }
  }

  void _filterCategories() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() => _filteredCategories = _categories);
      return;
    }

    final filtered = _categories.where((category) {
      final nameAr = (category['name_ar'] ?? '').toString().toLowerCase();
      final nameEn = (category['name_en'] ?? '').toString().toLowerCase();
      final description = (category['description'] ?? '').toString().toLowerCase();
      final status = (category['status'] ?? '').toString().toLowerCase();

      return nameAr.contains(query) ||
          nameEn.contains(query) ||
          description.contains(query) ||
          status.contains(query);
    }).toList();

    setState(() => _filteredCategories = filtered);
    
    SemanticsService.announce(
      'تم العثور على ${filtered.length} قسم',
      Directionality.of(context),
    );
  }

  Future<void> _showCategoryDialog({Map<String, dynamic>? category}) async {
    final nameArController = TextEditingController(
      text: category?['name_ar']?.toString() ?? '',
    );
    final nameEnController = TextEditingController(
      text: category?['name_en']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: category?['description']?.toString() ?? '',
    );
    final iconController = TextEditingController(
      text: category?['icon']?.toString() ?? '',
    );

    String status = category?['status']?.toString() ?? 'active';
    final formKey = GlobalKey<FormState>();
    final dbHelper = DatabaseHelper();

    await showCupertinoDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: CupertinoAlertDialog(
                title: Text(category == null ? 'إضافة قسم جديد' : 'تعديل القسم'),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDialogTextField(
                          controller: nameArController,
                          label: 'اسم القسم بالعربي',
                          placeholder: 'أدخل اسم القسم بالعربية',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'اسم القسم بالعربي مطلوب';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildDialogTextField(
                          controller: nameEnController,
                          label: 'اسم القسم بالإنجليزي',
                          placeholder: 'Enter category name in English',
                        ),
                        const SizedBox(height: 12),
                        _buildDialogTextField(
                          controller: descriptionController,
                          label: 'الوصف',
                          placeholder: 'أدخل وصف القسم',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        _buildDialogTextField(
                          controller: iconController,
                          label: 'الأيقونة',
                          placeholder: 'مثال: school',
                        ),
                        const SizedBox(height: 12),
                        _buildDialogStatusPicker(
                          value: status,
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => status = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  CupertinoDialogAction(
                    onPressed: () async {
                      if (formKey.currentState?.validate() != true) return;

                      Navigator.pop(context);
                      final now = DateTime.now().toIso8601String();

                      if (category == null) {
                        await dbHelper.insert('categories', {
                          'name_ar': nameArController.text.trim(),
                          'name_en': nameEnController.text.trim().isEmpty ? null : nameEnController.text.trim(),
                          'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                          'icon': iconController.text.trim().isEmpty ? null : iconController.text.trim(),
                          'status': status,
                          'created_at': now,
                          'updated_at': now,
                        });
                        _showSuccessMessage('تمت إضافة القسم بنجاح');
                      } else {
                        await dbHelper.update(
                          'categories',
                          {
                            'name_ar': nameArController.text.trim(),
                            'name_en': nameEnController.text.trim().isEmpty ? null : nameEnController.text.trim(),
                            'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                            'icon': iconController.text.trim().isEmpty ? null : iconController.text.trim(),
                            'status': status,
                            'updated_at': now,
                          },
                          where: 'id = ?',
                          whereArgs: [category['id']],
                        );
                        _showSuccessMessage('تم تحديث القسم بنجاح');
                      }
                      await _loadCategories();
                    },
                    child: const Text('حفظ'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    String? placeholder,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: CupertinoTextFormFieldRow(
        controller: controller,
        placeholder: placeholder ?? label,
        maxLines: maxLines,
        validator: validator,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildDialogStatusPicker({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return GestureDetector(
      onTap: () {
        _showStatusPicker(context, value, onChanged);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الحالة',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: value == 'active' ? AppColors.success : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  value == 'active' ? 'نشط' : 'غير نشط',
                  style: TextStyle(
                    fontSize: 14,
                    color: value == 'active' ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusPicker(BuildContext context, String currentStatus, ValueChanged<String?> onChanged) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('اختر الحالة'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              onChanged('active');
              Navigator.pop(context);
              SemanticsService.announce('تم اختيار حالة نشط', Directionality.of(context));
            },
            child: const Text('نشط'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              onChanged('inactive');
              Navigator.pop(context);
              SemanticsService.announce('تم اختيار حالة غير نشط', Directionality.of(context));
            },
            child: const Text('غير نشط'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
      ),
    );
  }

  Future<void> _deleteCategory(int id) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('حذف القسم'),
        content: const Text('هل أنت متأكد أنك تريد حذف هذا القسم؟'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            isDestructiveAction: true,
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );
      _showSuccessMessage('تم حذف القسم بنجاح');
      await _loadCategories();
    } catch (e) {
      _showErrorMessage('حدث خطأ: ${e.toString()}');
    }
  }

  void _showSuccessMessage(String message) {
    SemanticsService.announce(message, Directionality.of(context));
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
    SemanticsService.announce(message, Directionality.of(context));
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

  String _statusText(String status) {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'inactive':
        return 'غير نشط';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'inactive':
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
          label: 'إدارة الأقسام',
          child: const Text(
            'الأقسام',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        backgroundColor: AppColors.surface,
        trailing: AdminMenuSheet(
          currentRoute: 'categories',
          adminId: _adminId,
          adminName: _adminName,
          adminEmail: _adminEmail,
        ),
        automaticallyImplyLeading: false,
      ),
      child: _isLoading
          ?  Center(
              child: Semantics(
                label: 'جاري تحميل الأقسام',
                child: CupertinoActivityIndicator(radius: 20),
              ),
            )
          : CustomScrollView(
              slivers: [
                const CupertinoSliverRefreshControl(),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildTopActions(),
                      const SizedBox(height: 16),
                      _buildSearchCard(),
                      const SizedBox(height: 16),
                      if (_filteredCategories.isEmpty) _buildEmptyWidget() else _buildCategoriesList(),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Semantics(
      label: 'إجمالي الأقسام: ${_categories.length}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.secondary,
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إدارة الأقسام',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'عدد الأقسام الحالية: ${_categories.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.category_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopActions() {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: 'إضافة قسم جديد',
            hint: 'اضغط لإضافة قسم جديد',
            child: CupertinoButton(
              color: AppColors.primary,
              onPressed: () => _showCategoryDialog(),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.add, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'إضافة قسم جديد',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Semantics(
          button: true,
          label: 'تحديث القائمة',
          hint: 'اضغط لتحديث قائمة الأقسام',
          child: CupertinoButton(
            color: AppColors.surface,
            onPressed: _loadCategories,
            child: Icon(
              CupertinoIcons.refresh,
              size: 20,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: CupertinoTextField(
        controller: _searchController,
        placeholder: 'بحث باسم القسم (عربي/إنجليزي) أو الوصف',
        placeholderStyle: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.7),
        ),
        padding: const EdgeInsets.all(14),
        prefix: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Icon(
            CupertinoIcons.search,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildCategoriesList() {
    return ListView.builder(
      itemCount: _filteredCategories.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final item = _filteredCategories[index];
        final id = item['id'] as int;
        final status = (item['status'] ?? 'active').toString();
        final nameAr = item['name_ar']?.toString() ?? '';
        final nameEn = item['name_en']?.toString() ?? '';
        final description = item['description']?.toString() ?? '';
        final icon = item['icon']?.toString() ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Semantics(
            container: true,
            label: 'قسم $nameAr، الحالة ${_statusText(status)}',
            child: Container(
              padding: const EdgeInsets.all(16),
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.category_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nameAr,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (nameEn.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            nameEn,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _statusText(status),
                                style: TextStyle(
                                  color: _statusColor(status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (icon.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'الأيقونة: $icon',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Semantics(
                        button: true,
                        label: 'تعديل قسم $nameAr',
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _showCategoryDialog(category: item),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              CupertinoIcons.pencil,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Semantics(
                        button: true,
                        label: 'حذف قسم $nameAr',
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _deleteCategory(id),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              CupertinoIcons.delete,
                              size: 18,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.category_outlined,
            size: 60,
            color: AppColors.textSecondary,
            semanticLabel: 'أيقونة لا توجد أقسام',
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد أقسام حتى الآن',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة أول قسم ليظهر هنا',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Semantics(
            button: true,
            label: 'إضافة قسم جديد',
            child: CupertinoButton(
              color: AppColors.primary,
              onPressed: () => _showCategoryDialog(),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.add, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'إضافة قسم جديد',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}