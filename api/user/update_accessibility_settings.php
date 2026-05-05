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
    $fontSize = isset($data['font_size']) ? trim($data['font_size']) : 'medium';
    $highContrast = isset($data['high_contrast']) ? (int)$data['high_contrast'] : 0;
    $textToSpeech = isset($data['text_to_speech']) ? (int)$data['text_to_speech'] : 0;
    $simplifiedMode = isset($data['simplified_mode']) ? (int)$data['simplified_mode'] : 0;
    $preferredInput = isset($data['preferred_input']) ? trim($data['preferred_input']) : 'touch';

    if ($userId <= 0) {
        echo json_encode([
            'success' => false,
            'message' => 'user_id is required'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $database = new Database();
    $conn = $database->getConnection();

    $checkQuery = "SELECT id FROM accessibility_settings WHERE user_id = :user_id LIMIT 1";
    $checkStmt = $conn->prepare($checkQuery);
    $checkStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $checkStmt->execute();
    $exists = $checkStmt->fetch(PDO::FETCH_ASSOC);

    if ($exists) {
        $query = "UPDATE accessibility_settings
                  SET font_size = :font_size,
                      high_contrast = :high_contrast,
                      text_to_speech = :text_to_speech,
                      simplified_mode = :simplified_mode,
                      preferred_input = :preferred_input,
                      updated_at = CURRENT_TIMESTAMP
                  WHERE user_id = :user_id";
    } else {
        $query = "INSERT INTO accessibility_settings
                  (user_id, font_size, high_contrast, text_to_speech, simplified_mode, preferred_input)
                  VALUES
                  (:user_id, :font_size, :high_contrast, :text_to_speech, :simplified_mode, :preferred_input)";
    }

    $stmt = $conn->prepare($query);
    $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $stmt->bindParam(':font_size', $fontSize);
    $stmt->bindParam(':high_contrast', $highContrast, PDO::PARAM_INT);
    $stmt->bindParam(':text_to_speech', $textToSpeech, PDO::PARAM_INT);
    $stmt->bindParam(':simplified_mode', $simplifiedMode, PDO::PARAM_INT);
    $stmt->bindParam(':preferred_input', $preferredInput);
    $stmt->execute();

    echo json_encode([
        'success' => true,
        'message' => 'تم تحديث إعدادات الوصول بنجاح'
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error',
        'error' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}