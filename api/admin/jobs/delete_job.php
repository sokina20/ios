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

    $check = $conn->prepare("SELECT id FROM jobs WHERE id = :id LIMIT 1");
    $check->bindParam(':id', $id, PDO::PARAM_INT);
    $check->execute();

    if ($check->rowCount() === 0) {
        echo json_encode([
            'success' => false,
            'message' => 'الوظيفة غير موجودة'
        ]);
        exit();
    }

    $deleteApplications = $conn->prepare("DELETE FROM job_applications WHERE job_id = :id");
    $deleteApplications->bindParam(':id', $id, PDO::PARAM_INT);
    $deleteApplications->execute();

    $stmt = $conn->prepare("DELETE FROM jobs WHERE id = :id");
    $stmt->bindParam(':id', $id, PDO::PARAM_INT);
    $stmt->execute();

    echo json_encode([
        'success' => true,
        'message' => 'تم حذف الوظيفة بنجاح'
    ]);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'حدث خطأ أثناء حذف الوظيفة: ' . $e->getMessage()
    ]);
}
?>