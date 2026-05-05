import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Colors;
import 'package:flutter/rendering.dart';
import 'package:saedny/core/theme/app_colors.dart';
import '../../../database/database_helper.dart';
import '../../../models/job_model.dart';
import 'apply_job_screen.dart';

class JobDetailsScreen extends StatefulWidget {
  final int userId;
  final int jobId;

  const JobDetailsScreen({
    super.key,
    required this.userId,
    required this.jobId,
  });

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  JobModel? _job;

  @override
  void initState() {
    super.initState();
    _loadJobDetails();
  }

  Future<void> _loadJobDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final dbHelper = DatabaseHelper();
      
      final jobData = await dbHelper.getJobDetails(widget.jobId);
      if (jobData == null) throw Exception('الوظيفة غير موجودة');
      
      final companyData = await dbHelper.getCompanyById(jobData['company_id'] as int);
      
      final hasAppliedData = await dbHelper.hasUserAppliedForJob(widget.userId, widget.jobId);
      final applicationStatus = hasAppliedData != null 
          ? (hasAppliedData['status'] as String? ?? 'pending')
          : '';
      
      final job = JobModel(
        id: jobData['id'] as int,
        companyId: jobData['company_id'] as int,
        title: jobData['title'] as String,
        description: jobData['description'] as String,
        requirements: jobData['requirements'] as String?,
        location: jobData['location'] as String?,
        employmentType: jobData['employment_type'] as String,
        salaryMin: jobData['salary_min']?.toString(),
        salaryMax: jobData['salary_max']?.toString(),
        targetDisabilityId: jobData['target_disability_id'] as int?,
        applicationDeadline: jobData['application_deadline'] as String?,
        createdAt: jobData['created_at'] as String?,
        companyName: companyData?['company_name'] as String? ?? '',
        companyLogo: companyData?['logo'] as String?,
        disabilityName: await dbHelper.getDisabilityTypeName(jobData['target_disability_id'] as int?),
        hasApplied: hasAppliedData != null,
        applicationStatus: applicationStatus,
        companyEmail: companyData?['email'] as String?,
        companyPhone: companyData?['phone'] as String?,
        companyWebsite: companyData?['website'] as String?,
        companyCity: companyData?['city'] as String?,
        companyAddress: companyData?['address'] as String?,
        companyDescription: companyData?['description'] as String?,
        coverLetter: hasAppliedData?['cover_letter'] as String?,
        cvFile: hasAppliedData?['cv_file'] as String?,
        notes: hasAppliedData?['notes'] as String?,
      );

      if (!mounted) return;
      
      SemanticsService.announce(
        'تم تحميل تفاصيل وظيفة ${job.title}',
        Directionality.of(context),
      );
      
