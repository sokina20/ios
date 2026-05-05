import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

class AppValidators {
  // 📞 أرقام السعودية: 05xxxxxxxx (11 رقم) أو 5xxxxxxxx (10 أرقام)
  static final RegExp _saudiPhoneRegex = RegExp(
    r'^(05|5)?[0-9]{8}$',
  );
  
  // ✅ صيغة رقم الجوال السعودي مع مفتاح الدوله
  static final RegExp _saudiPhoneWithCountryRegex = RegExp(
    r'^(\+966|00966)?(05|5)[0-9]{8}$',
  );
  
  // 📧 صيغة البريد الإلكتروني
  static final RegExp _emailRegex = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  );
  
  // 🆔 رقم الهوية الوطنية (10 أرقام)
  static final RegExp _nationalIdRegex = RegExp(
    r'^[12][0-9]{9}$',
  );
  
  // 🏢 رقم السجل التجاري (10 أرقام)
  static final RegExp _commercialRegisterRegex = RegExp(
    r'^[0-9]{10}$',
  );

  // ==================== التحقق من الحقول المطلوبة ====================

  /// التحقق من حقل مطلوب مع رسالة مخصصة
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName مطلوب';
    }
    return null;
  }

  // ==================== التحقق من الاسم ====================

  /// التحقق من الاسم (يدعم الأسماء العربية والإنجليزية)
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الاسم مطلوب';
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length < 2) {
      return 'الاسم قصير جداً (يجب أن يكون حرفين على الأقل)';
    }
    
    if (trimmed.length > 100) {
      return 'الاسم طويل جداً (حد أقصى 100 حرف)';
    }
    
    // التحقق من وجود أحرف صالحة (عربية، إنجليزية، مسافات)
    final validNameRegex = RegExp(r'^[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FFa-zA-Z\s]+$');
    if (!validNameRegex.hasMatch(trimmed)) {
      return 'الاسم يجب أن يحتوي على أحرف فقط (بدون رموز أو أرقام)';
    }
    
    return null;
  }

  // ==================== التحقق من البريد الإلكتروني ====================

  /// التحقق من صحة البريد الإلكتروني
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }

    final email = value.trim();
    
    if (!_emailRegex.hasMatch(email)) {
      return 'صيغة البريد الإلكتروني غير صحيحة (مثال: name@example.com)';
    }
    
    return null;
  }

  // ==================== التحقق من رقم الجوال السعودي ====================

  /// التحقق من رقم الجوال السعودي (إجباري)
  static String? validateSaudiPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'رقم الجوال مطلوب';
    }

    final phone = _cleanPhoneNumber(value.trim());
    
    if (!_saudiPhoneRegex.hasMatch(phone)) {
      return 'رقم الجوال غير صحيح (يجب أن يبدأ بـ 05 ويتكون من 10 أرقام)';
    }
    
    return null;
  }

  /// التحقق من رقم الجوال السعودي (اختياري)
  static String? validateOptionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final phone = _cleanPhoneNumber(value.trim());
    
    if (!_saudiPhoneRegex.hasMatch(phone)) {
      return 'رقم الجوال غير صحيح (يجب أن يبدأ بـ 05 ويتكون من 10 أرقام)';
    }
    
    return null;
  }

  /// تنظيف رقم الجوال (إزالة المسافات والشرطات والعلامات)
  static String _cleanPhoneNumber(String phone) {
    return phone
        .replaceAll(RegExp(r'[\s\-\(\)\+]'), '')  // إزالة المسافات والشرطات والأقواس
        .replaceAll(RegExp(r'^\+966'), '0')       // تحويل +966 إلى 0
        .replaceAll(RegExp(r'^00966'), '0');      // تحويل 00966 إلى 0
  }

  /// تنسيق رقم الجوال للعرض (05xxxxxxxx)
  static String formatSaudiPhone(String phone) {
    final cleaned = _cleanPhoneNumber(phone);
    if (cleaned.length == 10 && cleaned.startsWith('05')) {
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 7)} ${cleaned.substring(7)}';
    }
    return phone;
  }

  // ==================== التحقق من رقم الهوية الوطنية ====================

  /// التحقق من رقم الهوية الوطنية (10 أرقام)
  static String? validateNationalId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'رقم الهوية مطلوب';
    }

    final id = value.trim().replaceAll(RegExp(r'\s'), '');
    
    if (!_nationalIdRegex.hasMatch(id)) {
      return 'رقم الهوية غير صحيح (10 أرقام، يبدأ بـ 1 أو 2)';
    }
    
    // التحقق من صحة رقم الهوية باستخدام خوارزمية (اختياري)
    if (!_validateNationalIdChecksum(id)) {
      return 'رقم الهوية غير صالح';
    }
    
    return null;
  }

  /// التحقق من صحة رقم الهوية باستخدام خوارزمية checksum
  static bool _validateNationalIdChecksum(String id) {
    if (id.length != 10) return false;
    
    int sum = 0;
    for (int i = 0; i < 10; i++) {
      int digit = int.parse(id[i]);
      int weight = (i % 2 == 0) ? 1 : 2;
      int contribution = digit * weight;
      sum += (contribution > 9) ? contribution - 9 : contribution;
    }
    return sum % 10 == 0;
  }

  // ==================== التحقق من كلمة المرور ====================

  /// التحقق من قوة كلمة المرور
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    
    if (value.length > 50) {
      return 'كلمة المرور طويلة جداً (حد أقصى 50 حرف)';
    }
    
    return null;
  }

  /// التحقق من قوة كلمة المرور (متطلبات إضافية)
  static String? validateStrongPassword(String? value) {
    final baseValidation = validatePassword(value);
    if (baseValidation != null) return baseValidation;
    
    final password = value!;
    bool hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowerCase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    if (!hasUpperCase || !hasLowerCase) {
      return 'كلمة المرور يجب أن تحتوي على حروف كبيرة وصغيرة';
    }
    
    if (!hasDigits) {
      return 'كلمة المرور يجب أن تحتوي على رقم واحد على الأقل';
    }
    
    if (!hasSpecialChars) {
      // ✅ تصحيح: تجنب الأحرف الخاصة التي تسبب مشكلة
      return 'يُفضل استخدام رموز خاصة مثل (!@#\$%^&*)';
    }
    
    return null;
  }

  /// التحقق من تطابق كلمة المرور
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'تأكيد كلمة المرور مطلوب';
    }
    
    if (value != password) {
      return 'كلمة المرور وتأكيدها غير متطابقتين';
    }
    
    return null;
  }

  // ==================== التحقق من وظائف ====================

  /// التحقق من رسالة التقديم أو ملف CV
  static String? validateJobCoverLetterOrCv(String? coverLetter, String? cvFile) {
    final hasCoverLetter = coverLetter != null && coverLetter.trim().isNotEmpty;
    final hasCv = cvFile != null && cvFile.trim().isNotEmpty;

    if (!hasCoverLetter && !hasCv) {
      return 'يجب إدخال رسالة تقديم أو اختيار ملف CV';
    }

    if (hasCoverLetter && coverLetter!.trim().length < 10) {
      return 'رسالة التقديم قصيرة جداً (10 أحرف على الأقل)';
    }
    
    if (hasCoverLetter && coverLetter.trim().length > 1000) {
      return 'رسالة التقديم طويلة جداً (حد أقصى 1000 حرف)';
    }

    return null;
  }

  // ==================== التحقق من الملف الشخصي ====================

  /// التحقق من الاسم في الملف الشخصي
  static String? validateProfileName(String? value) {
    return validateName(value);
  }

  /// التحقق من السيرة الذاتية النصية
  static String? validateBio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // اختياري
    }
    
    if (value.trim().length > 500) {
      return 'السيرة الذاتية طويلة جداً (حد أقصى 500 حرف)';
    }
    
    return null;
  }

  // ==================== Accessibility ====================

  /// إعلان خطأ VoiceOver لمستخدمي Accessibility
  static void announceError(BuildContext context, String message) {
    SemanticsService.announce(
      message,
      Directionality.of(context),
    );
  }
}

// ==================== Extension لإضافة التحقق بسهولة ====================

extension ValidatorExtension on String? {
  /// التحقق من أن القيمة غير فارغة
  String? get required => AppValidators.validateRequired(this, 'هذا الحقل');
  
  /// التحقق من صحة الاسم
  String? get validName => AppValidators.validateName(this);
  
  /// التحقق من صحة البريد الإلكتروني
  String? get validEmail => AppValidators.validateEmail(this);
  
  /// التحقق من صحة رقم الجوال السعودي
  String? get validSaudiPhone => AppValidators.validateSaudiPhone(this);
  
  /// التحقق من صحة رقم الهوية
  String? get validNationalId => AppValidators.validateNationalId(this);
  
  /// التحقق من صحة كلمة المرور
  String? get validPassword => AppValidators.validatePassword(this);
  
  /// التحقق من قوة كلمة المرور
  String? get validStrongPassword => AppValidators.validateStrongPassword(this);
}