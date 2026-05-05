<?php
require_once __DIR__ . '/../config/db.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $database = new Database();
    $conn = $database->getConnection();

    $query = "SELECT id, name_ar, name_en, description, icon
              FROM categories
              WHERE status = 'active'
              ORDER BY id ASC";

    $stmt = $conn->prepare($query);
    $stmt->execute();

    echo json_encode([
        'success' => true,
        'message' => 'Categories fetched successfully',
        'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error',
        'error' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}