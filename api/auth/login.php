<?php

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../config/db.php';

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception('طريقة الطلب غير مسموحة');
    }

    $data = json_decode(file_get_contents("php://input"), true);

    $email = trim($data['email'] ?? '');
    $password = trim($data['password'] ?? '');

    if ($email === '' || $password === '') {
        throw new Exception('البريد الإلكتروني وكلمة المرور مطلوبان');
    }

    $database = new Database();
    $conn = $database->getConnection();

    $stmt = $conn->prepare("
        SELECT id, full_name, email, phone, role, disability_type_id, status, password
        FROM users
        WHERE email = :email
        LIMIT 1
    ");
    $stmt->bindValue(':email', $email);
    $stmt->execute();

    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        echo json_encode([
            'success' => false,
            'message' => 'بيانات الدخول غير صحيحة'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    if (($user['status'] ?? 'active') !== 'active') {
        echo json_encode([
            'success' => false,
            'message' => 'الحساب غير نشط'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $passwordValid = false;

    // للمستخدمين الجدد المشفرين
    if (password_verify($password, $user['password'])) {
        $passwordValid = true;
    }

    // دعم مؤقت للحسابات القديمة غير المشفرة مثل الأدمن
    if (!$passwordValid && $password === $user['password']) {
        $passwordValid = true;
    }

    if (!$passwordValid) {
        echo json_encode([
            'success' => false,
            'message' => 'بيانات الدخول غير صحيحة'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    unset($user['password']);

    echo json_encode([
        'success' => true,
        'message' => 'تم تسجيل الدخول بنجاح',
        'user' => $user
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>