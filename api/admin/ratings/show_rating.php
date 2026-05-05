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

    $ratingId = isset($input['rating_id']) ? (int)$input['rating_id'] : 0;

    if ($ratingId <= 0) {
        throw new Exception('معرف التقييم غير صالح');
    }

    $checkStmt = $conn->prepare("SELECT id, status FROM lesson_ratings WHERE id = :id LIMIT 1");
    $checkStmt->bindValue(':id', $ratingId, PDO::PARAM_INT);
    $checkStmt->execute();

    $rating = $checkStmt->fetch(PDO::FETCH_ASSOC);

    if (!$rating) {
        throw new Exception('التقييم غير موجود');
    }

    if ($rating['status'] === 'visible') {
        echo json_encode([
            'success' => true,
            'message' => 'التقييم ظاهر بالفعل'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $stmt = $conn->prepare("
        UPDATE lesson_ratings
        SET status = 'visible'
        WHERE id = :id
    ");
    $stmt->bindValue(':id', $ratingId, PDO::PARAM_INT);
    $stmt->execute();

    echo json_encode([
        'success' => true,
        'message' => 'تم إظهار التقييم بنجاح'
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}