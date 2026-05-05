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

if ($id <= 0) {
    echo json_encode([
        'success' => false,
        'message' => 'المعرف غير صالح'
    ]);
    exit();
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

    $lessonCheckQuery = "SELECT id FROM lessons WHERE category_id = :id LIMIT 1";
    $lessonCheckStmt = $conn->prepare($lessonCheckQuery);
    $lessonCheckStmt->bindParam(':id', $id, PDO::PARAM_INT);
    $lessonCheckStmt->execute();

    if ($lessonCheckStmt->rowCount() > 0) {
        echo json_encode([
            'success' => false,
            'message' => 'لا يمكن حذف القسم لأنه مرتبط بدروس'
        ]);
        exit();
    }

    $query = "DELETE FROM categories WHERE id = :id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':id', $id, PDO::PARAM_INT);
    $stmt->execute();

    echo json_encode([
        'success' => true,
        'message' => 'تم حذف القسم بنجاح'
    ]);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'حدث خطأ أثناء حذف القسم: ' . $e->getMessage()
    ]);
}
?>