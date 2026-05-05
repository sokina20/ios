import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Colors;
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:saedny/core/theme/app_colors.dart';
import 'package:saedny/screens/admin/widgets/admin_menu_sheet.dart';
import '../../database/database_helper.dart';

class AdminCompaniesScreen extends StatefulWidget {
  const AdminCompaniesScreen({super.key});

  @override
  State<AdminCompaniesScreen> createState() => _AdminCompaniesScreenState();
}

class _AdminCompaniesScreenState extends State<AdminCompaniesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _filteredCompanies = [];

  final TextEditingController _searchController = TextEditingController();

  final int _adminId = 1;
  final String _adminName = 'مدير النظام';
  final String _adminEmail = 'admin@saedny.com';

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    _searchController.addListener(_filterCompanies);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        'لوحة تحكم المدير - إدارة الشركات',
        Directionality.of(context),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanies() async {
    setState(() => _isLoading = true);

    try {
      final dbHelper = DatabaseHelper();
      final companies = await dbHelper.query('companies', orderBy: 'id ASC');

      if (!mounted) return;

      SemanticsService.announce(
        'تم تحميل ${companies.length} شركة',
        Directionality.of(context),
      );

      setState(() {
        _companies = companies;
        _filteredCompanies = companies;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorMessage('حدث خطأ: ${e.toString()}');
    }
  }

  void _filterCompanies() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() => _filteredCompanies = _companies);
      return;
    }

    final filtered = _companies.where((company) {
      final name = (company['company_name'] ?? '').toString().toLowerCase();
      final email = (company['email'] ?? '').toString().toLowerCase();
      final city = (company['city'] ?? '').toString().toLowerCase();
      final phone = (company['phone'] ?? '').toString().toLowerCase();
      final status = (company['status'] ?? '').toString().toLowerCase();

      return name.contains(query) ||
          email.contains(query) ||
          city.contains(query) ||
          phone.contains(query) ||
          status.contains(query);
    }).toList();

    setState(() => _filteredCompanies = filtered);

    SemanticsService.announce(
      'تم العثور على ${filtered.length} شركة',
      Directionality.of(context),
    );
  }

  Future<String?> _saveLogoLocally(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logosDir = Directory('${appDir.path}/company_logos');

      if (!await logosDir.exists()) {
        await logosDir.create(recursive: true);
      }

      final extension = path.extension(imageFile.path);
      final fileName =
          'logo_${DateTime.now().millisecondsSinceEpoch}$extension';
      final savedPath = path.join(logosDir.path, fileName);

      await imageFile.copy(savedPath);
      return savedPath;
    } catch (e) {
      _showErrorMessage('خطأ في حفظ الشعار: ${e.toString()}');
      return null;
    }
  }

  Future<void> _showCompanyDialog({Map<String, dynamic>? company}) async {
    final companyNameController = TextEditingController(
      text: company?['company_name']?.toString() ?? '',
    );
    final emailController = TextEditingController(
      text: company?['email']?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: company?['phone']?.toString() ?? '',
    );
    final websiteController = TextEditingController(
      text: company?['website']?.toString() ?? '',
    );
    final cityController = TextEditingController(
      text: company?['city']?.toString() ?? '',
    );
    final addressController = TextEditingController(
      text: company?['address']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: company?['description']?.toString() ?? '',
    );

    String status = company?['status']?.toString() ?? 'approved';

    File? selectedLogoFile;
    String existingLogoPath = company?['logo']?.toString() ?? '';
    bool isUploading = false;

    final formKey = GlobalKey<FormState>();
    final dbHelper = DatabaseHelper();

    await showCupertinoDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickLogo() async {
              final picker = ImagePicker();
              final file = await picker.pickImage(source: ImageSource.gallery);

              if (file == null) return;

              setDialogState(() {
                selectedLogoFile = File(file.path);
              });
            }

            return Directionality(
              textDirection: TextDirection.rtl,
              child: CupertinoAlertDialog(
                title: Text(
                  company == null ? 'إضافة شركة جديدة' : 'تعديل الشركة',
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
                            controller: companyNameController,
                            label: 'اسم الشركة',
                            placeholder: 'أدخل اسم الشركة',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'اسم الشركة مطلوب';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildDialogTextField(
                            controller: emailController,
                            label: 'البريد الإلكتروني',
                            placeholder: 'company@example.com',
                          ),
                          const SizedBox(height: 12),
                          _buildDialogTextField(
                            controller: phoneController,
                            label: 'الهاتف',
                            placeholder: 'أدخل رقم الهاتف',
                          ),
                          const SizedBox(height: 12),
                          _buildDialogTextField(
                            controller: websiteController,
                            label: 'الموقع الإلكتروني',
                            placeholder: 'https://example.com',
                          ),
                          const SizedBox(height: 12),
                          _buildDialogTextField(
                            controller: cityController,
                            label: 'المدينة',
                            placeholder: 'أدخل المدينة',
                          ),
                          const SizedBox(height: 12),
                          _buildDialogTextField(
                            controller: addressController,
                            label: 'العنوان',
                            placeholder: 'أدخل العنوان',
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogTextField(
                            controller: descriptionController,
                            label: 'الوصف',
                            placeholder: 'أدخل وصف الشركة',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 14),

                          Semantics(
                            button: true,
                            label: 'اختيار شعار الشركة',
                            child: CupertinoButton(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              onPressed: isUploading ? null : pickLogo,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.photo,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'اختيار شعار الشركة',
                                    style: TextStyle(color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          if (selectedLogoFile != null)
                            _buildLogoPreview(file: selectedLogoFile)
                          else if (existingLogoPath.isNotEmpty)
                            _buildLogoPreview(pathString: existingLogoPath),

                          const SizedBox(height: 12),

                          _buildDialogStatusPicker(
                            value: status,
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => status = value);
                              }
                            },
                          ),

                          if (isUploading)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CupertinoActivityIndicator(),
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
                    onPressed: isUploading
                        ? null
                        : () async {
                            if (formKey.currentState?.validate() != true)
                              return;

                            setDialogState(() => isUploading = true);

                            String? logoPath = existingLogoPath;

                            if (selectedLogoFile != null) {
                              logoPath = await _saveLogoLocally(
                                selectedLogoFile!,
                              );
                            }

                            if (!mounted) return;

                            if (context.mounted) Navigator.pop(context);

                            final now = DateTime.now().toIso8601String();

                            if (company == null) {
                              await dbHelper.insert('companies', {
                                'company_name': companyNameController.text
                                    .trim(),
                                'email': emailController.text.trim().isEmpty
                                    ? null
                                    : emailController.text.trim(),
                                'phone': phoneController.text.trim().isEmpty
                                    ? null
                                    : phoneController.text.trim(),
                                'website': websiteController.text.trim().isEmpty
                                    ? null
                                    : websiteController.text.trim(),
                                'city': cityController.text.trim().isEmpty
                                    ? null
                                    : cityController.text.trim(),
                                'address': addressController.text.trim().isEmpty
                                    ? null
                                    : addressController.text.trim(),
                                'description':
                                    descriptionController.text.trim().isEmpty
                                    ? null
                                    : descriptionController.text.trim(),
                                'logo': logoPath,
                                'status': status,
                                'created_at': now,
                                'updated_at': now,
                              });
                              _showSuccessMessage('تمت إضافة الشركة بنجاح');
                            } else {
                              await dbHelper.update(
                                'companies',
                                {
                                  'company_name': companyNameController.text
                                      .trim(),
                                  'email': emailController.text.trim().isEmpty
                                      ? null
                                      : emailController.text.trim(),
                                  'phone': phoneController.text.trim().isEmpty
                                      ? null
                                      : phoneController.text.trim(),
                                  'website':
                                      websiteController.text.trim().isEmpty
                                      ? null
                                      : websiteController.text.trim(),
                                  'city': cityController.text.trim().isEmpty
                                      ? null
                                      : cityController.text.trim(),
                                  'address':
                                      addressController.text.trim().isEmpty
                                      ? null
                                      : addressController.text.trim(),
                                  'description':
                                      descriptionController.text.trim().isEmpty
                                      ? null
                                      : descriptionController.text.trim(),
                                  'logo': logoPath,
                                  'status': status,
                                  'updated_at': now,
                                },
                                where: 'id = ?',
                                whereArgs: [company!['id']],
                              );
                              _showSuccessMessage('تم تحديث الشركة بنجاح');
                            }
                            await _loadCompanies();
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
        border: Border.all(color: AppColors.border, width: 0.5),
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

  Widget _buildLogoPreview({File? file, String? pathString}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: file != null
            ? Image.file(
                file,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildLogoPlaceholder(),
              )
            : (pathString != null && File(pathString).existsSync()
                  ? Image.file(
                      File(pathString),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildLogoPlaceholder(),
                    )
                  : _buildLogoPlaceholder()),
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(Icons.business, color: AppColors.primary, size: 34),
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
          border: Border.all(color: AppColors.border, width: 0.5),
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
                    color: _statusColor(value),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _statusText(value),
                  style: TextStyle(fontSize: 14, color: _statusColor(value)),
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

  void _showStatusPicker(
    BuildContext context,
    String currentStatus,
    ValueChanged<String?> onChanged,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('اختر حالة الشركة'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              onChanged('approved');
              Navigator.pop(context);
              SemanticsService.announce(
                'تم اختيار حالة معتمدة',
                Directionality.of(context),
              );
            },
            child: const Text('معتمدة'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              onChanged('pending');
              Navigator.pop(context);
              SemanticsService.announce(
                'تم اختيار حالة معلقة',
                Directionality.of(context),
              );
            },
            child: const Text('معلقة'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              onChanged('rejected');
              Navigator.pop(context);
              SemanticsService.announce(
                'تم اختيار حالة مرفوضة',
                Directionality.of(context),
              );
            },
            child: const Text('مرفوضة'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              onChanged('inactive');
              Navigator.pop(context);
              SemanticsService.announce(
                'تم اختيار حالة غير نشطة',
                Directionality.of(context),
              );
            },
            child: const Text('غير نشطة'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
      ),
    );
  }

  Future<void> _deleteCompany(int id) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('حذف الشركة'),
        content: const Text('هل أنت متأكد أنك تريد حذف هذه الشركة؟'),
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
      await dbHelper.delete('companies', where: 'id = ?', whereArgs: [id]);
      _showSuccessMessage('تم حذف الشركة بنجاح');
      await _loadCompanies();
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
      case 'approved':
        return 'معتمدة';
      case 'pending':
        return 'معلقة';
      case 'rejected':
        return 'مرفوضة';
      case 'inactive':
        return 'غير نشطة';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.accent;
      case 'rejected':
        return AppColors.error;
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
          label: 'إدارة الشركات',
          child: const Text(
            'الشركات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        backgroundColor: AppColors.surface,
        trailing: AdminMenuSheet(
          currentRoute: 'companies',
          adminId: _adminId,
          adminName: _adminName,
          adminEmail: _adminEmail,
        ),
        automaticallyImplyLeading: false,
      ),
      child: _isLoading
          ? Center(
              child: Semantics(
                label: 'جاري تحميل الشركات',
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
                      _buildCompaniesList(),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Semantics(
      label: 'إجمالي الشركات: ${_companies.length}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
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
                    'إدارة الشركات',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'إجمالي الشركات: ${_companies.length}',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
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
                Icons.business_rounded,
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
            label: 'إضافة شركة جديدة',
            hint: 'اضغط لإضافة شركة جديدة',
            child: CupertinoButton(
              color: AppColors.primary,
              onPressed: () => _showCompanyDialog(),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.add, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'إضافة شركة جديدة',
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
            onPressed: _loadCompanies,
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
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: CupertinoTextField(
        controller: _searchController,
        placeholder: 'بحث باسم الشركة أو البريد أو الهاتف أو المدينة',
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
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildCompaniesList() {
    if (_filteredCompanies.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          children: [
            Icon(
              Icons.business_outlined,
              size: 60,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد شركات مطابقة',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredCompanies.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final item = _filteredCompanies[index];
        final id = item['id'] as int;
        final status = (item['status'] ?? 'approved').toString();
        final name = item['company_name']?.toString() ?? '';
        final email = item['email']?.toString() ?? '';
        final phone = item['phone']?.toString() ?? '';
        final city = item['city']?.toString() ?? '';
        final website = item['website']?.toString() ?? '';
        final logo = item['logo']?.toString() ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCompanyAvatar(logo),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (email.isNotEmpty)
                        Text(
                          'البريد: $email',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (phone.isNotEmpty)
                        Text(
                          'الهاتف: $phone',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (city.isNotEmpty)
                        Text(
                          'المدينة: $city',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (website.isNotEmpty)
                        Text(
                          'الموقع: $website',
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
                      label: 'تعديل شركة $name',
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        
                        onPressed: () => _showCompanyDialog(company: item),
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
                      label: 'حذف شركة $name',
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        
                        onPressed: () => _deleteCompany(id),
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

  Widget _buildCompanyAvatar(String logoPath) {
    if (logoPath.isNotEmpty && File(logoPath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          File(logoPath),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
        ),
      );
    }

    return _buildAvatarPlaceholder();
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.business_outlined,
        color: AppColors.primary,
        size: 24,
      ),
    );
  }
}
