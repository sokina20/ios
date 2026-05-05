import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Colors;
import 'package:flutter/rendering.dart';
import 'package:saedny/core/theme/app_colors.dart';
import '../../database/database_helper.dart';
import 'widgets/admin_menu_sheet.dart';

class AdminDisabilitiesScreen extends StatefulWidget {
  const AdminDisabilitiesScreen({super.key});

  @override
  State<AdminDisabilitiesScreen> createState() =>
      _AdminDisabilitiesScreenState();
}

class _AdminDisabilitiesScreenState extends State<AdminDisabilitiesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _disabilities = [];
  List<Map<String, dynamic>> _filteredDisabilities = [];

  final TextEditingController _searchController = TextEditingController();
  
  final int _adminId = 1;
  final String _adminName = 'مدير النظام';
  final String _adminEmail = 'admin@saedny.com';

  @override
  void initState() {
    super.initState();
    _loadDisabilities();
    _searchController.addListener(_filterDisabilities);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        'لوحة تحكم المدير - إدارة الإعاقات',
        Directionality.of(context),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDisabilities() async {
    setState(() => _isLoading = true);

    try {
      final dbHelper = DatabaseHelper();
      final items = await dbHelper.query(
        'disability_types',
        orderBy: 'id ASC',
      );
      
      if (!mounted) return;
      
      SemanticsService.announce(
        'تم تحميل ${items.length} نوع إعاقة',
        Directionality.of(context),
      );
      
      setState(() {
        _disabilities = items;
        _filteredDisabilities = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorMessage('حدث خطأ: ${e.toString()}');
    }
  }

  void _filterDisabilities() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() => _filteredDisabilities = _disabilities);
      return;
    }

    final filtered = _disabilities.where((item) {
      final nameAr = (item['name_ar'] ?? '').toString().toLowerCase();
      final nameEn = (item['name_en'] ?? '').toString().toLowerCase();
      final description = (item['description'] ?? '').toString().toLowerCase();
      final status = (item['status'] ?? '').toString().toLowerCase();

      return nameAr.contains(query) ||
          nameEn.contains(query) ||
          description.contains(query) ||
          status.contains(query);
    }).toList();

    setState(() => _filteredDisabilities = filtered);
    
    SemanticsService.announce(
      'تم العثور على ${filtered.length} نوع إعاقة',
      Directionality.of(context),
    );
  }

  Future<void> _showDisabilityDialog({Map<String, dynamic>? disability}) async {
    final nameArController = TextEditingController(
      text: disability?['name_ar']?.toString() ?? '',
    );
    final nameEnController = TextEditingController(
      text: disability?['name_en']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: disability?['description']?.toString() ?? '',
    );

    String status = disability?['status']?.toString() ?? 'active';

    final formKey = GlobalKey<FormState>();

    await showCupertinoDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: CupertinoAlertDialog(
                title: Text(
                  disability == null
                      ? 'إضافة نوع إعاقة'
                      : 'تعديل نوع الإعاقة',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                content: SingleChildScrollView(
                  child: SizedBox(
                    width: 400,
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDialogTextField(
                            controller: nameArController,
                            label: 'الاسم بالعربي',
                            placeholder: 'أدخل اسم الإعاقة بالعربية',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'الاسم بالعربي مطلوب';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildDialogTextField(
                            controller: nameEnController,
                            label: 'الاسم بالإنجليزي',
                            placeholder: 'Enter disability name in English',
                          ),
                          const SizedBox(height: 12),
                          _buildDialogTextField(
                            controller: descriptionController,
                            label: 'الوصف',
                            placeholder: 'أدخل وصف نوع الإعاقة',
                            maxLines: 3,
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
                      final dbHelper = DatabaseHelper();

                      if (disability == null) {
                        await dbHelper.insert('disability_types', {
                          'name_ar': nameArController.text.trim(),
                          'name_en': nameEnController.text.trim().isEmpty ? null : nameEnController.text.trim(),
                          'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                          'status': status,
                          'created_at': now,
                        });
                        _showSuccessMessage('تمت إضافة نوع الإعاقة بنجاح');
                      } else {
                        await dbHelper.update(
                          'disability_types',
                          {
                            'name_ar': nameArController.text.trim(),
                            'name_en': nameEnController.text.trim().isEmpty ? null : nameEnController.text.trim(),
                            'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                            'status': status,
                          },
                          where: 'id = ?',
                          whereArgs: [disability['id']],
                        );
                        _showSuccessMessage('تم تحديث نوع الإعاقة بنجاح');
                      }
                      await _loadDisabilities();
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
                    color: value == 'active' ? AppColors.success : AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  value == 'active' ? 'نشط' : 'غير نشط',
                  style: TextStyle(
                    fontSize: 14,
                    color: value == 'active' ? AppColors.success : AppColors.textSecondary,
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

  Future<void> _deleteDisability(int id) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('حذف نوع الإعاقة'),
        content: const Text('هل أنت متأكد أنك تريد حذف هذا النوع؟'),
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
        'disability_types',
        where: 'id = ?',
        whereArgs: [id],
      );
      _showSuccessMessage('تم حذف نوع الإعاقة بنجاح');
      await _loadDisabilities();
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
        return AppColors.textSecondary;
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
          label: 'إدارة الإعاقات',
          child: const Text(
            'الإعاقات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        backgroundColor: AppColors.surface,
        trailing: AdminMenuSheet(
          currentRoute: 'disabilities',
          adminId: _adminId,
          adminName: _adminName,
          adminEmail: _adminEmail,
        ),
        automaticallyImplyLeading: false,
      ),
      child: _isLoading
          ?  Center(
              child: Semantics(
                label: 'جاري تحميل أنواع الإعاقات',
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
                      _buildDisabilitiesList(),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Semantics(
      label: 'إجمالي أنواع الإعاقات: ${_disabilities.length}',
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
                    'إدارة الإعاقات',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'إجمالي الأنواع: ${_disabilities.length}',
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
                Icons.accessibility_new_rounded,
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
            label: 'إضافة نوع إعاقة جديد',
            hint: 'اضغط لإضافة نوع إعاقة جديد',
            child: CupertinoButton(
              color: AppColors.primary,
              onPressed: () => _showDisabilityDialog(),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.add, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'إضافة نوع إعاقة',
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
            onPressed: _loadDisabilities,
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
        placeholder: 'بحث بالاسم أو الوصف أو الحالة',
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

  Widget _buildDisabilitiesList() {
    if (_filteredDisabilities.isEmpty) {
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
              Icons.accessibility_new_rounded,
              size: 60,
              color: AppColors.textSecondary,
              semanticLabel: 'أيقونة لا توجد إعاقات',
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد أنواع إعاقة مطابقة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ابدأ بإضافة نوع إعاقة جديد',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Semantics(
              button: true,
              label: 'إضافة نوع إعاقة جديد',
              child: CupertinoButton(
                color: AppColors.primary,
                onPressed: () => _showDisabilityDialog(),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.add, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'إضافة نوع إعاقة',
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

    return ListView.builder(
      itemCount: _filteredDisabilities.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final item = _filteredDisabilities[index];
        final id = item['id'] as int;
        final status = (item['status'] ?? 'active').toString();
        final nameAr = item['name_ar']?.toString() ?? '';
        final nameEn = item['name_en']?.toString() ?? '';
        final description = item['description']?.toString() ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Semantics(
            container: true,
            label: 'نوع إعاقة $nameAr، الحالة ${_statusText(status)}',
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
                    child: Icon(
                      Icons.accessibility_new_rounded,
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
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Semantics(
                        button: true,
                        label: 'تعديل نوع الإعاقة $nameAr',
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          
                          onPressed: () => _showDisabilityDialog(disability: item),
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
                        label: 'حذف نوع الإعاقة $nameAr',
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          
                          onPressed: () => _deleteDisability(id),
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
}