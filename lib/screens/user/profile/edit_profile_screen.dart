import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Colors;
import 'package:flutter/rendering.dart';
import 'package:saedny/core/theme/app_colors.dart';
import '../../../../../database/database_helper.dart';
import '../../../../../models/disability_type_model.dart';
import '../../../../../models/user_profile_model.dart';

class EditProfileScreen extends StatefulWidget {
  final int userId;
  final UserProfileModel profile;

  const EditProfileScreen({
    super.key,
    required this.userId,
    required this.profile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _countryController;
  late final TextEditingController _educationController;
  late final TextEditingController _bioController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyPhoneController;
  late final TextEditingController _guardianNameController;
  late final TextEditingController _guardianPhoneController;

  bool _isLoading = false;
  List<DisabilityTypeModel> _disabilities = [];

  String? _selectedGender;
  int? _selectedDisabilityId;
  bool _needsAssistant = false;
  String _preferredLanguage = 'ar';

  @override
  void initState() {
    super.initState();

    final p = widget.profile;
    _fullNameController = TextEditingController(text: p.fullName);
    _phoneController = TextEditingController(text: p.phone ?? '');
    _birthDateController = TextEditingController(text: p.birthDate ?? '');
    _addressController = TextEditingController(text: p.address ?? '');
    _cityController = TextEditingController(text: p.city ?? '');
    _countryController = TextEditingController(text: p.country ?? '');
    _educationController = TextEditingController(text: p.educationLevel ?? '');
    _bioController = TextEditingController(text: p.bio ?? '');
    _emergencyNameController = TextEditingController(text: p.emergencyContactName ?? '');
    _emergencyPhoneController = TextEditingController(text: p.emergencyContactPhone ?? '');
    _guardianNameController = TextEditingController(text: p.guardianName ?? '');
    _guardianPhoneController = TextEditingController(text: p.guardianPhone ?? '');

    _selectedGender = p.gender;
    _selectedDisabilityId = p.disabilityTypeId;
    _needsAssistant = p.needsAssistant;
    _preferredLanguage = p.preferredLanguage;

    _loadDisabilities();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        'صفحة تعديل الملف الشخصي',
        Directionality.of(context),
      );
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _educationController.dispose();
    _bioController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadDisabilities() async {
    try {
      final dbHelper = DatabaseHelper();
      final disabilitiesData = await dbHelper.query('disability_types');
      
      final list = disabilitiesData.map((d) => DisabilityTypeModel(
        id: d['id'] as int,
        nameAr: d['name_ar'] as String,
        nameEn: d['name_en'] as String?,
      )).toList();
      
      if (!mounted) return;
      setState(() {
        _disabilities = list;
      });
    } catch (_) {}
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الاسم الكامل مطلوب';
    }
    if (value.trim().length < 3) {
      return 'الاسم قصير جداً';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (value.trim().length < 8) {
      return 'رقم الهاتف قصير جداً';
    }
    return null;
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    
    if (!_formKey.currentState!.validate()) {
      SemanticsService.announce(
        'يرجى التحقق من صحة البيانات المدخلة',
        Directionality.of(context),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      SemanticsService.announce(
        'جاري حفظ التغييرات',
        Directionality.of(context),
      );

      final dbHelper = DatabaseHelper();
      final now = DateTime.now().toIso8601String();

      await dbHelper.update(
        'users',
        {
          'full_name': _fullNameController.text.trim(),
          'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          'gender': _selectedGender,
          'birth_date': _birthDateController.text.trim().isEmpty ? null : _birthDateController.text.trim(),
          'disability_type_id': _selectedDisabilityId,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [widget.userId],
      );

      final existingProfile = await dbHelper.query(
        'user_profiles',
        where: 'user_id = ?',
        whereArgs: [widget.userId],
      );

      if (existingProfile.isNotEmpty) {
        await dbHelper.update(
          'user_profiles',
          {
            'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
            'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
            'country': _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
            'education_level': _educationController.text.trim().isEmpty ? null : _educationController.text.trim(),
            'bio': _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
            'emergency_contact_name': _emergencyNameController.text.trim().isEmpty ? null : _emergencyNameController.text.trim(),
            'emergency_contact_phone': _emergencyPhoneController.text.trim().isEmpty ? null : _emergencyPhoneController.text.trim(),
            'guardian_name': _guardianNameController.text.trim().isEmpty ? null : _guardianNameController.text.trim(),
            'guardian_phone': _guardianPhoneController.text.trim().isEmpty ? null : _guardianPhoneController.text.trim(),
            'needs_assistant': _needsAssistant ? 1 : 0,
            'preferred_language': _preferredLanguage,
            'updated_at': now,
          },
          where: 'user_id = ?',
          whereArgs: [widget.userId],
        );
      } else {
        await dbHelper.insert('user_profiles', {
          'user_id': widget.userId,
          'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
          'country': _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
          'education_level': _educationController.text.trim().isEmpty ? null : _educationController.text.trim(),
          'bio': _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
          'emergency_contact_name': _emergencyNameController.text.trim().isEmpty ? null : _emergencyNameController.text.trim(),
          'emergency_contact_phone': _emergencyPhoneController.text.trim().isEmpty ? null : _emergencyPhoneController.text.trim(),
          'guardian_name': _guardianNameController.text.trim().isEmpty ? null : _guardianNameController.text.trim(),
          'guardian_phone': _guardianPhoneController.text.trim().isEmpty ? null : _guardianPhoneController.text.trim(),
          'needs_assistant': _needsAssistant ? 1 : 0,
          'preferred_language': _preferredLanguage,
          'created_at': now,
          'updated_at': now,
        });
      }

      if (!mounted) return;
      
      SemanticsService.announce(
        'تم تحديث الملف الشخصي بنجاح',
        Directionality.of(context),
      );
      
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('حدث خطأ: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('تم الحفظ'),
        content: const Text('تم تحديث الملف الشخصي بنجاح'),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
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

  void _showGenderPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('الجنس'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedGender = 'male');
              Navigator.pop(context);
              SemanticsService.announce('تم اختيار ذكر', Directionality.of(context));
            },
            child: const Text('ذكر'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedGender = 'female');
              Navigator.pop(context);
              SemanticsService.announce('تم اختيار أنثى', Directionality.of(context));
            },
            child: const Text('أنثى'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedGender = 'other');
              Navigator.pop(context);
              SemanticsService.announce('تم اختيار آخر', Directionality.of(context));
            },
            child: const Text('آخر'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
      ),
    );
  }

  void _showDisabilityPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('نوع الإعاقة'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedDisabilityId = null);
              Navigator.pop(context);
              SemanticsService.announce('تم اختيار لا يوجد', Directionality.of(context));
            },
            child: const Text('لا يوجد'),
          ),
          ..._disabilities.map((item) {
            return CupertinoActionSheetAction(
              onPressed: () {
                setState(() => _selectedDisabilityId = item.id);
                Navigator.pop(context);
                SemanticsService.announce('تم اختيار ${item.nameAr}', Directionality.of(context));
              },
              child: Text(item.nameAr),
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

  void _showLanguagePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('اللغة المفضلة'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _preferredLanguage = 'ar');
              Navigator.pop(context);
              SemanticsService.announce('تم اختيار اللغة العربية', Directionality.of(context));
            },
            child: const Text('العربية'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _preferredLanguage = 'en');
              Navigator.pop(context);
              SemanticsService.announce('تم اختيار اللغة الإنجليزية', Directionality.of(context));
            },
            child: const Text('English'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Semantics(
      header: true,
      label: title,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? placeholder,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    return Semantics(
      label: label,
      hint: 'أدخل $label',
      textField: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
        child: CupertinoTextField(
          controller: controller,
          placeholder: placeholder ?? label,
          placeholderStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          padding: const EdgeInsets.all(15),
          prefix: prefixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(
                    prefixIcon,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                )
              : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildPickerRow({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: '$label: $value',
      hint: 'اضغط مرتين لتغيير $label',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    CupertinoIcons.chevron_forward,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Semantics(
          header: true,
          label: 'تعديل الملف الشخصي',
          child: const Text(
            'تعديل الملف الشخصي',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        backgroundColor: AppColors.surface,
      ),
      child: Form(
        key: _formKey,
        child: CupertinoScrollbar(
          child: CustomScrollView(
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {},
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader('البيانات الأساسية', icon: Icons.person_outline),
                    
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'الاسم الكامل',
                      placeholder: 'أدخل اسمك الكامل',
                      prefixIcon: Icons.person_outline,
                      validator: _validateName,
                    ),
                    
                    Semantics(
                      label: 'البريد الإلكتروني',
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.border,
                            width: 0.5,
                          ),
                        ),
                        child: CupertinoTextField(
                          controller: TextEditingController(text: widget.profile.email),
                          placeholder: 'البريد الإلكتروني',
                          enabled: false,
                          padding: const EdgeInsets.all(15),
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Icon(
                              Icons.email_outlined,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    _buildTextField(
                      controller: _phoneController,
                      label: 'رقم الهاتف',
                      placeholder: 'أدخل رقم الهاتف',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                    ),
                    
                    _buildPickerRow(
                      label: 'الجنس',
                      value: _selectedGender == 'male' ? 'ذكر' : (_selectedGender == 'female' ? 'أنثى' : (_selectedGender == 'other' ? 'آخر' : 'غير محدد')),
                      icon: Icons.people_outline,
                      onTap: _showGenderPicker,
                    ),
                    
                    _buildTextField(
                      controller: _birthDateController,
                      label: 'تاريخ الميلاد',
                      placeholder: 'YYYY-MM-DD',
                      prefixIcon: Icons.calendar_today,
                    ),
                    
                    _buildPickerRow(
                      label: 'نوع الإعاقة',
                      value: _selectedDisabilityId == null 
                          ? 'لا يوجد' 
                          : (_disabilities.firstWhere((d) => d.id == _selectedDisabilityId, orElse: () => DisabilityTypeModel(id: 0, nameAr: ''))).nameAr,
                      icon: Icons.accessible,
                      onTap: _showDisabilityPicker,
                    ),

                    const SizedBox(height: 8),
                    
                    _buildSectionHeader('بيانات إضافية', icon: Icons.info_outline),
                    
                    _buildTextField(
                      controller: _addressController,
                      label: 'العنوان',
                      placeholder: 'أدخل عنوانك',
                      prefixIcon: Icons.location_on_outlined,
                    ),
                    
                    _buildTextField(
                      controller: _cityController,
                      label: 'المدينة',
                      placeholder: 'أدخل مدينتك',
                      prefixIcon: Icons.location_city,
                    ),
                    
                    _buildTextField(
                      controller: _countryController,
                      label: 'الدولة',
                      placeholder: 'أدخل دولتك',
                      prefixIcon: Icons.public,
                    ),
                    
                    _buildTextField(
                      controller: _educationController,
                      label: 'المستوى التعليمي',
                      placeholder: 'مثال: بكالوريوس',
                      prefixIcon: Icons.school_outlined,
                    ),
                    
                    _buildTextField(
                      controller: _bioController,
                      label: 'نبذة قصيرة',
                      placeholder: 'اكتب نبذة عن نفسك',
                      prefixIcon: Icons.description_outlined,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 8),
                    
                    _buildSectionHeader('جهات التواصل', icon: Icons.contact_phone),
                    
                    _buildTextField(
                      controller: _emergencyNameController,
                      label: 'اسم جهة الطوارئ',
                      placeholder: 'اسم شخص للتواصل في الطوارئ',
                      prefixIcon: Icons.emergency,
                    ),
                    
                    _buildTextField(
                      controller: _emergencyPhoneController,
                      label: 'هاتف جهة الطوارئ',
                      placeholder: 'رقم هاتف جهة الطوارئ',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                    ),
                    
                    _buildTextField(
                      controller: _guardianNameController,
                      label: 'اسم الوصي',
                      placeholder: 'اسم الوصي أو ولي الأمر',
                      prefixIcon: Icons.family_restroom,
                    ),
                    
                    _buildTextField(
                      controller: _guardianPhoneController,
                      label: 'هاتف الوصي',
                      placeholder: 'رقم هاتف الوصي',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                    ),

                    const SizedBox(height: 8),
                    
                    _buildSectionHeader('إعدادات إضافية', icon: Icons.settings_outlined),
                    
                    Semantics(
                      label: 'أحتاج إلى مساعد',
                      hint: _needsAssistant ? 'مفعل حالياً' : 'غير مفعل',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.border,
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.assistant,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'أحتاج إلى مساعد',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            CupertinoSwitch(
                              value: _needsAssistant,
                              activeColor: AppColors.primary,
                              onChanged: (value) {
                                setState(() => _needsAssistant = value);
                                SemanticsService.announce(
                                  value ? 'تم تفعيل طلب المساعد' : 'تم إلغاء طلب المساعد',
                                  Directionality.of(context),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildPickerRow(
                      label: 'اللغة المفضلة',
                      value: _preferredLanguage == 'ar' ? 'العربية' : 'English',
                      icon: Icons.language,
                      onTap: _showLanguagePicker,
                    ),

                    const SizedBox(height: 24),
                    
                    Semantics(
                      button: true,
                      label: _isLoading ? 'جارٍ حفظ التغييرات' : 'زر حفظ التغييرات',
                      hint: 'اضغط مرتين لحفظ التغييرات في الملف الشخصي',
                      child: SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          color: AppColors.primary,
                          onPressed: _isLoading ? null : _saveProfile,
                          child: _isLoading
                              ? const CupertinoActivityIndicator(
                                  color: CupertinoColors.white,
                                )
                              : const Text(
                                  'حفظ التغييرات',
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
        ),
      ),
    );
  }
}