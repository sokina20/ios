import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Colors;
import 'package:flutter/rendering.dart';
import 'package:saedny/core/theme/app_colors.dart';
import '../../../../../database/database_helper.dart';
import '../../../../../models/update_accessibility_request_model.dart';

class AccessibilitySettingsScreen extends StatefulWidget {
  final int userId;
  final String currentFontSize;
  final bool currentHighContrast;
  final bool currentSimplifiedMode;
  final String currentPreferredInput;

  const AccessibilitySettingsScreen({
    super.key,
    required this.userId,
    required this.currentFontSize,
    required this.currentHighContrast,
    required this.currentSimplifiedMode,
    required this.currentPreferredInput,
  });

  @override
  State<AccessibilitySettingsScreen> createState() =>
      _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState
    extends State<AccessibilitySettingsScreen> {
  bool _isLoading = false;

  late String _fontSize;
  late bool _highContrast;
  late bool _simplifiedMode;
  late String _preferredInput;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.currentFontSize;
    _highContrast = widget.currentHighContrast;
    _simplifiedMode = widget.currentSimplifiedMode;
    _preferredInput = widget.currentPreferredInput;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        'إعدادات الوصول والتسهيلات',
        Directionality.of(context),
      );
    });
  }

  String _getFontSizeText(String value) {
    switch (value) {
      case 'small':
        return 'صغير';
      case 'medium':
        return 'متوسط';
      case 'large':
        return 'كبير';
      case 'xlarge':
        return 'كبير جداً';
      default:
        return 'متوسط';
    }
  }

  double _getFontSizeValue(String value) {
    switch (value) {
      case 'small':
        return 14;
      case 'medium':
        return 16;
      case 'large':
        return 20;
      case 'xlarge':
        return 24;
      default:
        return 16;
    }
  }

  String _getPreferredInputText(String value) {
    switch (value) {
      case 'touch':
        return 'اللمس';
      case 'voice':
        return 'الصوت';
      case 'keyboard':
        return 'لوحة المفاتيح';
      default:
        return 'اللمس';
    }
  }

  Future<void> _saveSettings() async {
    try {
      setState(() => _isLoading = true);

      SemanticsService.announce(
        'جاري حفظ إعدادات الوصول',
        Directionality.of(context),
      );

      final request = UpdateAccessibilityRequestModel(
        userId: widget.userId,
        fontSize: _fontSize,
        highContrast: _highContrast,
        textToSpeech: false,
        simplifiedMode: _simplifiedMode,
        preferredInput: _preferredInput,
      );

      final dbHelper = DatabaseHelper();
      
      final existingSettings = await dbHelper.query(
        'accessibility_settings',
        where: 'user_id = ?',
        whereArgs: [widget.userId],
      );
      
      final now = DateTime.now().toIso8601String();
      
      if (existingSettings.isNotEmpty) {
        await dbHelper.update(
          'accessibility_settings',
          {
            'font_size': request.fontSize,
            'high_contrast': request.highContrast ? 1 : 0,
            'simplified_mode': request.simplifiedMode ? 1 : 0,
            'preferred_input': request.preferredInput,
            'updated_at': now,
          },
          where: 'user_id = ?',
          whereArgs: [widget.userId],
        );
      } else {
        await dbHelper.insert('accessibility_settings', {
          'user_id': request.userId,
          'font_size': request.fontSize,
          'high_contrast': request.highContrast ? 1 : 0,
          'simplified_mode': request.simplifiedMode ? 1 : 0,
          'preferred_input': request.preferredInput,
          'created_at': now,
          'updated_at': now,
        });
      }

      if (!mounted) return;
      
      SemanticsService.announce(
        'تم حفظ إعدادات الوصول بنجاح',
        Directionality.of(context),
      );
      
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('حدث خطأ: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('تم الحفظ'),
        content: const Text('تم حفظ إعدادات الوصول بنجاح'),
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

  void _showFontSizePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('اختر حجم الخط'),
        message: const Text('اختر الحجم المناسب لقراءة أسهل'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _fontSize = 'small');
              Navigator.pop(context);
              SemanticsService.announce('تم اختيار حجم خط صغير', Directionality.of(context));
            },
            child: const Text('صغير'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _fontSize = 'medium');
              Navigator.pop(context);
              SemanticsService.announce('تم اختيار حجم خط متوسط', Directionality.of(context));
            },
            child: const Text('متوسط'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _fontSize = 'large');
              Navigator.pop(context);
              SemanticsService.announce('تم اختيار حجم خط كبير', Directionality.of(context));
            },
            child: const Text('كبير'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _fontSize = 'xlarge');
              Navigator.pop(context);
              SemanticsService.announce('تم اختيار حجم خط كبير جداً', Directionality.of(context));
            },
            child: const Text('كبير جداً'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
      ),
    );
  }

  void _showPreferredInputPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('طريقة الإدخال المفضلة'),
        message: const Text('اختر الطريقة التي تفضلها للتفاعل مع التطبيق'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _preferredInput = 'touch');
              Navigator.pop(context);
              SemanticsService.announce('تم اختيار طريقة الإدخال باللمس', Directionality.of(context));
            },
            child: const Text('اللمس'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _preferredInput = 'voice');
              Navigator.pop(context);
              SemanticsService.announce('تم اختيار طريقة الإدخال بالصوت', Directionality.of(context));
            },
            child: const Text('الصوت'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _preferredInput = 'keyboard');
              Navigator.pop(context);
              SemanticsService.announce('تم اختيار طريقة الإدخال بلوحة المفاتيح', Directionality.of(context));
            },
            child: const Text('لوحة المفاتيح'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
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
          label: 'إعدادات الوصول والتسهيلات',
          child: const Text(
            'إعدادات الوصول',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        backgroundColor: AppColors.surface,
      ),
      child: CupertinoScrollbar(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Semantics(
                    label: 'معاينة حجم الخط',
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                            'معاينة النص',
                            style: TextStyle(
                              fontSize: _getFontSizeValue(_fontSize) - 2,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'هذا نموذج للنص بحجم الخط المختار',
                            style: TextStyle(
                              fontSize: _getFontSizeValue(_fontSize),
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Semantics(
                    label: 'حجم الخط الحالي: ${_getFontSizeText(_fontSize)}',
                    hint: 'اضغط مرتين لتغيير حجم الخط',
                    button: true,
                    child: GestureDetector(
                      onTap: _showFontSizePicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.border,
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.textformat_size,
                                  size: 22,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'حجم الخط',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'اختر الحجم المناسب للقراءة',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  _getFontSizeText(_fontSize),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  CupertinoIcons.chevron_forward,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Semantics(
                    label: 'وضع التباين العالي',
                    hint: _highContrast ? 'مفعل حالياً، اضغط مرتين لإلغاء التفعيل' : 'غير مفعل، اضغط مرتين للتفعيل',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.border,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.contrast,
                                size: 22,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'تباين عالٍ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'زيادة التباين بين الألوان لتسهيل القراءة',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          CupertinoSwitch(
                            value: _highContrast,
                            activeColor: AppColors.primary,
                            onChanged: (value) {
                              setState(() => _highContrast = value);
                              SemanticsService.announce(
                                value ? 'تم تفعيل وضع التباين العالي' : 'تم إلغاء وضع التباين العالي',
                                Directionality.of(context),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Semantics(
                    label: 'الوضع المبسط',
                    hint: _simplifiedMode ? 'مفعل حالياً، اضغط مرتين لإلغاء التفعيل' : 'غير مفعل، اضغط مرتين للتفعيل',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.border,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.clean_hands,
                                size: 22,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'الوضع المبسط',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'إزالة العناصر غير الأساسية وتبسيط الواجهة',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          CupertinoSwitch(
                            value: _simplifiedMode,
                            activeColor: AppColors.primary,
                            onChanged: (value) {
                              setState(() => _simplifiedMode = value);
                              SemanticsService.announce(
                                value ? 'تم تفعيل الوضع المبسط' : 'تم إلغاء الوضع المبسط',
                                Directionality.of(context),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Semantics(
                    label: 'طريقة الإدخال المفضلة: ${_getPreferredInputText(_preferredInput)}',
                    hint: 'اضغط مرتين لتغيير طريقة الإدخال',
                    button: true,
                    child: GestureDetector(
                      onTap: _showPreferredInputPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.border,
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.touch_app,
                                  size: 22,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'طريقة الإدخال المفضلة',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'اختر الطريقة التي تفضلها للتفاعل',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  _getPreferredInputText(_preferredInput),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  CupertinoIcons.chevron_forward,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Semantics(
                    button: true,
                    label: _isLoading ? 'جارٍ حفظ الإعدادات' : 'زر حفظ إعدادات الوصول',
                    hint: 'اضغط مرتين لحفظ التغييرات',
                    child: SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: AppColors.primary,
                        onPressed: _isLoading ? null : _saveSettings,
                        child: _isLoading
                            ? const CupertinoActivityIndicator(
                                color: CupertinoColors.white,
                              )
                            : const Text(
                                'حفظ الإعدادات',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Semantics(
                    label: 'يمكنك تغيير هذه الإعدادات في أي وقت',
                    child: Text(
                      'يمكنك تغيير هذه الإعدادات في أي وقت',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
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
    );
  }
}