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

    $active_only = isset($_GET['active_only']) && $_GET['active_only'] == '1';

    $query = "SELECT
                id,
                name_ar,
                name_en,
                description,
                status,
                created_at
              FROM disability_types";

    if ($active_only) {
        $query .= " WHERE status = 'active'";
    }

    $query .= " ORDER BY id DESC";

    $stmt = $conn->prepare($query);
    $stmt->execute();
    $items = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'data' => $items,
        'message' => 'تم جلب أنواع الإعاقات بنجاح'
    ]);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'حدث خطأ أثناء جلب أنواع الإعاقات: ' . $e->getMessage()
    ]);
}
?>