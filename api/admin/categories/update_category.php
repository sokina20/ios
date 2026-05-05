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
$name_ar = trim($data['name_ar'] ?? '');
$name_en = trim($data['name_en'] ?? '');
$description = trim($data['description'] ?? '');
$icon = trim($data['icon'] ?? '');
$status = trim($data['status'] ?? 'active');

if ($id <= 0) {
    echo json_encode([
        'success' => false,
        'message' => 'المعرف غير صالح'
    ]);
    exit();
}

if ($name_ar === '') {
    echo json_encode([
        'success' => false,
        'message' => 'اسم القسم بالعربي مطلوب'
    ]);
    exit();
}

if (!in_array($status, ['active', 'inactive'])) {
    $status = 'active';
}

try {
    $database = new Database();
    $conn = $database->getConnection();

    $checkQuery = "SELECT id FROM categories WHERE id = :id LIMIT 1";
    $checkStmt = $conn->prepare($checkQuery);
    $checkStmt->bindParam(':id', $id, PDO::PARAM_INT);
    $checkStmt->execute();

    if ($checkStmt->rowCount() === 0) {
        echo json_encode([
            'success' => false,
            'message' => 'القسم غير موجود'
        ]);
        exit();
    }

    $dupQuery = "SELECT id FROM categories WHERE name_ar = :name_ar AND id != :id LIMIT 1";
    $dupStmt = $conn->prepare($dupQuery);
    $dupStmt->bindParam(':name_ar', $name_ar);
    $dupStmt->bindParam(':id', $id, PDO::PARAM_INT);
    $dupStmt->execute();

    if ($dupStmt->rowCount() > 0) {
        echo json_encode([
            'success' => false,
            'message' => 'يوجد قسم آخر بنفس الاسم'
        ]);
        exit();
    }

    $query = "UPDATE categories
              SET name_ar = :name_ar,
                  name_en = :name_en,
                  description = :description,
                  icon = :icon,
                  status = :status
              WHERE id = :id";

    $stmt = $conn->prepare($query);
    $stmt->bindParam(':name_ar', $name_ar);
    $stmt->bindParam(':name_en', $name_en);
    $stmt->bindParam(':description', $description);
    $stmt->bindParam(':icon', $icon);
    $stmt->bindParam(':status', $status);
    $stmt->bindParam(':id', $id, PDO::PARAM_INT);
    $stmt->execute();

    echo json_encode([
        'success' => true,
        'message' => 'تم تعديل القسم بنجاح'
    ]);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'حدث خطأ أثناء تعديل القسم: ' . $e->getMessage()
    ]);
}
?>