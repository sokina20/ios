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

    $query = "SELECT 
                u.id,
                u.full_name,
                u.username,
                u.email,
                u.phone,
                u.role,
                u.status,
                u.profile_image,
                u.disability_type_id,
                u.created_at,
                d.name_ar AS disability_name
              FROM users u
              LEFT JOIN disability_types d ON u.disability_type_id = d.id
              ORDER BY u.id DESC";

    $stmt = $conn->prepare($query);
    $stmt->execute();

    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'data' => $users,
        'message' => 'تم جلب المستخدمين بنجاح'
    ]);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'حدث خطأ أثناء جلب المستخدمين: ' . $e->getMessage()
    ]);
}
?>