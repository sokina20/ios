import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/splash/splash_screen.dart';
import 'core/theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SaednyApp());
}

class SaednyApp extends StatelessWidget {
  const SaednyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'ساعدني',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        barBackgroundColor: AppColors.surface,
        brightness: Brightness.light,
        textTheme: const CupertinoTextThemeData(
          textStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            color: AppColors.textPrimary,
          ),
        ),
      ),
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}