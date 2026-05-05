<?php
require_once __DIR__ . '/../config/db.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $data = json_decode(file_get_contents("php://input"), true);

    $userId = isset($data['user_id']) ? (int)$data['user_id'] : 0;
    $lessonId = isset($data['lesson_id']) ? (int)$data['lesson_id'] : 0;

    if ($userId <= 0 || $lessonId <= 0) {
        echo json_encode([
            'success' => false,
            'message' => 'user_id and lesson_id are required'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $database = new Database();
    $conn = $database->getConnection();

    $checkQuery = "SELECT id FROM favorite_lessons WHERE user_id = :user_id AND lesson_id = :lesson_id LIMIT 1";
    $checkStmt = $conn->prepare($checkQuery);
    $checkStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $checkStmt->bindParam(':lesson_id', $lessonId, PDO::PARAM_INT);
    $checkStmt->execute();
    $existing = $checkStmt->fetch(PDO::FETCH_ASSOC);

    if ($existing) {
        $deleteQuery = "DELETE FROM favorite_lessons WHERE user_id = :user_id AND lesson_id = :lesson_id";
        $deleteStmt = $conn->prepare($deleteQuery);
        $deleteStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
        $deleteStmt->bindParam(':lesson_id', $lessonId, PDO::PARAM_INT);
        $deleteStmt->execute();

        echo json_encode([
            'success' => true,
            'message' => 'Lesson removed from favorites',
            'is_favorite' => false
        ], JSON_UNESCAPED_UNICODE);
    } else {
        $insertQuery = "INSERT INTO favorite_lessons (user_id, lesson_id) VALUES (:user_id, :lesson_id)";
        $insertStmt = $conn->prepare($insertQuery);
        $insertStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
        $insertStmt->bindParam(':lesson_id', $lessonId, PDO::PARAM_INT);
        $insertStmt->execute();

        echo json_encode([
            'success' => true,
            'message' => 'Lesson added to favorites',
            'is_favorite' => true
        ], JSON_UNESCAPED_UNICODE);
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error',
        'error' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}