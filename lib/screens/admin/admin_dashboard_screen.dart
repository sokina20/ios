import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Colors;
import 'package:flutter/rendering.dart';
import 'package:saedny/core/theme/app_colors.dart';
import 'package:saedny/screens/auth/login_screen.dart';
import '../../database/database_helper.dart';
import 'widgets/admin_menu_sheet.dart';
import 'widgets/admin_stat_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  int usersCount = 0;
  int lessonsCount = 0;
  int categoriesCount = 0;
  int jobsCount = 0;
  int companiesCount = 0;
  int applicationsCount = 0;

  List<Map<String, dynamic>> activities = [];
  
  final int _adminId = 1;
  final String _adminName = 'مدير النظام';
  final String _adminEmail = 'admin@saedny.com';

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        'لوحة تحكم المدير',
        Directionality.of(context),
      );
    });
  }

  Future<void> _loadDashboardStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dbHelper = DatabaseHelper();
      
      usersCount = await dbHelper.getCount('users');
      lessonsCount = await dbHelper.getCount('lessons', where: 'status = ?', whereArgs: ['published']);
      categoriesCount = await dbHelper.getCount('categories');
      jobsCount = await dbHelper.getCount('jobs', where: 'is_active = 1');
      companiesCount = await dbHelper.getCount('companies');
      applicationsCount = await dbHelper.getCount('job_applications');
      
      final recentUsers = await dbHelper.query(
        'users',
        orderBy: 'created_at DESC',
        limit: 5,
      );
      
      final recentApplications = await dbHelper.query(
        'job_applications',
        orderBy: 'applied_at DESC',
        limit: 5,
      );
      
      activities = [];
      
      for (var user in recentUsers) {
        activities.add({
          'text': 'مستخدم جديد: ${user['full_name']} (${user['email']})',
          'created_at': user['created_at'],
        });
      }
      
      for (var app in recentApplications) {
        activities.add({
          'text': 'تقديم جديد على وظيفة رقم ${app['job_id']}',
          'created_at': app['applied_at'],
        });
      }
      
      activities.sort((a, b) {
        final dateA = a['created_at'] as String? ?? '';
        final dateB = b['created_at'] as String? ?? '';
        return dateB.compareTo(dateA);
      });
      
      if (activities.length > 10) {
        activities = activities.sublist(0, 10);
      }
      
      if (!mounted) return;
      
      SemanticsService.announce(
        'تم تحميل الإحصائيات: $usersCount مستخدم، $lessonsCount درس',
        Directionality.of(context),
      );
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      
      SemanticsService.announce(
        'فشل تحميل الإحصائيات',
        Directionality.of(context),
      );
    }
  }

  Future<void> _logout() async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    SemanticsService.announce(
      'جاري تسجيل الخروج',
      Directionality.of(context),
    );

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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Semantics(
          header: true,
          label: 'لوحة تحكم المدير',
          child: const Text(
            'لوحة الأدمن',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showLogoutDialog,
              child: Icon(
                CupertinoIcons.clear,
                size: 22,
                color: AppColors.error,
              ),
            ),
            AdminMenuSheet(
              currentRoute: 'dashboard',
              adminId: _adminId,
              adminName: _adminName,
              adminEmail: _adminEmail,
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
      ),
      child: _isLoading
          ? const Center(
              child: CupertinoActivityIndicator(radius: 20),
            )
          : _errorMessage != null
              ? _buildErrorWidget()
              : _buildContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            CupertinoButton(
              color: AppColors.primary,
              onPressed: _loadDashboardStats,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: _loadDashboardStats,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildHeader(),
              const SizedBox(height: 20),
              _buildStatsGrid(),
              const SizedBox(height: 20),
              _buildActivitiesCard(),
              const SizedBox(height: 10),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
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
              children: const [
                Text(
                  'مرحباً بك في لوحة التحكم',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'كل الإحصائيات هنا مرتبطة بقاعدة البيانات بشكل مباشر',
                  style: TextStyle(
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
              Icons.dashboard_customize_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.05,
      children: [
        AdminStatCard(
          title: 'المستخدمون',
          value: '$usersCount',
          icon: Icons.people_alt_outlined,
          semanticsLabel: 'إجمالي المستخدمين $usersCount',
        ),
        AdminStatCard(
          title: 'الدروس',
          value: '$lessonsCount',
          icon: Icons.menu_book_outlined,
          semanticsLabel: 'عدد الدروس $lessonsCount',
        ),
        AdminStatCard(
          title: 'الأقسام',
          value: '$categoriesCount',
          icon: Icons.category_outlined,
          semanticsLabel: 'عدد الأقسام $categoriesCount',
        ),
        AdminStatCard(
          title: 'الوظائف',
          value: '$jobsCount',
          icon: Icons.work_outline,
          semanticsLabel: 'عدد الوظائف $jobsCount',
        ),
        AdminStatCard(
          title: 'الشركات',
          value: '$companiesCount',
          icon: Icons.business_outlined,
          semanticsLabel: 'عدد الشركات $companiesCount',
        ),
        AdminStatCard(
          title: 'الطلبات',
          value: '$applicationsCount',
          icon: Icons.assignment_outlined,
          semanticsLabel: 'عدد طلبات التوظيف $applicationsCount',
        ),
      ],
    );
  }

  Widget _buildActivitiesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'آخر الأنشطة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _loadDashboardStats,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.refresh,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (activities.isEmpty)
            const _ActivityItem(text: 'لا توجد أنشطة حتى الآن')
          else
            ...activities.map(
              (activity) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ActivityItem(
                  text: activity['text']?.toString() ?? 'نشاط غير معروف',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String text;

  const _ActivityItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              CupertinoIcons.clock,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}