import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:saedny/core/theme/app_colors.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    //  إعلان صوتي قبل الانتقال للشاشة التالية
    SemanticsService.announce(
      'تم تحميل التطبيق، جاري الانتقال إلى شاشة تسجيل الدخول',
      Directionality.of(context),
    );

    // التنقل بأسلوب iOS
    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      // إخفاء شريط التنقل الافتراضي
      navigationBar: const CupertinoNavigationBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        border: null,
      ),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ الشعار مع دعم الـ Accessibility
                Semantics(
                  label: 'شعار تطبيق ساعدني',
                  hint: 'هذا هو الشعار الرسمي لتطبيق ساعدني',
                  value: 'ساعدني - منصة تعليمية وتدريبية',
                  excludeSemantics: false,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 160,
                    height: 160,
                    semanticLabel: 'شعار تطبيق ساعدني',
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        CupertinoIcons.app_badge,
                        size: 160,
                        color: CupertinoColors.white,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                
                // ✅ النص الوصفي مع دعم الـ Accessibility كـ Header
                Semantics(
                  header: true, // يعتبر هذا النص عنوان رئيسي للشاشة
                  label: 'وصف المنصة',
                  hint: 'هذا هو الهدف الرئيسي من التطبيق',
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'منصة تعليمية وتيدريبية داعمة لذوي الهمم',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                // ✅ مؤشر التحميل مع دعم الـ Accessibility
                Semantics(
                  label: 'جاري تحميل التطبيق',
                  hint: 'يرجى الانتظار، سيتم نقلك تلقائياً إلى شاشة تسجيل الدخول خلال ثانيتين',
                  liveRegion: true, // يعلن عن أي تغييرات فيه تلقائياً
                  child: const CupertinoActivityIndicator(
                    radius: 14,
                    color: CupertinoColors.white,
                  ),
                ),
                
                // ✅ إضافة نص إضافي لمساعدة مستخدمي الـ VoiceOver
                const SizedBox(height: 20),
                Semantics(
                  label: 'معلومات إضافية',
                  hint: 'يمكنك النقر مرتين على أي عنصر لاختياره',
                  child: const SizedBox.shrink(), // عنصر غير مرئي لكن يقرأه VoiceOver
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}