      setState(() {
        _job = job;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
      
      SemanticsService.announce(
        'فشل تحميل تفاصيل الوظيفة',
        Directionality.of(context),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _employmentTypeText(String type) {
    switch (type) {
      case 'full_time':
        return 'دوام كامل';
      case 'part_time':
        return 'دوام جزئي';
      case 'remote':
        return 'عن بعد';
      case 'internship':
        return 'تدريب';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = _job;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Semantics(
          header: true,
          label: job == null ? 'تفاصيل الوظيفة' : 'تفاصيل وظيفة ${job.title}',
          child: Text(
            job?.title ?? 'تفاصيل الوظيفة',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        backgroundColor: AppColors.surface,
      ),
      child: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _buildContent(job!),
    );
  }

  Widget _buildLoadingState() {
    return  Center(
      child: Semantics(
        label: 'جاري تحميل تفاصيل الوظيفة',
        child: CupertinoActivityIndicator(radius: 18),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          label: 'حدث خطأ أثناء تحميل تفاصيل الوظيفة',
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
                semanticLabel: 'أيقونة خطأ',
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                button: true,
                label: 'زر إعادة المحاولة',
                hint: 'اضغط مرتين لإعادة تحميل تفاصيل الوظيفة',
                child: CupertinoButton(
                  color: AppColors.primary,
                  onPressed: _loadJobDetails,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.refresh, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'إعادة المحاولة',
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
    );
  }

  Widget _buildContent(JobModel job) {
    return CupertinoScrollbar(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: _loadJobDetails,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Semantics(
                  header: true,
                  label: job.title,
                  child: Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                Semantics(
                  label: 'شركة ${job.companyName}',
                  child: Text(
                    job.companyName,
                    style: TextStyle(
                      fontSize: 17,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if ((job.location ?? '').isNotEmpty)
                      _chip(Icons.location_on_outlined, 'الموقع: ${job.location}'),
                    _chip(Icons.work_outline, 'النوع: ${_employmentTypeText(job.employmentType)}'),
                    if ((job.salaryMin ?? '').isNotEmpty || (job.salaryMax ?? '').isNotEmpty)
                      _chip(Icons.attach_money, 'الراتب: ${job.salaryMin ?? "-"} - ${job.salaryMax ?? "-"}'),
                    if ((job.applicationDeadline ?? '').isNotEmpty)
                      _chip(Icons.calendar_today, 'آخر موعد: ${job.applicationDeadline}'),
                    if ((job.disabilityName ?? '').isNotEmpty)
                      _chip(Icons.accessible, 'مناسبة لـ ${job.disabilityName}'),
                  ],
                ),

                const SizedBox(height: 24),
                
                Semantics(
                  header: true,
                  label: 'وصف الوظيفة',
                  child: const Text(
                    'وصف الوظيفة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: 'وصف الوظيفة: ${job.description}',
                  child: Text(
                    job.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.7,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                
                Semantics(
                  header: true,
                  label: 'متطلبات الوظيفة',
                  child: const Text(
                    'المتطلبات',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: (job.requirements ?? '').isNotEmpty
                      ? 'متطلبات الوظيفة: ${job.requirements}'
                      : 'لا توجد متطلبات إضافية',
                  child: Text(
                    (job.requirements ?? '').isNotEmpty
                        ? job.requirements!
                        : 'لا توجد متطلبات إضافية',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.7,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                
                Semantics(
                  header: true,
                  label: 'معلومات الشركة',
                  child: const Text(
                    'معلومات الشركة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                if ((job.companyDescription ?? '').isNotEmpty)
                  Semantics(
                    label: 'وصف الشركة: ${job.companyDescription}',
                    child: Text(
                      job.companyDescription!,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.7,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 8),
                
                _buildCompanyInfoCard(job),

                const SizedBox(height: 24),
                
                if (job.hasApplied)
                  _buildAppliedCard(job)
                else
                  _buildApplyButton(job),

                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyInfoCard(JobModel job) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((job.companyCity ?? '').isNotEmpty)
            Semantics(
              label: 'مدينة الشركة: ${job.companyCity}',
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_city,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'المدينة: ${job.companyCity}',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if ((job.companyPhone ?? '').isNotEmpty)
            Semantics(
              label: 'هاتف الشركة: ${job.companyPhone}',
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'الهاتف: ${job.companyPhone}',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if ((job.companyEmail ?? '').isNotEmpty)
            Semantics(
              label: 'بريد الشركة: ${job.companyEmail}',
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'البريد: ${job.companyEmail}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if ((job.companyWebsite ?? '').isNotEmpty)
            Semantics(
              label: 'موقع الشركة: ${job.companyWebsite}',
              child: Row(
                children: [
                  Icon(
                    Icons.language,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'الموقع الإلكتروني: ${job.companyWebsite}',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppliedCard(JobModel job) {
    return Semantics(
      label: 'تم التقديم على هذه الوظيفة، الحالة: ${job.applicationStatus.isEmpty ? "قيد المراجعة" : job.applicationStatus}',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.success.withValues(alpha: 0.08),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 20,
                  color: AppColors.success,
                ),
                SizedBox(width: 8),
                Text(
                  'تم التقديم على هذه الوظيفة',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'الحالة الحالية: ${job.applicationStatus.isEmpty ? "قيد المراجعة" : job.applicationStatus}',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyButton(JobModel job) {
    return Semantics(
      button: true,
      label: 'زر التقديم على الوظيفة ${job.title}',
      hint: 'اضغط مرتين للانتقال إلى نموذج التقديم',
      child: SizedBox(
        width: double.infinity,
        child: CupertinoButton(
          color: AppColors.primary,
          onPressed: () async {
            SemanticsService.announce(
              'جاري فتح نموذج التقديم على وظيفة ${job.title}',
              Directionality.of(context),
            );
            
            final applied = await Navigator.push<bool>(
              context,
              CupertinoPageRoute(
                builder: (_) => ApplyJobScreen(
                  userId: widget.userId,
                  job: job,
                ),
              ),
            );

            if (applied == true) {
              SemanticsService.announce(
                'تم التقديم بنجاح، جاري تحديث الصفحة',
                Directionality.of(context),
              );
              await _loadJobDetails();
            }
          },
          child: const Text(
            'التقديم على الوظيفة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Semantics(
      label: text,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}