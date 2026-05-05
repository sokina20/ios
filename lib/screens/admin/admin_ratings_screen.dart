import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Colors;
import 'package:flutter/rendering.dart';
import 'package:saedny/core/theme/app_colors.dart';
import '../../database/database_helper.dart';
import '../../models/admin_rating_model.dart';
import 'widgets/admin_menu_sheet.dart';

class AdminRatingsScreen extends StatefulWidget {
  const AdminRatingsScreen({super.key});

  @override
  State<AdminRatingsScreen> createState() => _AdminRatingsScreenState();
}

class _AdminRatingsScreenState extends State<AdminRatingsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<AdminRatingModel> _ratings = [];

  final int _adminId = 1;
  final String _adminName = 'مدير النظام';
  final String _adminEmail = 'admin@saedny.com';

  @override
  void initState() {
    super.initState();
    _loadRatings();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        'لوحة تحكم المدير - إدارة التقييمات',
        Directionality.of(context),
      );
    });
  }

  Future<void> _loadRatings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dbHelper = DatabaseHelper();
      
      final results = await dbHelper.rawQuery('''
        SELECT 
          lr.*,
          l.title_ar as lesson_title,
          u.full_name as user_name,
          u.email as user_email
        FROM lesson_ratings lr
        JOIN lessons l ON lr.lesson_id = l.id
        JOIN users u ON lr.user_id = u.id
        ORDER BY lr.created_at DESC
      ''');
      
      final ratings = results.map((row) => AdminRatingModel(
        id: row['id'] as int,
        lessonId: row['lesson_id'] as int,
        userId: row['user_id'] as int,
        rating: row['rating'] as int,
        comment: row['comment'] as String?,
        status: row['status'] as String? ?? 'visible',
        createdAt: row['created_at'] as String? ?? '',
        lessonTitle: row['lesson_title'] as String? ?? '',
        userName: row['user_name'] as String? ?? '',
        userEmail: row['user_email'] as String?,
      )).toList();

      if (!mounted) return;
      
      SemanticsService.announce(
        'تم تحميل ${ratings.length} تقييم',
        Directionality.of(context),
      );
      
      setState(() {
        _ratings = ratings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
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
      case 'visible': return 'ظاهر';
      case 'hidden': return 'مخفي';
      default: return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'visible': return AppColors.success;
      case 'hidden': return AppColors.accent;
      default: return AppColors.textSecondary;
    }
  }

  Future<void> _updateRatingVisibility(int ratingId, String newStatus) async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.update(
        'lesson_ratings',
        {'status': newStatus},
        where: 'id = ?',
        whereArgs: [ratingId],
      );
      
      final message = newStatus == 'visible' ? 'تم إظهار التقييم' : 'تم إخفاء التقييم';
      _showSuccessMessage(message);
      await _loadRatings();
    } catch (e) {
      _showErrorMessage('حدث خطأ: ${e.toString()}');
    }
  }

  Future<void> _deleteRating(int ratingId) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('حذف التقييم'),
        content: const Text('هل أنت متأكد أنك تريد حذف هذا التقييم؟'),
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
        'lesson_ratings',
        where: 'id = ?',
        whereArgs: [ratingId],
      );
      _showSuccessMessage('تم حذف التقييم');
      await _loadRatings();
    } catch (e) {
      _showErrorMessage('حدث خطأ: ${e.toString()}');
    }
  }

  String _starsText(int rating) {
    if (rating <= 0) return '0';
    return '★' * rating;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Semantics(
          header: true,
          label: 'إدارة التقييمات',
          child: const Text(
            'التقييمات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        backgroundColor: AppColors.surface,
        trailing: AdminMenuSheet(
          currentRoute: 'ratings',
          adminId: _adminId,
          adminName: _adminName,
          adminEmail: _adminEmail,
        ),
        automaticallyImplyLeading: false,
      ),
      child: _isLoading
          ?  Center(
              child: Semantics(
                label: 'جاري تحميل التقييمات',
                child: CupertinoActivityIndicator(radius: 20),
              ),
            )
          : _errorMessage != null
              ? _buildErrorWidget()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: _loadRatings,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildHeader(),
              const SizedBox(height: 16),
              _buildInfoBanner(),
              const SizedBox(height: 16),
              if (_ratings.isEmpty) _buildEmptyWidget() else _buildRatingsList(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Semantics(
      label: 'إجمالي التقييمات: ${_ratings.length}',
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
                    'إدارة التقييمات',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'عدد التقييمات الحالية: ${_ratings.length}',
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
                Icons.star_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Semantics(
      label: 'يمكنك عرض التقييمات وإخفاء أو إظهار أو حذف أي تقييم',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.info_circle,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'يمكنك عرض التقييمات وإخفاء أو إظهار أو حذف أي تقييم',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'تحديث القائمة',
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 40),
                onPressed: _loadRatings,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    CupertinoIcons.refresh,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingsList() {
    return ListView.builder(
      itemCount: _ratings.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final item = _ratings[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildRatingCard(item),
        );
      },
    );
  }

  Widget _buildRatingCard(AdminRatingModel item) {
    final isHidden = item.status == 'hidden';

    return Semantics(
      container: true,
      label: 'تقييم درس ${item.lessonTitle} من ${item.userName} بتقييم ${item.rating} من 5',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.rate_review_outlined,
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
                        item.lessonTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.userName,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      if ((item.userEmail ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.userEmail!,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(item.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusText(item.status),
                    style: TextStyle(
                      color: _statusColor(item.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _infoRow('التقييم', '${item.rating} / 5  ${_starsText(item.rating)}'),
            _infoRow('تاريخ الإضافة', item.createdAt),
            _infoRow(
              'التعليق',
              (item.comment ?? '').trim().isEmpty ? 'لا يوجد تعليق' : item.comment!,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    label: isHidden ? 'إظهار التقييم' : 'إخفاء التقييم',
                    child: CupertinoButton(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      onPressed: () => _updateRatingVisibility(item.id, isHidden ? 'visible' : 'hidden'),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.eye, size: 16, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('إخفاء', style: TextStyle(color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'حذف التقييم',
                    child: CupertinoButton(
                      color: AppColors.error.withValues(alpha: 0.1),
                      onPressed: () => _deleteRating(item.id),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.delete, size: 16, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('حذف', style: TextStyle(color: AppColors.error)),
                        ],
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
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
            height: 1.6,
          ),
          children: [
            TextSpan(
              text: '$title: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: AppColors.error,
              semanticLabel: 'أيقونة خطأ',
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Semantics(
              button: true,
              label: 'زر إعادة المحاولة',
              hint: 'اضغط مرتين لإعادة تحميل التقييمات',
              child: CupertinoButton(
                color: AppColors.primary,
                onPressed: _loadRatings,
                child: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
            Icons.star_outline_rounded,
            size: 60,
            color: AppColors.textSecondary,
            semanticLabel: 'أيقونة لا توجد تقييمات',
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد تقييمات حاليًا',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'عندما يقيّم المستخدمون الدروس ستظهر التقييمات هنا',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Semantics(
            button: true,
            label: 'تحديث القائمة',
            child: CupertinoButton(
              color: AppColors.primary,
              onPressed: _loadRatings,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.refresh, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'تحديث القائمة',
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