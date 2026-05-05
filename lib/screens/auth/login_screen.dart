import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Colors;
import 'package:flutter/rendering.dart';
import 'package:saedny/core/theme/app_colors.dart';
import 'package:saedny/screens/user/main/user_main_screen.dart';
import '../../database/database_helper.dart';
import '../admin/admin_dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        'مرحباً بك في صفحة تسجيل الدخول إلى تطبيق ساعدني',
        Directionality.of(context),
      );
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      SemanticsService.announce(
        'يرجى التحقق من صحة البيانات المدخلة',
        Directionality.of(context),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    SemanticsService.announce(
      'جاري تسجيل الدخول، يرجى الانتظار',
      Directionality.of(context),
    );

    try {
      final dbHelper = DatabaseHelper();

      final user = await dbHelper.getUserByEmail(_emailController.text.trim());

      if (user == null) {
        throw Exception('المستخدم غير موجود');
      }

      if (user['password'] != _passwordController.text.trim()) {
        throw Exception('كلمة المرور غير صحيحة');
      }

      if (user['status'] != 'active') {
        throw Exception('الحساب غير نشط. يرجى التواصل مع الدعم');
      }

      await dbHelper.updateLastLogin(user['id'] as int);

      final userId = user['id'] as int;
      final role = user['role'] as String;

      SemanticsService.announce(
        'تم تسجيل الدخول بنجاح، جاري تحويلك إلى الصفحة الرئيسية',
        Directionality.of(context),
      );

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (_) => UserMainScreen(userId: userId)),
        );
      }
    } catch (e) {
      if (!mounted) return;

      final errorMessage = e.toString().replaceFirst('Exception: ', '');

      SemanticsService.announce(
        'فشل تسجيل الدخول: $errorMessage',
        Directionality.of(context),
      );

      _showCupertinoErrorDialog(errorMessage);
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCupertinoErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('فشل تسجيل الدخول'),
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: CupertinoPageScaffold(
        backgroundColor: AppColors.background,
        navigationBar: const CupertinoNavigationBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          border: null,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Semantics(
              container: true,
              label: 'صفحة تسجيل الدخول إلى تطبيق ساعدني',
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Logo
                  Semantics(
                    label: 'شعار تطبيق ساعدني',
                    hint: 'منصة تعليمية وتدريبية داعمة لذوي الهمم',
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 100,
                      height: 100,
                      semanticLabel: 'شعار تطبيق ساعدني',
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            Icons.apps,
                            size: 50,
                            color: AppColors.primary,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Welcome text
                  Semantics(
                    header: true,
                    label: 'مرحباً بعودتك إلى تطبيق ساعدني',
                    child: Text(
                      'مرحباً بعودتك',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Semantics(
                    label: 'سجل الدخول للوصول إلى حسابك والاستفادة من الخدمات',
                    child: Text(
                      'سجل الدخول للوصول إلى حسابك',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Form
                  Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      children: [
                        // Email field - ✅ استخدام CupertinoTextField مع Form
                        Semantics(
                          label: 'حقل البريد الإلكتروني',
                          hint: 'أدخل بريدك الإلكتروني المسجل',
                          textField: true,
                          child: CupertinoTextField(
                            controller: _emailController,
                            autofocus: true,
                            keyboardType: TextInputType.emailAddress,
                            placeholder: 'البريد الإلكتروني',
                            placeholderStyle: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.7),
                            ),
                            padding: const EdgeInsets.all(15),
                            prefix: Semantics(
                              label: 'أيقونة البريد الإلكتروني',
                              child: const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.email_outlined,
                                  size: 20,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.border,
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password field - ✅ مع زر إظهار/إخفاء
                        Semantics(
                          label: 'حقل كلمة المرور',
                          hint: 'أدخل كلمة المرور الخاصة بك',
                          textField: true,
                          child: CupertinoTextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            placeholder: 'كلمة المرور',
                            placeholderStyle: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.7),
                            ),
                            padding: const EdgeInsets.all(15),
                            prefix: Semantics(
                              label: 'أيقونة كلمة المرور',
                              child: const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.lock_outline,
                                  size: 20,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            suffix: Semantics(
                              button: true,
                              label: _obscurePassword
                                  ? 'إظهار كلمة المرور'
                                  : 'إخفاء كلمة المرور',
                              hint: 'اضغط لإظهار أو إخفاء كلمة المرور',
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                minSize: 40,
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                child: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.border,
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),

                        // ✅ إضافة رسالة خطأ للتحقق
                        const SizedBox(height: 8),
                        if (_formKey.currentState?.validate() == false) ...[
                          Semantics(
                            label: 'يرجى ملء جميع الحقول بشكل صحيح',
                            child: const Text(
                              'يرجى ملء جميع الحقول بشكل صحيح',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Login button
                        Semantics(
                          label: _isLoading
                              ? 'جارٍ تسجيل الدخول'
                              : 'زر تسجيل الدخول',
                          hint: 'اضغط لتسجيل الدخول إلى حسابك',
                          button: true,
                          child: SizedBox(
                            width: double.infinity,
                            child: CupertinoButton(
                              color: AppColors.primary,
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? const CupertinoActivityIndicator(
                                      color: CupertinoColors.white,
                                    )
                                  : const Text(
                                      'تسجيل الدخول',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: CupertinoColors.white,

                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Register link
                        Semantics(
                          button: true,
                          label: 'زر إنشاء حساب جديد',
                          hint: 'اضغط للانتقال إلى صفحة إنشاء الحساب',
                          child: CupertinoButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    SemanticsService.announce(
                                      'جاري الانتقال إلى صفحة إنشاء حساب جديد',
                                      Directionality.of(context),
                                    );
                                    Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (_) => const RegisterScreen(),
                                      ),
                                    );
                                  },
                            child: Text(
                              'ليس لديك حساب؟ إنشاء حساب',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
