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
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;

    if ($userId <= 0) {
        echo json_encode([
            'success' => false,
            'message' => 'user_id is required'
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

    $query = "SELECT
                j.id,
                j.company_id,
                j.title,
                j.description,
                j.requirements,
                j.location,
                j.employment_type,
                j.salary_min,
                j.salary_max,
                j.target_disability_id,
                j.application_deadline,
                j.created_at,
                c.company_name,
                c.logo AS company_logo,
                d.name_ar AS disability_name,
                CASE WHEN ja.id IS NULL THEN 0 ELSE 1 END AS has_applied,
                COALESCE(ja.status, '') AS application_status
              FROM jobs j
              INNER JOIN companies c ON c.id = j.company_id
              LEFT JOIN disability_types d ON d.id = j.target_disability_id
              LEFT JOIN job_applications ja
                ON ja.job_id = j.id AND ja.user_id = :user_id
              WHERE j.is_active = 1
              AND c.status = 'approved'
              AND (
                j.target_disability_id IS NULL
                OR j.target_disability_id = :disability_type_id
              )
              ORDER BY
                CASE WHEN j.target_disability_id = :disability_type_id THEN 0 ELSE 1 END,
                j.created_at DESC";

    $stmt = $conn->prepare($query);
    $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    $stmt->bindParam(':disability_type_id', $disabilityTypeId, PDO::PARAM_INT);
    $stmt->execute();

    echo json_encode([
        'success' => true,
        'message' => 'Jobs fetched successfully',
        'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error',
        'error' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}