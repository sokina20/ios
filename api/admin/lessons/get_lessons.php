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
                l.id,
                l.category_id,
                l.title_ar,
                l.title_en,
                l.short_description,
                l.content,
                l.lesson_type,
                l.difficulty_level,
                l.target_disability_id,
                l.thumbnail,
                l.lesson_file,
                l.lesson_file_type,
                l.duration_minutes,
                l.is_featured,
                l.status,
                l.created_by,
                l.created_at,
                c.name_ar AS category_name_ar
              FROM lessons l
              INNER JOIN categories c ON l.category_id = c.id
              ORDER BY l.id DESC";

    $stmt = $conn->prepare($query);
    $stmt->execute();
    $lessons = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'data' => $lessons,
        'message' => 'تم جلب الدروس بنجاح'
    ]);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'حدث خطأ أثناء جلب الدروس: ' . $e->getMessage()
    ]);
}
?>