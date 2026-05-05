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
    $progressPercent = isset($data['progress_percent']) ? (float)$data['progress_percent'] : 0;
    $isCompleted = isset($data['is_completed']) ? (int)$data['is_completed'] : 0;

    if ($userId <= 0 || $lessonId <= 0) {
        echo json_encode([
            'success' => false,
            'message' => 'user_id and lesson_id are required'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    if ($progressPercent < 0) $progressPercent = 0;
    if ($progressPercent > 100) $progressPercent = 100;

    if ($isCompleted === 1) {
        $progressPercent = 100;
    }

    $database = new Database();
    $conn = $database->getConnection();

    $checkQuery = "SELECT id FROM lesson_progress WHERE user_id = :user_id AND lesson_id = :lesson_id LIMIT 1";
    $checkStmt = $conn->prepare($checkQuery);
    $checkStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $checkStmt->bindParam(':lesson_id', $lessonId, PDO::PARAM_INT);
    $checkStmt->execute();
    $existing = $checkStmt->fetch(PDO::FETCH_ASSOC);

    if ($existing) {
        $query = "UPDATE lesson_progress
                  SET progress_percent = :progress_percent,
                      is_completed = :is_completed,
                      completed_at = CASE WHEN :is_completed = 1 THEN NOW() ELSE completed_at END,
                      last_accessed_at = NOW(),
                      updated_at = CURRENT_TIMESTAMP
                  WHERE user_id = :user_id AND lesson_id = :lesson_id";
    } else {
        $query = "INSERT INTO lesson_progress
                  (user_id, lesson_id, progress_percent, is_completed, completed_at, last_accessed_at)
                  VALUES
                  (:user_id, :lesson_id, :progress_percent, :is_completed,
                   CASE WHEN :is_completed = 1 THEN NOW() ELSE NULL END,
                   NOW())";
    }

    $stmt = $conn->prepare($query);
    $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $stmt->bindParam(':lesson_id', $lessonId, PDO::PARAM_INT);
    $stmt->bindParam(':progress_percent', $progressPercent);
    $stmt->bindParam(':is_completed', $isCompleted, PDO::PARAM_INT);
    $stmt->execute();

    echo json_encode([
        'success' => true,
        'message' => 'Lesson progress saved successfully'
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error',
        'error' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
