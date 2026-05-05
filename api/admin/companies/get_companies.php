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

    $stmt = $conn->prepare("
        SELECT id, company_name, email, phone, website, city, address, description, logo, status, created_at
        FROM companies
        ORDER BY created_at DESC
    ");
    $stmt->execute();

    $companies = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'data' => $companies,
        'message' => 'تم جلب الشركات بنجاح'
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'حدث خطأ: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>