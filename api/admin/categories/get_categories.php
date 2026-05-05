<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../../config/db.php';

try {
    $database = new Database();
    $conn = $database->getConnection();

    $query = "SELECT id, name_ar, name_en, description, icon, status, created_at
              FROM categories
              ORDER BY id DESC";

    $stmt = $conn->prepare($query);
    $stmt->execute();

    $categories = $stmt->fetchAll();

    echo json_encode([
        'success' => true,
        'data' => $categories,
        'message' => 'تم جلب الأقسام بنجاح'
    ]);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'حدث خطأ أثناء جلب الأقسام: ' . $e->getMessage()
    ]);
}
?>