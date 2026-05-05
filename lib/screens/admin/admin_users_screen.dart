import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Colors;
import 'package:flutter/rendering.dart';
import 'package:saedny/core/theme/app_colors.dart';
import '../../database/database_helper.dart';
import 'widgets/admin_menu_sheet.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  List<Map<String, dynamic>> _disabilities = [];

  final TextEditingController _searchController = TextEditingController();

  final int _adminId = 1;
  final String _adminName = 'مدير النظام';
  final String _adminEmail = 'admin@saedny.com';

  @override
  void initState() {
    super.initState();
    _loadAll();
    _searchController.addListener(_filterUsers);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        'لوحة تحكم المدير - إدارة المستخدمين',
        Directionality.of(context),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);

    try {
      final dbHelper = DatabaseHelper();

      final users = await dbHelper.rawQuery('''
        SELECT 
          u.*,
          dt.name_ar as disability_name
        FROM users u
        LEFT JOIN disability_types dt ON u.disability_type_id = dt.id
        ORDER BY u.created_at DESC
      ''');

      final disabilities = await dbHelper.query(
        'disability_types',
        where: 'status = ?',
        whereArgs: ['active'],
        orderBy: 'name_ar ASC',
      );

      if (!mounted) return;

      SemanticsService.announce(
        'تم تحميل ${users.length} مستخدم',
        Directionality.of(context),
      );

      setState(() {
        _users = users;
        _filteredUsers = users;
        _disabilities = disabilities;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorMessage('حدث خطأ: ${e.toString()}');
    }
  }

  void _filterUsers() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() => _filteredUsers = _users);
      return;
    }

    final filtered = _users.where((user) {
      final name = (user['full_name'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final phone = (user['phone'] ?? '').toString().toLowerCase();
      final role = (user['role'] ?? '').toString().toLowerCase();
      final disability = (user['disability_name'] ?? '')
          .toString()
          .toLowerCase();

      return name.contains(query) ||
          email.contains(query) ||
          phone.contains(query) ||
          role.contains(query) ||
          disability.contains(query);
    }).toList();

    setState(() => _filteredUsers = filtered);

    SemanticsService.announce(
      'تم العثور على ${filtered.length} مستخدم',
      Directionality.of(context),
    );
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

  Future<void> _updateUserStatus(int userId, String newStatus) async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.update(
        'users',
        {'status': newStatus},
        where: 'id = ?',
        whereArgs: [userId],
      );
      _showSuccessMessage('تم تحديث حالة المستخدم بنجاح');
      await _loadAll();
    } catch (e) {
      _showErrorMessage('حدث خطأ: ${e.toString()}');
    }
  }

  Future<void> _updateUserRole(int userId, String newRole) async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.update(
        'users',
        {'role': newRole},
        where: 'id = ?',
        whereArgs: [userId],
      );
      _showSuccessMessage('تم تحديث دور المستخدم بنجاح');
      await _loadAll();
    } catch (e) {
      _showErrorMessage('حدث خطأ: ${e.toString()}');
    }
  }

  Future<void> _updateUserDisability(int userId, int? disabilityId) async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.update(
        'users',
        {'disability_type_id': disabilityId},
        where: 'id = ?',
        whereArgs: [userId],
      );
      _showSuccessMessage('تم تحديث نوع الإعاقة بنجاح');
      await _loadAll();
    } catch (e) {
      _showErrorMessage('حدث خطأ: ${e.toString()}');
    }
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
                SemanticsService.announce(
                  'تم اختيار ${items[i]}',
                  Directionality.of(context),
                );
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

  Future<void> _showChangeStatusDialog(Map<String, dynamic> user) async {
    final userId = user['id'] as int;
    String selectedStatus = (user['status'] ?? 'active').toString();

    await showCupertinoDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: CupertinoAlertDialog(
              title: const Text('تغيير حالة المستخدم'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusPicker(
                    value: selectedStatus,
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedStatus = value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                CupertinoDialogAction(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateUserStatus(userId, selectedStatus);
                  },
                  child: const Text('حفظ'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusPicker({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    final statusMap = {
      'active': 'نشط',
      'inactive': 'غير نشط',
      'suspended': 'موقوف',
    };

    return GestureDetector(
      onTap: () {
        _showPicker<String?>(
          title: 'اختر الحالة',
          items: ['نشط', 'غير نشط', 'موقوف'],
          values: ['active', 'inactive', 'suspended'],
          currentValue: value,
          onChanged: onChanged,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.5),
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
                  statusMap[value] ?? value,
                  style: TextStyle(fontSize: 14, color: _statusColor(value)),
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

  Future<void> _showChangeRoleDialog(Map<String, dynamic> user) async {
    final userId = user['id'] as int;
    String selectedRole = (user['role'] ?? 'user').toString();

    await showCupertinoDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: CupertinoAlertDialog(
              title: const Text('تغيير دور المستخدم'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRolePicker(
                    value: selectedRole,
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedRole = value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                CupertinoDialogAction(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateUserRole(userId, selectedRole);
                  },
                  child: const Text('حفظ'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRolePicker({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    final roleMap = {
      'user': 'مستخدم',
      'admin': 'أدمن',
      'company': 'شركة',
      'parent': 'ولي أمر',
      'teacher': 'معلم',
    };

    return GestureDetector(
      onTap: () {
        _showPicker<String?>(
          title: 'اختر الدور',
          items: ['مستخدم', 'أدمن', 'شركة', 'ولي أمر', 'معلم'],
          values: ['user', 'admin', 'company', 'parent', 'teacher'],
          currentValue: value,
          onChanged: onChanged,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الدور',
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
                    color: _roleColor(value),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  roleMap[value] ?? value,
                  style: TextStyle(fontSize: 14, color: _roleColor(value)),
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

  Future<void> _showChangeDisabilityDialog(Map<String, dynamic> user) async {
    final userId = user['id'] as int;
    int? selectedDisabilityId = user['disability_type_id'] as int?;

    await showCupertinoDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: CupertinoAlertDialog(
              title: const Text('تغيير نوع الإعاقة'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDisabilityPicker(
                    value: selectedDisabilityId,
                    onChanged: (value) {
                      setDialogState(() => selectedDisabilityId = value);
                    },
                  ),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                CupertinoDialogAction(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateUserDisability(userId, selectedDisabilityId);
                  },
                  child: const Text('حفظ'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDisabilityPicker({
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    final disabilityNames = [
      'بدون تحديد',
      ..._disabilities.map((d) => d['name_ar'] as String? ?? '').toList(),
    ];
    final disabilityValues = [
      null,
      ..._disabilities.map((d) => d['id'] as int).toList(),
    ];

    String getCurrentText() {
      if (value == null) return 'بدون تحديد';
      final index = disabilityValues.indexOf(value);
      return index != -1 ? disabilityNames[index] : 'بدون تحديد';
    }

    return GestureDetector(
      onTap: () {
        _showPicker<int?>(
          title: 'اختر نوع الإعاقة',
          items: disabilityNames,
          values: disabilityValues,
          currentValue: value,
          onChanged: onChanged,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'نوع الإعاقة',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                Text(
                  getCurrentText(),
                  style: TextStyle(fontSize: 14, color: AppColors.primary),
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

  String _roleText(String role) {
    switch (role) {
      case 'admin':
        return 'أدمن';
      case 'user':
        return 'مستخدم';
      case 'company':
        return 'شركة';
      case 'parent':
        return 'ولي أمر';
      case 'teacher':
        return 'معلم';
      default:
        return role;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'inactive':
        return 'غير نشط';
      case 'suspended':
        return 'موقوف';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'inactive':
        return AppColors.accent;
      case 'suspended':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFF9C27B0);
      case 'company':
        return const Color(0xFF2196F3);
      case 'teacher':
        return const Color(0xFF009688);
      case 'parent':
        return const Color(0xFFFF9800);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Semantics(
          header: true,
          label: 'إدارة المستخدمين',
          child: const Text(
            'المستخدمين',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        backgroundColor: AppColors.surface,
        trailing: AdminMenuSheet(
          currentRoute: 'users',
          adminId: _adminId,
          adminName: _adminName,
          adminEmail: _adminEmail,
        ),
        automaticallyImplyLeading: false,
      ),
      child: _isLoading
          ? Center(
              child: Semantics(
                label: 'جاري تحميل المستخدمين',
                child: CupertinoActivityIndicator(radius: 20),
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _loadAll),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildHeader(),
              const SizedBox(height: 16),
              _buildSearchCard(),
              const SizedBox(height: 16),
              if (_filteredUsers.isEmpty)
                _buildEmptyWidget()
              else
                _buildUsersList(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Semantics(
      label: 'إجمالي المستخدمين: ${_users.length}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
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
                    'إدارة المستخدمين',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'إجمالي المستخدمين: ${_users.length}',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
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
                Icons.people_alt_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: CupertinoTextField(
        controller: _searchController,
        placeholder: 'بحث باسم المستخدم أو البريد أو الهاتف أو الدور',
        placeholderStyle: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.7),
        ),
        padding: const EdgeInsets.all(14),
        prefix: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Icon(
            CupertinoIcons.search,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildUsersList() {
    return ListView.builder(
      itemCount: _filteredUsers.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        final role = (user['role'] ?? 'user').toString();
        final status = (user['status'] ?? 'active').toString();
        final name = user['full_name']?.toString() ?? '';
        final email = user['email']?.toString() ?? '';
        final phone = user['phone']?.toString() ?? '';
        final disabilityName = user['disability_name']?.toString() ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Semantics(
            container: true,
            label:
                'مستخدم $name، الدور ${_roleText(role)}، الحالة ${_statusText(status)}',
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.person,
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
                          name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'البريد: $email',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (phone.isNotEmpty)
                          Text(
                            'الهاتف: $phone',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        if (disabilityName.isNotEmpty)
                          Text(
                            'نوع الإعاقة: $disabilityName',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
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
                                color: _roleColor(role).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _roleText(role),
                                style: TextStyle(
                                  color: _roleColor(role),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(
                                  status,
                                ).withValues(alpha: 0.12),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Semantics(
                        button: true,
                        label: 'تغيير دور المستخدم',
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 40),
                          onPressed: () => _showChangeRoleDialog(user),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              CupertinoIcons.person_add,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Semantics(
                        button: true,
                        label: 'تغيير حالة المستخدم',
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 40),
                          onPressed: () => _showChangeStatusDialog(user),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              CupertinoIcons.switch_camera,
                              size: 18,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Semantics(
                        button: true,
                        label: 'تغيير نوع الإعاقة',
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 40),
                          onPressed: () => _showChangeDisabilityDialog(user),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.teal.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.accessibility_new,
                              size: 18,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 60,
            color: AppColors.textSecondary,
            semanticLabel: 'أيقونة لا توجد مستخدمين',
          ),
          const SizedBox(height: 16),
          const Text(
            'لا يوجد مستخدمون مطابقون',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Semantics(
            button: true,
            label: 'تحديث القائمة',
            child: CupertinoButton(
              color: AppColors.primary,
              onPressed: _loadAll,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.refresh, size: 18,color: Colors.white),
                  SizedBox(width: 8),
                   Text(
                  'تحديث القائمة',
                  style: TextStyle(
                    color: Colors.white,  // ✅ نص أبيض
                    fontSize: 14,
                  ),
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
