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

    $checkQuery = "SELECT id FROM lessons WHERE id = :id LIMIT 1";
    $checkStmt = $conn->prepare($checkQuery);
    $checkStmt->bindParam(':id', $id, PDO::PARAM_INT);
    $checkStmt->execute();

    if ($checkStmt->rowCount() === 0) {
        echo json_encode([
            'success' => false,
            'message' => 'الدرس غير موجود'
        ]);
        exit();
    }

    $resourceCheck = $conn->prepare("SELECT id FROM lesson_resources WHERE lesson_id = :id LIMIT 1");
    $resourceCheck->bindParam(':id', $id, PDO::PARAM_INT);
    $resourceCheck->execute();

    if ($resourceCheck->rowCount() > 0) {
        $deleteResources = $conn->prepare("DELETE FROM lesson_resources WHERE lesson_id = :id");
        $deleteResources->bindParam(':id', $id, PDO::PARAM_INT);
        $deleteResources->execute();
    }

    $deleteFavorites = $conn->prepare("DELETE FROM favorite_lessons WHERE lesson_id = :id");
    $deleteFavorites->bindParam(':id', $id, PDO::PARAM_INT);
    $deleteFavorites->execute();

    $deleteProgress = $conn->prepare("DELETE FROM lesson_progress WHERE lesson_id = :id");
    $deleteProgress->bindParam(':id', $id, PDO::PARAM_INT);
    $deleteProgress->execute();

    $deleteCourseLinks = $conn->prepare("DELETE FROM course_lessons WHERE lesson_id = :id");
    $deleteCourseLinks->bindParam(':id', $id, PDO::PARAM_INT);
    $deleteCourseLinks->execute();

    $query = "DELETE FROM lessons WHERE id = :id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':id', $id, PDO::PARAM_INT);
    $stmt->execute();

    echo json_encode([
        'success' => true,
        'message' => 'تم حذف الدرس بنجاح'
    ]);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'حدث خطأ أثناء حذف الدرس: ' . $e->getMessage()
    ]);
}
?>