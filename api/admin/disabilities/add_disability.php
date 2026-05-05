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

$name_ar = trim($data['name_ar'] ?? '');
$name_en = trim($data['name_en'] ?? '');
$description = trim($data['description'] ?? '');
$status = trim($data['status'] ?? 'active');

if ($name_ar === '') {
    echo json_encode([
        'success' => false,
        'message' => 'الاسم بالعربي مطلوب'
    ]);
    exit();
}

if (!in_array($status, ['active', 'inactive'])) {
    $status = 'active';
}

try {
    $database = new Database();
    $conn = $database->getConnection();

    $check = $conn->prepare("SELECT id FROM disability_types WHERE name_ar = :name_ar LIMIT 1");
    $check->bindParam(':name_ar', $name_ar);
    $check->execute();

    if ($check->rowCount() > 0) {
        echo json_encode([
            'success' => false,
            'message' => 'هذا النوع موجود مسبقًا'
        ]);
        exit();
    }

    $query = "INSERT INTO disability_types (
                name_ar, name_en, description, status
              ) VALUES (
                :name_ar, :name_en, :description, :status
              )";

    $stmt = $conn->prepare($query);
    $stmt->bindParam(':name_ar', $name_ar);
    $stmt->bindParam(':name_en', $name_en);
    $stmt->bindParam(':description', $description);
    $stmt->bindParam(':status', $status);
    $stmt->execute();

    echo json_encode([
        'success' => true,
        'message' => 'تمت إضافة نوع الإعاقة بنجاح',
        'data' => ['id' => $conn->lastInsertId()]
    ]);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'حدث خطأ أثناء إضافة نوع الإعاقة: ' . $e->getMessage()
    ]);
}
?>