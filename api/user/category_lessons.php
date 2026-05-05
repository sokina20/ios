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
    $categoryId = isset($_GET['category_id']) ? (int)$_GET['category_id'] : 0;
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;

    if ($categoryId <= 0 || $userId <= 0) {
        echo json_encode([
            'success' => false,
            'message' => 'category_id and user_id are required'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $database = new Database();
    $conn = $database->getConnection();

    $userQuery = "SELECT disability_type_id FROM users WHERE id = :user_id LIMIT 1";
    $userStmt = $conn->prepare($userQuery);
    $userStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $userStmt->execute();
    $user = $userStmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        echo json_encode([
            'success' => false,
            'message' => 'User not found'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $disabilityTypeId = $user['disability_type_id'];

    $categoryQuery = "SELECT id, name_ar, name_en, description, icon
                      FROM categories
                      WHERE id = :category_id AND status = 'active'
                      LIMIT 1";
    $categoryStmt = $conn->prepare($categoryQuery);
    $categoryStmt->bindParam(':category_id', $categoryId, PDO::PARAM_INT);
    $categoryStmt->execute();
    $category = $categoryStmt->fetch(PDO::FETCH_ASSOC);

    if (!$category) {
        echo json_encode([
            'success' => false,
            'message' => 'Category not found'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $lessonsQuery = "SELECT 
                        l.id,
                        l.category_id,
                        l.title_ar,
                        l.title_en,
                        l.short_description,
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
                        ), 0) AS average_rating
                     FROM lessons l
                     INNER JOIN categories c ON c.id = l.category_id
                     LEFT JOIN disability_types d ON d.id = l.target_disability_id
                     LEFT JOIN lesson_progress lp 
                        ON lp.lesson_id = l.id AND lp.user_id = :user_id
                     LEFT JOIN favorite_lessons fl 
                        ON fl.lesson_id = l.id AND fl.user_id = :user_id
                     WHERE l.category_id = :category_id
                     AND l.status = 'published'
                     AND (
                        l.target_disability_id IS NULL
                        OR l.target_disability_id = :disability_type_id
                     )
                     ORDER BY l.is_featured DESC, l.created_at DESC";

    $lessonsStmt = $conn->prepare($lessonsQuery);
    $lessonsStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $lessonsStmt->bindParam(':category_id', $categoryId, PDO::PARAM_INT);
    $lessonsStmt->bindParam(':disability_type_id', $disabilityTypeId, PDO::PARAM_INT);
    $lessonsStmt->execute();
    $lessons = $lessonsStmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'message' => 'Category lessons fetched successfully',
        'data' => [
            'category' => $category,
            'lessons' => $lessons
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