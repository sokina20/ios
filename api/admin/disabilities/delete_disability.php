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

    $check = $conn->prepare("SELECT id FROM disability_types WHERE id = :id LIMIT 1");
    $check->bindParam(':id', $id, PDO::PARAM_INT);
    $check->execute();

    if ($check->rowCount() === 0) {
        echo json_encode([
            'success' => false,
            'message' => 'نوع الإعاقة غير موجود'
        ]);
        exit();
    }

    $userCheck = $conn->prepare("SELECT id FROM users WHERE disability_type_id = :id LIMIT 1");
    $userCheck->bindParam(':id', $id, PDO::PARAM_INT);
    $userCheck->execute();

    if ($userCheck->rowCount() > 0) {
        echo json_encode([
            'success' => false,
            'message' => 'لا يمكن حذف النوع لأنه مرتبط بمستخدمين'
        ]);
        exit();
    }

    $lessonCheck = $conn->prepare("SELECT id FROM lessons WHERE target_disability_id = :id LIMIT 1");
    $lessonCheck->bindParam(':id', $id, PDO::PARAM_INT);
    $lessonCheck->execute();

    if ($lessonCheck->rowCount() > 0) {
        echo json_encode([
            'success' => false,
            'message' => 'لا يمكن حذف النوع لأنه مرتبط بدروس'
        ]);
        exit();
    }

    $jobCheck = $conn->prepare("SELECT id FROM jobs WHERE target_disability_id = :id LIMIT 1");
    $jobCheck->bindParam(':id', $id, PDO::PARAM_INT);
    $jobCheck->execute();

    if ($jobCheck->rowCount() > 0) {
        echo json_encode([
            'success' => false,
            'message' => 'لا يمكن حذف النوع لأنه مرتبط بوظائف'
        ]);
        exit();
    }

    $stmt = $conn->prepare("DELETE FROM disability_types WHERE id = :id");
    $stmt->bindParam(':id', $id, PDO::PARAM_INT);
    $stmt->execute();

    echo json_encode([
        'success' => true,
        'message' => 'تم حذف نوع الإعاقة بنجاح'
    ]);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'حدث خطأ أثناء حذف نوع الإعاقة: ' . $e->getMessage()
    ]);
}
?>