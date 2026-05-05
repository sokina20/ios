<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../config/db.php';

try {
    $database = new Database();
    $conn = $database->getConnection();

    $stmt = $conn->prepare("
        SELECT 
            lr.id,
            lr.lesson_id,
            lr.user_id,
            lr.rating,
            lr.comment,
            lr.status,
            lr.created_at,
            l.title_ar AS lesson_title,
            u.full_name AS user_name
        FROM lesson_ratings lr
        LEFT JOIN lessons l ON l.id = lr.lesson_id
        LEFT JOIN users u ON u.id = lr.user_id
        ORDER BY lr.created_at DESC
    ");
    $stmt->execute();
    $ratings = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'data' => $ratings,
        'message' => 'تم جلب التقييمات بنجاح'
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'حدث خطأ: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>