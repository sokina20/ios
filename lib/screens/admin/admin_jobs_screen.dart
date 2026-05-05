import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Colors;
import 'package:flutter/rendering.dart';
import 'package:saedny/core/theme/app_colors.dart';
import '../../database/database_helper.dart';
import 'widgets/admin_menu_sheet.dart';

class AdminJobsScreen extends StatefulWidget {
  const AdminJobsScreen({super.key});

  @override
  State<AdminJobsScreen> createState() => _AdminJobsScreenState();
}

class _AdminJobsScreenState extends State<AdminJobsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _disabilities = [];

  final int _adminId = 1;
  final String _adminName = 'مدير النظام';
  final String _adminEmail = 'admin@saedny.com';

  @override
  void initState() {
    super.initState();
    _loadAll();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        'لوحة تحكم المدير - إدارة الوظائف',
        Directionality.of(context),
      );
    });
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);

    try {
      final dbHelper = DatabaseHelper();
      
      final jobs = await dbHelper.rawQuery('''
        SELECT 
          j.*,
          c.company_name,
          dt.name_ar as target_disability_name
        FROM jobs j
        JOIN companies c ON j.company_id = c.id
        LEFT JOIN disability_types dt ON j.target_disability_id = dt.id
        ORDER BY j.created_at DESC
      ''');
      
      final companies = await dbHelper.query(
        'companies',
        where: 'status = ?',
        whereArgs: ['approved'],
        orderBy: 'company_name ASC',
      );
      
      final disabilities = await dbHelper.query(
        'disability_types',
        where: 'status = ?',
        whereArgs: ['active'],
        orderBy: 'name_ar ASC',
      );
      
      if (!mounted) return;
      
      SemanticsService.announce(
        'تم تحميل ${jobs.length} وظيفة',
        Directionality.of(context),
      );
      
      setState(() {
        _jobs = jobs;
        _companies = companies;
        _disabilities = disabilities;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
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

  Future<void> _showJobDialog({Map<String, dynamic>? job}) async {
    final titleController = TextEditingController(
      text: job?['title']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: job?['description']?.toString() ?? '',
    );
    final requirementsController = TextEditingController(
      text: job?['requirements']?.toString() ?? '',
    );
    final locationController = TextEditingController(
      text: job?['location']?.toString() ?? '',
    );
    final salaryMinController = TextEditingController(
      text: (job?['salary_min'] as num?)?.toString() ?? '',
    );
    final salaryMaxController = TextEditingController(
      text: (job?['salary_max'] as num?)?.toString() ?? '',
    );
    final deadlineController = TextEditingController(
      text: job?['application_deadline']?.toString() ?? '',
    );

    int? selectedCompanyId = job?['company_id'] as int?;
    int? selectedDisabilityId = job?['target_disability_id'] as int?;
    String employmentType = job?['employment_type']?.toString() ?? 'full_time';
    bool isActive = (job?['is_active'] as int?) == 1;

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
                title: Text(
                  job == null ? 'إضافة وظيفة جديدة' : 'تعديل الوظيفة',
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
                          _buildCompanyPicker(
                            value: selectedCompanyId,
                            onChanged: (value) {
                              setDialogState(() => selectedCompanyId = value);
                            },
                            validator: (value) {
                              if (value == null) return 'اختر الشركة';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildDialogTextField(
                            controller: titleController,
                            label: 'المسمى الوظيفي',
                            placeholder: 'أدخل المسمى الوظيفي',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'المسمى الوظيفي مطلوب';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildDialogTextField(
                            controller: descriptionController,
                            label: 'الوصف',
                            placeholder: 'أدخل وصف الوظيفة',
                            maxLines: 4,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'الوصف مطلوب';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildDialogTextField(
                            controller: requirementsController,
                            label: 'المتطلبات',
                            placeholder: 'أدخل متطلبات الوظيفة',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogTextField(
                            controller: locationController,
                            label: 'الموقع',
                            placeholder: 'أدخل موقع العمل',
                          ),
                          const SizedBox(height: 12),
                          _buildEmploymentTypePicker(
                            value: employmentType,
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => employmentType = value);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildDisabilityPicker(
                            value: selectedDisabilityId,
                            onChanged: (value) {
                              setDialogState(() => selectedDisabilityId = value);
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildDialogTextField(
                            controller: salaryMinController,
                            label: 'الراتب الأدنى',
                            placeholder: 'اختياري',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogTextField(
                            controller: salaryMaxController,
                            label: 'الراتب الأعلى',
                            placeholder: 'اختياري',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogTextField(
                            controller: deadlineController,
                            label: 'تاريخ انتهاء التقديم',
                            placeholder: 'YYYY-MM-DD',
                          ),
                          const SizedBox(height: 8),
                          _buildActiveSwitch(
                            value: isActive,
                            onChanged: (value) {
                              setDialogState(() => isActive = value);
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

                      if (job == null) {
                        await dbHelper.insert('jobs', {
                          'company_id': selectedCompanyId!,
                          'title': titleController.text.trim(),
                          'description': descriptionController.text.trim(),
                          'requirements': requirementsController.text.trim().isEmpty ? null : requirementsController.text.trim(),
                          'location': locationController.text.trim().isEmpty ? null : locationController.text.trim(),
                          'employment_type': employmentType,
                          'target_disability_id': selectedDisabilityId,
                          'salary_min': salaryMinController.text.trim().isEmpty ? null : double.tryParse(salaryMinController.text.trim()),
                          'salary_max': salaryMaxController.text.trim().isEmpty ? null : double.tryParse(salaryMaxController.text.trim()),
                          'application_deadline': deadlineController.text.trim().isEmpty ? null : deadlineController.text.trim(),
                          'is_active': isActive ? 1 : 0,
                          'created_at': now,
                          'updated_at': now,
                        });
                        _showSuccessMessage('تمت إضافة الوظيفة بنجاح');
                      } else {
                        await dbHelper.update(
                          'jobs',
                          {
                            'company_id': selectedCompanyId!,
                            'title': titleController.text.trim(),
                            'description': descriptionController.text.trim(),
                            'requirements': requirementsController.text.trim().isEmpty ? null : requirementsController.text.trim(),
                            'location': locationController.text.trim().isEmpty ? null : locationController.text.trim(),
                            'employment_type': employmentType,
                            'target_disability_id': selectedDisabilityId,
                            'salary_min': salaryMinController.text.trim().isEmpty ? null : double.tryParse(salaryMinController.text.trim()),
                            'salary_max': salaryMaxController.text.trim().isEmpty ? null : double.tryParse(salaryMaxController.text.trim()),
                            'application_deadline': deadlineController.text.trim().isEmpty ? null : deadlineController.text.trim(),
                            'is_active': isActive ? 1 : 0,
                            'updated_at': now,
                          },
                          where: 'id = ?',
                          whereArgs: [job['id']],
                        );
                        _showSuccessMessage('تم تحديث الوظيفة بنجاح');
                      }
                      await _loadAll();
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
    TextInputType keyboardType = TextInputType.text,
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
        keyboardType: keyboardType,
        validator: validator,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildCompanyPicker({
    required int? value,
    required ValueChanged<int?> onChanged,
    String? Function(int?)? validator,
  }) {
    return GestureDetector(
      onTap: () {
        _showCompanyPicker(context, value, onChanged);
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
              'الشركة',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                Text(
                  value != null
                      ? (_companies.firstWhere(
                          (c) => c['id'] == value,
                          orElse: () => {'company_name': 'غير معروف'},
                        )['company_name'] as String? ?? 'غير معروف')
                      : 'اختر الشركة',
                  style: TextStyle(
                    fontSize: 14,
                    color: value != null ? AppColors.primary : AppColors.textSecondary,
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

  void _showCompanyPicker(BuildContext context, int? currentValue, ValueChanged<int?> onChanged) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('اختر الشركة'),
        actions: [
          ..._companies.map((company) {
            final id = company['id'] as int;
            final name = company['company_name'] as String? ?? '';
            return CupertinoActionSheetAction(
              onPressed: () {
                onChanged(id);
                Navigator.pop(context);
                SemanticsService.announce('تم اختيار شركة $name', Directionality.of(context));
              },
              child: Text(name),
            );
          }),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
      ),
    );
  }

  Widget _buildEmploymentTypePicker({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return GestureDetector(
      onTap: () {
        _showEmploymentTypePicker(context, value, onChanged);
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
              'نوع الدوام',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                Text(
                  _employmentTypeText(value),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
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

  void _showEmploymentTypePicker(BuildContext context, String currentValue, ValueChanged<String?> onChanged) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('اختر نوع الدوام'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              onChanged('full_time');
              Navigator.pop(context);
              SemanticsService.announce('تم اختيار دوام كامل', Directionality.of(context));
            },
            child: const Text('دوام كامل'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              onChanged('part_time');
              Navigator.pop(context);
              SemanticsService.announce('تم اختيار دوام جزئي', Directionality.of(context));
            },
            child: const Text('دوام جزئي'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              onChanged('remote');
              Navigator.pop(context);
              SemanticsService.announce('تم اختيار عن بعد', Directionality.of(context));
            },
            child: const Text('عن بعد'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              onChanged('internship');
              Navigator.pop(context);
              SemanticsService.announce('تم اختيار تدريب', Directionality.of(context));
            },
            child: const Text('تدريب'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
      ),
    );
  }

  Widget _buildDisabilityPicker({
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    return GestureDetector(
      onTap: () {
        _showDisabilityPicker(context, value, onChanged);
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
              'الفئة المناسبة',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                Text(
                  value != null
                      ? (_disabilities.firstWhere(
                          (d) => d['id'] == value,
                          orElse: () => {'name_ar': 'عام'},
                        )['name_ar'] as String? ?? 'عام')
                      : 'عام (جميع الفئات)',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
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

  void _showDisabilityPicker(BuildContext context, int? currentValue, ValueChanged<int?> onChanged) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('اختر الفئة المناسبة'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              onChanged(null);
              Navigator.pop(context);
              SemanticsService.announce('تم اختيار عام جميع الفئات', Directionality.of(context));
            },
            child: const Text('عام (جميع الفئات)'),
          ),
          ..._disabilities.map((disability) {
            final id = disability['id'] as int;
            final name = disability['name_ar'] as String? ?? '';
            return CupertinoActionSheetAction(
              onPressed: () {
                onChanged(id);
                Navigator.pop(context);
                SemanticsService.announce('تم اختيار فئة $name', Directionality.of(context));
              },
              child: Text(name),
            );
          }),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
      ),
    );
  }

  Widget _buildActiveSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'الوظيفة نشطة',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Future<void> _deleteJob(int id, String title) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('حذف الوظيفة'),
        content: Text('هل أنت متأكد أنك تريد حذف وظيفة "$title"؟'),
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
        'jobs',
        where: 'id = ?',
        whereArgs: [id],
      );
      _showSuccessMessage('تم حذف الوظيفة بنجاح');
      await _loadAll();
    } catch (e) {
      _showErrorMessage('حدث خطأ: ${e.toString()}');
    }
  }

  String _employmentTypeText(String value) {
    switch (value) {
      case 'full_time':
        return 'دوام كامل';
      case 'part_time':
        return 'دوام جزئي';
      case 'remote':
        return 'عن بعد';
      case 'internship':
        return 'تدريب';
      default:
        return value;
    }
  }

  String _salaryFormat(dynamic salary) {
    if (salary == null) return '-';
    if (salary is int) return salary.toString();
    if (salary is double) return salary.toString();
    return salary.toString();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Semantics(
          header: true,
          label: 'إدارة الوظائف',
          child: const Text(
            'الوظائف',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        backgroundColor: AppColors.surface,
        trailing: AdminMenuSheet(
          currentRoute: 'jobs',
          adminId: _adminId,
          adminName: _adminName,
          adminEmail: _adminEmail,
        ),
        automaticallyImplyLeading: false,
      ),
      child: _isLoading
          ?  Center(
              child: Semantics(
                label: 'جاري تحميل الوظائف',
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
                      if (_companies.isEmpty) ...[
                        const SizedBox(height: 14),
                        _buildWarningBanner(),
                      ],
                      const SizedBox(height: 16),
                      if (_jobs.isEmpty) _buildEmptyWidget() else _buildJobsList(),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Semantics(
      label: 'إجمالي الوظائف: ${_jobs.length}',
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
                    'إدارة الوظائف',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'إجمالي الوظائف: ${_jobs.length}',
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
                Icons.work_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Semantics(
      label: 'يجب إضافة شركة قبل إضافة الوظائف',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.info_circle,
              size: 18,
              color: AppColors.error,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'يجب إضافة شركة واحدة على الأقل قبل إضافة الوظائف',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
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
            label: 'إضافة وظيفة جديدة',
            hint: 'اضغط لإضافة وظيفة جديدة',
            child: CupertinoButton(
              color: _companies.isEmpty ? AppColors.textSecondary : AppColors.primary,
              onPressed: _companies.isEmpty ? null : () => _showJobDialog(),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.add, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'إضافة وظيفة جديدة',
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
          hint: 'اضغط لتحديث قائمة الوظائف',
          child: CupertinoButton(
            color: AppColors.surface,
            onPressed: _loadAll,
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

  Widget _buildJobsList() {
    return ListView.builder(
      itemCount: _jobs.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final item = _jobs[index];
        final id = item['id'] as int;
        final isActive = (item['is_active'] as int?) == 1;
        final title = item['title']?.toString() ?? '';
        final companyName = item['company_name']?.toString() ?? '';
        final disabilityName = item['target_disability_name']?.toString() ?? '';
        final location = item['location']?.toString() ?? '';
        final employmentType = item['employment_type']?.toString() ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
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
                    Icons.work_outline,
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
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'الشركة: $companyName',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (disabilityName.isNotEmpty)
                        Text(
                          'الفئة: $disabilityName',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (location.isNotEmpty)
                        Text(
                          'الموقع: $location',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      Text(
                        'الدوام: ${_employmentTypeText(employmentType)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: (isActive ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isActive ? 'نشطة' : 'مغلقة',
                          style: TextStyle(
                            color: isActive ? AppColors.success : AppColors.error,
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
                      label: 'تعديل وظيفة $title',
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        
                        onPressed: () => _showJobDialog(job: item),
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
                      label: 'حذف وظيفة $title',
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        
                        onPressed: () => _deleteJob(id, title),
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
            Icons.work_outline,
            size: 60,
            color: AppColors.textSecondary,
            semanticLabel: 'أيقونة لا توجد وظائف',
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد وظائف حتى الآن',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة وظيفة جديدة',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Semantics(
            button: true,
            label: 'إضافة وظيفة جديدة',
            child: CupertinoButton(
              color: AppColors.primary,
              onPressed: _companies.isEmpty ? null : () => _showJobDialog(),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.add, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'إضافة وظيفة جديدة',
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