import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Colors;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:saedny/core/theme/app_colors.dart';
import '../../../database/database_helper.dart';
import '../../../models/job_model.dart';

class ApplyJobScreen extends StatefulWidget {
  final int userId;
  final JobModel job;

  const ApplyJobScreen({
    super.key,
    required this.userId,
    required this.job,
  });

  @override
  State<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends State<ApplyJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coverLetterController = TextEditingController();

  bool _isSubmitting = false;
  bool _isPickingFile = false;
  String? _uploadedCvPath;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        'صفحة التقديم على وظيفة ${widget.job.title} في شركة ${widget.job.companyName}',
        Directionality.of(context),
      );
    });
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    super.dispose();
  }

  Future<void> _pickAndSaveCv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      
      if (file.path == null) {
        throw Exception('تعذر قراءة مسار الملف');
      }

      setState(() {
        _isPickingFile = true;
      });

      SemanticsService.announce(
        'جاري رفع وحفظ ملف السيرة الذاتية',
        Directionality.of(context),
      );

      final appDir = await getApplicationDocumentsDirectory();
      final cvDir = Directory('${appDir.path}/cvs');
      
      if (!await cvDir.exists()) {
        await cvDir.create(recursive: true);
      }

      final extension = path.extension(file.path!);
      final uniqueFileName = 'cv_${widget.userId}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final savedPath = path.join(cvDir.path, uniqueFileName);

      final sourceFile = File(file.path!);
      await sourceFile.copy(savedPath);

      setState(() {
        _uploadedCvPath = savedPath;
        _selectedFileName = file.name;
      });

      SemanticsService.announce(
        'تم حفظ ملف ${file.name} بنجاح',
        Directionality.of(context),
      );
      
      if (!mounted) return;
      _showSuccessMessage('تم حفظ ملف السيرة الذاتية بنجاح');
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('حدث خطأ أثناء حفظ الملف: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isPickingFile = false;
      });
    }
  }

  Future<void> _submitApplication() async {
    FocusScope.of(context).unfocus();

    final coverLetter = _coverLetterController.text.trim();
    
    if (coverLetter.isEmpty && _uploadedCvPath == null) {
      _showErrorMessage('يجب إما كتابة رسالة تقديم أو رفع ملف CV');
      SemanticsService.announce(
        'يجب إما كتابة رسالة تقديم أو رفع ملف CV',
        Directionality.of(context),
      );
      return;
    }
    
    if (coverLetter.isNotEmpty && coverLetter.length < 10) {
      _showErrorMessage('رسالة التقديم قصيرة جدًا (على الأقل 10 أحرف)');
      SemanticsService.announce(
        'رسالة التقديم قصيرة جدًا، يجب أن تكون 10 أحرف على الأقل',
        Directionality.of(context),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    SemanticsService.announce(
      'جاري إرسال طلب التقديم للوظيفة',
      Directionality.of(context),
    );

    try {
      final dbHelper = DatabaseHelper();

      await dbHelper.insert('job_applications', {
        'job_id': widget.job.id,
        'user_id': widget.userId,
        'cover_letter': coverLetter.isEmpty ? null : coverLetter,
        'cv_file': _uploadedCvPath,
        'status': 'pending',
        'applied_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      SemanticsService.announce(
        'تم التقديم على الوظيفة بنجاح',
        Directionality.of(context),
      );
      
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('حدث خطأ: $e');
      SemanticsService.announce(
        'فشل إرسال الطلب: $e',
        Directionality.of(context),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showSuccessMessage(String message) {
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

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('تم التقديم بنجاح'),
        content: const Text('تم إرسال طلبك للوظيفة بنجاح، سيتم مراجعته من قبل الجهة المعنية'),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String message) {
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

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Semantics(
          header: true,
          label: 'نموذج التقديم على الوظيفة ${job.title}',
          child: const Text(
            'التقديم على الوظيفة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        backgroundColor: AppColors.surface,
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: CupertinoScrollbar(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Semantics(
                        label: 'معلومات الوظيفة: ${job.title} في شركة ${job.companyName}',
                        child: Container(
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
                              Text(
                                job.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                job.companyName,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (job.location != null && job.location!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        job.location!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Semantics(
                        header: true,
                        label: 'رسالة التقديم',
                        child: const Text(
                          'رسالة التقديم',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Semantics(
                        textField: true,
                        label: 'حقل رسالة التقديم',
                        hint: 'اكتب رسالة تقديم مناسبة للوظيفة، هذا الحقل اختياري إذا تم رفع ملف CV',
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.border,
                              width: 0.5,
                            ),
                          ),
                          child: CupertinoTextFormFieldRow(
                            controller: _coverLetterController,
                            maxLines: 6,
                            minLines: 3,
                            placeholder: 'اكتب رسالة تقديم مختصرة وواضحة...',
                            placeholderStyle: TextStyle(
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
                            ),
                            padding: const EdgeInsets.all(12),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) return null;
                              if (value!.trim().length < 10) {
                                return 'رسالة التقديم قصيرة جدًا';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Semantics(
                        header: true,
                        label: 'ملف السيرة الذاتية',
                        child: const Text(
                          'ملف السيرة الذاتية CV',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (_selectedFileName != null)
                        Semantics(
                          label: 'الملف المختار: $_selectedFileName',
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: AppColors.success.withValues(alpha: 0.08),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.25),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.insert_drive_file,
                                  size: 20,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedFileName!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Semantics(
                                  button: true,
                                  label: 'إزالة الملف المختار',
                                  child: CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(30, 30),
                                    onPressed: () {
                                      setState(() {
                                        _uploadedCvPath = null;
                                        _selectedFileName = null;
                                      });
                                      SemanticsService.announce(
                                        'تم إزالة الملف المختار',
                                        Directionality.of(context),
                                      );
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 18,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 10),

                      Semantics(
                        button: true,
                        label: 'زر اختيار ملف السيرة الذاتية',
                        hint: 'اضغط مرتين لاختيار ملف PDF أو Word وحفظه داخل التطبيق',
                        child: CupertinoButton(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          onPressed: (_isSubmitting || _isPickingFile) ? null : _pickAndSaveCv,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isPickingFile)
                                const CupertinoActivityIndicator(radius: 10)
                              else
                                Icon(
                                  Icons.upload_file,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              const SizedBox(width: 8),
                              Text(
                                _isPickingFile ? 'جاري رفع الملف...' : 'اختيار وحفظ ملف CV',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      Semantics(
                        label: 'يمكنك التقديم برسالة فقط أو بملف CV فقط أو بكليهما',
                        child: Text(
                          'يمكنك التقديم برسالة فقط أو بملف CV فقط أو بكليهما',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Semantics(
                        button: true,
                        label: _isSubmitting ? 'جارٍ إرسال الطلب' : 'زر إرسال طلب التقديم',
                        hint: 'اضغط مرتين لإرسال طلبك لهذه الوظيفة',
                        child: SizedBox(
                          width: double.infinity,
                          child: CupertinoButton(
                            color: AppColors.primary,
                            onPressed: (_isSubmitting || _isPickingFile) ? null : _submitApplication,
                            child: _isSubmitting
                                ? const CupertinoActivityIndicator(
                                    color: CupertinoColors.white,
                                  )
                                : const Text(
                                    'إرسال الطلب',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}