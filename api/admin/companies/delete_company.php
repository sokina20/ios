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

    $data = json_decode(file_get_contents("php://input"), true);
    $id = intval($data['id'] ?? 0);

    if ($id <= 0) {
        throw new Exception('معرف الشركة غير صالح');
    }

    $database = new Database();
    $conn = $database->getConnection();

    $stmt = $conn->prepare("DELETE FROM companies WHERE id = :id");
    $stmt->bindValue(':id', $id, PDO::PARAM_INT);
    $stmt->execute();

    echo json_encode([
        'success' => true,
        'message' => 'تم حذف الشركة بنجاح'
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>