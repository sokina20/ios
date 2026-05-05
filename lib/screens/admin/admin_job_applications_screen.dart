import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Colors;
import 'package:flutter/rendering.dart';
import 'package:open_file/open_file.dart';
import 'package:saedny/core/theme/app_colors.dart';
import '../../database/database_helper.dart';
import '../../models/admin_job_application_model.dart';
import 'widgets/admin_menu_sheet.dart';

class AdminJobApplicationsScreen extends StatefulWidget {
  const AdminJobApplicationsScreen({super.key});

  @override
  State<AdminJobApplicationsScreen> createState() =>
      _AdminJobApplicationsScreenState();
}

class _AdminJobApplicationsScreenState
    extends State<AdminJobApplicationsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<AdminJobApplicationModel> _applications = [];

  final int _adminId = 1;
  final String _adminName = 'مدير النظام';
  final String _adminEmail = 'admin@saedny.com';

  @override
  void initState() {
    super.initState();
    _loadApplications();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        'لوحة تحكم المدير - إدارة طلبات التوظيف',
        Directionality.of(context),
      );
    });
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dbHelper = DatabaseHelper();
      
      final results = await dbHelper.rawQuery('''
        SELECT 
          ja.id,
          ja.job_id,
          ja.user_id,
          ja.cover_letter,
          ja.cv_file,
          ja.status,
          ja.applied_at,
          ja.reviewed_at,
          ja.notes,
          j.title as job_title,
          c.company_name,
          u.full_name as applicant_name,
          u.email as applicant_email,
          u.phone as applicant_phone
        FROM job_applications ja
        JOIN jobs j ON ja.job_id = j.id
        JOIN companies c ON j.company_id = c.id
        JOIN users u ON ja.user_id = u.id
        ORDER BY ja.applied_at DESC
      ''');
      
      final applications = results.map((row) => AdminJobApplicationModel(
        id: row['id'] as int,
        jobId: row['job_id'] as int,
        userId: row['user_id'] as int,
        applicantName: row['applicant_name'] as String,
        applicantEmail: row['applicant_email'] as String,
        applicantPhone: row['applicant_phone'] as String?,
        jobTitle: row['job_title'] as String,
        companyName: row['company_name'] as String,
        coverLetter: row['cover_letter'] as String?,
        cvFile: row['cv_file'] as String?,
        status: row['status'] as String,
        appliedAt: row['applied_at'] as String,
        reviewedAt: row['reviewed_at'] as String?,
        notes: row['notes'] as String?,
      )).toList();

      if (!mounted) return;
      
      SemanticsService.announce(
        'تم تحميل ${applications.length} طلب توظيف',
        Directionality.of(context),
      );
      
      setState(() {
        _applications = applications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      
      SemanticsService.announce(
        'فشل تحميل الطلبات',
        Directionality.of(context),
      );
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'reviewed':
        return 'تمت المراجعة';
      case 'accepted':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.accent;
      case 'reviewed':
        return AppColors.primary;
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
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

  Future<void> _openCv(String? path) async {
    if (path == null || path.trim().isEmpty) {
      _showErrorMessage('لا يوجد ملف CV لهذا الطلب');
      return;
    }

    final file = File(path);
    if (!await file.exists()) {
      _showErrorMessage('ملف السيرة الذاتية غير موجود');
      return;
    }

    try {
      final result = await OpenFile.open(path);
      if (result.type != ResultType.done) {
        _showErrorMessage('تعذر فتح ملف السيرة الذاتية');
      }
    } catch (e) {
      _showErrorMessage('حدث خطأ أثناء فتح الملف');
    }
  }

  Future<void> _showUpdateStatusDialog(AdminJobApplicationModel application) async {
    String selectedStatus = application.status;
    final notesController = TextEditingController(text: application.notes ?? '');

    await showCupertinoDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: CupertinoAlertDialog(
                title: const Text('تحديث حالة الطلب'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusPicker(
                        value: selectedStatus,
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedStatus = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.border,
                            width: 0.5,
                          ),
                        ),
                        child: CupertinoTextField(
                          controller: notesController,
                          maxLines: 4,
                          placeholder: 'ملاحظات الأدمن',
                          placeholderStyle: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                          ),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  CupertinoDialogAction(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _updateApplicationStatus(
                        applicationId: application.id,
                        status: selectedStatus,
                        notes: notesController.text.trim(),
                      );
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

  Widget _buildStatusPicker({
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
          border: Border.all(
            color: AppColors.border,
            width: 0.5,
          ),
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
                  style: TextStyle(
                    fontSize: 14,
                    color: _statusColor(value),
                  ),
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

  void _showStatusPicker(BuildContext context, String currentStatus, ValueChanged<String?> onChanged) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('اختر حالة الطلب'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              onChanged('pending');
              Navigator.pop(context);
              SemanticsService.announce('تم اختيار حالة قيد المراجعة', Directionality.of(context));
            },
            child: const Text('قيد المراجعة'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              onChanged('reviewed');
              Navigator.pop(context);
              SemanticsService.announce('تم اختيار حالة تمت المراجعة', Directionality.of(context));
            },
            child: const Text('تمت المراجعة'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              onChanged('accepted');
              Navigator.pop(context);
              SemanticsService.announce('تم اختيار حالة مقبول', Directionality.of(context));
            },
            child: const Text('مقبول'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              onChanged('rejected');
              Navigator.pop(context);
              SemanticsService.announce('تم اختيار حالة مرفوض', Directionality.of(context));
            },
            child: const Text('مرفوض'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
      ),
    );
  }

  Future<void> _updateApplicationStatus({
    required int applicationId,
    required String status,
    String? notes,
  }) async {
    try {
      final dbHelper = DatabaseHelper();
      final now = DateTime.now().toIso8601String();
      
      await dbHelper.update(
        'job_applications',
        {
          'status': status,
          'reviewed_at': now,
          'notes': notes?.isEmpty == true ? null : notes,
        },
        where: 'id = ?',
        whereArgs: [applicationId],
      );

      if (!mounted) return;
      _showSuccessMessage('تم تحديث حالة الطلب بنجاح');
      await _loadApplications();
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('حدث خطأ: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Semantics(
          header: true,
          label: 'إدارة طلبات التوظيف',
          child: const Text(
            'طلبات التوظيف',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        backgroundColor: AppColors.surface,
        trailing: AdminMenuSheet(
          currentRoute: 'job_applications',
          adminId: _adminId,
          adminName: _adminName,
          adminEmail: _adminEmail,
        ),
        automaticallyImplyLeading: false,
      ),
      child: _isLoading
          ?  Center(
              child: Semantics(
                label: 'جاري تحميل طلبات التوظيف',
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
        const CupertinoSliverRefreshControl(),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildHeader(),
              const SizedBox(height: 16),
              _buildInfoBanner(),
              const SizedBox(height: 16),
              if (_applications.isEmpty) _buildEmptyWidget() else _buildApplicationsList(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner() {
    return Semantics(
      label: 'يمكنك مراجعة الطلبات وتحديث حالتها وفتح السيرة الذاتية',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.info_circle,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'يمكنك مراجعة الطلبات وتحديث حالتها وفتح السيرة الذاتية',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'تحديث القائمة',
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 40),
                onPressed: _loadApplications,
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

  Widget _buildHeader() {
    return Semantics(
      label: 'إجمالي الطلبات: ${_applications.length}',
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
                    'إدارة طلبات التوظيف',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'عدد الطلبات الحالية: ${_applications.length}',
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
                Icons.assignment_turned_in_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsList() {
    return ListView.builder(
      itemCount: _applications.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final app = _applications[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildApplicationCard(app),
        );
      },
    );
  }

  Widget _buildApplicationCard(AdminJobApplicationModel app) {
    final hasCv = (app.cvFile ?? '').trim().isNotEmpty;

    return Semantics(
      container: true,
      label: 'طلب توظيف لوظيفة ${app.jobTitle} من ${app.applicantName}',
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
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
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
                        app.jobTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        app.companyName,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(app.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusText(app.status),
                    style: TextStyle(
                      color: _statusColor(app.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow('اسم المتقدم', app.applicantName),
            _infoRow('البريد الإلكتروني', app.applicantEmail),
            _infoRow(
              'الهاتف',
              (app.applicantPhone ?? '').trim().isEmpty ? '-' : app.applicantPhone!,
            ),
            _infoRow('تاريخ التقديم', app.appliedAt),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'عرض تفاصيل الطلب',
                    child: CupertinoButton(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      onPressed: () => _showApplicationDetailsSheet(app),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.eye,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'عرض التفاصيل',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'تحديث حالة الطلب',
                    child: CupertinoButton(
                      color: AppColors.primary,
                      onPressed: () => _showUpdateStatusDialog(app),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.pencil, size: 16, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'تحديث الحالة',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (hasCv) ...[
              const SizedBox(height: 10),
              Semantics(
                button: true,
                label: 'فتح السيرة الذاتية',
                child: CupertinoButton(
                  color: AppColors.surface,
                  onPressed: () => _openCv(app.cvFile),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.doc,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'فتح السيرة الذاتية',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
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

  void _showApplicationDetailsSheet(AdminJobApplicationModel app) {
    final hasCv = (app.cvFile ?? '').trim().isNotEmpty;

    showCupertinoModalPopup(
      context: context,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      app.jobTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      app.companyName,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _detailTile('اسم المتقدم', app.applicantName),
                    _detailTile('البريد الإلكتروني', app.applicantEmail),
                    _detailTile(
                      'الهاتف',
                      (app.applicantPhone ?? '').trim().isEmpty
                          ? '-'
                          : app.applicantPhone!,
                    ),
                    _detailTile('الحالة', _statusText(app.status)),
                    _detailTile('تاريخ التقديم', app.appliedAt),
                    _detailTile(
                      'تاريخ المراجعة',
                      (app.reviewedAt ?? '').trim().isEmpty
                          ? '-'
                          : app.reviewedAt!,
                    ),
                    _detailTile(
                      'رسالة التقديم',
                      (app.coverLetter ?? '').trim().isEmpty
                          ? 'لا توجد'
                          : app.coverLetter!,
                    ),
                    _detailTile(
                      'ملاحظات الأدمن',
                      (app.notes ?? '').trim().isEmpty ? 'لا توجد' : app.notes!,
                    ),
                    const SizedBox(height: 18),
                    if (hasCv) ...[
                      Semantics(
                        button: true,
                        label: 'فتح السيرة الذاتية',
                        child: CupertinoButton(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          onPressed: () => _openCv(app.cvFile),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.doc,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'فتح السيرة الذاتية',
                                style: TextStyle(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Semantics(
                      button: true,
                      label: 'تحديث حالة الطلب',
                      child: CupertinoButton(
                        color: AppColors.primary,
                        onPressed: () {
                          Navigator.pop(context);
                          _showUpdateStatusDialog(app);
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.pencil, size: 16, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'تحديث الحالة',
                              style: TextStyle(color: Colors.white),
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
        );
      },
    );
  }

  Widget _detailTile(String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
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
              hint: 'اضغط مرتين لإعادة تحميل الطلبات',
              child: CupertinoButton(
                color: AppColors.primary,
                onPressed: _loadApplications,
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
            Icons.work_off_outlined,
            size: 60,
            color: AppColors.textSecondary,
            semanticLabel: 'أيقونة لا توجد طلبات',
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد طلبات توظيف حاليًا',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'عندما يقدّم المستخدمون على الوظائف ستظهر الطلبات هنا',
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
              onPressed: _loadApplications,
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