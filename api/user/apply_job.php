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

    $jobId = isset($data['job_id']) ? (int)$data['job_id'] : 0;
    $userId = isset($data['user_id']) ? (int)$data['user_id'] : 0;
    $coverLetter = isset($data['cover_letter']) ? trim($data['cover_letter']) : null;
    $cvFile = isset($data['cv_file']) ? trim($data['cv_file']) : null;

    if ($jobId <= 0 || $userId <= 0) {
        echo json_encode([
            'success' => false,
            'message' => 'job_id and user_id are required'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    if ((empty($coverLetter) || strlen($coverLetter) < 10) && empty($cvFile)) {
        echo json_encode([
            'success' => false,
            'message' => 'يجب إدخال رسالة تقديم مناسبة أو رفع ملف CV'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $database = new Database();
    $conn = $database->getConnection();

    $jobCheckQuery = "SELECT id FROM jobs WHERE id = :job_id AND is_active = 1 LIMIT 1";
    $jobCheckStmt = $conn->prepare($jobCheckQuery);
    $jobCheckStmt->bindParam(':job_id', $jobId, PDO::PARAM_INT);
    $jobCheckStmt->execute();

    if (!$jobCheckStmt->fetch(PDO::FETCH_ASSOC)) {
        echo json_encode([
            'success' => false,
            'message' => 'الوظيفة غير متاحة'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $checkQuery = "SELECT id FROM job_applications WHERE job_id = :job_id AND user_id = :user_id LIMIT 1";
    $checkStmt = $conn->prepare($checkQuery);
    $checkStmt->bindParam(':job_id', $jobId, PDO::PARAM_INT);
    $checkStmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $checkStmt->execute();

    if ($checkStmt->fetch(PDO::FETCH_ASSOC)) {
        echo json_encode([
            'success' => false,
            'message' => 'لقد قمت بالتقديم على هذه الوظيفة مسبقًا'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $query = "INSERT INTO job_applications
              (job_id, user_id, cover_letter, cv_file, status, applied_at)
              VALUES
              (:job_id, :user_id, :cover_letter, :cv_file, 'pending', NOW())";

    $stmt = $conn->prepare($query);
    $stmt->bindParam(':job_id', $jobId, PDO::PARAM_INT);
    $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $stmt->bindParam(':cover_letter', $coverLetter);
    $stmt->bindParam(':cv_file', $cvFile);
    $stmt->execute();

    echo json_encode([
        'success' => true,
        'message' => 'تم إرسال طلب التقديم بنجاح'
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error',
        'error' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}