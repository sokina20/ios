import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/rendering.dart';
import 'package:saedny/core/theme/app_colors.dart';
import '../../database/database_helper.dart';
import '../../models/disability_type_model.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  List<DisabilityTypeModel> _disabilities = [];
  int? _selectedDisabilityId;

  @override
  void initState() {
    super.initState();
    _loadDisabilities();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        'صفحة إنشاء حساب جديد، يرجى ملء البيانات المطلوبة',
        Directionality.of(context),
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadDisabilities() async {
    final dbHelper = DatabaseHelper();
    final disabilitiesData = await dbHelper.query('disability_types');
    
    final items = disabilitiesData.map((d) => DisabilityTypeModel(
      id: d['id'] as int,
      nameAr: d['name_ar'] as String,
      nameEn: d['name_en'] as String?,
    )).toList();
    
    if (!mounted) return;

    setState(() {
      _disabilities = items;
    });
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'الاسم الكامل مطلوب';
    }

    if (name.length < 3) {
      return 'الاسم الكامل قصير جدًا';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'أدخل بريدًا إلكترونيًا صحيحًا';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return null;
    }

    final phoneRegex = RegExp(r'^[0-9]{7,15}$');
    if (!phoneRegex.hasMatch(phone)) {
      return 'أدخل رقم هاتف صحيحًا';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';

    if (password.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }

    if (password.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final confirmPassword = value?.trim() ?? '';

    if (confirmPassword.isEmpty) {
      return 'تأكيد كلمة المرور مطلوب';
    }

    if (confirmPassword != _passwordController.text.trim()) {
      return 'كلمتا المرور غير متطابقتين';
    }

    return null;
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      SemanticsService.announce(
        'يرجى التحقق من صحة البيانات المدخلة',
        Directionality.of(context),
      );
      return;
    }

    setState(() => _isLoading = true);

    SemanticsService.announce(
      'جاري إنشاء الحساب، يرجى الانتظار',
      Directionality.of(context),
    );

    try {
      final dbHelper = DatabaseHelper();
      
      final existingUser = await dbHelper.getUserByEmail(_emailController.text.trim());
      
      if (existingUser != null) {
        throw Exception('البريد الإلكتروني مسجل مسبقًا');
      }
      
      final now = DateTime.now().toIso8601String();
      
      final userId = await dbHelper.insert('users', {
        'full_name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'password': _passwordController.text.trim(),
        'disability_type_id': _selectedDisabilityId,
        'role': 'user',
        'status': 'active',
        'created_at': now,
        'updated_at': now,
      });
      
      await dbHelper.insert('user_profiles', {
        'user_id': userId,
        'preferred_language': 'ar',
        'created_at': now,
        'updated_at': now,
      });
      
      await dbHelper.insert('accessibility_settings', {
        'user_id': userId,
        'font_size': 'medium',
        'high_contrast': 0,
        'text_to_speech': 0,
        'simplified_mode': 0,
        'preferred_input': 'touch',
        'created_at': now,
        'updated_at': now,
      });
      
      if (!mounted) return;

      SemanticsService.announce(
        'تم إنشاء الحساب بنجاح، جاري نقلك إلى صفحة تسجيل الدخول',
        Directionality.of(context),
      );
      
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      
      SemanticsService.announce(
        'فشل إنشاء الحساب: $errorMessage',
        Directionality.of(context),
      );
      
      _showCupertinoErrorDialog(errorMessage);
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('تم إنشاء الحساب بنجاح'),
        content: const Text('يرجى تسجيل الدخول للاستفادة من خدمات التطبيق'),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                CupertinoPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('تسجيل الدخول'),
          ),
        ],
      ),
    );
  }

  void _showCupertinoErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('فشل إنشاء الحساب'),
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

  // ✅ دالة مبسطة لبناء حقل نصي مع التحقق
  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required IconData prefixIcon,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onToggleVisibility,
    bool showVisibilityToggle = false,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Semantics(
      label: placeholder,
      hint: 'أدخل $placeholder',
      textField: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            placeholderStyle: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            padding: const EdgeInsets.all(15),
            prefix: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Icon(
                prefixIcon,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
            suffix: showVisibilityToggle
                ? Semantics(
                    button: true,
                    label: obscureText ? 'إظهار $placeholder' : 'إخفاء $placeholder',
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 40,
                      onPressed: onToggleVisibility,
                      child: Icon(
                        obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : null,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border,
                width: 0.5,
              ),
            ),
            onChanged: (value) {
              if (validator != null) {
                setState(() {});
              }
            },
          ),
          // ✅ رسالة الخطأ
          if (validator != null)
            Builder(
              builder: (context) {
                final error = validator(controller.text);
                if (error != null) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, left: 12),
                    child: Text(
                      error,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: CupertinoPageScaffold(
        backgroundColor: AppColors.background,
        navigationBar: CupertinoNavigationBar(
          middle: Semantics(
            header: true,
            label: 'صفحة إنشاء حساب جديد',
            child: const Text(
              'إنشاء حساب',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.white,

              ),
            ),
          ),
          backgroundColor: AppColors.surface,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Semantics(
              container: true,
              label: 'نموذج إنشاء حساب جديد',
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  
                  // Logo
                  Semantics(
                    label: 'شعار تطبيق ساعدني',
                    hint: 'منصة تعليمية وتدريبية داعمة لذوي الهمم',
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 80,
                      height: 80,
                      semanticLabel: 'شعار تطبيق ساعدني',
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(
                            Icons.apps,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  Semantics(
                    header: true,
                    label: 'إنشاء حساب جديد في تطبيق ساعدني',
                    child: Text(
                      'إنشاء حساب جديد',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Semantics(
                    label: 'أنشئ حسابك وابدأ باستخدام التطبيق',
                    child: Text(
                      'أنشئ حسابك وابدأ باستخدام التطبيق',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Form Container
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.border,
                        width: 0.5,
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: [
                          // Name field
                          _buildTextField(
                            controller: _nameController,
                            placeholder: 'الاسم الكامل',
                            prefixIcon: Icons.person_outline,
                            validator: _validateName,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          
                          // Email field
                          _buildTextField(
                            controller: _emailController,
                            placeholder: 'البريد الإلكتروني',
                            prefixIcon: Icons.email_outlined,
                            validator: _validateEmail,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          
                          // Phone field
                          _buildTextField(
                            controller: _phoneController,
                            placeholder: 'رقم الهاتف (اختياري)',
                            prefixIcon: Icons.phone_outlined,
                            validator: _validatePhone,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          
                          // Disability Type dropdown
                          _buildDisabilityDropdown(),
                          const SizedBox(height: 16),
                          
                          // Password field
                          _buildTextField(
                            controller: _passwordController,
                            placeholder: 'كلمة المرور',
                            prefixIcon: Icons.lock_outline,
                            validator: _validatePassword,
                            obscureText: _obscurePassword,
                            showVisibilityToggle: true,
                            onToggleVisibility: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          
                          // Confirm Password field
                          _buildTextField(
                            controller: _confirmPasswordController,
                            placeholder: 'تأكيد كلمة المرور',
                            prefixIcon: Icons.lock_reset_outlined,
                            validator: _validateConfirmPassword,
                            obscureText: _obscureConfirmPassword,
                            showVisibilityToggle: true,
                            onToggleVisibility: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: 24),
                          
                          // Register button
                          Semantics(
                            label: _isLoading
                                ? 'جارٍ إنشاء الحساب'
                                : 'زر إنشاء الحساب',
                            hint: 'اضغط مرتين لإنشاء حساب جديد',
                            button: true,
                            child: SizedBox(
                              width: double.infinity,
                              child: CupertinoButton(
                                color: AppColors.primary,
                                onPressed: _isLoading ? null : _register,
                                child: _isLoading
                                    ? const CupertinoActivityIndicator(
                                        color: CupertinoColors.white,
                                      )
                                    : const Text(
                                        'إنشاء الحساب',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: CupertinoColors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          
                          // Login link
                          Semantics(
                            button: true,
                            label: 'زر الانتقال إلى تسجيل الدخول',
                            hint: 'اضغط مرتين للرجوع إلى صفحة تسجيل الدخول',
                            child: CupertinoButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      SemanticsService.announce(
                                        'جاري العودة إلى صفحة تسجيل الدخول',
                                        Directionality.of(context),
                                      );
                                      Navigator.pushReplacement(
                                        context,
                                        CupertinoPageRoute(
                                          builder: (_) => const LoginScreen(),
                                        ),
                                      );
                                    },
                              child: Text(
                                'لديك حساب بالفعل؟ تسجيل الدخول',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisabilityDropdown() {
    return Semantics(
      label: 'حقل نوع الإعاقة',
      hint: 'اختر نوع الإعاقة لتخصيص المحتوى لك',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
          color: AppColors.surface,
        ),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          onPressed: () => _showDisabilityPicker(),
          child: Row(
            children: [
              Icon(
                Icons.accessible_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedDisabilityId == null
                      ? 'نوع الإعاقة (اختياري)'
                      : (_disabilities.firstWhere(
                          (d) => d.id == _selectedDisabilityId,
                          orElse: () => DisabilityTypeModel(id: 0, nameAr: ''),
                        ).nameAr),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedDisabilityId == null
                        ? AppColors.textSecondary.withOpacity(0.7)
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                CupertinoIcons.chevron_down,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDisabilityPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('اختر نوع الإعاقة'),
        message: const Text('يمكنك اختيار نوع الإعاقة لتخصيص المحتوى لك'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedDisabilityId = null);
              Navigator.pop(context);
              SemanticsService.announce('تم إلغاء اختيار نوع الإعاقة', Directionality.of(context));
            },
            child: const Text('بدون تحديد'),
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
}