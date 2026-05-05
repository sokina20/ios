import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/rendering.dart';
import 'package:saedny/core/theme/app_colors.dart';
import '../../../database/database_helper.dart';
import '../../../models/job_model.dart';
import 'job_details_screen.dart';

class JobsScreen extends StatefulWidget {
  final int userId;

  const JobsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<JobModel> _jobs = [];

  @override
  void initState() {
    super.initState();
    _loadJobs();
    
    // ✅ إعلان ترحيبي عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        'صفحة الوظائف المتاحة',
        Directionality.of(context),
      );
    });
  }

  Future<void> _loadJobs() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final dbHelper = DatabaseHelper();
      
      final jobsData = await dbHelper.getAllActiveJobs();
      
      final List<JobModel> jobs = [];
      
      for (var jobData in jobsData) {
        final companyData = await dbHelper.getCompanyById(jobData['company_id'] as int);
        
        final hasAppliedData = await dbHelper.hasUserAppliedForJob(widget.userId, jobData['id'] as int);
        
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
          applicationStatus: hasAppliedData != null 
              ? (hasAppliedData['status'] as String? ?? 'pending')
              : '',
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
        
        jobs.add(job);
      }

      if (!mounted) return;
      
      // ✅ إعلان عند نجاح التحميل
      if (jobs.isNotEmpty) {
        SemanticsService.announce(
          'تم تحميل ${jobs.length} وظيفة',
          Directionality.of(context),
        );
      }
      
      setState(() {
        _jobs = jobs;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
      
      // ✅ إعلان عند حدوث خطأ
      SemanticsService.announce(
        'فشل تحميل الوظائف: ${e.toString()}',
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
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Semantics(
          header: true,
          label: 'صفحة الوظائف المتاحة',
          child: const Text(
            'الوظائف',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        backgroundColor: AppColors.surface,
      ),
      child: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return  Center(
      child: Semantics(
        label: 'جاري تحميل الوظائف',
        child: CupertinoActivityIndicator(
          radius: 18,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          label: 'حدث خطأ أثناء تحميل الوظائف',
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
                hint: 'اضغط مرتين لإعادة تحميل الوظائف',
                child: CupertinoButton(
                  color: AppColors.primary,
                  onPressed: _loadJobs,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.refresh, size: 18),
                      SizedBox(width: 8),
                      Text('إعادة المحاولة'),
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

  Widget _buildContent() {
    if (_jobs.isEmpty) {
      return Center(
        child: Semantics(
          label: 'لا توجد وظائف متاحة حالياً',
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.work_outline,
                size: 64,
                color: AppColors.textSecondary,
                semanticLabel: 'أيقونة وظائف فارغة',
              ),
              const SizedBox(height: 16),
              const Text(
                'لا توجد وظائف متاحة حالياً',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Semantics(
                button: true,
                label: 'زر تحديث',
                hint: 'اضغط لتحديث قائمة الوظائف',
                child: CupertinoButton(
                  color: AppColors.primary,
                  onPressed: _loadJobs,
                  child: const Text('تحديث'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CupertinoScrollbar(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: _loadJobs,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final job = _jobs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildJobCard(job),
                  );
                },
                childCount: _jobs.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(JobModel job) {
    return Semantics(
      button: true,
      label: 'وظيفة ${job.title} في شركة ${job.companyName}',
      hint: 'اضغط مرتين لعرض تفاصيل الوظيفة',
      child: GestureDetector(
        onTap: () async {
          // ✅ إعلان عند فتح تفاصيل الوظيفة
          SemanticsService.announce(
            'جاري فتح تفاصيل وظيفة ${job.title}',
            Directionality.of(context),
          );
          
          await Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => JobDetailsScreen(
                userId: widget.userId,
                jobId: job.id,
              ),
            ),
          );
          
          // ✅ إعلان عند العودة وتحديث القائمة
          SemanticsService.announce(
            'جاري تحديث قائمة الوظائف',
            Directionality.of(context),
          );
          await _loadJobs();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان الوظيفة
              Text(
                job.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              
              // اسم الشركة
              Row(
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.companyName,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // الشيبس (معلومات سريعة)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if ((job.location ?? '').isNotEmpty)
                    _chip(
                      Icons.location_on_outlined,
                      job.location!,
                    ),
                  _chip(
                    Icons.work_outline,
                    _employmentTypeText(job.employmentType),
                  ),
                  if ((job.disabilityName ?? '').isNotEmpty)
                    _chip(
                      Icons.accessible,
                      job.disabilityName!,
                      isDisability: true,
                    ),
                  if (job.hasApplied)
                    _chip(
                      Icons.check_circle_outline,
                      'تم التقديم',
                      isApplied: true,
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // وصف مختصر (أول 100 حرف)
              if (job.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    job.description.length > 100
                        ? '${job.description.substring(0, 100)}...'
                        : job.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              
              // سهم للانتقال
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    CupertinoIcons.forward,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text, {
    bool isApplied = false,
    bool isDisability = false,
  }) {
    Color getChipColor() {
      if (isApplied) return AppColors.success;
      if (isDisability) return AppColors.primary;
      return AppColors.textSecondary;
    }
    
    Color getBackgroundColor() {
      if (isApplied) return AppColors.success.withOpacity(0.1);
      if (isDisability) return AppColors.primary.withOpacity(0.1);
      return AppColors.background;
    }
    
    return Semantics(
      label: text,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: getBackgroundColor(),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: getChipColor().withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: getChipColor(),
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: getChipColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}