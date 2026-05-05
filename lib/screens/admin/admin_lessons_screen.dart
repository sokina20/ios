import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Colors;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:saedny/core/theme/app_colors.dart';
import '../../database/database_helper.dart';
import 'widgets/admin_menu_sheet.dart';

class AdminLessonsScreen extends StatefulWidget {
  const AdminLessonsScreen({super.key});

  @override
  State<AdminLessonsScreen> createState() => _AdminLessonsScreenState();
}

class _AdminLessonsScreenState extends State<AdminLessonsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _lessons = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _disabilities = [];

  final ImagePicker _imagePicker = ImagePicker();

  final int _adminId = 1;
  final String _adminName = 'مدير النظام';
  final String _adminEmail = 'admin@saedny.com';

  @override
  void initState() {
    super.initState();
    _loadAll();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        'لوحة تحكم المدير - إدارة الدروس',
        Directionality.of(context),
      );
    });
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);

    try {
      final dbHelper = DatabaseHelper();
      
      final lessons = await dbHelper.rawQuery('''
        SELECT 
          l.*,
          c.name_ar as category_name_ar,
          dt.name_ar as target_disability_name
        FROM lessons l
        JOIN categories c ON l.category_id = c.id
        LEFT JOIN disability_types dt ON l.target_disability_id = dt.id
        ORDER BY l.created_at DESC
      ''');
      
      final categories = await dbHelper.rawQuery('''
        SELECT * FROM categories WHERE status = 'active' ORDER BY name_ar ASC
      ''');
      
      final disabilities = await dbHelper.rawQuery('''
        SELECT * FROM disability_types WHERE status = 'active' ORDER BY name_ar ASC
      ''');
      
      if (!mounted) return;
      
      SemanticsService.announce(
        'تم تحميل ${lessons.length} درس',
        Directionality.of(context),
      );
      
      setState(() {
        _lessons = lessons;
        _categories = categories;
        _disabilities = disabilities;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorMessage('حدث خطأ: ${e.toString()}');
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

  Future<String?> _saveFileLocally(File file, String subFolder) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${appDir.path}/$subFolder');
      
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final extension = path.extension(file.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
      final savedPath = path.join(targetDir.path, fileName);
      
      await file.copy(savedPath);
      return savedPath;
    } catch (e) {
      _showErrorMessage('خطأ في حفظ الملف: ${e.toString()}');
      return null;
    }
  }

  Future<File?> _pickThumbnailImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;
    return File(picked.path);
  }

  Future<File?> _pickLessonFile(String lessonType) async {
    FilePickerResult? result;

    try {
      if (lessonType == 'video') {
        result = await FilePicker.platform.pickFiles(type: FileType.video);
      } else if (lessonType == 'audio') {
        result = await FilePicker.platform.pickFiles(type: FileType.audio);
      } else if (lessonType == 'text') {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        );
      } else {
        result = await FilePicker.platform.pickFiles(type: FileType.any);
      }

      if (result == null || result.files.isEmpty) return null;
      
      final filePath = result.files.single.path;
      if (filePath == null) return null;
      
      return File(filePath);
    } catch (e) {
      _showErrorMessage('خطأ في اختيار الملف: ${e.toString()}');
      return null;
    }
  }

  Future<void> _showLessonDialog({Map<String, dynamic>? lesson}) async {
    final titleArController = TextEditingController(
      text: lesson?['title_ar']?.toString() ?? '',
    );
    final titleEnController = TextEditingController(
      text: lesson?['title_en']?.toString() ?? '',
    );
    final shortDescriptionController = TextEditingController(
      text: lesson?['short_description']?.toString() ?? '',
    );
    final contentController = TextEditingController(
      text: lesson?['content']?.toString() ?? '',
    );
    final durationController = TextEditingController(
      text: lesson?['duration_minutes']?.toString() ?? '0',
    );

    int? selectedCategoryId = lesson?['category_id'] as int?;
    int? selectedDisabilityId = lesson?['target_disability_id'] as int?;

    String lessonType = lesson?['lesson_type']?.toString() ?? 'text';
    String difficultyLevel = lesson?['difficulty_level']?.toString() ?? 'easy';
    String status = lesson?['status']?.toString() ?? 'published';
    bool isFeatured = (lesson?['is_featured'] as int?) == 1;

    File? selectedThumbnailFile;
    File? selectedLessonFile;

    final oldThumbnail = lesson?['thumbnail']?.toString() ?? '';
    final oldLessonFile = lesson?['lesson_file']?.toString() ?? '';

    final formKey = GlobalKey<FormState>();

    await showCupertinoDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: CupertinoAlertDialog(
                title: Text(
                  lesson == null ? 'إضافة درس جديد' : 'تعديل الدرس',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                content: SingleChildScrollView(
                  child: SizedBox(
                    width: 420,
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCategoryPicker(
                            value: selectedCategoryId,
                            onChanged: (value) {
                              setDialogState(() => selectedCategoryId = value);
                            },
                            validator: (value) {
                              if (value == null) return 'اختر القسم';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildDialogTextField(
                            controller: titleArController,
                            label: 'عنوان الدرس بالعربي',
                            placeholder: 'أدخل عنوان الدرس بالعربية',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'عنوان الدرس بالعربي مطلوب';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildDialogTextField(
                            controller: titleEnController,
                            label: 'عنوان الدرس بالإنجليزي',
                            placeholder: 'Enter lesson title in English',
                          ),
                          const SizedBox(height: 12),
                          _buildDialogTextField(
                            controller: shortDescriptionController,
                            label: 'الوصف المختصر',
                            placeholder: 'أدخل وصفاً مختصراً للدرس',
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogTextField(
                            controller: contentController,
                            label: 'محتوى الدرس',
                            placeholder: 'أدخل محتوى الدرس',
                            maxLines: 4,
                          ),
                          const SizedBox(height: 12),
                          _buildLessonTypePicker(
                            value: lessonType,
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() {
                                  lessonType = value;
                                  selectedLessonFile = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildDifficultyPicker(
                            value: difficultyLevel,
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => difficultyLevel = value);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildDisabilityPicker(
                            value: selectedDisabilityId,
                            onChanged: (value) {
                              setDialogState(() => selectedDisabilityId = value);
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildDialogTextField(
                            controller: durationController,
                            label: 'المدة بالدقائق',
                            placeholder: '0',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          _buildStatusPicker(
                            value: status,
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => status = value);
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildFeaturedSwitch(
                            value: isFeatured,
                            onChanged: (value) {
                              setDialogState(() => isFeatured = value);
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildThumbnailPicker(
                            selectedFile: selectedThumbnailFile,
                            oldFile: oldThumbnail,
                            onPick: () async {
                              final file = await _pickThumbnailImage();
                              if (file != null) {
                                setDialogState(() {
                                  selectedThumbnailFile = file;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildLessonFilePicker(
                            lessonType: lessonType,
                            selectedFile: selectedLessonFile,
                            oldFile: oldLessonFile,
                            onPick: () async {
                              final file = await _pickLessonFile(lessonType);
                              if (file != null) {
                                setDialogState(() {
                                  selectedLessonFile = file;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  CupertinoDialogAction(
                    onPressed: () async {
                      if (formKey.currentState?.validate() != true) return;

                      Navigator.pop(context);
                      final now = DateTime.now().toIso8601String();
                      final dbHelper = DatabaseHelper();

                      String? thumbnailPath = oldThumbnail;
                      final thumbnailFile = selectedThumbnailFile;
                      if (thumbnailFile != null) {
                        thumbnailPath = await _saveFileLocally(thumbnailFile, 'lesson_thumbnails');
                      }

                      String? lessonFilePath = oldLessonFile;
                      final lessonFile = selectedLessonFile;
                      if (lessonFile != null) {
                        final subFolder = lessonType == 'video' ? 'lesson_videos' 
                            : lessonType == 'audio' ? 'lesson_audios' 
                            : 'lesson_files';
                        lessonFilePath = await _saveFileLocally(lessonFile, subFolder);
                      }
                      
                      if (lesson == null) {
                        await dbHelper.insert('lessons', {
                          'category_id': selectedCategoryId!,
                          'title_ar': titleArController.text.trim(),
                          'title_en': titleEnController.text.trim().isEmpty ? null : titleEnController.text.trim(),
                          'short_description': shortDescriptionController.text.trim().isEmpty ? null : shortDescriptionController.text.trim(),
                          'content': contentController.text.trim().isEmpty ? null : contentController.text.trim(),
                          'lesson_type': lessonType,
                          'difficulty_level': difficultyLevel,
                          'target_disability_id': selectedDisabilityId,
                          'thumbnail': thumbnailPath,
                          'lesson_file': lessonFilePath,
                          'lesson_file_type': lessonType == 'video' ? 'video' : lessonType == 'audio' ? 'audio' : 'file',
                          'duration_minutes': int.tryParse(durationController.text.trim()) ?? 0,
                          'is_featured': isFeatured ? 1 : 0,
                          'status': status,
                          'created_by': _adminId,
                          'created_at': now,
                          'updated_at': now,
                        });
                        _showSuccessMessage('تمت إضافة الدرس بنجاح');
                      } else {
                        await dbHelper.update(
                          'lessons',
                          {
                            'category_id': selectedCategoryId!,
                            'title_ar': titleArController.text.trim(),
                            'title_en': titleEnController.text.trim().isEmpty ? null : titleEnController.text.trim(),
                            'short_description': shortDescriptionController.text.trim().isEmpty ? null : shortDescriptionController.text.trim(),
                            'content': contentController.text.trim().isEmpty ? null : contentController.text.trim(),
                            'lesson_type': lessonType,
                            'difficulty_level': difficultyLevel,
                            'target_disability_id': selectedDisabilityId,
                            'thumbnail': thumbnailPath,
                            'lesson_file': lessonFilePath,
                            'lesson_file_type': lessonType == 'video' ? 'video' : lessonType == 'audio' ? 'audio' : 'file',
                            'duration_minutes': int.tryParse(durationController.text.trim()) ?? 0,
                            'is_featured': isFeatured ? 1 : 0,
                            'status': status,
                            'updated_at': now,
                          },
                          where: 'id = ?',
                          whereArgs: [lesson!['id']],
                        );
                        _showSuccessMessage('تم تحديث الدرس بنجاح');
                      }
                      await _loadAll();
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

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    String? placeholder,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: CupertinoTextFormFieldRow(
        controller: controller,
        placeholder: placeholder ?? label,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  void _showPicker<T>({
    required String title,
    required List<String> items,
    required List<T> values,
    required T? currentValue,
    required ValueChanged<T?> onChanged,
  }) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(title),
        actions: [
          for (int i = 0; i < items.length; i++)
            CupertinoActionSheetAction(
              onPressed: () {
                onChanged(values[i]);
                Navigator.pop(context);
                SemanticsService.announce('تم اختيار ${items[i]}', Directionality.of(context));
              },
              child: Text(items[i]),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
      ),
    );
  }

  Widget _buildCategoryPicker({
    required int? value,
    required ValueChanged<int?> onChanged,
    String? Function(int?)? validator,
  }) {
    return Container(
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
          const Text(
            'القسم',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () {
              _showPicker<int?>(
                title: 'اختر القسم',
                items: _categories.map((c) => c['name_ar'] as String? ?? '').toList(),
                values: _categories.map((c) => c['id'] as int).toList(),
                currentValue: value,
                onChanged: onChanged,
              );
            },
            child: Row(
              children: [
                Text(
                  value != null
                      ? (_categories.firstWhere(
                          (c) => c['id'] == value,
                          orElse: () => {'name_ar': 'غير معروف'},
                        )['name_ar'] as String? ?? 'غير معروف')
                      : 'اختر القسم',
                  style: TextStyle(
                    fontSize: 14,
                    color: value != null ? AppColors.primary : AppColors.textSecondary,
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
          ),
        ],
      ),
    );
  }

  Widget _buildLessonTypePicker({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    final typeMap = {
      'text': 'نصي',
      'video': 'فيديو',
      'audio': 'صوت',
      'interactive': 'تفاعلي',
    };
    
    return Container(
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
          const Text(
            'نوع الدرس',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () {
              _showPicker<String?>(
                title: 'اختر نوع الدرس',
                items: ['نصي', 'فيديو', 'صوت', 'تفاعلي'],
                values: ['text', 'video', 'audio', 'interactive'],
                currentValue: value,
                onChanged: onChanged,
              );
            },
            child: Row(
              children: [
                Text(
                  typeMap[value] ?? value,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
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
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyPicker({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    final diffMap = {
      'easy': 'سهل',
      'medium': 'متوسط',
      'hard': 'صعب',
    };
    
    return Container(
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
          const Text(
            'مستوى الصعوبة',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () {
              _showPicker<String?>(
                title: 'اختر مستوى الصعوبة',
                items: ['سهل', 'متوسط', 'صعب'],
                values: ['easy', 'medium', 'hard'],
                currentValue: value,
                onChanged: onChanged,
              );
            },
            child: Row(
              children: [
                Text(
                  diffMap[value] ?? value,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
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
          ),
        ],
      ),
    );
  }

  Widget _buildDisabilityPicker({
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    final disabilityNames = _disabilities.map((d) => d['name_ar'] as String? ?? '').toList();
    final disabilityIds = _disabilities.map((d) => d['id'] as int).toList();
    
    return Container(
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
          const Text(
            'الفئة المستهدفة',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () {
              _showPicker<int?>(
                title: 'اختر الفئة المستهدفة',
                items: ['عام (جميع الفئات)', ...disabilityNames],
                values: [null, ...disabilityIds],
                currentValue: value,
                onChanged: onChanged,
              );
            },
            child: Row(
              children: [
                Text(
                  value != null
                      ? (disabilityNames[disabilityIds.indexOf(value)] ?? 'عام')
                      : 'عام (جميع الفئات)',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPicker({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    final statusMap = {
      'published': 'منشور',
      'draft': 'مسودة',
      'archived': 'مؤرشف',
    };
    
    final statusColors = {
      'published': AppColors.success,
      'draft': AppColors.accent,
      'archived': AppColors.textSecondary,
    };
    
    return Container(
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
          const Text(
            'الحالة',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () {
              _showPicker<String?>(
                title: 'اختر الحالة',
                items: ['منشور', 'مسودة', 'مؤرشف'],
                values: ['published', 'draft', 'archived'],
                currentValue: value,
                onChanged: onChanged,
              );
            },
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColors[value] ?? AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  statusMap[value] ?? value,
                  style: TextStyle(
                    fontSize: 14,
                    color: statusColors[value] ?? AppColors.textSecondary,
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
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'درس مميز',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailPicker({
    required File? selectedFile,
    required String oldFile,
    required VoidCallback onPick,
  }) {
    return Container(
      width: double.infinity,
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
          const Text(
            'الصورة المصغرة',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            button: true,
            label: 'اختيار صورة للدرس',
            child: CupertinoButton(
              color: AppColors.secondary.withValues(alpha: 0.1),
              onPressed: onPick,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.photo,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selectedFile == null ? 'اختيار صورة من المعرض' : 'تم اختيار صورة جديدة',
                    style: TextStyle(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (selectedFile != null) ...[
            const SizedBox(height: 8),
            Text(
              selectedFile.path.split('/').last,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ] else if (oldFile.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'يوجد صورة محفوظة حالياً',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLessonFilePicker({
    required String lessonType,
    required File? selectedFile,
    required String oldFile,
    required VoidCallback onPick,
  }) {
    String getFileHint() {
      if (lessonType == 'video') return 'اختر ملف فيديو';
      if (lessonType == 'audio') return 'اختر ملف صوت';
      if (lessonType == 'text') return 'اختر PDF أو DOC أو TXT';
      return 'اختر ملف مناسب';
    }

    return Container(
      width: double.infinity,
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
          const Text(
            'ملف الدرس',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            getFileHint(),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            button: true,
            label: 'اختيار ملف الدرس',
            child: CupertinoButton(
              color: AppColors.secondary.withValues(alpha: 0.1),
              onPressed: onPick,
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
                    selectedFile == null ? 'اختيار ملف الدرس' : 'تم اختيار ملف جديد',
                    style: TextStyle(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (selectedFile != null) ...[
            const SizedBox(height: 8),
            Text(
              selectedFile.path.split('/').last,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ] else if (oldFile.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'يوجد ملف محفوظ حالياً',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _deleteLesson(int id, String title) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('حذف الدرس'),
        content: Text('هل أنت متأكد أنك تريد حذف درس "$title"؟'),
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
        'lessons',
        where: 'id = ?',
        whereArgs: [id],
      );
      _showSuccessMessage('تم حذف الدرس بنجاح');
      await _loadAll();
    } catch (e) {
      _showErrorMessage('حدث خطأ: ${e.toString()}');
    }
  }

  String _lessonTypeText(String value) {
    switch (value) {
      case 'text': return 'نصي';
      case 'video': return 'فيديو';
      case 'audio': return 'صوت';
      case 'interactive': return 'تفاعلي';
      default: return value;
    }
  }

  String _difficultyText(String value) {
    switch (value) {
      case 'easy': return 'سهل';
      case 'medium': return 'متوسط';
      case 'hard': return 'صعب';
      default: return value;
    }
  }

  String _statusText(String value) {
    switch (value) {
      case 'published': return 'منشور';
      case 'draft': return 'مسودة';
      case 'archived': return 'مؤرشف';
      default: return value;
    }
  }

  Color _statusColor(String value) {
    switch (value) {
      case 'published': return AppColors.success;
      case 'draft': return AppColors.accent;
      case 'archived': return AppColors.textSecondary;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Semantics(
          header: true,
          label: 'إدارة الدروس',
          child: const Text(
            'الدروس',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        backgroundColor: AppColors.surface,
        trailing: AdminMenuSheet(
          currentRoute: 'lessons',
          adminId: _adminId,
          adminName: _adminName,
          adminEmail: _adminEmail,
        ),
        automaticallyImplyLeading: false,
      ),
      child: _isLoading
          ?  Center(
              child: Semantics(
                label: 'جاري تحميل الدروس',
                child: CupertinoActivityIndicator(radius: 20),
              ),
            )
          : CustomScrollView(
              slivers: [
                const CupertinoSliverRefreshControl(),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildTopActions(),
                      if (_categories.isEmpty) ...[
                        const SizedBox(height: 14),
                        _buildWarningBanner(),
                      ],
                      const SizedBox(height: 16),
                      if (_lessons.isEmpty) _buildEmptyWidget() else _buildLessonsList(),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Semantics(
      label: 'إجمالي الدروس: ${_lessons.length}',
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
                children: const [
                  Text(
                    'إدارة الدروس',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'أضف وعدّل واحذف الدروس المرتبطة بالأقسام',
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
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Semantics(
      label: 'يجب إضافة قسم قبل إضافة الدروس',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.info_circle,
              size: 18,
              color: AppColors.error,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'يجب إضافة قسم واحد على الأقل قبل إضافة الدروس',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopActions() {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: 'إضافة درس جديد',
            hint: 'اضغط لإضافة درس جديد',
            child: CupertinoButton(
              color: AppColors.primary,
              onPressed: _categories.isEmpty ? null : () => _showLessonDialog(),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.add, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'إضافة درس جديد',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Semantics(
          button: true,
          label: 'تحديث القائمة',
          hint: 'اضغط لتحديث قائمة الدروس',
          child: CupertinoButton(
            color: AppColors.surface,
            onPressed: _loadAll,
            child: Icon(
              CupertinoIcons.refresh,
              size: 20,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLessonsList() {
    return ListView.builder(
      itemCount: _lessons.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final item = _lessons[index];
        final id = item['id'] as int;
        final isFeatured = (item['is_featured'] as int?) == 1;
        final title = item['title_ar']?.toString() ?? '';
        final categoryName = item['category_name_ar']?.toString() ?? '';
        final disabilityName = item['target_disability_name']?.toString() ?? '';
        final lessonType = item['lesson_type']?.toString() ?? '';
        final difficulty = item['difficulty_level']?.toString() ?? '';
        final duration = item['duration_minutes'] ?? 0;
        final hasFile = (item['lesson_file']?.toString() ?? '').isNotEmpty;
        final status = item['status']?.toString() ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
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
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'القسم: $categoryName',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (disabilityName.isNotEmpty)
                        Text(
                          'الفئة: $disabilityName',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      Text(
                        'النوع: ${_lessonTypeText(lessonType)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'الصعوبة: ${_difficultyText(difficulty)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'المدة: $duration دقيقة',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (hasFile)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'يوجد ملف مرفق',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _statusText(status),
                              style: TextStyle(
                                color: _statusColor(status),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (isFeatured)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'مميز',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Semantics(
                      button: true,
                      label: 'تعديل درس $title',
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(40, 40),
                        onPressed: () => _showLessonDialog(lesson: item),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            CupertinoIcons.pencil,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      button: true,
                      label: 'حذف درس $title',
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(40, 40),
                        onPressed: () => _deleteLesson(id, title),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            CupertinoIcons.delete,
                            size: 18,
                            color: AppColors.error,
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
      },
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
            Icons.menu_book_outlined,
            size: 60,
            color: AppColors.textSecondary,
            semanticLabel: 'أيقونة لا توجد دروس',
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد دروس حتى الآن',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة درس جديد',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Semantics(
            button: true,
            label: 'إضافة درس جديد',
            child: CupertinoButton(
              color: AppColors.primary,
              onPressed: _categories.isEmpty ? null : () => _showLessonDialog(),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.add, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'إضافة درس جديد',
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