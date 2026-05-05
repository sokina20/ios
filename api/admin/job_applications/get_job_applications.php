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
            ja.id,
            ja.job_id,
            ja.user_id,
            ja.cover_letter,
            ja.cv_file,
            ja.status,
            ja.applied_at,
            ja.reviewed_at,
            ja.notes,
            u.full_name AS applicant_name,
            u.email AS applicant_email,
            u.phone AS applicant_phone,
            j.title AS job_title,
            c.company_name
        FROM job_applications ja
        INNER JOIN users u ON ja.user_id = u.id
        INNER JOIN jobs j ON ja.job_id = j.id
        INNER JOIN companies c ON j.company_id = c.id
        ORDER BY ja.applied_at DESC
    ";

    $stmt = $conn->prepare($sql);
    $stmt->execute();

    $applications = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'applications' => $applications
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}