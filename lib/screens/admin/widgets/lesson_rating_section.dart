import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/rendering.dart';
import 'package:saedny/core/theme/app_colors.dart';
import '../../../database/database_helper.dart';

class LessonRatingSection extends StatefulWidget {
  final int lessonId;
  final int userId;

  const LessonRatingSection({
    super.key,
    required this.lessonId,
    required this.userId,
  });

  @override
  State<LessonRatingSection> createState() => _LessonRatingSectionState();
}

class _LessonRatingSectionState extends State<LessonRatingSection> {
  int selectedRating = 5;
  final TextEditingController commentController = TextEditingController();
  bool isSubmitting = false;

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    // إخفاء لوحة المفاتيح
    FocusScope.of(context).unfocus();
    
    if (selectedRating < 1 || selectedRating > 5) {
      _showErrorMessage('يرجى اختيار تقييم من 1 إلى 5');
      return;
    }

    setState(() => isSubmitting = true);

    SemanticsService.announce(
      'جاري إرسال تقييمك للدرس',
      Directionality.of(context),
    );

    try {
      final dbHelper = DatabaseHelper();
      
      await dbHelper.addOrUpdateRating(
        widget.userId,
        widget.lessonId,
        selectedRating,
        comment: commentController.text.trim().isEmpty 
            ? null 
            : commentController.text.trim(),
      );

      if (!mounted) return;

      SemanticsService.announce(
        'تم إرسال تقييمك بنجاح',
        Directionality.of(context),
      );
      
      _showSuccessMessage('تم إرسال التقييم بنجاح');

      commentController.clear();
      setState(() {
        selectedRating = 5;
      });
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('حدث خطأ: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (!mounted) return;
      setState(() => isSubmitting = false);
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

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'سيء جداً';
      case 2:
        return 'سيء';
      case 3:
        return 'متوسط';
      case 4:
        return 'جيد';
      case 5:
        return 'ممتاز';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          label: 'تقييم الدرس',
          child: const Text(
            'قيّم هذا الدرس',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // ✅ Rating Stars - بنمط iOS
        Semantics(
          label: 'التقييم المختار: ${_getRatingText(selectedRating)}، $selectedRating من 5 نجوم',
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                final isSelected = star <= selectedRating;
                
                return Semantics(
                  button: true,
                  label: isSelected ? 'نجمة ممتلئة' : 'نجمة فارغة',
                  hint: 'اضغط مرتين لتقييم الدرس ب $star نجوم',
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 44,
                    onPressed: isSubmitting ? null : () {
                      setState(() {
                        selectedRating = star;
                      });
                      SemanticsService.announce(
                        'تم اختيار تقييم $star نجوم: ${_getRatingText(star)}',
                        Directionality.of(context),
                      );
                    },
                    child: Icon(
                      isSelected ? CupertinoIcons.star_fill : CupertinoIcons.star,
                      size: 36,
                      color: isSelected ? AppColors.accent : AppColors.border,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        
        // ✅ نص توضيحي للتقييم المختار
        if (selectedRating > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Center(
              child: Text(
                _getRatingText(selectedRating),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        
        const SizedBox(height: 8),
        
        // ✅ حقل التعليق بنمط iOS
        Semantics(
          label: 'حقل التعليق',
          hint: 'اكتب تعليقك على الدرس (اختياري)',
          textField: true,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border,
                width: 0.5,
              ),
            ),
            child: CupertinoTextField(
              controller: commentController,
              maxLines: 3,
              minLines: 2,
              placeholder: 'اكتب تعليقك هنا (اختياري)...',
              placeholderStyle: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // ✅ زر إرسال التقييم
        Semantics(
          button: true,
          label: isSubmitting ? 'جارٍ إرسال التقييم' : 'زر إرسال التقييم',
          hint: 'اضغط مرتين لإرسال تقييمك لهذا الدرس',
          child: SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: AppColors.primary,
              onPressed: isSubmitting ? null : _submitRating,
              child: isSubmitting
                  ? const CupertinoActivityIndicator(
                      color: CupertinoColors.white,
                    )
                  : const Text(
                      'إرسال التقييم',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}