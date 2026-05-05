import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:saedny/core/theme/app_colors.dart';
import 'package:saedny/screens/user/home/user_home_screen.dart';
import 'package:saedny/screens/user/profile/profile_screen.dart';

import '../categories/categories_screen.dart';
import '../jobs/jobs_screen.dart';

class UserMainScreen extends StatefulWidget {
  final int userId;
  final int initialIndex;

  const UserMainScreen({
    super.key,
    required this.userId,
    this.initialIndex = 0,
  });

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3);
    
    // ✅ إعلان ترحيبي عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _announceCurrentTab();
    });
  }

  void _announceCurrentTab() {
    final tabNames = ['الرئيسية', 'الأقسام', 'الوظائف', 'حسابي'];
    SemanticsService.announce(
      'تم التبديل إلى تبويب ${tabNames[_currentIndex]}',
      Directionality.of(context),
    );
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    
    setState(() {
      _currentIndex = index;
    });
    
    _announceCurrentTab();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      // ✅ شريط التنقل العلوي لكل تبويب (سيتم إخفاؤه لأن كل شاشة لها NavigationBar خاص بها)
      tabBar: CupertinoTabBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        backgroundColor: AppColors.surface,
        activeColor: AppColors.primary,
        inactiveColor: AppColors.textSecondary,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
        height: 56,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house, size: 22),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.square_grid_2x2, size: 22),
            label: 'الأقسام',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.briefcase, size: 22),
            label: 'الوظائف',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person, size: 22),
            label: 'حسابي',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return UserHomeScreen(userId: widget.userId);
          case 1:
            return CategoriesScreen(userId: widget.userId);
          case 2:
            return JobsScreen(userId: widget.userId);
          case 3:
            return ProfileScreen(userId: widget.userId);
          default:
            return UserHomeScreen(userId: widget.userId);
        }
      },
    );
  }
}