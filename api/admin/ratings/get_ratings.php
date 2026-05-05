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

    $sql = "
        SELECT
            lr.id,
            lr.lesson_id,
            lr.user_id,
            lr.rating,
            lr.comment,
            lr.status,
            lr.created_at,
            l.title_ar AS lesson_title,
            u.full_name AS user_name,
            u.email AS user_email
        FROM lesson_ratings lr
        INNER JOIN lessons l ON lr.lesson_id = l.id
        INNER JOIN users u ON lr.user_id = u.id
        ORDER BY lr.created_at DESC
    ";

    $stmt = $conn->prepare($sql);
    $stmt->execute();

    $ratings = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'data' => $ratings
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}