import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Divider;
import 'package:flutter/rendering.dart';
import 'package:saedny/core/theme/app_colors.dart';
import '../admin_categories_screen.dart';
import '../admin_companies_screen.dart';
import '../admin_dashboard_screen.dart';
import '../admin_disabilities_screen.dart';
import '../admin_job_applications_screen.dart';
import '../admin_jobs_screen.dart';
import '../admin_lessons_screen.dart';
import '../admin_ratings_screen.dart';
import '../admin_users_screen.dart';
import '../../auth/login_screen.dart';

// ✅ تم تغيير اسم الملف من AdminDrawer إلى AdminMenuSheet
// ✅ تم تغيير الـ Widget من Drawer إلى ActionSheet/BottomSheet

class AdminMenuSheet extends StatefulWidget {
  final String currentRoute;
  final int adminId;
  final String adminName;
  final String adminEmail;

  const AdminMenuSheet({
    super.key,
    required this.currentRoute,
    required this.adminId,
    required this.adminName,
    required this.adminEmail,
  });

  @override
  State<AdminMenuSheet> createState() => _AdminMenuSheetState();
}

class _AdminMenuSheetState extends State<AdminMenuSheet> {
  Future<void> _logout() async {
    if (!mounted) return;

    // ✅ استخدام CupertinoPageRoute بدلاً من MaterialPageRoute
    Navigator.pushAndRemoveUntil(
      context,
      CupertinoPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showLogoutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج من لوحة التحكم؟'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            isDestructiveAction: true,
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  void _showMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        
        title: Column(
          children: [
            // ✅ صورة المستخدم على شكل iOS
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                
              ),
              child: Icon(
                CupertinoIcons.person_circle,
                size: 45,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.adminName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.adminEmail,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'مدير النظام',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        message: const Text('اختر القسم الذي تريد إدارته'),
        actions: [
          // ✅ لوحة التحكم
          _buildMenuItem(
            icon: CupertinoIcons.home,
            title: 'لوحة التحكم',
            routeName: 'dashboard',
            page: const AdminDashboardScreen(),
          ),
          
          // ✅ الأقسام
          _buildMenuItem(
            icon: CupertinoIcons.square_grid_2x2,
            title: 'الأقسام',
            routeName: 'categories',
            page: const AdminCategoriesScreen(),
          ),
          
          // ✅ إدارة الإعاقات
          _buildMenuItem(
            icon: Icons.accessibility_new_rounded,
            title: 'إدارة الإعاقات',
            routeName: 'disabilities',
            page: const AdminDisabilitiesScreen(),
          ),
          
          // ✅ الدروس
          _buildMenuItem(
            icon: CupertinoIcons.book,
            title: 'الدروس',
            routeName: 'lessons',
            page: const AdminLessonsScreen(),
          ),
          
          // ✅ المستخدمون
          _buildMenuItem(
            icon: CupertinoIcons.person_3,
            title: 'المستخدمون',
            routeName: 'users',
            page: const AdminUsersScreen(),
          ),
          
          // ✅ إدارة التقييمات
          _buildMenuItem(
            icon: CupertinoIcons.star,
            title: 'إدارة التقييمات',
            routeName: 'ratings',
            page: const AdminRatingsScreen(),
          ),
          
          // ✅ الوظائف
          _buildMenuItem(
            icon: CupertinoIcons.briefcase,
            title: 'الوظائف',
            routeName: 'jobs',
            page: const AdminJobsScreen(),
          ),
          
          // ✅ طلبات التوظيف
          _buildMenuItem(
            icon: CupertinoIcons.doc_text,
            title: 'طلبات التوظيف',
            routeName: 'job_applications',
            page: const AdminJobApplicationsScreen(),
          ),
          
          // ✅ الشركات
          _buildMenuItem(
            icon: CupertinoIcons.building_2_fill,
            title: 'الشركات',
            routeName: 'companies',
            page: const AdminCompaniesScreen(),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String routeName,
    required Widget page,
  }) {
    final isSelected = widget.currentRoute == routeName;
    
    return CupertinoActionSheetAction(
      onPressed: () {
        Navigator.pop(context); // إغلاق القائمة
        
        if (isSelected) return;
        
        // ✅ إعلان VoiceOver
        SemanticsService.announce(
          'جاري الانتقال إلى $title',
          Directionality.of(context),
        );
        
        // ✅ استخدام CupertinoPageRoute بدلاً من MaterialPageRoute
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (_) => page),
        );
      },
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              CupertinoIcons.checkmark_alt,
              size: 18,
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }

  // ✅ زر فتح القائمة (يتم وضعه في شريط التنقل)
  Widget get menuButton {
    return Semantics(
      button: true,
      label: 'فتح قائمة الإدارة',
      hint: 'اضغط مرتين لفتح قائمة الأقسام الإدارية',
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _showMenu,
        child: Icon(
          CupertinoIcons.line_horizontal_3,
          size: 24,
          color: AppColors.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ هذه الـ Widget تعيد زر القائمة فقط
    // يمكنك استخدام menuButton في شريط التنقل
    return menuButton;
  }
}

// ✅ نسخة بديلة باستخدام BottomSheet (لمزيد من التفاصيل)
class AdminBottomSheetMenu extends StatefulWidget {
  final String currentRoute;
  final int adminId;
  final String adminName;
  final String adminEmail;

  const AdminBottomSheetMenu({
    super.key,
    required this.currentRoute,
    required this.adminId,
    required this.adminName,
    required this.adminEmail,
  });

  @override
  State<AdminBottomSheetMenu> createState() => _AdminBottomSheetMenuState();
}

class _AdminBottomSheetMenuState extends State<AdminBottomSheetMenu> {
  Future<void> _logout() async {
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      CupertinoPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showLogoutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج من لوحة التحكم؟'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            isDestructiveAction: true,
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  void _showBottomSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // ✅ مقبض السحب (Drag Handle)
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // ✅ رأس القائمة
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.person_circle,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.adminName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.adminEmail,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'مدير النظام',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // ✅ قائمة العناصر
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildBottomSheetItem(
                    icon: CupertinoIcons.home,
                    title: 'لوحة التحكم',
                    routeName: 'dashboard',
                    page: const AdminDashboardScreen(),
                  ),
                  _buildBottomSheetItem(
                    icon: CupertinoIcons.square_grid_2x2,
                    title: 'الأقسام',
                    routeName: 'categories',
                    page: const AdminCategoriesScreen(),
                  ),
                  _buildBottomSheetItem(
                    icon: Icons.accessibility_new_rounded,
                    title: 'إدارة الإعاقات',
                    routeName: 'disabilities',
                    page: const AdminDisabilitiesScreen(),
                  ),
                  _buildBottomSheetItem(
                    icon: CupertinoIcons.book,
                    title: 'الدروس',
                    routeName: 'lessons',
                    page: const AdminLessonsScreen(),
                  ),
                  _buildBottomSheetItem(
                    icon: CupertinoIcons.person_3,
                    title: 'المستخدمون',
                    routeName: 'users',
                    page: const AdminUsersScreen(),
                  ),
                  _buildBottomSheetItem(
                    icon: CupertinoIcons.star,
                    title: 'إدارة التقييمات',
                    routeName: 'ratings',
                    page: const AdminRatingsScreen(),
                  ),
                  _buildBottomSheetItem(
                    icon: CupertinoIcons.briefcase,
                    title: 'الوظائف',
                    routeName: 'jobs',
                    page: const AdminJobsScreen(),
                  ),
                  _buildBottomSheetItem(
                    icon: CupertinoIcons.doc_text,
                    title: 'طلبات التوظيف',
                    routeName: 'job_applications',
                    page: const AdminJobApplicationsScreen(),
                  ),
                  _buildBottomSheetItem(
                    icon: CupertinoIcons.building_2_fill,
                    title: 'الشركات',
                    routeName: 'companies',
                    page: const AdminCompaniesScreen(),
                  ),
                  
                  const Divider(height: 24),
                  
                  // ✅ زر تسجيل الخروج
                  CupertinoButton(
                    onPressed: _showLogoutDialog,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.clear,
                          size: 22,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'تسجيل الخروج',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetItem({
    required IconData icon,
    required String title,
    required String routeName,
    required Widget page,
  }) {
    final isSelected = widget.currentRoute == routeName;
    
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 12),
      onPressed: () {
        Navigator.pop(context);
        
        if (isSelected) return;
        
        SemanticsService.announce(
          'جاري الانتقال إلى $title',
          Directionality.of(context),
        );
        
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (_) => page),
        );
      },
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              CupertinoIcons.checkmark_alt,
              size: 18,
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }

  Widget get menuButton {
    return Semantics(
      button: true,
      label: 'فتح القائمة الجانبية',
      hint: 'اضغط مرتين لفتح قائمة الأقسام الإدارية',
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _showBottomSheet,
        child: Icon(
          CupertinoIcons.line_horizontal_3,
          size: 24,
          color: AppColors.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return menuButton;
  }
}