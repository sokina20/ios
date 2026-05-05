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
$icon = trim($data['icon'] ?? '');
$status = trim($data['status'] ?? 'active');

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

    $checkQuery = "SELECT id FROM categories WHERE name_ar = :name_ar LIMIT 1";
    $checkStmt = $conn->prepare($checkQuery);
    $checkStmt->bindParam(':name_ar', $name_ar);
    $checkStmt->execute();

    if ($checkStmt->rowCount() > 0) {
        echo json_encode([
            'success' => false,
            'message' => 'هذا القسم موجود مسبقًا'
        ]);
        exit();
    }

    $query = "INSERT INTO categories (name_ar, name_en, description, icon, status)
              VALUES (:name_ar, :name_en, :description, :icon, :status)";

    $stmt = $conn->prepare($query);
    $stmt->bindParam(':name_ar', $name_ar);
    $stmt->bindParam(':name_en', $name_en);
    $stmt->bindParam(':description', $description);
    $stmt->bindParam(':icon', $icon);
    $stmt->bindParam(':status', $status);
    $stmt->execute();

    $newId = $conn->lastInsertId();

    echo json_encode([
        'success' => true,
        'message' => 'تمت إضافة القسم بنجاح',
        'data' => [
            'id' => $newId,
            'name_ar' => $name_ar,
            'name_en' => $name_en,
            'description' => $description,
            'icon' => $icon,
            'status' => $status
        ]
    ]);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'حدث خطأ أثناء إضافة القسم: ' . $e->getMessage()
    ]);
}
?>