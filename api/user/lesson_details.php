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
    $lessonId = isset($_GET['lesson_id']) ? (int)$_GET['lesson_id'] : 0;
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;

    if ($lessonId <= 0 || $userId <= 0) {
        echo json_encode([
            'success' => false,
            'message' => 'lesson_id and user_id are required'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $database = new Database();
    $conn = $database->getConnection();

    $lessonQuery = "SELECT 
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
                        l.created_at,
                        c.name_ar AS category_name,
                        d.name_ar AS disability_name,
                        COALESCE(lp.progress_percent, 0) AS progress_percent,
                        COALESCE(lp.is_completed, 0) AS is_completed,
                        CASE WHEN fl.id IS NULL THEN 0 ELSE 1 END AS is_favorite,
                        COALESCE((
                            SELECT AVG(r.rating)
                            FROM lesson_ratings r
                            WHERE r.lesson_id = l.id AND r.status = 'visible'
                        ), 0) AS average_rating,
                        COALESCE((
                            SELECT COUNT(*)
                            FROM lesson_ratings r
                            WHERE r.lesson_id = l.id AND r.status = 'visible'
                        ), 0) AS ratings_count,
                        COALESCE((
                            SELECT rating
                            FROM lesson_ratings r
                            WHERE r.lesson_id = l.id AND r.user_id = :user_id
                            LIMIT 1
                        ), 0) AS user_rating
                    FROM lessons l
                    INNER JOIN categories c ON c.id = l.category_id
                    LEFT JOIN disability_types d ON d.id = l.target_disability_id
                    LEFT JOIN lesson_progress lp
                        ON lp.lesson_id = l.id AND lp.user_id = :user_id
                    LEFT JOIN favorite_lessons fl
                        ON fl.lesson_id = l.id AND fl.user_id = :user_id
                    WHERE l.id = :lesson_id
                    AND l.status = 'published'
                    LIMIT 1";

    $lessonStmt = $conn->prepare($lessonQuery);
    $lessonStmt->bindParam(':lesson_id', $lessonId, PDO::PARAM_INT);
    $lessonStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $lessonStmt->execute();
    $lesson = $lessonStmt->fetch(PDO::FETCH_ASSOC);

    if (!$lesson) {
        echo json_encode([
            'success' => false,
            'message' => 'Lesson not found'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $resourcesQuery = "SELECT id, lesson_id, resource_type, file_path, external_url, title
                       FROM lesson_resources
                       WHERE lesson_id = :lesson_id
                       ORDER BY id ASC";

    $resourcesStmt = $conn->prepare($resourcesQuery);
    $resourcesStmt->bindParam(':lesson_id', $lessonId, PDO::PARAM_INT);
    $resourcesStmt->execute();
    $resources = $resourcesStmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'message' => 'Lesson details fetched successfully',
        'data' => [
            'lesson' => $lesson,
            'resources' => $resources
        ]
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error',
        'error' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}