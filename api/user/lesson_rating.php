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
    $rating = isset($data['rating']) ? (int)$data['rating'] : 0;
    $comment = isset($data['comment']) ? trim($data['comment']) : null;

    if ($userId <= 0 || $lessonId <= 0 || $rating < 1 || $rating > 5) {
        echo json_encode([
            'success' => false,
            'message' => 'Invalid rating data'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $database = new Database();
    $conn = $database->getConnection();

    $checkQuery = "SELECT id FROM lesson_ratings WHERE user_id = :user_id AND lesson_id = :lesson_id LIMIT 1";
    $checkStmt = $conn->prepare($checkQuery);
    $checkStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $checkStmt->bindParam(':lesson_id', $lessonId, PDO::PARAM_INT);
    $checkStmt->execute();
    $existing = $checkStmt->fetch(PDO::FETCH_ASSOC);

    if ($existing) {
        $query = "UPDATE lesson_ratings
                  SET rating = :rating, comment = :comment, status = 'visible'
                  WHERE user_id = :user_id AND lesson_id = :lesson_id";
    } else {
        $query = "INSERT INTO lesson_ratings
                  (lesson_id, user_id, rating, comment, status)
                  VALUES
                  (:lesson_id, :user_id, :rating, :comment, 'visible')";
    }

    $stmt = $conn->prepare($query);
    $stmt->bindParam(':lesson_id', $lessonId, PDO::PARAM_INT);
    $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $stmt->bindParam(':rating', $rating, PDO::PARAM_INT);
    $stmt->bindParam(':comment', $comment);
    $stmt->execute();

    echo json_encode([
        'success' => true,
        'message' => 'Lesson rating saved successfully'
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error',
        'error' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}