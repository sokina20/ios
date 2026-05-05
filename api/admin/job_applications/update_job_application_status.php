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

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception('طريقة الطلب غير مسموحة');
    }

    $database = new Database();
    $conn = $database->getConnection();

    $rawInput = file_get_contents("php://input");
    $jsonInput = json_decode($rawInput, true);

    if (is_array($jsonInput) && !empty($jsonInput)) {
        $input = $jsonInput;
    } else {
        $input = $_POST;
    }

    $applicationId = isset($input['application_id']) ? (int)$input['application_id'] : 0;
    $status = isset($input['status']) ? trim($input['status']) : '';
    $notes = isset($input['notes']) ? trim($input['notes']) : null;

    $allowedStatuses = ['pending', 'reviewed', 'accepted', 'rejected'];

    if ($applicationId <= 0) {
        throw new Exception('معرف الطلب غير صالح');
    }

    if (!in_array($status, $allowedStatuses)) {
        throw new Exception('حالة الطلب غير صالحة');
    }

    $checkStmt = $conn->prepare("SELECT id FROM job_applications WHERE id = :id LIMIT 1");
    $checkStmt->bindValue(':id', $applicationId, PDO::PARAM_INT);
    $checkStmt->execute();

    if ($checkStmt->rowCount() === 0) {
        throw new Exception('طلب التوظيف غير موجود');
    }

    $sql = "
        UPDATE job_applications
        SET status = :status,
            notes = :notes,
            reviewed_at = NOW()
        WHERE id = :id
    ";

    $stmt = $conn->prepare($sql);
    $stmt->bindValue(':status', $status);
    $stmt->bindValue(':notes', $notes);
    $stmt->bindValue(':id', $applicationId, PDO::PARAM_INT);
    $stmt->execute();

    echo json_encode([
        'success' => true,
        'message' => 'تم تحديث حالة الطلب بنجاح'
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}