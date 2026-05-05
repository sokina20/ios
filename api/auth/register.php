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

    $full_name = trim($data['full_name'] ?? '');
    $email = trim($data['email'] ?? '');
    $phone = trim($data['phone'] ?? '');
    $password = trim($data['password'] ?? '');
    $disability_type_id = isset($data['disability_type_id']) &&
            $data['disability_type_id'] !== ''
        ? (int)$data['disability_type_id']
        : null;

    if ($full_name === '' || $email === '' || $password === '') {
        throw new Exception('الاسم والبريد وكلمة المرور مطلوبة');
    }

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        throw new Exception('البريد الإلكتروني غير صالح');
    }

    if (strlen($password) < 4) {
        throw new Exception('كلمة المرور قصيرة جدًا');
    }

    $database = new Database();
    $conn = $database->getConnection();

    $checkStmt = $conn->prepare("SELECT id FROM users WHERE email = :email LIMIT 1");
    $checkStmt->bindValue(':email', $email);
    $checkStmt->execute();

    if ($checkStmt->fetch(PDO::FETCH_ASSOC)) {
        throw new Exception('البريد الإلكتروني مستخدم مسبقًا');
    }

    if ($disability_type_id !== null) {
        $disabilityStmt = $conn->prepare("
            SELECT id FROM disability_types
            WHERE id = :id AND status = 'active'
            LIMIT 1
        ");
        $disabilityStmt->bindValue(':id', $disability_type_id, PDO::PARAM_INT);
        $disabilityStmt->execute();

        if (!$disabilityStmt->fetch(PDO::FETCH_ASSOC)) {
            throw new Exception('نوع الإعاقة غير صالح');
        }
    }

    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);

    $insertStmt = $conn->prepare("
        INSERT INTO users (
            full_name,
            email,
            phone,
            password,
            role,
            disability_type_id,
            status
        ) VALUES (
            :full_name,
            :email,
            :phone,
            :password,
            'user',
            :disability_type_id,
            'active'
        )
    ");

    $insertStmt->bindValue(':full_name', $full_name);
    $insertStmt->bindValue(':email', $email);
    $insertStmt->bindValue(':phone', $phone !== '' ? $phone : null);
    $insertStmt->bindValue(':password', $hashedPassword);
    $insertStmt->bindValue(':disability_type_id', $disability_type_id, $disability_type_id === null ? PDO::PARAM_NULL : PDO::PARAM_INT);

    $insertStmt->execute();

    $userId = (int)$conn->lastInsertId();

    $profileStmt = $conn->prepare("
        INSERT INTO user_profiles (
            user_id,
            preferred_language
        ) VALUES (
            :user_id,
            'ar'
        )
    ");
    $profileStmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
    $profileStmt->execute();

    $accessStmt = $conn->prepare("
        INSERT INTO accessibility_settings (
            user_id
        ) VALUES (
            :user_id
        )
    ");
    $accessStmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
    $accessStmt->execute();

    echo json_encode([
        'success' => true,
        'message' => 'تم إنشاء الحساب بنجاح'
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>