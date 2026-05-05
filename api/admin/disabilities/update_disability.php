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
$status = trim($data['status'] ?? 'active');

if ($id <= 0 || $name_ar === '') {
    echo json_encode([
        'success' => false,
        'message' => 'البيانات غير صالحة'
    ]);
    exit();
}

if (!in_array($status, ['active', 'inactive'])) {
    $status = 'active';
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

    $dup = $conn->prepare("SELECT id FROM disability_types WHERE name_ar = :name_ar AND id != :id LIMIT 1");
    $dup->bindParam(':name_ar', $name_ar);
    $dup->bindParam(':id', $id, PDO::PARAM_INT);
    $dup->execute();

    if ($dup->rowCount() > 0) {
        echo json_encode([
            'success' => false,
            'message' => 'يوجد نوع آخر بنفس الاسم'
        ]);
        exit();
    }

    $query = "UPDATE disability_types SET
                name_ar = :name_ar,
                name_en = :name_en,
                description = :description,
                status = :status
              WHERE id = :id";

    $stmt = $conn->prepare($query);
    $stmt->bindParam(':name_ar', $name_ar);
    $stmt->bindParam(':name_en', $name_en);
    $stmt->bindParam(':description', $description);
    $stmt->bindParam(':status', $status);
    $stmt->bindParam(':id', $id, PDO::PARAM_INT);
    $stmt->execute();

    echo json_encode([
        'success' => true,
        'message' => 'تم تعديل نوع الإعاقة بنجاح'
    ]);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'حدث خطأ أثناء تعديل نوع الإعاقة: ' . $e->getMessage()
    ]);
}
?>