<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../../config/db.php';

$data = json_decode(file_get_contents("php://input"), true);

$id = intval($data['id'] ?? 0);
$role = trim($data['role'] ?? '');

if ($id <= 0) {
    echo json_encode([
        'success' => false,
        'message' => 'معرف المستخدم غير صالح'
    ]);
    exit();
}

if (!in_array($role, ['admin', 'user', 'company', 'parent', 'teacher'])) {
    echo json_encode([
        'success' => false,
        'message' => 'الدور غير صالح'
    ]);
    exit();
}

try {
    $database = new Database();
    $conn = $database->getConnection();

    $check = $conn->prepare("SELECT id FROM users WHERE id = :id LIMIT 1");
    $check->bindParam(':id', $id, PDO::PARAM_INT);
    $check->execute();

    if ($check->rowCount() === 0) {
        echo json_encode([
            'success' => false,
            'message' => 'المستخدم غير موجود'
        ]);
        exit();
    }

    $query = "UPDATE users SET role = :role WHERE id = :id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':role', $role);
    $stmt->bindParam(':id', $id, PDO::PARAM_INT);
    $stmt->execute();

    echo json_encode([
        'success' => true,
        'message' => 'تم تحديث دور المستخدم بنجاح'
    ]);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'حدث خطأ أثناء تحديث الدور: ' . $e->getMessage()
    ]);
}
?>