import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'saedny_db.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // ===================== جدول disability_types =====================
    await db.execute('''
      CREATE TABLE disability_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_ar TEXT NOT NULL,
        name_en TEXT,
        description TEXT,
        status TEXT DEFAULT 'active',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ===================== جدول users =====================
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        username TEXT UNIQUE,
        email TEXT UNIQUE NOT NULL,
        phone TEXT,
        password TEXT NOT NULL,
        role TEXT DEFAULT 'user',
        gender TEXT,
        birth_date TEXT,
        disability_type_id INTEGER,
        status TEXT DEFAULT 'active',
        profile_image TEXT,
        last_login_at TEXT,
        email_verified_at TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (disability_type_id) REFERENCES disability_types (id) ON DELETE SET NULL
      )
    ''');

    // ===================== جدول user_profiles =====================
    await db.execute('''
      CREATE TABLE user_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        address TEXT,
        city TEXT,
        country TEXT,
        education_level TEXT,
        bio TEXT,
        emergency_contact_name TEXT,
        emergency_contact_phone TEXT,
        guardian_name TEXT,
        guardian_phone TEXT,
        needs_assistant INTEGER DEFAULT 0,
        preferred_language TEXT DEFAULT 'ar',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // ===================== جدول categories =====================
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_ar TEXT NOT NULL,
        name_en TEXT,
        description TEXT,
        icon TEXT,
        status TEXT DEFAULT 'active',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ===================== جدول lessons =====================
    await db.execute('''
      CREATE TABLE lessons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        title_ar TEXT NOT NULL,
        title_en TEXT,
        short_description TEXT,
        content TEXT,
        lesson_type TEXT DEFAULT 'text',
        difficulty_level TEXT DEFAULT 'easy',
        target_disability_id INTEGER,
        thumbnail TEXT,
        lesson_file TEXT,
        lesson_file_type TEXT,
        duration_minutes INTEGER DEFAULT 0,
        is_featured INTEGER DEFAULT 0,
        status TEXT DEFAULT 'published',
        created_by INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE,
        FOREIGN KEY (target_disability_id) REFERENCES disability_types (id) ON DELETE SET NULL
      )
    ''');

    // ===================== جدول courses =====================
    await db.execute('''
      CREATE TABLE courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title_ar TEXT NOT NULL,
        title_en TEXT,
        description TEXT,
        course_type TEXT DEFAULT 'educational',
        target_disability_id INTEGER,
        image TEXT,
        duration_hours INTEGER DEFAULT 0,
        status TEXT DEFAULT 'published',
        created_by INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (target_disability_id) REFERENCES disability_types (id) ON DELETE SET NULL
      )
    ''');

    // ===================== جدول course_enrollments =====================
    await db.execute('''
      CREATE TABLE course_enrollments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        course_id INTEGER NOT NULL,
        status TEXT DEFAULT 'enrolled',
        progress_percent REAL DEFAULT 0,
        enrolled_at TEXT DEFAULT CURRENT_TIMESTAMP,
        completed_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE CASCADE,
        UNIQUE(user_id, course_id)
      )
    ''');

    // ===================== جدول course_lessons =====================
    await db.execute('''
      CREATE TABLE course_lessons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER NOT NULL,
        lesson_id INTEGER NOT NULL,
        sort_order INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE CASCADE,
        FOREIGN KEY (lesson_id) REFERENCES lessons (id) ON DELETE CASCADE,
        UNIQUE(course_id, lesson_id)
      )
    ''');

    // ===================== جدول lesson_progress =====================
    await db.execute('''
      CREATE TABLE lesson_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        lesson_id INTEGER NOT NULL,
        progress_percent REAL DEFAULT 0,
        is_completed INTEGER DEFAULT 0,
        completed_at TEXT,
        last_accessed_at TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (lesson_id) REFERENCES lessons (id) ON DELETE CASCADE,
        UNIQUE(user_id, lesson_id)
      )
    ''');

    // ===================== جدول favorite_lessons =====================
    await db.execute('''
      CREATE TABLE favorite_lessons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        lesson_id INTEGER NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (lesson_id) REFERENCES lessons (id) ON DELETE CASCADE,
        UNIQUE(user_id, lesson_id)
      )
    ''');

    // ===================== جدول lesson_ratings =====================
    await db.execute('''
      CREATE TABLE lesson_ratings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lesson_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        rating INTEGER NOT NULL,
        comment TEXT,
        status TEXT DEFAULT 'visible',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (lesson_id) REFERENCES lessons (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(lesson_id, user_id)
      )
    ''');

    // ===================== جدول lesson_resources =====================
    await db.execute('''
      CREATE TABLE lesson_resources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lesson_id INTEGER NOT NULL,
        resource_type TEXT NOT NULL,
        file_path TEXT,
        external_url TEXT,
        title TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (lesson_id) REFERENCES lessons (id) ON DELETE CASCADE
      )
    ''');

    // ===================== جدول companies =====================
    await db.execute('''
      CREATE TABLE companies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_name TEXT NOT NULL,
        email TEXT UNIQUE,
        phone TEXT,
        website TEXT,
        city TEXT,
        address TEXT,
        description TEXT,
        logo TEXT,
        status TEXT DEFAULT 'pending',
        created_by INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ===================== جدول jobs =====================
    await db.execute('''
      CREATE TABLE jobs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        requirements TEXT,
        location TEXT,
        employment_type TEXT DEFAULT 'full_time',
        salary_min REAL,
        salary_max REAL,
        target_disability_id INTEGER,
        is_active INTEGER DEFAULT 1,
        application_deadline TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (company_id) REFERENCES companies (id) ON DELETE CASCADE,
        FOREIGN KEY (target_disability_id) REFERENCES disability_types (id) ON DELETE SET NULL
      )
    ''');

    // ===================== جدول job_applications =====================
    await db.execute('''
      CREATE TABLE job_applications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        cover_letter TEXT,
        cv_file TEXT,
        status TEXT DEFAULT 'pending',
        applied_at TEXT DEFAULT CURRENT_TIMESTAMP,
        reviewed_at TEXT,
        notes TEXT,
        FOREIGN KEY (job_id) REFERENCES jobs (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(job_id, user_id)
      )
    ''');

    // ===================== جدول skills =====================
    await db.execute('''
      CREATE TABLE skills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_ar TEXT NOT NULL,
        name_en TEXT,
        description TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ===================== جدول user_skills =====================
    await db.execute('''
      CREATE TABLE user_skills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        skill_id INTEGER NOT NULL,
        level TEXT DEFAULT 'beginner',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (skill_id) REFERENCES skills (id) ON DELETE CASCADE,
        UNIQUE(user_id, skill_id)
      )
    ''');

    // ===================== جدول accessibility_settings =====================
    await db.execute('''
      CREATE TABLE accessibility_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        font_size TEXT DEFAULT 'medium',
        high_contrast INTEGER DEFAULT 0,
        text_to_speech INTEGER DEFAULT 0,
        voice_commands INTEGER DEFAULT 0,
        sign_language_support INTEGER DEFAULT 0,
        captions_enabled INTEGER DEFAULT 0,
        simplified_mode INTEGER DEFAULT 0,
        color_blind_mode INTEGER DEFAULT 0,
        preferred_input TEXT DEFAULT 'touch',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // ===================== جدول notifications =====================
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        notification_type TEXT DEFAULT 'system',
        is_read INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        read_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // ===================== جدول admin_activity_logs =====================
    await db.execute('''
      CREATE TABLE admin_activity_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        admin_id INTEGER NOT NULL,
        action TEXT NOT NULL,
        target_table TEXT,
        target_id INTEGER,
        details TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (admin_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // ===================== جدول feedback =====================
    await db.execute('''
      CREATE TABLE feedback (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        feedback_type TEXT DEFAULT 'app',
        reference_id INTEGER,
        rating INTEGER,
        comment TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL
      )
    ''');

    // ===================== جدول support_requests =====================
    await db.execute('''
      CREATE TABLE support_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        subject TEXT NOT NULL,
        message TEXT NOT NULL,
        request_type TEXT DEFAULT 'general',
        status TEXT DEFAULT 'open',
        admin_reply TEXT,
        replied_by INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        replied_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (replied_by) REFERENCES users (id) ON DELETE SET NULL
      )
    ''');

    await _insertInitialData(db);
  }

  Future<void> _insertInitialData(Database db) async {
    // إدراج أنواع الإعاقة
    final disabilities = [
      {'id': 1, 'name_ar': 'إعاقة بصرية', 'name_en': 'Visual Impairment', 'description': 'دعم قارئ الشاشة والنطق الصوتي والتكبير'},
      {'id': 2, 'name_ar': 'إعاقة سمعية', 'name_en': 'Hearing Impairment', 'description': 'دعم الترجمة النصية والإشعارات المرئية'},
      {'id': 3, 'name_ar': 'إعاقة حركية', 'name_en': 'Motor Disability', 'description': 'دعم الأوامر الصوتية والأزرار الكبيرة'},
      {'id': 4, 'name_ar': 'صعوبات تعلم', 'name_en': 'Learning Difficulties', 'description': 'محتوى مبسط وخطوات صغيرة'},
      {'id': 5, 'name_ar': 'إعاقة ذهنية بسيطة', 'name_en': 'Mild Intellectual Disability', 'description': 'واجهات مبسطة ومحتوى سهل'},
      {'id': 6, 'name_ar': 'متعدد', 'name_en': 'Multiple Disabilities', 'description': 'دعم أكثر من حالة حسب الإعدادات'},
    ];
    for (var d in disabilities) {
      await db.insert('disability_types', d, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // إدراج التصنيفات
    final categories = [
      {'id': 1, 'name_ar': 'التعليم', 'name_en': 'Education', 'description': 'دروس ومحتوى تعليمي مخصص', 'icon': 'school', 'status': 'active'},
      {'id': 2, 'name_ar': 'التدريب', 'name_en': 'Training', 'description': 'تدريب على المهارات الحياتية والوظيفية', 'icon': 'fitness_center', 'status': 'active'},
      {'id': 3, 'name_ar': 'التوظيف', 'name_en': 'Employment', 'description': 'الوظائف المناسبة وربط المستخدمين بالشركات', 'icon': 'work', 'status': 'active'},
      {'id': 4, 'name_ar': 'الدعم النفسي', 'name_en': 'Psychological Support', 'description': 'محتوى داعم وتحفيزي', 'icon': 'favorite', 'status': 'active'},
      {'id': 5, 'name_ar': 'الإرشاد الأسري', 'name_en': 'Family Guidance', 'description': 'مواد موجهة للأسر والمعلمين', 'icon': 'groups', 'status': 'active'},
    ];
    for (var c in categories) {
      await db.insert('categories', c, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // إدراج المهارات
    final skills = [
      {'id': 1, 'name_ar': 'استخدام الحاسوب', 'name_en': 'Computer Skills'},
      {'id': 2, 'name_ar': 'التواصل', 'name_en': 'Communication'},
      {'id': 3, 'name_ar': 'إدارة الوقت', 'name_en': 'Time Management'},
      {'id': 4, 'name_ar': 'العمل الجماعي', 'name_en': 'Teamwork'},
      {'id': 5, 'name_ar': 'خدمة العملاء', 'name_en': 'Customer Service'},
    ];
    for (var s in skills) {
      await db.insert('skills', s, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // إدراج الشركات
    await db.insert('companies', {
      'id': 1,
      'company_name': 'شركة الأمل للتوظيف الشامل',
      'email': 'hr@alamal.com',
      'phone': '777123456',
      'website': 'https://alamal.example.com',
      'city': 'صنعاء',
      'address': 'شارع حدة',
      'description': 'شركة داعمة لتوظيف ذوي الهمم',
      'status': 'approved',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // إدراج الوظائف
    await db.insert('jobs', {
      'id': 1,
      'company_id': 1,
      'title': 'مدخل بيانات',
      'description': 'فرصة عمل مناسبة للعمل المكتبي وإدخال البيانات',
      'requirements': 'معرفة أساسية بالحاسوب والدقة في العمل',
      'location': 'صنعاء',
      'employment_type': 'full_time',
      'salary_min': 300,
      'salary_max': 500,
      'target_disability_id': 3,
      'is_active': 1,
      'application_deadline': '2026-12-31',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    
    await db.insert('jobs', {
      'id': 2,
      'company_id': 1,
      'title': 'خدمة عملاء عن بعد',
      'description': 'فرصة عمل عن بعد في خدمة العملاء',
      'requirements': 'مهارات تواصل جيدة واستخدام الحاسوب',
      'location': 'عن بعد',
      'employment_type': 'remote',
      'salary_min': 250,
      'salary_max': 450,
      'target_disability_id': null,
      'is_active': 1,
      'application_deadline': '2026-12-31',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // إدراج الدروس
    await db.insert('lessons', {
      'id': 1,
      'category_id': 1,
      'title_ar': 'التعرف على الحروف',
      'title_en': 'Learning Letters',
      'short_description': 'درس مبسط لتعلم الحروف',
      'content': 'محتوى تعليمي تجريبي لتعلم الحروف بطريقة صوتية وبصرية.',
      'lesson_type': 'interactive',
      'difficulty_level': 'easy',
      'target_disability_id': 4,
      'duration_minutes': 15,
      'is_featured': 1,
      'status': 'published',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    
    await db.insert('lessons', {
      'id': 2,
      'category_id': 2,
      'title_ar': 'مهارات التواصل الأساسية',
      'title_en': 'Basic Communication Skills',
      'short_description': 'تدريب على مهارات التواصل',
      'content': 'محتوى تدريبي يساعد المستخدم على تطوير مهارات التواصل.',
      'lesson_type': 'video',
      'difficulty_level': 'easy',
      'target_disability_id': null,
      'duration_minutes': 20,
      'is_featured': 1,
      'status': 'published',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // إدراج الكورسات
    await db.insert('courses', {
      'id': 1,
      'title_ar': 'تأهيل مهني أساسي',
      'title_en': 'Basic Vocational Training',
      'description': 'برنامج تدريبي لإعداد المستخدمين لسوق العمل',
      'course_type': 'employment',
      'duration_hours': 12,
      'status': 'published',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    
    await db.insert('courses', {
      'id': 2,
      'title_ar': 'مهارات الحياة اليومية',
      'title_en': 'Daily Life Skills',
      'description': 'برنامج يساعد على الاستقلالية في الحياة اليومية',
      'course_type': 'life_skills',
      'duration_hours': 10,
      'status': 'published',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // إدراج المستخدمين
    await db.insert('users', {
      'id': 1,
      'full_name': 'مدير النظام',
      'username': 'admin',
      'email': 'admin@saedny.com',
      'phone': '777000111',
      'password': 'admin1234',
      'role': 'admin',
      'status': 'active',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    
    await db.insert('users', {
      'id': 2,
      'full_name': 'أحمد محمد',
      'username': 'ahmed',
      'email': 'ahmed@example.com',
      'phone': '777111222',
      'password': 'user1234',
      'role': 'user',
      'gender': 'male',
      'birth_date': '1990-01-01',
      'disability_type_id': 3,
      'status': 'active',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    
    await db.insert('users', {
      'id': 3,
      'full_name': 'فاطمة علي',
      'username': 'fatima',
      'email': 'fatima@example.com',
      'phone': '777333444',
      'password': 'user1234',
      'role': 'user',
      'gender': 'female',
      'birth_date': '1995-05-15',
      'disability_type_id': 2,
      'status': 'active',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // ===================== دوال مساعدة عامة =====================

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    data.removeWhere((key, value) => value == null);
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    required String where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    data.removeWhere((key, value) => value == null);
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    required String where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? args]) async {
    final db = await database;
    if (args != null && args.isNotEmpty) {
      return await db.rawQuery(sql, args);
    }
    return await db.rawQuery(sql);
  }

  // ===================== دوال المستخدمين =====================

  Future<Map<String, dynamic>?> getUserById(int userId) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim()],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> updateLastLogin(int userId) async {
    final db = await database;
    await db.update(
      'users',
      {'last_login_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<String?> getDisabilityTypeName(int? disabilityTypeId) async {
    if (disabilityTypeId == null) return null;
    final db = await database;
    final result = await db.query(
      'disability_types',
      where: 'id = ?',
      whereArgs: [disabilityTypeId],
    );
    return result.isNotEmpty ? result.first['name_ar'] as String? : null;
  }

  Future<Map<String, int>> getUserStats(int userId) async {
    final db = await database;

    final completed = await db.rawQuery(
      'SELECT COUNT(*) as count FROM lesson_progress WHERE user_id = ? AND is_completed = 1',
      [userId],
    );

    final favorites = await db.rawQuery(
      'SELECT COUNT(*) as count FROM favorite_lessons WHERE user_id = ?',
      [userId],
    );

    final applications = await db.rawQuery(
      'SELECT COUNT(*) as count FROM job_applications WHERE user_id = ?',
      [userId],
    );

    final started = await db.rawQuery(
      'SELECT COUNT(*) as count FROM lesson_progress WHERE user_id = ? AND progress_percent > 0 AND is_completed = 0',
      [userId],
    );

    return {
      'completed_lessons': (completed.first['count'] as int?) ?? 0,
      'started_lessons': (started.first['count'] as int?) ?? 0,
      'favorite_lessons': (favorites.first['count'] as int?) ?? 0,
      'job_applications': (applications.first['count'] as int?) ?? 0,
    };
  }

  // ===================== دوال الملف الشخصي =====================

  Future<Map<String, dynamic>?> getUserProfile(int userId) async {
    final db = await database;
    final result = await db.query(
      'user_profiles',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (result.isEmpty) {
      final now = DateTime.now().toIso8601String();
      await db.insert('user_profiles', {
        'user_id': userId,
        'preferred_language': 'ar',
        'needs_assistant': 0,
        'created_at': now,
        'updated_at': now,
      });
      return await getUserProfile(userId);
    }
    return result.first;
  }

  // ===================== دوال التصنيفات =====================

  Future<List<Map<String, dynamic>>> getActiveCategories() async {
    final db = await database;
    return await db.query(
      'categories',
      where: 'status = ?',
      whereArgs: ['active'],
      orderBy: 'id ASC',
    );
  }

  // ===================== دوال الدروس =====================

  Future<List<Map<String, dynamic>>> getFeaturedLessons(int userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        l.*,
        cat.name_ar as category_name,
        COALESCE(lp.progress_percent, 0) as progress_percent,
        COALESCE(lp.is_completed, 0) as is_completed,
        (
          SELECT COUNT(*) 
          FROM favorite_lessons 
          WHERE user_id = ? AND lesson_id = l.id
        ) as is_favorite,
        COALESCE((
          SELECT AVG(rating) 
          FROM lesson_ratings 
          WHERE lesson_id = l.id
        ), 0) as average_rating,
        COALESCE((
          SELECT COUNT(*) 
          FROM lesson_ratings 
          WHERE lesson_id = l.id
        ), 0) as ratings_count,
        COALESCE((
          SELECT rating 
          FROM lesson_ratings 
          WHERE user_id = ? AND lesson_id = l.id
        ), 0) as user_rating
      FROM lessons l
      LEFT JOIN lesson_progress lp ON l.id = lp.lesson_id AND lp.user_id = ?
      LEFT JOIN categories cat ON l.category_id = cat.id
      WHERE l.status = 'published' AND l.is_featured = 1
      GROUP BY l.id
      ORDER BY l.created_at DESC
      LIMIT 6
    ''', [userId, userId, userId]);
  }

  Future<List<Map<String, dynamic>>> getLessonsByCategory(int userId, int categoryId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        l.*,
        cat.name_ar as category_name,
        COALESCE(lp.progress_percent, 0) as progress_percent,
        COALESCE(lp.is_completed, 0) as is_completed,
        (
          SELECT COUNT(*) 
          FROM favorite_lessons 
          WHERE user_id = ? AND lesson_id = l.id
        ) as is_favorite,
        COALESCE((
          SELECT AVG(rating) 
          FROM lesson_ratings 
          WHERE lesson_id = l.id
        ), 0) as average_rating,
        COALESCE((
          SELECT COUNT(*) 
          FROM lesson_ratings 
          WHERE lesson_id = l.id
        ), 0) as ratings_count,
        COALESCE((
          SELECT rating 
          FROM lesson_ratings 
          WHERE user_id = ? AND lesson_id = l.id
        ), 0) as user_rating
      FROM lessons l
      LEFT JOIN lesson_progress lp ON l.id = lp.lesson_id AND lp.user_id = ?
      LEFT JOIN categories cat ON l.category_id = cat.id
      WHERE l.category_id = ? AND l.status = 'published'
      GROUP BY l.id
      ORDER BY l.created_at DESC
    ''', [userId, userId, userId, categoryId]);
  }

  Future<Map<String, dynamic>?> getLessonDetails(int lessonId, int userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        l.*,
        cat.name_ar as category_name,
        COALESCE(lp.progress_percent, 0) as progress_percent,
        COALESCE(lp.is_completed, 0) as is_completed,
        (
          SELECT COUNT(*) 
          FROM favorite_lessons 
          WHERE user_id = ? AND lesson_id = l.id
        ) as is_favorite,
        COALESCE((
          SELECT AVG(rating) 
          FROM lesson_ratings 
          WHERE lesson_id = l.id
        ), 0) as average_rating,
        COALESCE((
          SELECT COUNT(*) 
          FROM lesson_ratings 
          WHERE lesson_id = l.id
        ), 0) as ratings_count,
        COALESCE((
          SELECT rating 
          FROM lesson_ratings 
          WHERE user_id = ? AND lesson_id = l.id
        ), 0) as user_rating
      FROM lessons l
      LEFT JOIN lesson_progress lp ON l.id = lp.lesson_id AND lp.user_id = ?
      LEFT JOIN categories cat ON l.category_id = cat.id
      WHERE l.id = ? AND l.status = 'published'
      GROUP BY l.id
    ''', [userId, userId, userId, lessonId]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getLessonResources(int lessonId) async {
    final db = await database;
    return await db.query(
      'lesson_resources',
      where: 'lesson_id = ?',
      whereArgs: [lessonId],
    );
  }

  Future<void> toggleFavorite(int userId, int lessonId) async {
    final db = await database;
    final existing = await db.query(
      'favorite_lessons',
      where: 'user_id = ? AND lesson_id = ?',
      whereArgs: [userId, lessonId],
    );
    
    if (existing.isNotEmpty) {
      await db.delete(
        'favorite_lessons',
        where: 'user_id = ? AND lesson_id = ?',
        whereArgs: [userId, lessonId],
      );
    } else {
      await db.insert('favorite_lessons', {
        'user_id': userId,
        'lesson_id': lessonId,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> updateLessonProgress(int userId, int lessonId, int progressPercent, {bool isCompleted = false}) async {
    final db = await database;
    final existing = await db.query(
      'lesson_progress',
      where: 'user_id = ? AND lesson_id = ?',
      whereArgs: [userId, lessonId],
    );
    
    final now = DateTime.now().toIso8601String();
    
    if (existing.isNotEmpty) {
      await db.update(
        'lesson_progress',
        {
          'progress_percent': progressPercent,
          'is_completed': isCompleted ? 1 : 0,
          'completed_at': isCompleted ? now : null,
          'last_accessed_at': now,
          'updated_at': now,
        },
        where: 'user_id = ? AND lesson_id = ?',
        whereArgs: [userId, lessonId],
      );
    } else {
      await db.insert('lesson_progress', {
        'user_id': userId,
        'lesson_id': lessonId,
        'progress_percent': progressPercent,
        'is_completed': isCompleted ? 1 : 0,
        'completed_at': isCompleted ? now : null,
        'last_accessed_at': now,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  Future<void> addOrUpdateRating(int userId, int lessonId, int rating, {String? comment}) async {
    final db = await database;
    final existing = await db.query(
      'lesson_ratings',
      where: 'user_id = ? AND lesson_id = ?',
      whereArgs: [userId, lessonId],
    );
    
    final now = DateTime.now().toIso8601String();
    
    if (existing.isNotEmpty) {
      await db.update(
        'lesson_ratings',
        {
          'rating': rating,
          'comment': comment,
          'created_at': now,
        },
        where: 'user_id = ? AND lesson_id = ?',
        whereArgs: [userId, lessonId],
      );
    } else {
      await db.insert('lesson_ratings', {
        'user_id': userId,
        'lesson_id': lessonId,
        'rating': rating,
        'comment': comment,
        'status': 'visible',
        'created_at': now,
      });
    }
  }

  // ===================== دوال الوظائف =====================

  Future<List<Map<String, dynamic>>> getAllActiveJobs() async {
    final db = await database;
    return await db.query(
      'jobs',
      where: 'is_active = 1',
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getJobDetails(int jobId) async {
    final db = await database;
    final result = await db.query(
      'jobs',
      where: 'id = ? AND is_active = 1',
      whereArgs: [jobId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getCompanyById(int companyId) async {
    final db = await database;
    final result = await db.query(
      'companies',
      where: 'id = ?',
      whereArgs: [companyId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> hasUserAppliedForJob(int userId, int jobId) async {
    final db = await database;
    final result = await db.query(
      'job_applications',
      where: 'user_id = ? AND job_id = ?',
      whereArgs: [userId, jobId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getRecommendedJobs(int userId, int? disabilityId) async {
    final db = await database;
    String query = '''
      SELECT j.*, c.company_name, c.logo as company_logo
      FROM jobs j
      JOIN companies c ON j.company_id = c.id
      WHERE j.is_active = 1
    ''';
    
    final List<dynamic> args = [];
    
    if (disabilityId != null) {
      query += ' AND (j.target_disability_id = ? OR j.target_disability_id IS NULL)';
      args.add(disabilityId);
    }
    
    query += ' ORDER BY j.created_at DESC LIMIT 6';
    
    return await db.rawQuery(query, args);
  }

  // ===================== دوال الكورسات =====================

  Future<List<Map<String, dynamic>>> getActiveCourses() async {
    final db = await database;
    return await db.query(
      'courses',
      where: 'status = ?',
      whereArgs: ['published'],
      orderBy: 'id ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getCourseById(int courseId) async {
    final db = await database;
    return await db.query(
      'courses',
      where: 'id = ?',
      whereArgs: [courseId],
    );
  }

  Future<bool> isUserEnrolledInCourse(int userId, int courseId) async {
    final db = await database;
    final result = await db.query(
      'course_enrollments',
      where: 'user_id = ? AND course_id = ?',
      whereArgs: [userId, courseId],
    );
    return result.isNotEmpty;
  }

  Future<void> enrollUserInCourse(int userId, int courseId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.insert('course_enrollments', {
      'user_id': userId,
      'course_id': courseId,
      'status': 'enrolled',
      'enrolled_at': now,
    });
  }

  // ===================== دوال إعدادات الوصول =====================

  Future<Map<String, dynamic>?> getAccessibilitySettings(int userId) async {
    final db = await database;
    final result = await db.query(
      'accessibility_settings',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (result.isEmpty) {
      final now = DateTime.now().toIso8601String();
      await db.insert('accessibility_settings', {
        'user_id': userId,
        'font_size': 'medium',
        'high_contrast': 0,
        'text_to_speech': 0,
        'simplified_mode': 0,
        'preferred_input': 'touch',
        'created_at': now,
        'updated_at': now,
      });
      return await getAccessibilitySettings(userId);
    }
    return result.first;
  }

  // ===================== دوال إضافية =====================

  Future<List<Map<String, dynamic>>> getUserFavoriteLessons(int userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT l.*, cat.name_ar as category_name
      FROM favorite_lessons fl
      JOIN lessons l ON fl.lesson_id = l.id
      LEFT JOIN categories cat ON l.category_id = cat.id
      WHERE fl.user_id = ?
      ORDER BY fl.created_at DESC
    ''', [userId]);
  }

  Future<List<Map<String, dynamic>>> getUserJobApplications(int userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        ja.*, 
        j.title, 
        j.location, 
        j.employment_type, 
        c.company_name
      FROM job_applications ja
      JOIN jobs j ON ja.job_id = j.id
      JOIN companies c ON j.company_id = c.id
      WHERE ja.user_id = ?
      ORDER BY ja.applied_at DESC
    ''', [userId]);
  }

  Future<List<Map<String, dynamic>>> getUserEnrolledCourses(int userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT c.*, ce.status, ce.progress_percent, ce.enrolled_at, ce.completed_at
      FROM course_enrollments ce
      JOIN courses c ON ce.course_id = c.id
      WHERE ce.user_id = ?
      ORDER BY ce.enrolled_at DESC
    ''', [userId]);
  }

  Future<int> getCount(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    final result = await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      columns: ['COUNT(*) as count'],
    );
    return result.isNotEmpty ? (result.first['count'] as int) : 0;
  }

  Future<void> clearLoggedInUser() async {
    // لا حاجة للتنفيذ
  }
}